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
}
