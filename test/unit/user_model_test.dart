import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('User toMap and fromMap serialization integrity', () {
      final user = User(
        id: 'usr_001',
        name: 'Rahim Khan',
        avatarUrl: 'https://example.com/avatar.jpg',
        phone: Phone(
          code: '+880',
          number: '1712345678',
          formattedNumber: '+880 1712345678',
        ),
        activityStatus: UserActivityStatus.online,
      );

      final map = user.toMap();
      expect(map['id'], equals('usr_001'));
      expect(map['name'], equals('Rahim Khan'));
      expect(map['activityStatus'], equals('Online'));

      final reconstructed = User.fromMap(map);
      expect(reconstructed.id, equals(user.id));
      expect(reconstructed.name, equals(user.name));
      expect(reconstructed.phone.getFormattedNumber(), equals('+880 1712345678'));
    });

    test('User copyWith updates specific fields cleanly', () {
      final original = User(
        id: 'usr_002',
        name: 'Old Name',
        avatarUrl: '',
        phone: Phone(code: '+1', number: '5551234'),
        activityStatus: UserActivityStatus.offline,
      );

      final updated = original.copyWith(name: 'New Name', avatarUrl: 'https://img.com/p.jpg');
      expect(updated.id, equals(original.id));
      expect(updated.name, equals('New Name'));
      expect(updated.avatarUrl, equals('https://img.com/p.jpg'));
      expect(updated.phone.code, equals('+1'));
    });
  });
}
