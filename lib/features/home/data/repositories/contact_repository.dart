import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' show FlutterContacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';

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
    } catch (e, st) {
      debugPrint('[ContactsRepository] getContactByPhone error: $e\n$st');
    }

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

      // 2. Query registered Livocal users via secure backend endpoint /api/contacts/match
      // Protects privacy by matching only contact numbers without dumping the /users collection
      final Map<String, _FirestoreUser> registeredByPhone = {};
      try {
        final idToken = await auth.FirebaseAuth.instance.currentUser?.getIdToken();
        if (idToken != null && allNormalized.isNotEmpty) {
          final response = await http.post(
            Uri.parse(AppConfig.matchContactsUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'phoneNumbers': allNormalized.toList(),
            }),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final matches = data['matches'] as List<dynamic>? ?? [];
            for (final m in matches) {
              final map = m as Map<String, dynamic>;
              final userId = map['id'] as String?;
              if (userId == null) continue;
              final phoneData = map['phone'] as Map<String, dynamic>?;
              final rawNumber = phoneData?['rawNumber'] as String? ?? '';
              final code = phoneData?['code'] as String? ?? '';
              final number = phoneData?['number'] as String? ?? '';
              final avatarUrl = map['avatarUrl'] as String? ?? '';
              final name = map['name'] as String? ?? '';

              final entry = _FirestoreUser(
                userId: userId,
                avatarUrl: avatarUrl,
                name: name,
              );

              // Cache user in local Isar database so we have it for chats/calls
              await IsarDb.saveUser(User(
                id: userId,
                name: name,
                avatarUrl: avatarUrl,
                phone: Phone(
                  code: code,
                  number: number,
                  formattedNumber: rawNumber.isNotEmpty ? rawNumber : '$code$number',
                ),
                activityStatus: UserActivityStatus.online,
              ));

              final normalizedRaw = _normalize(rawNumber);
              final normalizedCodeNum = _normalize('$code$number');

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
          } else {
            debugPrint('[ContactsRepository] /api/contacts/match returned status: ${response.statusCode}');
          }
        }
      } catch (e) {
        debugPrint('[ContactsRepository] backend /api/contacts/match error: $e');
      }

      // Offline fallback: cross-reference with users already cached in local Isar database
      if (registeredByPhone.isEmpty) {
        try {
          final cachedUsers = await IsarDb.getUsers();
          for (final u in cachedUsers) {
            final entry = _FirestoreUser(
              userId: u.id,
              avatarUrl: u.avatarUrl,
              name: u.name,
            );
            final normRaw = _normalize(u.phone.rawNumber);
            final normCode = _normalize('${u.phone.code}${u.phone.number}');
            if (normRaw.isNotEmpty) registeredByPhone[normRaw] = entry;
            if (normCode.isNotEmpty) registeredByPhone[normCode] = entry;
          }
        } catch (e) {
          debugPrint('[ContactsRepository] local cache fallback error: $e');
        }
      }

      // 3. Match each device contact against registered users (deduplicated by contactId)
      final selfNormalized = _normalize(self.phone.rawNumber);
      final seenUserIds = <String>{};

      // Group raw phone entries by contactId so multi-number contacts appear once
      final Map<String, List<_RawContactEntry>> groupedByContact = {};
      for (final entry in rawEntries) {
        groupedByContact.putIfAbsent(entry.contactId, () => []).add(entry);
      }

      for (final entries in groupedByContact.values) {
        _RawContactEntry? matchedEntry;
        _FirestoreUser? matchedUser;

        for (final entry in entries) {
          // Skip self
          if (entry.normalizedPhone == selfNormalized ||
              (selfNormalized.isNotEmpty &&
                  entry.normalizedPhone.endsWith(selfNormalized)) ||
              (entry.normalizedPhone.isNotEmpty &&
                  selfNormalized.endsWith(entry.normalizedPhone))) {
            continue;
          }

          // Direct match
          _FirestoreUser? match = registeredByPhone[entry.normalizedPhone];

          // Try without leading +
          if (match == null && entry.normalizedPhone.startsWith('+')) {
            match = registeredByPhone[entry.normalizedPhone.substring(1)];
          }

          // Try with common country codes if no + prefix
          if (match == null && !entry.normalizedPhone.startsWith('+')) {
            match = registeredByPhone['+880${entry.normalizedPhone}'];
            match ??= registeredByPhone['880${entry.normalizedPhone}'];
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

          if (match != null && !seenUserIds.contains(match.userId)) {
            matchedEntry = entry;
            matchedUser = match;
            break;
          }
        }

        if (matchedUser != null && matchedEntry != null) {
          seenUserIds.add(matchedUser.userId);
          result.add(Contact(
            contactId: matchedEntry.contactId,
            displayName: matchedEntry.displayName,
            phoneNumber: matchedEntry.rawPhoneNumber,
            userId: matchedUser.userId,
            avatarUrl: matchedUser.avatarUrl,
          ));
        } else if (entries.isNotEmpty) {
          // Unregistered contact: pick the first valid non-self number
          final primary = entries.firstWhere(
            (e) =>
                e.normalizedPhone != selfNormalized &&
                (!selfNormalized.isNotEmpty ||
                    !e.normalizedPhone.endsWith(selfNormalized)),
            orElse: () => entries.first,
          );
          if (primary.normalizedPhone != selfNormalized &&
              (!selfNormalized.isNotEmpty ||
                  !primary.normalizedPhone.endsWith(selfNormalized))) {
            result.add(Contact(
              contactId: primary.contactId,
              displayName: primary.displayName,
              phoneNumber: primary.rawPhoneNumber,
            ));
          }
        }
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
