import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/services/device_fingerprint_service.dart';
import 'package:livocal/shared/constants/app_config.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(
    firestore: FirebaseFirestore.instance,
    ref: ref,
  );
});

final walletStreamProvider = StreamProvider.family<UserWallet, String>((ref, userId) {
  return ref.watch(walletRepositoryProvider).watchWallet(userId);
});

class WalletRepository {
  final FirebaseFirestore? firestore;
  final Ref? ref;

  WalletRepository({
    this.firestore,
    this.ref,
  });

  DocumentReference<Map<String, dynamic>>? _walletRef(String userId) {
    if (firestore == null) return null;
    return firestore!.collection('users').doc(userId).collection('wallet').doc('current');
  }

  /// Streams realtime wallet balance & trial state for the authenticated user.
  Stream<UserWallet> watchWallet(String userId) {
    final docRef = _walletRef(userId);
    if (docRef == null) return const Stream.empty();
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserWallet.newTrial();
      }
      return UserWallet.fromMap(snapshot.data()!);
    });
  }

  /// Retrieves current snapshot of the user's wallet.
  Future<UserWallet> getWallet(String userId) async {
    try {
      final docRef = _walletRef(userId);
      if (docRef != null) {
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          return UserWallet.fromMap(doc.data()!);
        }
      }
      return await initializeOrGetWallet(userId: userId);
    } catch (e) {
      debugPrint('[WalletRepository] getWallet error: $e');
      return UserWallet.newTrial();
    }
  }

  /// Calls backend to verify hardware fingerprint, award 14-day 20-min trial if new,
  /// and return the authoritative wallet.
  Future<UserWallet> initializeOrGetWallet({
    required String userId,
    String? phone,
  }) async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      final deviceId = await DeviceFingerprintService().getDeviceFingerprint();

      if (idToken != null && idToken.isNotEmpty) {
        final uri = Uri.parse(AppConfig.walletInitOrGetUrl);
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'deviceId': deviceId,
            'phone': phone ?? currentUser?.phoneNumber ?? '',
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['wallet'] != null) {
            return UserWallet.fromMap(Map<String, dynamic>.from(data['wallet']));
          }
        } else {
          debugPrint('[WalletRepository] Backend init returned status ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('[WalletRepository] Backend wallet init failed, checking local Firestore: $e');
    }

    // Direct Firestore fallback read
    try {
      final docRef = _walletRef(userId);
      if (docRef != null) {
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          return UserWallet.fromMap(doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('[WalletRepository] Firestore fallback read error: $e');
    }

    return UserWallet.newTrial();
  }

  /// Deducts 1 minute for an active translated call via backend transaction.
  /// If [isTranslatedCall] is false, this is a free call and immediately returns success without deduction.
  Future<MinuteDeductionResult> deductMinute({
    required String callId,
    required String callerId,
    String? calleeId,
    required bool isTranslatedCall,
    required int durationSeconds,
    required int minuteIndex,
  }) async {
    if (!isTranslatedCall) {
      return const MinuteDeductionResult(
        success: true,
        deducted: 0,
        remainingMinutes: 999,
        message: 'FREE_LOCAL_CALL',
      );
    }

    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken != null) {
        final url = Uri.parse(AppConfig.walletDeductMinuteUrl);
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'callId': callId,
            'callerId': callerId,
            'calleeId': calleeId ?? '',
            'isTranslatedCall': true,
            'durationSeconds': durationSeconds,
            'minuteIndex': minuteIndex,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return MinuteDeductionResult(
            success: true,
            deducted: data['deducted'] as int? ?? 1,
            remainingMinutes: data['remainingMinutes'] as int? ?? 0,
            lowBalanceWarning: data['lowBalanceWarning'] as bool? ?? false,
            exhausted: data['exhausted'] as bool? ?? false,
            message: data['message'] as String?,
          );
        } else if (response.statusCode == 402) {
          final data = jsonDecode(response.body);
          return MinuteDeductionResult(
            success: false,
            deducted: 0,
            remainingMinutes: 0,
            exhausted: true,
            message: data['message'] as String? ?? 'Minutes exhausted',
          );
        }
      }
    } catch (e) {
      debugPrint('[WalletRepository] deductMinute error: $e');
    }

    // Fallback: check local Firestore wallet
    try {
      final wallet = await getWallet(callerId);
      final hasMin = wallet.hasMinutes;
      final remaining = wallet.effectiveRemainingMinutes;
      return MinuteDeductionResult(
        success: hasMin,
        deducted: hasMin ? 1 : 0,
        remainingMinutes: remaining,
        lowBalanceWarning: remaining <= 2 && remaining > 0,
        exhausted: !hasMin,
      );
    } catch (_) {
      return const MinuteDeductionResult(
        success: true,
        remainingMinutes: 1,
      );
    }
  }

  /// Finalizes call billing record on hang up.
  Future<void> finalizeCallBilling({
    required String callId,
    required int totalDurationSeconds,
    required int totalMinutesBilled,
    required bool isTranslatedCall,
  }) async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken != null) {
        final url = Uri.parse(AppConfig.walletCallEndUrl);
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'callId': callId,
            'totalDurationSeconds': totalDurationSeconds,
            'totalMinutesBilled': totalMinutesBilled,
            'isTranslatedCall': isTranslatedCall,
          }),
        ).timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint('[WalletRepository] finalizeCallBilling error: $e');
    }
  }
}

class MinuteDeductionResult {
  final bool success;
  final int deducted;
  final int remainingMinutes;
  final bool lowBalanceWarning;
  final bool exhausted;
  final String? message;

  const MinuteDeductionResult({
    required this.success,
    this.deducted = 0,
    this.remainingMinutes = 0,
    this.lowBalanceWarning = false,
    this.exhausted = false,
    this.message,
  });
}
