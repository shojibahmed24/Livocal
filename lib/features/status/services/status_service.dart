import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class StatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> postStatus(StatusModel status) async {
    try {
      // 1. Post to Firestore collection 'statuses'
      await _firestore.collection('statuses').doc(status.id).set(status.toMap());

      // 2. Cache my status locally in SharedPref
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
    } catch (e) {
      debugPrint('[StatusService] postStatus error: $e');
      // Even if Firestore fails (e.g. offline), preserve locally
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
              list.add(st);
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
