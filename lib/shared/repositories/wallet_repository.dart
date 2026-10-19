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
    } catch (e) {
      debugPrint('[WalletRepository] deductMinute fallback error: $e');
      return const MinuteDeductionResult(
        success: false,
        remainingMinutes: 0,
        exhausted: true,
        message: 'BILLING_GATEWAY_UNAVAILABLE',
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

  /// Recharges prepaid minutes for the user.
  /// Deducts payment via gateway/voucher and updates wallet balance.
  Future<bool> rechargeWallet({
    required String userId,
    required String packId,
    required int minutes,
    required double amount,
    String currency = 'BDT',
    String paymentMethod = 'Instant bKash/Card',
    String? transactionId,
    String? promoCode,
  }) async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();

      if (idToken != null) {
        final url = Uri.parse(AppConfig.walletRechargeUrl);
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'packId': packId,
            'minutes': minutes,
            'amount': amount,
            'currency': currency,
            'paymentMethod': paymentMethod,
            'transactionId': transactionId,
            'promoCode': promoCode,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return true;
          }
        }
      }

      // Local Firestore fallback if backend unreachable
      final docRef = _walletRef(userId);
      if (docRef != null && firestore != null) {
        await firestore!.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          int currentBalance = 0;
          int currentPurchased = 0;
          if (snap.exists && snap.data() != null) {
            final d = snap.data()!;
            currentBalance = (d['balanceMinutes'] as num?)?.toInt() ?? 0;
            currentPurchased = (d['totalMinutesPurchased'] as num?)?.toInt() ?? 0;
          }
          tx.set(docRef, {
            'balanceMinutes': currentBalance + minutes,
            'totalMinutesPurchased': currentPurchased + minutes,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[WalletRepository] rechargeWallet error: $e');
      return false;
    }
  }

  /// Submits real payment verification request (bKash/Nagad or Crypto USDT/Binance Pay)
  Future<PaymentSubmissionResult> submitPaymentRequest({
    required String packId,
    required String senderIdentifier,
    required String trxId,
    String paymentMethod = 'bKash',
    String? promoCode,
    String? senderPhone,
    int? minutes,
    double? amount,
  }) async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();

      if (idToken != null) {
        final url = Uri.parse(AppConfig.walletPaymentRequestUrl);
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'packId': packId,
            'senderIdentifier': senderIdentifier,
            'senderPhone': senderPhone ?? senderIdentifier,
            'trxId': trxId,
            'paymentMethod': paymentMethod,
            'promoCode': promoCode,
            'minutes': minutes,
            'amount': amount,
          }),
        ).timeout(const Duration(seconds: 10));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          return PaymentSubmissionResult(
            success: true,
            message: 'Payment request submitted successfully.',
            paymentData: data['payment'] is Map<String, dynamic> ? data['payment'] : null,
          );
        } else {
          return PaymentSubmissionResult(
            success: false,
            message: data['error']?.toString() ?? 'Payment request could not be processed.',
          );
        }
      }
      return const PaymentSubmissionResult(
        success: false,
        message: 'User session expired. Please log in again.',
      );
    } catch (e) {
      debugPrint('[WalletRepository] submitPaymentRequest error: $e');
      return PaymentSubmissionResult(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  /// Fetches real-time payment deposit accounts & addresses from the server
  Future<Map<String, dynamic>?> getDepositInfo() async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      final url = Uri.parse(AppConfig.walletDepositInfoUrl);
      final headers = <String, String>{};
      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['depositInfo'] is Map<String, dynamic>) {
          return data['depositInfo'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[WalletRepository] getDepositInfo error: $e');
      return null;
    }
  }

  /// Atomically transfers minutes from sender's wallet to receiver's wallet and records audit log
  Future<bool> transferMinutes({
    required String fromUserId,
    required String toUserId,
    required int minutes,
    String? note,
  }) async {
    if (minutes <= 0) return false;

    // 1. Try secure backend relay endpoint first (handles server transaction & audit)
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      final idToken = await currentUser?.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        final uri = Uri.parse(AppConfig.walletP2pTransferUrl);
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'toUserId': toUserId,
            'minutes': minutes,
            'note': note ?? '',
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return true;
          }
        } else {
          debugPrint('[WalletRepository] Backend p2p transfer returned ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('[WalletRepository] Backend p2p transfer failed, trying direct Firestore: $e');
    }

    // 2. Direct Firestore transaction fallback (for unit tests or offline/local fallback)
    if (firestore == null) return false;
    try {
      final senderRef = _walletRef(fromUserId);
      final receiverRef = _walletRef(toUserId);
      if (senderRef == null || receiverRef == null) return false;

      final transferId =
          'p2p_min_${DateTime.now().millisecondsSinceEpoch}_${fromUserId.length > 5 ? fromUserId.substring(0, 5) : fromUserId}';
      final transferRef = firestore!.collection('p2p_transfers').doc(transferId);

      return await firestore!.runTransaction<bool>((tx) async {
        final senderSnap = await tx.get(senderRef);
        if (!senderSnap.exists || senderSnap.data() == null) return false;

        final senderData = senderSnap.data()!;
        final senderBalance = (senderData['balanceMinutes'] as num?)?.toInt() ?? 0;
        if (senderBalance < minutes) return false;

        final receiverSnap = await tx.get(receiverRef);
        int receiverBalance = 0;
        int receiverPurchased = 0;
        if (receiverSnap.exists && receiverSnap.data() != null) {
          final rData = receiverSnap.data()!;
          receiverBalance = (rData['balanceMinutes'] as num?)?.toInt() ?? 0;
          receiverPurchased = (rData['totalMinutesPurchased'] as num?)?.toInt() ?? 0;
        }

        // Deduct from sender
        tx.set(senderRef, {
          'balanceMinutes': senderBalance - minutes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Credit to receiver
        tx.set(receiverRef, {
          'balanceMinutes': receiverBalance + minutes,
          'totalMinutesPurchased': receiverPurchased + minutes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Central audit record for Admin Panel
        tx.set(transferRef, {
          'id': transferId,
          'type': 'minute_transfer',
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'minutes': minutes,
          'note': note ?? '',
          'status': 'completed',
          'method': 'Livocal Wallet',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('[WalletRepository] transferMinutes error: $e');
      return false;
    }
  }
}

class PaymentSubmissionResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? paymentData;

  const PaymentSubmissionResult({
    required this.success,
    this.message,
    this.paymentData,
  });
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
