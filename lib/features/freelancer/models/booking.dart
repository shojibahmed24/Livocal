import 'package:isar/isar.dart';

part 'booking.g.dart';

/// A slot request created from the public booking page.
@collection
class Booking {
  Id id = Isar.autoIncrement;

  /// Firestore document id — the only stable identity (server creates it).
  @Index(unique: true)
  String remoteId;

  @Index()
  String hostUid;

  String guestName;
  String guestContact;
  String note;

  DateTime startAt;
  DateTime endAt;
  DateTime createdAt;

  /// `pending` | `confirmed` | `cancelled`
  String status;

  bool synced;

  Booking({
    required this.remoteId,
    required this.hostUid,
    required this.guestName,
    this.guestContact = '',
    this.note = '',
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    this.status = 'pending',
    this.synced = true,
  });

  @ignore
  bool get isPending => status == 'pending';

  @ignore
  bool get isConfirmed => status == 'confirmed';

  @ignore
  bool get isCancelled => status == 'cancelled';

  @ignore
  bool get isPast => endAt.isBefore(DateTime.now());

  static Booking fromMap(String remoteId, Map<String, dynamic> map) {
    final start =
        DateTime.tryParse((map['startAt'] ?? '').toString()) ?? DateTime.now();
    final end = DateTime.tryParse((map['endAt'] ?? '').toString()) ??
        start.add(const Duration(hours: 1));
    return Booking(
      remoteId: remoteId,
      hostUid: (map['hostUid'] ?? '').toString(),
      guestName: (map['guestName'] ?? '').toString(),
      guestContact: (map['guestContact'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      startAt: start,
      endAt: end,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: (map['status'] ?? 'pending').toString(),
      synced: true,
    );
  }

  Map<String, dynamic> toMap() => {
        'hostUid': hostUid,
        'guestName': guestName,
        'guestContact': guestContact,
        'note': note,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
