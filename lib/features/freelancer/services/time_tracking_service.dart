import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/time_entry.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

/// Records completed calls as billable time entries.
class TimeTrackingService {
  TimeTrackingService._();

  static const minimumSeconds = 30;

  static Stream<List<TimeEntry>> watch(String ownerUid) {
    return IsarDb.isar.timeEntrys
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final list = List<TimeEntry>.from(rows)
        ..sort((a, b) => b.at.compareTo(a.at));
      return list;
    });
  }

  static Future<void> recordCall({
    required String ownerUid,
    required String callId,
    required String clientUid,
    required String clientName,
    required int durationSeconds,
    required DateTime at,
  }) async {
    if (durationSeconds < minimumSeconds) return;
    try {
      final rows =
          await IsarDb.isar.timeEntrys.filter().callIdEqualTo(callId).findAll();
      if (rows.any((row) => row.ownerUid == ownerUid)) return;

      final entry = TimeEntry(
        ownerUid: ownerUid,
        callId: callId,
        clientUid: clientUid,
        clientName: clientName,
        minutes: (durationSeconds / 60).ceil(),
        at: at,
      );
      await IsarDb.isar.writeTxn(() => IsarDb.isar.timeEntrys.put(entry));
      unawaited(_push(entry));
    } catch (e) {
      debugPrint('[TimeTrackingService] record failed: $e');
    }
  }

  static Future<void> _push(TimeEntry entry) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(entry.ownerUid)
          .collection('time_entries')
          .doc(entry.callId)
          .set(entry.toMap());
      entry.synced = true;
      await IsarDb.isar.writeTxn(() => IsarDb.isar.timeEntrys.put(entry));
    } catch (e) {
      debugPrint('[TimeTrackingService] push failed: $e');
    }
  }
}
