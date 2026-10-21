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

  /// Check if a given user/contact ID is currently blocked
  static bool isBlocked(String contactId) {
    if (contactId.isEmpty) return false;
    try {
      if (!SharedPref.isInitialized) return false;
      final list = SharedPref.instance.getStringList(_prefKeyBlockedIds) ?? [];
      return list.contains(contactId);
    } catch (e) {
      debugPrint('[BlockService] isBlocked safe fallback: $e');
      return false;
    }
  }

  /// Get list of all currently blocked IDs
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

  /// Block a contact locally and in Firestore
  static Future<void> blockContact({
    required String contactId,
    required String contactName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (contactId.isEmpty) return;

    // 1. Update local IDs
    final ids = List<String>.from(getBlockedIds());
    if (!ids.contains(contactId)) {
      ids.add(contactId);
      await SharedPref.instance.setStringList(_prefKeyBlockedIds, ids);
    }

    // 2. Update local detailed meta
    final contacts = List<BlockedContactInfo>.from(getBlockedContacts());
    contacts.removeWhere((c) => c.id == contactId);
    contacts.add(BlockedContactInfo(
      id: contactId,
      name: contactName,
      phone: phone ?? '',
      avatarUrl: avatarUrl ?? '',
      blockedAt: DateTime.now(),
    ));

    final encoded = jsonEncode(contacts.map((c) => c.toMap()).toList());
    await SharedPref.instance.setString(_prefKeyBlockedMeta, encoded);

    // 3. Sync with Firestore
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('blocked_users')
            .doc(contactId)
            .set({
          'contactId': contactId,
          'contactName': contactName,
          'phone': phone ?? '',
          'avatarUrl': avatarUrl ?? '',
          'blockedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[BlockService] Error saving block to Firestore: $e');
      rethrow;
    }
  }

  /// Unblock a contact locally and in Firestore
  static Future<void> unblockContact(String contactId) async {
    if (contactId.isEmpty) return;

    // 1. Update local IDs
    final ids = List<String>.from(getBlockedIds());
    ids.remove(contactId);
    await SharedPref.instance.setStringList(_prefKeyBlockedIds, ids);

    // 2. Update local detailed meta
    final contacts = List<BlockedContactInfo>.from(getBlockedContacts());
    contacts.removeWhere((c) => c.id == contactId);
    final encoded = jsonEncode(contacts.map((c) => c.toMap()).toList());
    await SharedPref.instance.setString(_prefKeyBlockedMeta, encoded);

    // 3. Sync with Firestore
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('blocked_users')
            .doc(contactId)
            .delete();
      }
    } catch (e) {
      debugPrint('[BlockService] Error removing block from Firestore: $e');
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

        DateTime blockedAt = DateTime.now();
        if (data['blockedAt'] is Timestamp) {
          blockedAt = (data['blockedAt'] as Timestamp).toDate();
        }

        remoteContacts.add(BlockedContactInfo(
          id: cId,
          name: data['contactName'] as String? ?? 'Contact',
          phone: data['phone'] as String? ?? '',
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
      final mergedIds = mergedMap.keys.toList();

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
