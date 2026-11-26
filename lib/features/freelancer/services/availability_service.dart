import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/availability_day.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

/// Weekly availability, local-first with a Firestore mirror.
class AvailabilityService {
  AvailabilityService._();

  static const _weekdays = [1, 2, 3, 4, 5, 6, 7];
  static String? _timezone;

  static Future<String> _localTimeZone() async {
    if (_timezone != null) return _timezone!;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      _timezone = info.identifier;
    } catch (e) {
      debugPrint('[AvailabilityService] timezone failed: $e');
      _timezone = 'UTC';
    }
    return _timezone!;
  }

  static Stream<List<AvailabilityDay>> watch(String ownerUid) {
    return IsarDb.isar.availabilityDays
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final sorted = List<AvailabilityDay>.from(rows)
        ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      return sorted;
    });
  }

  /// Seeds Mon–Fri 09:00–17:00 the first time the screen opens.
  static Future<void> ensureDefaults(String ownerUid) async {
    final existing = await IsarDb.isar.availabilityDays
        .filter()
        .ownerUidEqualTo(ownerUid)
        .count();
    if (existing > 0) return;

    final now = DateTime.now();
    final timezone = await _localTimeZone();
    await IsarDb.isar.writeTxn(() async {
      for (final day in _weekdays) {
        final isWeekday = day <= 5;
        await IsarDb.isar.availabilityDays.put(
          AvailabilityDay(
            ownerUid: ownerUid,
            dayOfWeek: day,
            enabled: isWeekday,
            slots: isWeekday
                ? [AvailabilitySlot(start: '09:00', end: '17:00')]
                : const <AvailabilitySlot>[],
            timezone: timezone,
            updatedAt: now,
            synced: false,
          ),
        );
      }
    });
    final rows = await IsarDb.isar.availabilityDays
        .filter()
        .ownerUidEqualTo(ownerUid)
        .findAll();
    for (final row in rows) {
      await _push(row);
    }
  }

  static Future<void> saveDay(AvailabilityDay day) async {
    day.timezone = await _localTimeZone();
    day.updatedAt = DateTime.now();
    day.synced = false;
    await IsarDb.isar.writeTxn(
      () => IsarDb.isar.availabilityDays.put(day),
    );
    await _push(day);
  }

  /// Patches older rows that were stored before timezone support.
  static Future<void> syncTimezone(String ownerUid) async {
    final timezone = await _localTimeZone();
    final rows = await IsarDb.isar.availabilityDays
        .filter()
        .ownerUidEqualTo(ownerUid)
        .findAll();
    for (final row in rows) {
      if (row.timezone == timezone) continue;
      row.timezone = timezone;
      await saveDay(row);
    }
  }

  static Future<void> _push(AvailabilityDay day) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(day.ownerUid)
          .collection('availability')
          .doc(day.dayOfWeek.toString())
          .set(day.toMap());
      day.synced = true;
      await IsarDb.isar.writeTxn(
        () => IsarDb.isar.availabilityDays.put(day),
      );
    } catch (e) {
      debugPrint('[AvailabilityService] push failed: $e');
    }
  }
}
