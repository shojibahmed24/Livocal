import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' show FlutterContacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/shared/models/contact.dart';
import 'package:whatsapp_clone/shared/models/user.dart';

final contactsRepositoryProvider = Provider((ref) => ContactsRepository(ref));

class ContactsRepository {
  final ProviderRef ref;

  ContactsRepository(this.ref);

  Future<void> openContacts() async {
    FlutterContacts.openExternalPick();
  }

  Future<void> createNewContact() async {
    FlutterContacts.openExternalInsert();
  }

  Future<Contact?> getContactByPhone(String phoneNumber) async {
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) return null;

      final contacts = await FlutterContacts.getContacts(withProperties: true);

      for (var contact in contacts) {
        for (var phone in contact.phones) {
          String phoneNumberWithoutFormatting = phone.number
              .replaceAll(' ', '')
              .replaceAll('-', '')
              .replaceAll('(', '')
              .replaceAll(')', '');

          if (phoneNumberWithoutFormatting.contains(phoneNumber)) {
            return Contact(
              contactId: contact.id,
              displayName: contact.displayName,
              phoneNumber: phoneNumber,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Normalizes a phone number to digits-only (with optional leading +).
  static String _normalize(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Fetches all device contacts and cross-references them against Firestore
  /// `users` collection to identify which contacts are registered on Livocal.
  Future<List<Contact>> getContacts({required User self}) async {
    final result = <Contact>[];
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) return result;

      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // 1. Build a list of raw contacts and collect all normalized phone numbers
      final rawEntries = <_RawContactEntry>[];
      final allNormalized = <String>{};

      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final normalized = _normalize(phone.number);
          if (normalized.isEmpty) continue;
          rawEntries.add(_RawContactEntry(
            contactId: contact.id,
            displayName: contact.displayName,
            rawPhoneNumber: phone.number,
            normalizedPhone: normalized,
          ));
          allNormalized.add(normalized);
          // Also add without country code prefix for matching
          if (normalized.startsWith('+')) {
            // Strip country code: e.g. +8801721013902 -> 01721013902 (keep local)
            final withoutPlus = normalized.substring(1);
            if (withoutPlus.length > 4) {
              allNormalized.add(withoutPlus);
            }
          }
        }
      }

      // 2. Query all registered Livocal users from Firestore
      // We fetch all users and match locally (efficient for small-medium user bases)
      final Map<String, _FirestoreUser> registeredByPhone = {};
      try {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .get()
            .timeout(const Duration(seconds: 8));

        for (final doc in usersSnap.docs) {
          final data = doc.data();
          final userId = data['id'] as String?;
          if (userId == null) continue;

          final phoneData = data['phone'] as Map<String, dynamic>?;
          if (phoneData == null) continue;

          final rawNumber = phoneData['rawNumber'] as String? ?? '';
          final code = phoneData['code'] as String? ?? '';
          final number = phoneData['number'] as String? ?? '';
          final avatarUrl = data['avatarUrl'] as String? ?? '';
          final name = data['name'] as String? ?? '';

          final normalizedRaw = _normalize(rawNumber);
          final normalizedCodeNum = _normalize('$code$number');

          final entry = _FirestoreUser(
            userId: userId,
            avatarUrl: avatarUrl,
            name: name,
          );

          // Register multiple lookup keys for robust matching
          if (normalizedRaw.isNotEmpty) {
            registeredByPhone[normalizedRaw] = entry;
            if (normalizedRaw.startsWith('+')) {
              registeredByPhone[normalizedRaw.substring(1)] = entry;
            }
          }
          if (normalizedCodeNum.isNotEmpty && normalizedCodeNum != normalizedRaw) {
            registeredByPhone[normalizedCodeNum] = entry;
            if (normalizedCodeNum.startsWith('+')) {
              registeredByPhone[normalizedCodeNum.substring(1)] = entry;
            }
          }
        }
      } catch (e) {
        debugPrint('ContactsRepository: Firestore users fetch error: $e');
      }

      // 3. Match each device contact against registered users
      final selfNormalized = _normalize(self.phone.rawNumber);
      final seenUserIds = <String>{};

      for (final entry in rawEntries) {
        // Skip self
        if (entry.normalizedPhone == selfNormalized ||
            (selfNormalized.isNotEmpty &&
                entry.normalizedPhone.endsWith(selfNormalized)) ||
            (entry.normalizedPhone.isNotEmpty &&
                selfNormalized.endsWith(entry.normalizedPhone))) {
          continue;
        }

        // Try to match this contact to a registered Livocal user
        _FirestoreUser? match;

        // Direct match
        match = registeredByPhone[entry.normalizedPhone];

        // Try without leading + 
        if (match == null && entry.normalizedPhone.startsWith('+')) {
          match = registeredByPhone[entry.normalizedPhone.substring(1)];
        }

        // Try with common country codes if no + prefix
        if (match == null && !entry.normalizedPhone.startsWith('+')) {
          // Try +880 (Bangladesh)
          match = registeredByPhone['+880${entry.normalizedPhone}'];
          match ??= registeredByPhone['880${entry.normalizedPhone}'];
          // Try stripping leading 0 and adding +880
          if (match == null && entry.normalizedPhone.startsWith('0')) {
            final withoutZero = entry.normalizedPhone.substring(1);
            match = registeredByPhone['+880$withoutZero'];
            match ??= registeredByPhone['880$withoutZero'];
          }
        }

        // Try suffix matching (last 10 digits)
        if (match == null && entry.normalizedPhone.length >= 10) {
          final suffix = entry.normalizedPhone.substring(
              entry.normalizedPhone.length - 10);
          for (final key in registeredByPhone.keys) {
            if (key.length >= 10 && key.endsWith(suffix)) {
              match = registeredByPhone[key];
              break;
            }
          }
        }

        // Avoid duplicate entries for the same Livocal user
        if (match != null && seenUserIds.contains(match.userId)) continue;

        final contact = Contact(
          contactId: entry.contactId,
          displayName: entry.displayName,
          phoneNumber: entry.rawPhoneNumber,
          userId: match?.userId,
          avatarUrl: match?.avatarUrl,
        );

        if (match != null) {
          seenUserIds.add(match.userId);
        }

        result.add(contact);
      }
    } catch (e) {
      debugPrint('ContactsRepository.getContacts error: $e');
    }

    return result;
  }
}

class _RawContactEntry {
  final String contactId;
  final String displayName;
  final String rawPhoneNumber;
  final String normalizedPhone;

  _RawContactEntry({
    required this.contactId,
    required this.displayName,
    required this.rawPhoneNumber,
    required this.normalizedPhone,
  });
}

class _FirestoreUser {
  final String userId;
  final String avatarUrl;
  final String name;

  _FirestoreUser({
    required this.userId,
    required this.avatarUrl,
    required this.name,
  });
}
