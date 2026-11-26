import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/models/availability_day.dart';
import 'package:livocal/features/freelancer/models/booking.dart';

void main() {
  group('AvailabilitySlot', () {
    test('accepts a normal window', () {
      final slot = AvailabilitySlot(start: '09:00', end: '17:00');
      expect(slot.isValid, isTrue);
      expect(slot.startMinutes, 540);
      expect(slot.endMinutes, 1020);
    });

    test('rejects a reversed or empty window', () {
      expect(
        AvailabilitySlot(start: '17:00', end: '09:00').isValid,
        isFalse,
      );
      expect(
        AvailabilitySlot(start: '10:00', end: '10:00').isValid,
        isFalse,
      );
    });

    test('validSlots sorts by start time', () {
      final day = AvailabilityDay(
        ownerUid: 'me',
        dayOfWeek: 1,
        enabled: true,
        slots: [
          AvailabilitySlot(start: '14:00', end: '17:00'),
          AvailabilitySlot(start: '09:00', end: '12:00'),
        ],
        updatedAt: DateTime(2026, 11, 26),
      );

      expect(day.validSlots.first.start, '09:00');
      expect(day.toMap()['slots'], hasLength(2));
    });
  });

  group('Booking', () {
    test('parses a server document', () {
      final booking = Booking.fromMap('doc1', {
        'hostUid': 'host',
        'guestName': 'Rahim',
        'guestContact': '+8801700000000',
        'note': 'Landing page',
        'startAt': '2026-12-03T09:00:00.000Z',
        'endAt': '2026-12-03T12:00:00.000Z',
        'status': 'pending',
        'createdAt': '2026-11-26T10:00:00.000Z',
      });

      expect(booking.remoteId, 'doc1');
      expect(booking.isPending, isTrue);
      expect(booking.startAt.toUtc(), DateTime.utc(2026, 12, 3, 9));
      expect(booking.endAt.difference(booking.startAt).inHours, 3);
    });

    test('cancelled bookings are not pending or confirmed', () {
      final booking = Booking(
        remoteId: 'doc2',
        hostUid: 'host',
        guestName: 'Alex',
        startAt: DateTime(2026, 12, 1, 10),
        endAt: DateTime(2026, 12, 1, 11),
        createdAt: DateTime(2026, 11, 26),
        status: 'cancelled',
      );

      expect(booking.isCancelled, isTrue);
      expect(booking.isPending, isFalse);
      expect(booking.isConfirmed, isFalse);
    });
  });
}
