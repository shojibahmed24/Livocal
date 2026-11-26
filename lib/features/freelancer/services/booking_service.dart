import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/booking.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/services/reminder_service.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

/// Host-side booking list with confirm / reschedule / cancel.
class BookingService {
  BookingService._();

  static CollectionReference<Map<String, dynamic>> get _remote =>
      FirebaseFirestore.instance.collection('bookings');

  static Stream<List<Booking>> watch(String hostUid) {
    return IsarDb.isar.bookings
        .filter()
        .hostUidEqualTo(hostUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final list = List<Booking>.from(rows)
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return list;
    });
  }

  /// Pulls every booking of this host (server writes the documents).
  static Future<void> pull(String hostUid) async {
    try {
      final snapshot = await _remote
          .where('hostUid', isEqualTo: hostUid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      for (final doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.id, doc.data());
        final existing = await IsarDb.isar.bookings
            .filter()
            .remoteIdEqualTo(booking.remoteId)
            .findFirst();
        if (existing != null &&
            existing.status == booking.status &&
            existing.startAt == booking.startAt) {
          continue;
        }
        await IsarDb.isar.writeTxn(
          () => IsarDb.isar.bookings.put(booking),
        );
      }
    } catch (e) {
      debugPrint('[BookingService] pull failed: $e');
    }
  }

  static Future<void> confirm(Booking booking,
      {required String hostUid}) async {
    booking.status = 'confirmed';
    await _saveLocal(booking);
    await _push(booking);

    // Confirmed bookings become a CRM follow-up when the guest is a known user.
    final guestUid = await _resolveGuestUid(booking.guestContact);
    if (guestUid != null && guestUid.isNotEmpty && guestUid != hostUid) {
      final entry = await CrmService.ensure(hostUid, guestUid);
      entry.followUpAt = booking.startAt;
      if (entry.stage == CrmService.stageNew) {
        entry.stage = CrmService.stageNegotiating;
      }
      await CrmService.save(entry);
      await ReminderService.scheduleFollowUp(
        id: entry.id,
        clientName: booking.guestName,
        at: booking.startAt,
      );
    }
  }

  static Future<void> reschedule(Booking booking, DateTime startAt) async {
    final duration = booking.endAt.difference(booking.startAt);
    booking.startAt = startAt;
    booking.endAt = startAt.add(duration);
    await _saveLocal(booking);
    await _push(booking);
  }

  static Future<void> cancel(Booking booking) async {
    booking.status = 'cancelled';
    await _saveLocal(booking);
    await _push(booking);
  }

  static Future<void> _saveLocal(Booking booking) async {
    booking.synced = false;
    await IsarDb.isar.writeTxn(() => IsarDb.isar.bookings.put(booking));
  }

  static Future<void> _push(Booking booking) async {
    try {
      await _remote.doc(booking.remoteId).update({
        'status': booking.status,
        'startAt': booking.startAt.toIso8601String(),
        'endAt': booking.endAt.toIso8601String(),
      });
      booking.synced = true;
      await IsarDb.isar.writeTxn(() => IsarDb.isar.bookings.put(booking));
    } catch (e) {
      debugPrint('[BookingService] push failed: $e');
    }
  }

  /// Matches a guest contact string against locally known users by digits.
  static Future<String?> _resolveGuestUid(String contact) async {
    final digits = contact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return null;
    try {
      final users = await IsarDb.getUsers();
      final tail =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      for (final user in users) {
        final userDigits =
            user.phone.rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
        if (userDigits.length >= 7 && userDigits.endsWith(tail)) {
          return user.id;
        }
      }
    } catch (e) {
      debugPrint('[BookingService] guest match failed: $e');
    }
    return null;
  }
}
