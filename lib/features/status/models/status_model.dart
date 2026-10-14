import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String? mediaUrl;
  final int colorValue;
  final DateTime timestamp;

  const StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    this.mediaUrl,
    required this.colorValue,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'mediaUrl': mediaUrl,
      'colorValue': colorValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime ts = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }

    return StatusModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Contact',
      userAvatar: map['userAvatar'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'],
      colorValue: map['colorValue'] is int
          ? map['colorValue']
          : (int.tryParse(map['colorValue']?.toString() ?? '') ?? 0xFF00A884),
      timestamp: ts,
    );
  }

  bool get isExpired {
    final diff = DateTime.now().difference(timestamp);
    return diff.inHours >= 24;
  }
}
