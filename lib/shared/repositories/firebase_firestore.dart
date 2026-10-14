import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    } catch (_) {}
  }

  Stream<UserActivityStatus> userActivityStatusStream({required userId}) {
    if (userId.toString().startsWith('demo_')) {
      return Stream.value(UserActivityStatus.online);
    }
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
        .handleError((_) => UserActivityStatus.online);
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
    } catch (_) {}
  }

  Future<void> sendSystemMessage({
    required SystemMessage message,
    required String receiverId,
  }) async {
    try {
      await firestore
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .add(message.toMap())
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
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

          final docData = docChange.doc.data()!;
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
      phoneNumber = phoneNumber
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      QuerySnapshot<Map<String, dynamic>> snap;
      if (phoneNumber.startsWith('+')) {
        snap = await firestore
            .collection('users')
            .where('phone.rawNumber', isEqualTo: phoneNumber)
            .get()
            .timeout(const Duration(seconds: 2));
      } else {
        snap = await firestore
            .collection('users')
            .where('phone.number', isEqualTo: phoneNumber)
            .get()
            .timeout(const Duration(seconds: 2));
      }

      return snap.size == 0 ? null : User.fromMap(snap.docs[0].data());
    } catch (_) {
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
    } catch (_) {}
  }

  Future<String> getFcmToken(String userId) async {
    try {
      final docSnap = await firestore
          .collection('fcmTokens')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      return docSnap.data()?['token'] ?? '';
    } catch (_) {
      return '';
    }
  }
}
