import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class StatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> postStatus(StatusModel status) async {
    try {
      // 1. Populate privacy and allowedUserIds based on user's privacy setting
      final privacySetting =
          SharedPref.instance.getString('status_privacy') ?? 'My contacts';
      List<String> allowedRecipients = List<String>.from(status.allowedUserIds);

      if (allowedRecipients.isEmpty) {
        try {
          final contacts = await IsarDb.getContacts();
          final registeredUids = contacts
              .map((c) => c.userId)
              .where((uid) => uid != null && uid.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          allowedRecipients = registeredUids;
        } catch (e) {
          debugPrint('[StatusService] Error getting contacts for status privacy: $e');
        }
      }

      final payload = status.toMap();
      payload['privacy'] = privacySetting;
      payload['allowedUserIds'] = allowedRecipients;

      // 2. Post to Firestore collection 'statuses'
      await _firestore.collection('statuses').doc(status.id).set(payload);

      // 3. Cache my status locally in SharedPref
      final myStatusMap = {
        'id': status.id,
        'userId': status.userId,
        'userName': status.userName,
        'userAvatar': status.userAvatar,
        'text': status.text,
        'mediaUrl': status.mediaUrl,
        'colorValue': status.colorValue,
        'timestamp': status.timestamp.toIso8601String(),
        'privacy': privacySetting,
        'allowedUserIds': allowedRecipients,
      };
      await SharedPref.instance.setString('my_last_status', jsonEncode(myStatusMap));
    } catch (e) {
      debugPrint('[StatusService] postStatus error: $e');
      final myStatusMap = {
        'id': status.id,
        'userId': status.userId,
        'userName': status.userName,
        'userAvatar': status.userAvatar,
        'text': status.text,
        'mediaUrl': status.mediaUrl,
        'colorValue': status.colorValue,
        'timestamp': status.timestamp.toIso8601String(),
      };
      await SharedPref.instance.setString('my_last_status', jsonEncode(myStatusMap));
    }
  }

  static Future<StatusModel?> uploadPhotoStatus({
    required String userId,
    required String userName,
    required String userAvatar,
    required File imageFile,
    String caption = '',
  }) async {
    try {
      final now = DateTime.now();
      final statusId = 'status_${userId}_${now.millisecondsSinceEpoch}';
      final fileName = '${userId}_${now.millisecondsSinceEpoch}.jpg';

      // 1. Upload to Firebase Storage under /statuses/{fileName}
      final storageRef = _storage.ref().child('statuses/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await storageRef.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Create StatusModel
      final status = StatusModel(
        id: statusId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        text: caption,
        mediaUrl: downloadUrl,
        colorValue: 0xFF000000,
        timestamp: now,
      );

      // 3. Save to Firestore
      await postStatus(status);
      return status;
    } catch (e) {
      debugPrint('[StatusService] uploadPhotoStatus error: $e');
      rethrow;
    }
  }

  static StatusModel? getMyLocalStatus() {
    try {
      final raw = SharedPref.instance.getString('my_last_status');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final status = StatusModel.fromMap(map, map['id'] ?? '');
      if (status.isExpired) return null;
      return status;
    } catch (e) {
      return null;
    }
  }

  static Stream<StatusModel?> getMyStatusStream(String currentUserId) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: currentUserId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return getMyLocalStatus();
          final doc = snap.docs.first;
          final status = StatusModel.fromMap(doc.data(), doc.id);
          if (status.isExpired) return null;
          return status;
        })
        .handleError((err) {
          debugPrint('[StatusService] getMyStatusStream error: $err');
          return getMyLocalStatus();
        });
  }

  static Stream<List<StatusModel>> getRecentStatusesStream(String currentUserId) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection('statuses')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          final list = <StatusModel>[];
          for (final doc in snap.docs) {
            final st = StatusModel.fromMap(doc.data(), doc.id);
            if (st.userId != currentUserId && !st.isExpired) {
              // Privacy enforcement: only show if current user is in allowedUserIds
              if (st.allowedUserIds.contains(currentUserId) ||
                  st.allowedUserIds.isEmpty) {
                list.add(st);
              }
            }
          }
          return list;
        })
        .handleError((err) {
          debugPrint('[StatusService] getRecentStatusesStream error: $err');
          return <StatusModel>[];
        });
  }
}
