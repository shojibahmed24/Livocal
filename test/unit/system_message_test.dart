import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/models/message.dart';

void main() {
  group('SystemMessage Serialization & Delivery Receipts', () {
    test('SystemMessage serialization includes senderId and action', () {
      final sysMsg = SystemMessage(
        targetId: 'msg_12345',
        action: MessageAction.statusUpdate,
        update: MessageStatus.delivered.value,
        senderId: 'user_auth_789',
      );

      final map = sysMsg.toMap();
      expect(map['targetId'], equals('msg_12345'));
      expect(map['action'], equals(MessageAction.statusUpdate.value));
      expect(map['update'], equals(MessageStatus.delivered.value));
      expect(map['senderId'], equals('user_auth_789'));

      final reconstructed = SystemMessage.fromMap(map);
      expect(reconstructed.targetId, equals(sysMsg.targetId));
      expect(reconstructed.action, equals(sysMsg.action));
      expect(reconstructed.update, equals(sysMsg.update));
      expect(reconstructed.senderId, equals(sysMsg.senderId));
    });

    test('SystemMessage handles optional senderId gracefully when absent', () {
      final map = {
        'targetId': 'msg_999',
        'action': MessageAction.statusUpdate.value,
        'update': MessageStatus.seen.value,
      };

      final reconstructed = SystemMessage.fromMap(map);
      expect(reconstructed.targetId, equals('msg_999'));
      expect(reconstructed.senderId, isNull);

      final serialized = reconstructed.toMap();
      expect(serialized.containsKey('senderId'), isFalse);
    });
  });
}
