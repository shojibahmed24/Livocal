import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/features/settings/services/block_service.dart';

final firebaseFirestoreRepositoryProvider = Provider(
  (ref) => FirebaseFirestoreRepo(
    firestore: FirebaseFirestore.instance
      ..settings = const Settings(persistenceEnabled: false),
    ref: ref,
  ),
);

class FirebaseFirestoreRepo {
  final FirebaseFirestore firestore;
  final Ref ref;

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
    if (BlockService.isBlocked(message.receiverId)) {
      debugPrint('[FirebaseFirestoreRepo] Cannot send message to blocked contact ${message.receiverId}');
      throw StateError('Cannot send message to a blocked contact');
    }
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
      rethrow;
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

          final isSystemMessage = docData['action'] != null;
          if (isSystemMessage) {
            var deviceId = SharedPref.instance.getString('client_device_id');
            if (deviceId == null || deviceId.isEmpty) {
              deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
              SharedPref.instance.setString('client_device_id', deviceId);
            }

            final processedBy = List<dynamic>.from(docData['processedBy'] ?? []);
            if (!processedBy.contains(deviceId)) {
              final msg = SystemMessage.fromMap(docData);
              switch (msg.action) {
                case MessageAction.statusUpdate:
                  IsarDb.updateMessage(
                    msg.targetId,
                    status: MessageStatus.fromValue(msg.update),
                  );
                  break;
              }
              docChange.doc.reference.update({
                'processedBy': FieldValue.arrayUnion([deviceId]),
              }).catchError((e) {
                debugPrint('FirebaseFirestoreRepo update processedBy error: $e');
              });
            }
            continue;
          }

          // Check if message was deleted for everyone (reflect in local storage & UI)
          if (docData['deletedForEveryone'] == true ||
              docData['content'] == '🚫 This message was deleted') {
            final msgId = docData['id']?.toString() ?? docChange.doc.id;
            await IsarDb.deleteMessageForEveryone(msgId);
          }

          // Drop already-expired disappearing messages
          final expiresAtRaw = docData['expiresAt'];
          if (expiresAtRaw != null) {
            DateTime? expDate;
            if (expiresAtRaw is Timestamp) {
              expDate = expiresAtRaw.toDate();
            } else if (expiresAtRaw is Map) {
              final sec = expiresAtRaw['_seconds'] ?? expiresAtRaw['seconds'];
              if (sec is int) expDate = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
            }
            if (expDate != null && expDate.isBefore(DateTime.now())) {
              docChange.doc.reference.delete().catchError((_) {});
              continue;
            }
          }

          final senderId = docData['senderId'] as String? ?? '';
          if (senderId.isNotEmpty && senderId != ownId && BlockService.isBlocked(senderId)) {
            debugPrint('[FirebaseFirestoreRepo] Dropping message stream item from blocked sender: $senderId');
            continue;
          }

          // Real messages are preserved so multi-device sync and message history never get lost
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

      // 1. Check local cache first
      for (final cand in candidates) {
        final localUser = await IsarDb.getUserByPhone(cand);
        if (localUser != null) return localUser;
      }

      // 2. Authoritative backend match via Admin SDK (prevents client listing/enumeration)
      try {
        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (idToken != null) {
          final response = await http.post(
            Uri.parse(AppConfig.matchContactsUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'phoneNumbers': candidates.toList(),
            }),
          ).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final matches = data['matches'] as List<dynamic>? ?? [];
            if (matches.isNotEmpty) {
              final m = matches.first as Map<String, dynamic>;
              final phoneMap = m['phone'] as Map<String, dynamic>?;
              final rawNumber = phoneMap?['rawNumber'] as String? ?? '';
              final code = phoneMap?['code'] as String? ?? '';
              final number = phoneMap?['number'] as String? ?? '';
              final resolvedUser = User(
                id: m['id'] ?? '',
                name: m['name'] ?? '',
                avatarUrl: m['avatarUrl'] ?? '',
                phone: Phone(
                  code: code,
                  number: number,
                  formattedNumber: rawNumber.isNotEmpty ? rawNumber : '$code$number',
                ),
                activityStatus: UserActivityStatus.fromValue(m['activityStatus'] ?? 'online'),
              );
              await IsarDb.saveUser(resolvedUser);
              return resolvedUser;
            }
          }
        }
      } catch (backendErr) {
        debugPrint('[FirebaseFirestoreRepo] backend getUserByPhone error: $backendErr');
      }

      return null;
    } catch (e) {
      debugPrint('getUserByPhone error: $e');
      return null;
    }
  }

  Future<void> setFcmToken(String token) async {
    String? userId;
    try {
      final raw = SharedPref.instance.getString('user');
      if (raw == null) return;
      final user = jsonDecode(raw);
      userId = user['id'];
      // Security: Store push token ONLY in private /fcmTokens/{userId} collection.
      // Do NOT store in public /users collection to prevent harvesting leaks.
      await firestore
          .collection('fcmTokens')
          .doc(userId)
          .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[FirebaseFirestoreRepo] saveFcmToken error for ${userId ?? "unknown"}: $e');
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
