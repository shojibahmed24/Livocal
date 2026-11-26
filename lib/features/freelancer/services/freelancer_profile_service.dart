import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Thrown when another user already leased the generated slug.
class SlugTakenException implements Exception {
  const SlugTakenException();
}

/// Local-first public profile with a Firestore mirror.
///
/// The slug is leased in `profiles_slug/{slug}` inside a transaction so two
/// users can never publish the same link.
class FreelancerProfileService {
  FreelancerProfileService._();

  static const availabilityFullTime = 'full_time';
  static const availabilityPartTime = 'part_time';
  static const availabilityBusy = 'busy';

  static CollectionReference<Map<String, dynamic>> get _profiles =>
      FirebaseFirestore.instance.collection('profiles');

  static CollectionReference<Map<String, dynamic>> get _slugClaims =>
      FirebaseFirestore.instance.collection('profiles_slug');

  static Future<FreelancerProfile?> read(String ownerUid) async {
    final rows = await IsarDb.isar.freelancerProfiles
        .filter()
        .ownerUidEqualTo(ownerUid)
        .findAll();
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the stored profile, creating a draft with an unused slug.
  static Future<FreelancerProfile> ensure(
    String ownerUid, {
    required String displayName,
    required String avatarUrl,
  }) async {
    final existing = await read(ownerUid);
    if (existing != null) return existing;

    final profile = FreelancerProfile(
      ownerUid: ownerUid,
      slug: _generateSlug(displayName),
      displayName: displayName,
      avatarUrl: avatarUrl,
      updatedAt: DateTime.now(),
    );
    await IsarDb.isar.writeTxn(
      () => IsarDb.isar.freelancerProfiles.put(profile),
    );
    return profile;
  }

  /// Local write first, then a best-effort atomic push to Firestore.
  static Future<FreelancerProfile> save(FreelancerProfile profile) async {
    profile.updatedAt = DateTime.now();
    profile.synced = false;
    await IsarDb.isar.writeTxn(
      () => IsarDb.isar.freelancerProfiles.put(profile),
    );
    unawaited(_pushWithRetry(profile));
    return profile;
  }

  /// Pulls the remote copy when it is newer than the local draft.
  static Future<void> refresh(String ownerUid) async {
    try {
      final doc = await _profiles
          .doc(ownerUid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return;
      final remote =
          FreelancerProfile.fromMap(ownerUid, doc.data() ?? const {});
      final local = await read(ownerUid);
      if (local != null) {
        local.mergeMissingFrom(remote);
        await IsarDb.isar.writeTxn(
          () => IsarDb.isar.freelancerProfiles.put(local),
        );
      }
      if (local != null && !remote.updatedAt.isAfter(local.updatedAt)) return;
      // Never drop an unsynced local slug: it may not be claimed remotely yet.
      if (local != null && !local.synced && remote.slug != local.slug) return;
      remote.synced = true;
      await IsarDb.isar.writeTxn(
        () => IsarDb.isar.freelancerProfiles.put(remote),
      );
    } catch (e) {
      debugPrint('[FreelancerProfileService] refresh failed: $e');
    }
  }

  /// Regenerates the slug. Old claims are kept on purpose so previously
  /// shared links keep resolving to this profile.
  static Future<FreelancerProfile> regenerateSlug(
    FreelancerProfile profile,
  ) async {
    profile.slug = _generateSlug(profile.displayName);
    await save(profile);
    return profile;
  }

  /// Changes the public link name. Returns null on success, otherwise an
  /// i18n key describing the failure.
  static Future<String?> changeUsername(
    FreelancerProfile profile,
    String raw,
  ) async {
    final username = raw.trim().toLowerCase();
    final pattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,22}[a-z0-9])$');
    if (!pattern.hasMatch(username)) return 'usernameInvalid';

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return 'summaryFailed';
      final response = await http
          .post(
            Uri.parse(AppConfig.changeUsernameUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({'username': username}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 409) return 'usernameTaken';
      if (response.statusCode == 400) return 'usernameInvalid';
      if (response.statusCode != 200) return 'summaryFailed';

      profile.username = username;
      profile.slug = username;
      profile.synced = true;
      profile.updatedAt = DateTime.now();
      await IsarDb.isar.writeTxn(
        () => IsarDb.isar.freelancerProfiles.put(profile),
      );
      return null;
    } catch (e) {
      debugPrint('[FreelancerProfileService] username failed: $e');
      return 'summaryFailed';
    }
  }

  /// Direct cloud read used when the local cache is stale or incomplete.
  static Future<FreelancerProfile?> fetchRemote(String ownerUid) async {
    try {
      final doc = await _profiles
          .doc(ownerUid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      final profile =
          FreelancerProfile.fromMap(ownerUid, doc.data() ?? const {});
      profile.synced = true;
      await IsarDb.isar.writeTxn(
        () => IsarDb.isar.freelancerProfiles.put(profile),
      );
      return profile;
    } catch (e) {
      debugPrint('[FreelancerProfileService] fetchRemote failed: $e');
      return null;
    }
  }

  static Future<void> _pushWithRetry(FreelancerProfile profile) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await mergeGuard(profile);
        await _push(profile);
        profile.synced = true;
        await IsarDb.isar.writeTxn(
          () => IsarDb.isar.freelancerProfiles.put(profile),
        );
        return;
      } on SlugTakenException {
        profile.slug = _generateSlug(profile.displayName);
        await IsarDb.isar.writeTxn(
          () => IsarDb.isar.freelancerProfiles.put(profile),
        );
      } catch (e) {
        debugPrint('[FreelancerProfileService] push failed: $e');
        return;
      }
    }
  }

  static Future<void> _push(FreelancerProfile profile) async {
    final fs = FirebaseFirestore.instance;
    await fs.runTransaction((transaction) async {
      final claim = await transaction.get(_slugClaims.doc(profile.slug));
      final owner = claim.exists ? (claim.data()?['uid'] ?? '') : '';
      if (owner.isNotEmpty && owner != profile.ownerUid) {
        throw const SlugTakenException();
      }
      transaction.set(_slugClaims.doc(profile.slug), {
        'uid': profile.ownerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _profiles.doc(profile.ownerUid).set(profile.toMap());
  }

  /// Merge guard: never let an empty local field erase cloud data.
  static Future<void> mergeGuard(FreelancerProfile profile) async {
    try {
      final doc = await _profiles
          .doc(profile.ownerUid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return;
      final remote = FreelancerProfile.fromMap(
        profile.ownerUid,
        doc.data() ?? const {},
      );
      profile.mergeMissingFrom(remote);
    } catch (e) {
      debugPrint('[FreelancerProfileService] mergeGuard failed: $e');
    }
  }

  /// 24-char max slug: readable name part + random suffix.
  static String _generateSlug(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '')
        .split('-')
        .where((part) => part.isNotEmpty)
        .join('-');
    final trimmed = base.length > 18 ? base.substring(0, 18) : base;
    final prefix = trimmed.isEmpty ? 'freelancer' : trimmed;
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return '$prefix-$suffix';
  }
}
