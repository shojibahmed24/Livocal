import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

/// Local-first invoice storage with a Firestore mirror and a per-user counter.
class InvoiceService {
  InvoiceService._();

  static CollectionReference<Map<String, dynamic>> _remote(String ownerUid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('invoices');

  static Stream<List<Invoice>> watch(String ownerUid) {
    return IsarDb.isar.invoices
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final list = List<Invoice>.from(rows);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<List<Invoice>> listFor(String ownerUid) async {
    final rows =
        await IsarDb.isar.invoices.filter().ownerUidEqualTo(ownerUid).findAll();
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  /// Creates a draft with the next sequential number.
  static Future<Invoice> create({
    required String ownerUid,
    required String clientUid,
    required String clientName,
    String currency = 'USD',
  }) async {
    final sequence = await _nextSequence(ownerUid);
    final invoice = Invoice(
      ownerUid: ownerUid,
      clientUid: clientUid,
      clientName: clientName,
      number: _formatNumber(sequence),
      currency: currency,
      status: 'draft',
      createdAt: DateTime.now(),
      items: [InvoiceLine()],
    );
    await IsarDb.isar.writeTxn(() => IsarDb.isar.invoices.put(invoice));
    unawaited(_push(invoice));
    return invoice;
  }

  static Future<Invoice> save(Invoice invoice) async {
    invoice.synced = false;
    await IsarDb.isar.writeTxn(() => IsarDb.isar.invoices.put(invoice));
    unawaited(_push(invoice));
    return invoice;
  }

  static Future<Invoice> markSent(Invoice invoice) async {
    invoice.status = 'sent';
    invoice.sentAt = DateTime.now();
    return save(invoice);
  }

  static String _newToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(24, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  /// Publishes a public snapshot and returns the share token.
  static Future<String> ensureShareToken(
    Invoice invoice,
    String ownerName,
  ) async {
    if (invoice.publicToken.isEmpty) {
      invoice.publicToken = _newToken();
      await save(invoice);
    }
    try {
      await FirebaseFirestore.instance
          .collection('public_invoices')
          .doc(invoice.publicToken)
          .set({
        'ownerUid': invoice.ownerUid,
        'ownerName': ownerName,
        'number': invoice.number,
        'clientName': invoice.clientName,
        'items': invoice.items.map((item) => item.toMap()).toList(),
        'currency': invoice.currency,
        'taxPct': invoice.taxPct,
        'discount': invoice.discount,
        'total': invoice.total,
        'status': invoice.status,
        'dueDate': invoice.dueDate?.toIso8601String(),
        'notes': invoice.notes,
        'createdAt': invoice.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[InvoiceService] public snapshot failed: $e');
    }
    return invoice.publicToken;
  }

  static Future<Invoice> markPaid(Invoice invoice, {String? messageId}) async {
    invoice.status = 'paid';
    invoice.paidAt = DateTime.now();
    if (messageId != null) invoice.paymentMsgId = messageId;
    return save(invoice);
  }

  static Future<Invoice> markVoid(Invoice invoice) async {
    invoice.status = 'void';
    return save(invoice);
  }

  static Future<void> delete(Invoice invoice) async {
    await IsarDb.isar.writeTxn(() => IsarDb.isar.invoices.delete(invoice.id));
    try {
      await _remote(invoice.ownerUid).doc(invoice.id.toString()).delete();
    } catch (e) {
      debugPrint('[InvoiceService] remote delete failed: $e');
    }
  }

  /// Called after a P2P payment message is sent: matches a sent invoice with
  /// the same total and marks it paid. Returns the matched invoice, if any.
  static Future<Invoice?> autoMarkPaid({
    required String ownerUid,
    required String clientUid,
    required double amount,
    String? messageId,
  }) async {
    try {
      final rows = await IsarDb.isar.invoices
          .filter()
          .ownerUidEqualTo(ownerUid)
          .findAll();
      final candidates = rows
          .where(
            (invoice) =>
                invoice.clientUid == clientUid &&
                invoice.status == 'sent' &&
                (invoice.total - amount).abs() < 0.5,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (candidates.isEmpty) return null;
      return await markPaid(candidates.first, messageId: messageId);
    } catch (e) {
      debugPrint('[InvoiceService] autoMarkPaid failed: $e');
      return null;
    }
  }

  /// Best-effort restore after a reinstall (cloud copy wins only for numbers
  /// that do not exist locally).
  static Future<void> pull(String ownerUid) async {
    try {
      final snapshot = await _remote(ownerUid)
          .get(
            const GetOptions(source: Source.server),
          )
          .timeout(const Duration(seconds: 8));
      final local = await listFor(ownerUid);
      final knownNumbers = local.map((e) => e.number).toSet();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final number = (data['number'] ?? '').toString();
        if (number.isEmpty || knownNumbers.contains(number)) continue;
        final invoice = Invoice.fromMap(ownerUid, doc.id, data);
        await IsarDb.isar.writeTxn(() => IsarDb.isar.invoices.put(invoice));
      }
    } catch (e) {
      debugPrint('[InvoiceService] pull failed: $e');
    }
  }

  static Future<void> _push(Invoice invoice) async {
    try {
      await _remote(invoice.ownerUid)
          .doc(invoice.id.toString())
          .set(invoice.toMap());
      invoice.synced = true;
      await IsarDb.isar.writeTxn(() => IsarDb.isar.invoices.put(invoice));
    } catch (e) {
      debugPrint('[InvoiceService] push failed: $e');
    }
  }

  static Future<int> _nextSequence(String ownerUid) async {
    final counter = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('counters')
        .doc('invoice');
    try {
      var next = 1;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(counter);
        next = ((snapshot.data()?['value'] as num?)?.toInt() ?? 0) + 1;
        transaction.set(
          counter,
          {'value': next, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      });
      return next;
    } catch (e) {
      debugPrint('[InvoiceService] counter unavailable, using local: $e');
      final count =
          await IsarDb.isar.invoices.filter().ownerUidEqualTo(ownerUid).count();
      return count + 1;
    }
  }

  static String _formatNumber(int sequence) {
    final padded = sequence.toString().padLeft(3, '0');
    return 'INV-${DateTime.now().year}-$padded';
  }
}
