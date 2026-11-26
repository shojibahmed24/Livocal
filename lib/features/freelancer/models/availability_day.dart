import 'package:isar/isar.dart';

part 'availability_day.g.dart';

/// One bookable window, e.g. 09:00–12:00.
@embedded
class AvailabilitySlot {
  /// `HH:mm` 24-hour.
  String start;
  String end;

  AvailabilitySlot({this.start = '09:00', this.end = '17:00'});

  int get startMinutes => _toMinutes(start);
  int get endMinutes => _toMinutes(end);

  bool get isValid => startMinutes < endMinutes;

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  static AvailabilitySlot fromMap(Map<String, dynamic> map) {
    return AvailabilitySlot(
      start: (map['start'] ?? '09:00').toString(),
      end: (map['end'] ?? '17:00').toString(),
    );
  }
}

/// Weekly availability: one row per owner and weekday (1 = Monday).
@collection
class AvailabilityDay {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('dayOfWeek')], unique: true)
  String ownerUid;

  /// 1 (Mon) … 7 (Sun), matching `DateTime.weekday`.
  int dayOfWeek;

  bool enabled;
  List<AvailabilitySlot> slots;
  DateTime updatedAt;
  bool synced;

  AvailabilityDay({
    required this.ownerUid,
    required this.dayOfWeek,
    this.enabled = false,
    List<AvailabilitySlot> slots = const <AvailabilitySlot>[],
    required this.updatedAt,
    this.synced = false,
  }) : slots = List<AvailabilitySlot>.from(slots);

  @ignore
  List<AvailabilitySlot> get validSlots =>
      slots.where((slot) => slot.isValid).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'slots': slots.map((slot) => slot.toMap()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static AvailabilityDay fromMap(int dayOfWeek, Map<String, dynamic> map) {
    final rawSlots = map['slots'];
    return AvailabilityDay(
      ownerUid: '',
      dayOfWeek: dayOfWeek,
      enabled: map['enabled'] == true,
      slots: rawSlots is List
          ? rawSlots
              .whereType<Map>()
              .map(
                (e) => AvailabilitySlot.fromMap(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
          : const <AvailabilitySlot>[],
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      synced: true,
    );
  }
}
