import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livocal/features/chat/models/attachement.dart';

enum MessageStatus {
  pending('PENDING'),
  sent('SENT'),
  delivered('DELIVERED'),
  seen('SEEN');

  const MessageStatus(this.value);
  final String value;

  factory MessageStatus.fromValue(String value) {
    final res = MessageStatus.values.where(
      (element) => element.value == value,
    );

    if (res.isEmpty) {
      throw 'ValueError: $value is not a valid status code';
    }

    return res.first;
  }
}

class Message {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final Timestamp timestamp;
  final Attachment? attachment;
  MessageStatus status;
  final bool isDeleted;
  final Timestamp? expiresAt;
  final String? disappearingDuration;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.status,
    this.attachment,
    this.isDeleted = false,
    this.expiresAt,
    this.disappearingDuration,
  });

  factory Message.fromMap(Map<String, dynamic> msgData) {
    final rawContent = msgData['content'] as String? ?? '';
    final isDeletedMsg = msgData['deletedForEveryone'] == true ||
        msgData['isDeleted'] == true ||
        rawContent == '🚫 This message was deleted';

    return Message(
      id: msgData['id'],
      content: rawContent,
      status: MessageStatus.fromValue(msgData['status']),
      senderId: msgData['senderId'],
      receiverId: msgData['receiverId'],
      timestamp: msgData['timestamp'],
      attachment: msgData["attachment"] != null
          ? Attachment.fromMap(msgData["attachment"])
          : null,
      isDeleted: isDeletedMsg,
      expiresAt: msgData['expiresAt'] is Timestamp
          ? msgData['expiresAt'] as Timestamp
          : (msgData['expiresAt'] is Map && (msgData['expiresAt']['_seconds'] != null || msgData['expiresAt']['seconds'] != null)
              ? Timestamp(
                  (msgData['expiresAt']['_seconds'] ?? msgData['expiresAt']['seconds']) as int,
                  (msgData['expiresAt']['_nanoseconds'] ?? msgData['expiresAt']['nanoseconds'] ?? 0) as int,
                )
              : null),
      disappearingDuration: msgData['disappearingDuration'] as String?,
    );
  }

  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    String? receiverId,
    Timestamp? timestamp,
    MessageStatus? status,
    Attachment? attachment,
    bool? isDeleted,
    Timestamp? expiresAt,
    String? disappearingDuration,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
      isDeleted: isDeleted ?? this.isDeleted,
      expiresAt: expiresAt ?? this.expiresAt,
      disappearingDuration: disappearingDuration ?? this.disappearingDuration,
    );
  }

  @override
  String toString() {
    return content;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'status': status.value,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (disappearingDuration != null) 'disappearingDuration': disappearingDuration,
      "attachment": attachment?.toMap(),
      'isDeleted': isDeleted,
      'deletedForEveryone': isDeleted,
    };
  }
}

enum MessageAction {
  statusUpdate('STATUS_UPDATE');

  const MessageAction(this.value);
  final String value;

  factory MessageAction.fromValue(String value) {
    final res = MessageAction.values.where(
      (element) => element.value == value,
    );

    if (res.isEmpty) {
      throw 'ValueError: $value is not a valid action';
    }

    return res.first;
  }
}

class SystemMessage {
  final String targetId;
  final MessageAction action;
  final String update;
  final String? senderId;

  SystemMessage({
    required this.targetId,
    required this.action,
    required this.update,
    this.senderId,
  });

  factory SystemMessage.fromMap(Map<String, dynamic> msgData) {
    return SystemMessage(
      targetId: msgData['targetId'],
      action: MessageAction.fromValue(msgData['action']),
      update: msgData['update'],
      senderId: msgData['senderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'action': action.value,
      'update': update,
      if (senderId != null) 'senderId': senderId,
    };
  }
}

