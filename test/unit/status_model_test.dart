import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/status/models/status_model.dart';

void main() {
  group('StatusModel Tests', () {
    test('StatusModel toMap and fromMap serialization integrity', () {
      final now = DateTime.now();
      final status = StatusModel(
        id: 'status_123',
        userId: 'user_456',
        userName: 'Test User',
        userAvatar: 'https://example.com/avatar.jpg',
        text: 'Hello Livocal Status',
        colorValue: 0xFF00A884,
        timestamp: now,
      );

      final map = status.toMap();
      expect(map['id'], 'status_123');
      expect(map['userId'], 'user_456');
      expect(map['userName'], 'Test User');
      expect(map['text'], 'Hello Livocal Status');
      expect(map['colorValue'], 0xFF00A884);

      final revived = StatusModel.fromMap(map, 'status_123');
      expect(revived.id, 'status_123');
      expect(revived.userId, 'user_456');
      expect(revived.text, 'Hello Livocal Status');
      expect(revived.colorValue, 0xFF00A884);
      expect(revived.isExpired, isFalse);
    });

    test('StatusModel correctly identifies expired statuses older than 24 hours', () {
      final past = DateTime.now().subtract(const Duration(hours: 25));
      final expiredStatus = StatusModel(
        id: 'status_old',
        userId: 'user_456',
        userName: 'Test User',
        userAvatar: '',
        text: 'Old status',
        colorValue: 0xFF00A884,
        timestamp: past,
      );

      expect(expiredStatus.isExpired, isTrue);
    });
  });
}
