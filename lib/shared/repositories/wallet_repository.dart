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
        return UserWallet.noTrial();
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
      return UserWallet.noTrial();
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

    return UserWallet.noTrial();
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

    // Fail-closed: Never perform local fallback deduction without backend verification
    return const MinuteDeductionResult(
      success: false,
      remainingMinutes: 0,
      exhausted: true,
      message: 'BILLING_GATEWAY_UNAVAILABLE',
    );
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

      // Fail-closed: Never allow client-side balance self-granting
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

  /// Atomically transfers minutes from sender's wallet to receiver's wallet via authoritative backend.
  /// Eliminates client-side balance manipulation risks and enforces server-side idempotency.
  Future<MinuteTransferResult> transferMinutes({
    required String fromUserId,
    required String toUserId,
    required int minutes,
    String? note,
    String? idempotencyKey,
    String? messageId,
  }) async {
    if (minutes <= 0) {
      return const MinuteTransferResult(
        success: false,
        message: 'Minutes to transfer must be greater than 0',
      );
    }

    final fromSub = fromUserId.length > 8 ? fromUserId.substring(0, 8) : fromUserId;
    final toSub = toUserId.length > 8 ? toUserId.substring(0, 8) : toUserId;
    final idemKey = idempotencyKey ?? 'p2p_${fromSub}_${toSub}_${minutes}_${DateTime.now().millisecondsSinceEpoch ~/ 60000}';

    // 1. Authoritative Backend Gateway
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
            'idempotencyKey': idemKey,
            if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return MinuteTransferResult(
              success: true,
              transferId: data['transferId'] as String?,
              remainingMinutes: (data['remainingMinutes'] as num?)?.toInt(),
              message: data['message'] as String?,
            );
          }
        } else {
          debugPrint('[WalletRepository] Backend p2p transfer returned ${response.statusCode}: ${response.body}');
          try {
            final errData = jsonDecode(response.body);
            return MinuteTransferResult(
              success: false,
              message: errData['error'] as String? ?? 'Transfer rejected by server',
            );
          } catch (_) {}
        }
      } else {
        debugPrint('[WalletRepository] Missing authentication token for P2P transfer');
        return const MinuteTransferResult(
          success: false,
          message: 'Authentication required for minute transfer',
        );
      }
    } catch (e) {
      debugPrint('[WalletRepository] Backend p2p transfer error: $e');
      return MinuteTransferResult(
        success: false,
        message: 'Network error during minute transfer: $e',
      );
    }

    // Fail-closed: Never perform client-side direct balance mutation
    return const MinuteTransferResult(
      success: false,
      message: 'Transfer gateway unreachable',
    );
  }
}

class MinuteTransferResult {
  final bool success;
  final String? transferId;
  final int? remainingMinutes;
  final String? message;

  const MinuteTransferResult({
    required this.success,
    this.transferId,
    this.remainingMinutes,
    this.message,
  });
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
