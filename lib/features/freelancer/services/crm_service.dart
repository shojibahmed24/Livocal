import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

/// Offline-first CRM storage.
///
/// Local Isar is the source of truth for the UI; every write is mirrored to
/// `users/{ownerUid}/crm/{peerUid}` so a reinstall can restore it.
class CrmService {
  CrmService._();

  static const tagProspect = 'prospect';
  static const tagClient = 'client';
  static const tagArchived = 'archived';

  static const stageNew = 'new';
  static const stageNegotiating = 'negotiating';
  static const stageActive = 'active';
  static const stagePaid = 'paid';

  static const basisHourly = 'hourly';
  static const basisProject = 'project';

  static CollectionReference<Map<String, dynamic>> _remote(String ownerUid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('crm');

  static Stream<CrmEntry?> watch(String ownerUid, String peerUid) {
    return IsarDb.isar.crmEntrys
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final matches = rows.where((e) => e.peerUid == peerUid).toList();
      return matches.isEmpty ? null : matches.first;
    });
  }

  static Stream<List<CrmEntry>> watchAll(String ownerUid) {
    return IsarDb.isar.crmEntrys
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) => List<CrmEntry>.from(rows));
  }

  static Future<CrmEntry?> read(String ownerUid, String peerUid) async {
    final rows = await IsarDb.isar.crmEntrys
        .filter()
        .ownerUidEqualTo(ownerUid)
        .findAll();
    final matches = rows.where((e) => e.peerUid == peerUid).toList();
    return matches.isEmpty ? null : matches.first;
  }

  /// Returns the entry, creating a blank one locally when missing.
  static Future<CrmEntry> ensure(String ownerUid, String peerUid) async {
    final existing = await read(ownerUid, peerUid);
    if (existing != null) return existing;

    final entry = CrmEntry(
      ownerUid: ownerUid,
      peerUid: peerUid,
      updatedAt: DateTime.now(),
    );
    await IsarDb.isar.writeTxn(() => IsarDb.isar.crmEntrys.put(entry));
    return entry;
  }

  /// Local-first save, then best-effort mirror to Firestore.
  static Future<CrmEntry> save(CrmEntry entry) async {
    entry.updatedAt = DateTime.now();
    entry.synced = false;
    await IsarDb.isar.writeTxn(() => IsarDb.isar.crmEntrys.put(entry));

    unawaited(_push(entry));
    return entry;
  }

  static Future<void> _push(CrmEntry entry) async {
    try {
      await _remote(entry.ownerUid).doc(entry.peerUid).set(entry.toMap());
      entry.synced = true;
      await IsarDb.isar.writeTxn(() => IsarDb.isar.crmEntrys.put(entry));
    } catch (e) {
      debugPrint('[CrmService] push failed: $e');
    }
  }

  /// Pulls the remote copy when it is newer than the local one.
  static Future<void> refresh(String ownerUid, String peerUid) async {
    try {
      final doc = await _remote(ownerUid)
          .doc(peerUid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return;
      final remote =
          CrmEntry.fromMap(ownerUid, peerUid, doc.data() ?? const {});
      final local = await read(ownerUid, peerUid);
      if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) return;
      remote.synced = true;
      await IsarDb.isar.writeTxn(() => IsarDb.isar.crmEntrys.put(remote));
    } catch (e) {
      debugPrint('[CrmService] refresh failed: $e');
    }
  }

  /// Pushes every row that never reached Firestore (called on app start).
  static Future<void> flushPending(String ownerUid) async {
    try {
      final rows = await IsarDb.isar.crmEntrys
          .filter()
          .ownerUidEqualTo(ownerUid)
          .findAll();
      final pending = rows.where((e) => !e.synced).toList();
      for (final entry in pending) {
        await _push(entry);
      }
    } catch (e) {
      debugPrint('[CrmService] flushPending failed: $e');
    }
  }
}
