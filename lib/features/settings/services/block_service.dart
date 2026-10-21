import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class BlockedContactInfo {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;
  final DateTime blockedAt;

  const BlockedContactInfo({
    required this.id,
    required this.name,
    this.phone = '',
    this.avatarUrl = '',
    required this.blockedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'blockedAt': blockedAt.toIso8601String(),
      };

  factory BlockedContactInfo.fromMap(Map<String, dynamic> map) {
    return BlockedContactInfo(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Contact',
      phone: map['phone'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      blockedAt: map['blockedAt'] != null
          ? DateTime.tryParse(map['blockedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BlockService {
  static const String _prefKeyBlockedIds = 'blocked_contact_ids';
  static const String _prefKeyBlockedMeta = 'blocked_contacts_meta_json';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Check if a given user ID, phone number or identifier is currently blocked
  static bool isBlocked(String identifier) {
    if (identifier.isEmpty) return false;
    try {
      if (!SharedPref.isInitialized) return false;
      final list = SharedPref.instance.getStringList(_prefKeyBlockedIds) ?? [];
      if (list.contains(identifier)) return true;

      final cleanIdent = cleanPhone(identifier);
      if (cleanIdent.isNotEmpty) {
        if (list.contains(cleanIdent)) return true;
        // Check phone numbers of all blocked contacts
        final contacts = getBlockedContacts();
        for (final c in contacts) {
          if (c.id == identifier) return true;
          final cleanContactPhone = cleanPhone(c.phone);
          if (cleanContactPhone.isNotEmpty) {
            if (cleanContactPhone == cleanIdent ||
                cleanContactPhone.endsWith(cleanIdent) ||
                cleanIdent.endsWith(cleanContactPhone)) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('[BlockService] isBlocked safe fallback: $e');
      return false;
    }
  }

  /// Get list of all currently blocked IDs and numbers
  static List<String> getBlockedIds() {
    try {
      if (!SharedPref.isInitialized) return [];
      return SharedPref.instance.getStringList(_prefKeyBlockedIds) ?? [];
    } catch (e) {
      debugPrint('[BlockService] getBlockedIds safe fallback: $e');
      return [];
    }
  }

  /// Get full detailed list of blocked contacts
  static List<BlockedContactInfo> getBlockedContacts() {
    try {
      if (!SharedPref.isInitialized) return [];
      final raw = SharedPref.instance.getString(_prefKeyBlockedMeta);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) =>
              BlockedContactInfo.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BlockService] Error parsing blocked contacts meta: $e');
      return [];
    }
  }

  /// Block a contact locally and in Firestore with automatic rollback and phone-to-UID resolution
  static Future<void> blockContact({
    required String contactId,
    required String contactName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (contactId.isEmpty) return;

    // Snapshot previous state for rollback
    final prevIds = List<String>.from(getBlockedIds());
    final prevMeta = SharedPref.instance.getString(_prefKeyBlockedMeta);

    // Resolve UID if contactId is phone-keyed or phone is available
    String? resolvedUid;
    final clean = cleanPhone(phone ?? (contactId.startsWith('+') || contactId.startsWith('0') ? contactId : ''));
    if (!contactId.startsWith('+') && !contactId.startsWith('0') && contactId.length >= 20) {
      resolvedUid = contactId;
    }

    if (resolvedUid == null && clean.isNotEmpty) {
      try {
        final querySnap = await _firestore
            .collection('users')
            .where('phone.number', isEqualTo: clean)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 4));
        if (querySnap.docs.isNotEmpty) {
          resolvedUid = querySnap.docs.first.id;
        }
      } catch (e) {
        debugPrint('[BlockService] Could not resolve UID by phone: $e');
      }
    }

    // 1. Update local IDs (store raw ID, resolved UID, and clean phone)
    final ids = List<String>.from(prevIds);
    if (!ids.contains(contactId)) ids.add(contactId);
    if (resolvedUid != null && !ids.contains(resolvedUid)) ids.add(resolvedUid);
    if (clean.isNotEmpty && !ids.contains(clean)) ids.add(clean);
    await SharedPref.instance.setStringList(_prefKeyBlockedIds, ids);

    // 2. Update local detailed meta
    final contacts = List<BlockedContactInfo>.from(getBlockedContacts());
    contacts.removeWhere((c) => c.id == contactId || (resolvedUid != null && c.id == resolvedUid));
    contacts.add(BlockedContactInfo(
      id: resolvedUid ?? contactId,
      name: contactName,
      phone: phone ?? (clean.isNotEmpty ? clean : ''),
      avatarUrl: avatarUrl ?? '',
      blockedAt: DateTime.now(),
    ));

    final encoded = jsonEncode(contacts.map((c) => c.toMap()).toList());
    await SharedPref.instance.setString(_prefKeyBlockedMeta, encoded);

    // 3. Sync with Firestore with automatic rollback on error
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final batch = _firestore.batch();
        final primaryId = resolvedUid ?? contactId;
        final docRefPrimary = _firestore
            .collection('users')
            .doc(uid)
            .collection('blocked_users')
            .doc(primaryId);

        batch.set(docRefPrimary, {
          'contactId': primaryId,
          'contactName': contactName,
          'phone': phone ?? clean,
          'avatarUrl': avatarUrl ?? '',
          'blockedAt': FieldValue.serverTimestamp(),
        });

        if (resolvedUid != null && contactId != resolvedUid) {
          final docRefSecondary = _firestore
              .collection('users')
              .doc(uid)
              .collection('blocked_users')
              .doc(contactId);
          batch.set(docRefSecondary, {
            'contactId': contactId,
            'contactName': contactName,
            'phone': phone ?? clean,
            'avatarUrl': avatarUrl ?? '',
            'blockedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit().timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      // Rollback local state on server failure
      await SharedPref.instance.setStringList(_prefKeyBlockedIds, prevIds);
      if (prevMeta != null) {
        await SharedPref.instance.setString(_prefKeyBlockedMeta, prevMeta);
      }
      debugPrint('[BlockService] Error saving block to Firestore (rolled back locally): $e');
      rethrow;
    }
  }

  /// Unblock a contact locally and in Firestore with automatic rollback
  static Future<void> unblockContact(String contactId) async {
    if (contactId.isEmpty) return;

    final prevIds = List<String>.from(getBlockedIds());
    final prevMeta = SharedPref.instance.getString(_prefKeyBlockedMeta);

    final contacts = List<BlockedContactInfo>.from(getBlockedContacts());
    final match = contacts.where((c) => c.id == contactId).firstOrNull;
    final clean = match != null ? cleanPhone(match.phone) : cleanPhone(contactId);

    // 1. Update local IDs
    final ids = List<String>.from(prevIds);
    ids.remove(contactId);
    if (clean.isNotEmpty) ids.remove(clean);
    await SharedPref.instance.setStringList(_prefKeyBlockedIds, ids);

    // 2. Update local detailed meta
    contacts.removeWhere((c) => c.id == contactId);
    final encoded = jsonEncode(contacts.map((c) => c.toMap()).toList());
    await SharedPref.instance.setString(_prefKeyBlockedMeta, encoded);

    // 3. Sync with Firestore with automatic rollback
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final batch = _firestore.batch();
        batch.delete(_firestore
            .collection('users')
            .doc(uid)
            .collection('blocked_users')
            .doc(contactId));

        if (clean.isNotEmpty && clean != contactId) {
          batch.delete(_firestore
              .collection('users')
              .doc(uid)
              .collection('blocked_users')
              .doc(clean));
        }
        await batch.commit().timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      // Rollback local state on server failure
      await SharedPref.instance.setStringList(_prefKeyBlockedIds, prevIds);
      if (prevMeta != null) {
        await SharedPref.instance.setString(_prefKeyBlockedMeta, prevMeta);
      }
      debugPrint('[BlockService] Error removing block from Firestore (rolled back locally): $e');
      rethrow;
    }
  }

  /// Sync block list from Firestore on app launch (merges remote & local to protect offline blocks)
  static Future<void> syncFromFirestore() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked_users')
          .get();

      final List<String> remoteIds = [];
      final List<BlockedContactInfo> remoteContacts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cId = data['contactId'] as String? ?? doc.id;
        remoteIds.add(cId);

        final rawPhone = data['phone'] as String? ?? '';
        final clean = cleanPhone(rawPhone);
        if (clean.isNotEmpty && !remoteIds.contains(clean)) {
          remoteIds.add(clean);
        }

        DateTime blockedAt = DateTime.now();
        if (data['blockedAt'] is Timestamp) {
          blockedAt = (data['blockedAt'] as Timestamp).toDate();
        }

        remoteContacts.add(BlockedContactInfo(
          id: cId,
          name: data['contactName'] as String? ?? 'Contact',
          phone: rawPhone,
          avatarUrl: data['avatarUrl'] as String? ?? '',
          blockedAt: blockedAt,
        ));
      }

      // Merge: preserve local blocks not yet synced to Firestore
      final localIds = getBlockedIds();
      final localContacts = getBlockedContacts();

      final Map<String, BlockedContactInfo> mergedMap = {};
      for (final c in localContacts) {
        mergedMap[c.id] = c;
      }
      for (final c in remoteContacts) {
        mergedMap[c.id] = c;
      }

      final mergedList = mergedMap.values.toList();
      final Set<String> mergedIdsSet = Set.from(localIds)..addAll(remoteIds);
      for (final c in mergedList) {
        mergedIdsSet.add(c.id);
        final clean = cleanPhone(c.phone);
        if (clean.isNotEmpty) mergedIdsSet.add(clean);
      }
      final mergedIds = mergedIdsSet.toList();

      await SharedPref.instance.setStringList(_prefKeyBlockedIds, mergedIds);
      final encoded = jsonEncode(mergedList.map((c) => c.toMap()).toList());
      await SharedPref.instance.setString(_prefKeyBlockedMeta, encoded);

      // Backfill any local offline blocks to Firestore
      for (final localId in localIds) {
        if (!remoteIds.contains(localId)) {
          final c = mergedMap[localId];
          if (c != null) {
            _firestore
                .collection('users')
                .doc(uid)
                .collection('blocked_users')
                .doc(localId)
                .set({
              'contactId': c.id,
              'contactName': c.name,
              'phone': c.phone,
              'avatarUrl': c.avatarUrl,
              'blockedAt': FieldValue.serverTimestamp(),
            }).catchError((_) {});
          }
        }
      }
    } catch (e) {
      debugPrint('[BlockService] syncFromFirestore error: $e');
    }
  }
}
