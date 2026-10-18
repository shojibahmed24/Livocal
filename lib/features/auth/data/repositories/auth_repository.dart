import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/repositories/auth_repository.dart';
import 'package:livocal/shared/utils/snackbars.dart';

final authRepositoryProvider = Provider((ref) {
  return FirebaseAuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class FirebaseAuthRepository implements AuthenticationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const FirebaseAuthRepository({
    required this.auth,
    required this.firestore,
  });

  @override
  Future<bool> verifyOtp(
    String verificationID,
    String smsCode,
  ) async {
    final preExistingUid = auth.currentUser?.uid;
    try {
      debugPrint('[AuthRepository] verifyOtp starting: verificationId=${verificationID.length > 8 ? '${verificationID.substring(0, 6)}...' : 'present'}, smsCode=******');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationID,
        smsCode: smsCode,
      );

      final userCred = await auth.signInWithCredential(credential);
      debugPrint('[AuthRepository] verifyOtp success: uid=${userCred.user?.uid}');
      return userCred.user != null;
    } on FirebaseAuthException catch (e, st) {
      // Explicit Firebase Auth failure (e.g. invalid-verification-code, session-expired, invalid-credential).
      // NEVER allow fallback or return true on auth failures - prevents backdoor in re-auth / change-number.
      debugPrint('[AuthRepository] verifyOtp FirebaseAuthException: [${e.code}] ${e.message}\n$st');
      return false;
    } on TypeError catch (e, st) {
      debugPrint('[AuthRepository] verifyOtp TypeError (Pigeon decode mismatch): $e\n$st');
      // Only treat as authenticated if native auth genuinely signed in a NEW user/session during this call
      final activeUser = auth.currentUser;
      if (activeUser != null && (preExistingUid == null || activeUser.uid != preExistingUid)) {
        debugPrint('[AuthRepository] User authenticated successfully despite Pigeon decode error: uid=${activeUser.uid}');
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[AuthRepository] verifyOtp unexpected error: $e\n$st');
      return false;
    }
  }

  @override
  Future<void> signInWithPhone(
    BuildContext context,
    ProviderRef ref,
    String phoneNumber,
    void Function(String code) onCodeSent,
  ) async {
    try {
      debugPrint(
          '[AuthRepository] signInWithPhone starting for: ${phoneNumber.length > 4 ? '***${phoneNumber.substring(phoneNumber.length - 4)}' : '***'}');
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
              '[AuthRepository] Silent auto-verification completed via Play Integrity: smsCode=******');
          try {
            await auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('[AuthRepository] Auto sign-in error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[AuthRepository] verificationFailed: code=${e.code}, message=${e.message}');
          if (context.mounted) {
            Navigator.pop(context);
            String message = e.message ?? 'Verification failed';
            if (e.code == 'quota-exceeded') {
              message =
                  'Daily SMS quota exceeded. Add test numbers in Firebase Console.';
            } else if (e.code == 'app-not-authorized') {
              message =
                  'SHA-1 / SHA-256 fingerprint missing in Firebase Project Settings.';
            } else if (e.code == 'invalid-phone-number') {
              message =
                  'Invalid phone number format. Please include country code (e.g. +880).';
            }
            showSnackBar(
              context: context,
              content: message,
              type: SnacBarType.error,
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
              '[AuthRepository] codeSent! verificationId=${verificationId.length > 8 ? '${verificationId.substring(0, 6)}...' : 'present'}, resendToken=${resendToken != null ? 'present' : 'null'}');
          onCodeSent(verificationId);
          if (context.mounted) {
            Navigator.pop(context);
            showSnackBar(
              context: context,
              content: "6-Digit SMS Code Sent!",
              type: SnacBarType.info,
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
              '[AuthRepository] Code auto retrieval timed out: ${verificationId.length > 8 ? '${verificationId.substring(0, 6)}...' : 'present'}');
        },
      );
    } catch (e) {
      debugPrint('[AuthRepository] AuthRepository.verifyPhoneNumber catch: $e');
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(
          context: context,
          content: "Failed to send SMS: $e",
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Future<bool> registerUser(Map<String, dynamic> userData) async {
    try {
      await firestore
          .collection('users')
          .doc(userData['id'])
          .set(userData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('Firestore registerUser error: $e');
      return false;
    }
  }
}
