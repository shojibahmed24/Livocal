import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/chat/models/message.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/repositories/isar_db.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';

final firebaseFirestoreRepositoryProvider = Provider(
  (ref) => FirebaseFirestoreRepo(
    firestore: FirebaseFirestore.instance
      ..settings = const Settings(persistenceEnabled: false),
    ref: ref,
  ),
);

class FirebaseFirestoreRepo {
  final FirebaseFirestore firestore;
  final ProviderRef ref;

  const FirebaseFirestoreRepo({
    required this.firestore,
    required this.ref,
  });

  Future<void> setActivityStatus({
    required String userId,
    required String statusValue,
  }) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .update({'activityStatus': statusValue});
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] setActivityStatus failed for $userId: $e');
    }
  }

  Stream<UserActivityStatus> userActivityStatusStream({required userId}) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) {
          final data = event.data();
          if (data == null || data['activityStatus'] == null) {
            return UserActivityStatus.online;
          }
          return UserActivityStatus.fromValue(data['activityStatus']);
        })
        .handleError((err) {
          debugPrint('[FirebaseFirestoreRepo] userActivityStatusStream error for $userId: $err');
          return UserActivityStatus.online;
        });
  }

  Future<void> sendMessage(Message message) async {
    try {
      await firestore
          .collection('chats')
          .doc(message.receiverId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap())
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] sendMessage failed for ${message.id}: $e');
    }
  }

  Future<void> sendSystemMessage({
    required SystemMessage message,
    required String receiverId,
  }) async {
    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      final payload = message.toMap();
      if (authUid != null && !payload.containsKey('senderId')) {
        payload['senderId'] = authUid;
      }
      await firestore
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .add(payload)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] sendSystemMessage failed for ${message.targetId}: $e');
    }
  }

  Future<User?> getUserById(String id) async {
    final documentSnapshot = await firestore.collection('users').doc(id).get();

    return documentSnapshot.exists
        ? User.fromMap(documentSnapshot.data()!)
        : null;
  }

  Stream<List<Message>> getChatStream(String ownId) {
    return firestore
        .collection('chats')
        .doc(ownId)
        .collection('messages')
        .snapshots()
        .asyncMap(
      (querySnap) async {
        final messages = <Message>[];

        for (final docChange in querySnap.docChanges) {
          if (docChange.type == DocumentChangeType.removed) continue;

          final docData = docChange.doc.data();
          if (docData == null) continue;
          docChange.doc.reference.delete();

          final isSystemMessage = docData['action'] != null;
          if (isSystemMessage) {
            final msg = SystemMessage.fromMap(docData);
            switch (msg.action) {
              case MessageAction.statusUpdate:
                IsarDb.updateMessage(
                  msg.targetId,
                  status: MessageStatus.fromValue(msg.update),
                );
                break;
            }
            continue;
          }

          messages.add(Message.fromMap(docData));
        }

        return messages;
      },
    );
  }

  Future<User?> getUserByPhone(String phoneNumber) async {
    try {
      final clean = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (clean.isEmpty) return null;

      final candidates = <String>{clean};
      if (clean.startsWith('+')) {
        candidates.add(clean.substring(1));
      } else {
        candidates.add('+$clean');
        if (clean.startsWith('0')) {
          candidates.add('+880${clean.substring(1)}');
          candidates.add('880${clean.substring(1)}');
          candidates.add(clean.substring(1));
        } else {
          candidates.add('+880$clean');
          candidates.add('0$clean');
        }
      }

      for (final cand in candidates) {
        final snapRaw = await firestore
            .collection('users')
            .where('phone.rawNumber', isEqualTo: cand)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3));
        if (snapRaw.docs.isNotEmpty) {
          return User.fromMap(snapRaw.docs.first.data());
        }

        final snapNum = await firestore
            .collection('users')
            .where('phone.number', isEqualTo: cand)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3));
        if (snapNum.docs.isNotEmpty) {
          return User.fromMap(snapNum.docs.first.data());
        }
      }

      // Suffix fallback (match last 8-10 digits)
      final allSnap = await firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 5));
      final coreDigits = clean.length >= 8 ? clean.substring(clean.length - 8) : clean;
      for (final doc in allSnap.docs) {
        final data = doc.data();
        final phoneMap = data['phone'] as Map<String, dynamic>?;
        if (phoneMap != null) {
          final raw = (phoneMap['rawNumber'] ?? '').toString().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
          final num = (phoneMap['number'] ?? '').toString().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
          if ((raw.isNotEmpty && raw.endsWith(coreDigits)) ||
              (num.isNotEmpty && num.endsWith(coreDigits))) {
            return User.fromMap(data);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('getUserByPhone error: $e');
      return null;
    }
  }

  Future<void> setFcmToken(String token) async {
    try {
      final raw = SharedPref.instance.getString('user');
      if (raw == null) return;
      final user = jsonDecode(raw);
      final userId = user['id'];
      await Future.wait([
        firestore
            .collection('fcmTokens')
            .doc(userId)
            .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 4)),
        firestore
            .collection('users')
            .doc(userId)
            .set({'fcmToken': token}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 4)),
      ]);
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] saveFcmToken error for $userId: $e');
    }
  }

  Future<String> getFcmToken(String userId) async {
    try {
      final docSnap = await firestore
          .collection('fcmTokens')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      return docSnap.data()?['token'] ?? '';
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] getFcmToken error for $userId: $e');
      return '';
    }
  }
}
