import 'package:isar/isar.dart';

part 'time_entry.g.dart';

/// One completed call, recorded for time tracking and billing.
@collection
class TimeEntry {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('callId')], unique: true)
  String ownerUid;

  String callId;
  String clientUid;
  String clientName;

  /// Rounded up to the next full minute.
  int minutes;

  DateTime at;
  bool synced;

  TimeEntry({
    required this.ownerUid,
    required this.callId,
    required this.clientUid,
    required this.clientName,
    required this.minutes,
    required this.at,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'clientUid': clientUid,
        'clientName': clientName,
        'minutes': minutes,
        'at': at.toIso8601String(),
      };
}
