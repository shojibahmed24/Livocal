import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/quick_reply.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// Local-first quick replies with a seeded set per language.
class QuickReplyService {
  QuickReplyService._();

  static const categoryPitch = 'pitch';
  static const categoryRate = 'rate';
  static const categoryAvailability = 'availability';
  static const categoryClosing = 'closing';

  static CollectionReference<Map<String, dynamic>> _remote(String ownerUid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('quick_replies');

  static Stream<List<QuickReply>> watch(String ownerUid) {
    return IsarDb.isar.quickReplys
        .filter()
        .ownerUidEqualTo(ownerUid)
        .watch(fireImmediately: true)
        .map((rows) {
      final list = List<QuickReply>.from(rows);
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  /// Seeds English/Bengali starter templates once per user.
  static Future<void> ensureSeeded(String ownerUid, String langCode) async {
    final prefs = SharedPref.instance;
    final key = 'quick_replies_seeded_$ownerUid';
    if (prefs.getBool(key) ?? false) return;

    final seeds = _seedTemplates(langCode);
    await IsarDb.isar.writeTxn(() async {
      for (var i = 0; i < seeds.length; i++) {
        final seed = seeds[i];
        await IsarDb.isar.quickReplys.put(
          QuickReply(
            ownerUid: ownerUid,
            title: seed.$1,
            body: seed.$2,
            category: seed.$3,
            sortOrder: i,
            isDefault: true,
          ),
        );
      }
    });
    await prefs.setBool(key, true);
  }

  static Future<QuickReply> save(QuickReply reply) async {
    if (reply.id == 0) {
      final count = await IsarDb.isar.quickReplys
          .filter()
          .ownerUidEqualTo(reply.ownerUid)
          .count();
      reply.sortOrder = count;
    }
    await IsarDb.isar.writeTxn(() => IsarDb.isar.quickReplys.put(reply));
    unawaited(_push(reply));
    return reply;
  }

  static Future<void> delete(QuickReply reply) async {
    await IsarDb.isar.writeTxn(() => IsarDb.isar.quickReplys.delete(reply.id));
    try {
      await _remote(reply.ownerUid).doc(reply.id.toString()).delete();
    } catch (e) {
      debugPrint('[QuickReplyService] remote delete failed: $e');
    }
  }

  static Future<void> _push(QuickReply reply) async {
    try {
      await _remote(reply.ownerUid).doc(reply.id.toString()).set({
        'title': reply.title,
        'body': reply.body,
        'category': reply.category,
        'sortOrder': reply.sortOrder,
      });
    } catch (e) {
      debugPrint('[QuickReplyService] push failed: $e');
    }
  }

  static List<(String, String, String)> _seedTemplates(String lang) {
    if (lang == 'bn') {
      return const [
        (
          'শুরু করার পিচ',
          'হ্যালো! মেসেজের জন্য ধন্যবাদ। এই কাজটিতে আমি সাহায্য করতে পারব — বিস্তারিত জানালে সময় ও খরচ জানিয়ে দেব।',
          categoryPitch,
        ),
        (
          'রেট জানানো',
          'আমার রেট {amount}/ঘণ্টা (অথবা প্রজেক্ট অনুযায়ী)। আমি এই সপ্তাহেই শুরু করতে পারি।',
          categoryRate,
        ),
        (
          'সময় জানানো',
          'আমি প্রতিদিন সকাল ৯টা–সন্ধ্যা ৬টা (GMT+6) কলের জন্য আছি। সুবিধামতো সময় বলুন।',
          categoryAvailability,
        ),
        (
          'ধন্যবাদ',
          'সময় দেওয়ার জন্য ধন্যবাদ! কিছুক্ষণের মধ্যে প্রপোজাল পাঠাচ্ছি।',
          categoryClosing,
        ),
      ];
    }
    return const [
      (
        'Opening pitch',
        'Hi! Thanks for reaching out. I would be glad to help with this project — share a few details and I will send the scope and timeline.',
        categoryPitch,
      ),
      (
        'Rate',
        'My rate is {amount}/hour (or per project). I can start this week.',
        categoryRate,
      ),
      (
        'Availability',
        'I am available for calls between 9am and 6pm (GMT+6). Let me know a time that works for you.',
        categoryAvailability,
      ),
      (
        'Closing',
        'Thanks for your time! I will send the proposal shortly.',
        categoryClosing,
      ),
    ];
  }
}
