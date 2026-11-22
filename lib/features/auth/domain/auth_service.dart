import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:http/http.dart' as http;
import 'package:livocal/features/auth/data/repositories/auth_repository.dart';
import 'package:livocal/features/auth/views/welcome.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/repositories/firebase_storage.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

final authControllerProvider = Provider((ref) {
  return AuthController(ref: ref);
});

final verificationCodeProvider = StateProvider((ref) => '');

class AuthController {
  final ProviderRef ref;
  final FirebaseAuthRepository authRepository;

  AuthController({required this.ref})
      : authRepository = ref.watch(authRepositoryProvider);

  Future<bool> verifyOtp(
    String verificationID,
    String smsCode,
  ) async {
    return await authRepository.verifyOtp(
      verificationID,
      smsCode,
    );
  }

  Future<void> sendVerificationCode(
    BuildContext context,
    String phoneNumber,
    void Function(String code) onCodeSent,
  ) async {
    await authRepository.signInWithPhone(
      context,
      ref,
      phoneNumber,
      onCodeSent,
    );
  }

  Future<User> saveUserData(
    BuildContext context,
    WidgetRef ref,
    String username,
    Phone phone,
    File? avatar,
  ) async {
    String uid =
        authRepository.auth.currentUser?.uid ?? 'user_${phone.number}';
    String avatarUrl =
        'https://en.gravatar.com/userimage/238463648/8cc16f6f5423605920569a634fd097eb.jpeg?size=256';

    if (avatar != null) {
      try {
        final task = await ref
            .read(firebaseStorageRepoProvider)
            .uploadFileToFirebase(avatar, 'userAvatars/$uid');
        avatarUrl = await (await task).ref.getDownloadURL();
      } catch (e) {
        debugPrint('[AuthService] Avatar upload error for $uid: $e');
      }
    }

    final isExplicit = CallRepository.hasExplicitLanguage();
    final user = User(
      id: uid,
      name: username,
      avatarUrl: avatarUrl,
      phone: phone,
      activityStatus: UserActivityStatus.online,
      spokenLanguage: CallRepository.getMyLanguageCode(),
      hasExplicitSpokenLanguage: isExplicit,
    );

    try {
      await authRepository.registerUser(user.toMap());
    } catch (e) {
      debugPrint('[AuthService] registerUser failed in Firestore: $e');
      rethrow;
    }
    return user;
  }

  static Future<void> logout({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
  }) async {
    try {
      ref.read(firebaseFirestoreRepositoryProvider).setActivityStatus(
            userId: userId,
            statusValue: UserActivityStatus.offline.value,
          );
    } catch (e) {
      debugPrint('Logout setActivityStatus error: $e');
    }

    try {
      await IsarDb.clearAll();
    } catch (e) {
      debugPrint('Logout IsarDb.clearAll error: $e');
    }

    try {
      await SharedPref.instance.remove('user');
      await SharedPref.instance.remove('fcm_token_registered');
      await SharedPref.instance.remove('fcmToken');
      await SharedPref.instance.remove('call_history_records_v1');
      // Wipe any scoped and unscoped payment cache keys to prevent cross-account leaks
      final prefKeys = SharedPref.instance.getKeys();
      for (final k in prefKeys) {
        if (k.startsWith('payment_')) {
          await SharedPref.instance.remove(k);
        }
      }
    } catch (e) {
      debugPrint('Logout SharedPref clear error: $e');
    }

    try {
      await SecurePinService.wipe();
    } catch (e) {
      debugPrint('Logout SecurePinService.wipe error: $e');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Logout tempDir clear error: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Logout FirebaseAuth.signOut error: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomePage(),
      ),
      (route) => false,
    );
  }

  /// Full account erasure. The backend performs the cascade (Storage,
  /// Firestore collections/subcollections, then Firebase Auth) with Admin SDK
  /// privileges, so wallet/payment PII and media cannot be left behind.
  ///
  /// Returns `true` only after the server confirmed deletion. On any failure
  /// the local session is kept so the user can safely retry.
  static Future<bool> deleteAccount({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'You are not signed in. Please sign in and try again.',
          type: SnacBarType.error,
        );
      }
      return false;
    }

    try {
      final idToken = await user.getIdToken(true);
      final response = await http
          .post(
            Uri.parse(AppConfig.accountDeleteUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'confirm': 'DELETE'}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        debugPrint(
          '[AuthController] deleteAccount failed (${response.statusCode}): ${response.body}',
        );
        if (context.mounted) {
          showSnackBar(
            context: context,
            content:
                'Account deletion could not be completed. Please check your connection and retry.',
            type: SnacBarType.error,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('[AuthController] deleteAccount network error: $e');
      if (context.mounted) {
        showSnackBar(
          context: context,
          content:
              'Account deletion could not be completed. Please check your connection and retry.',
          type: SnacBarType.error,
        );
      }
      return false;
    }

    if (context.mounted) {
      await logout(
        context: context,
        ref: ref,
        userId: userId,
      );
    }
    return true;
  }
}
