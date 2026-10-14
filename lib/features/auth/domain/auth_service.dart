import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:whatsapp_clone/features/auth/data/repositories/auth_repository.dart';
import 'package:whatsapp_clone/features/auth/views/welcome.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/repositories/firebase_firestore.dart';
import 'package:whatsapp_clone/shared/repositories/firebase_storage.dart';
import 'package:whatsapp_clone/shared/repositories/isar_db.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';

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
      } catch (_) {}
    }

    final user = User(
      id: uid,
      name: username,
      avatarUrl: avatarUrl,
      phone: phone,
      activityStatus: UserActivityStatus.online,
    );

    try {
      await authRepository.registerUser(user.toMap());
    } catch (_) {}
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
    } catch (e) {
      debugPrint('Logout SharedPref clear error: $e');
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
}
