import 'dart:convert';
import 'dart:isolate';
import 'dart:ui' show RootIsolateToken;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:flutter_contacts/flutter_contacts.dart' show FlutterContacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/services/app_check_service.dart';
import 'package:livocal/shared/utils/phone_normalizer.dart';

/// Plain, isolate-friendly copy of a device contact.
class DeviceContactRow {
  final String id;
  final String name;
  final List<String> phones;

  const DeviceContactRow({
    required this.id,
    required this.name,
    required this.phones,
  });
}

/// Reads the address book on a worker isolate.
///
/// `FlutterContacts.getContacts` decodes a few thousand rows in Dart, which
/// blocked the UI thread for ~5 s on a 2077-contact phone and triggered an ANR.
Future<List<DeviceContactRow>> _readContactsOnWorker() async {
  final token = RootIsolateToken.instance;
  if (token == null) return const [];

  return Isolate.run(() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: false,
      withPhoto: false,
      withGroups: false,
      withAccounts: false,
      sorted: false,
    );
    return contacts
        .map((contact) => DeviceContactRow(
              id: contact.id,
              name: contact.displayName,
              phones: contact.phones
                  .map((phone) => phone.number)
                  .toList(growable: false),
            ))
        .toList(growable: false);
  });
}

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

  /// Asks for read access to the device address book.
  ///
  /// The picker calls this from an explicit "Allow access" card, because a
  /// silent denial previously produced an empty contact list with no way back.
  Future<bool> requestPermission() async {
    try {
      return await FlutterContacts.requestPermission(readonly: true);
    } catch (e) {
      debugPrint('[ContactsRepository] requestPermission error: $e');
      return false;
    }
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
  Future<List<Contact>> getContacts({
    required User self,
    bool matchRegistered = true,
  }) async {
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
          allNormalized.addAll(PhoneNormalizer.matchKeys(normalized));
        }
      }

      // 2. Query registered Livocal users via secure backend endpoint /api/contacts/match
      // Protects privacy by matching only contact numbers without dumping the /users collection
      final Map<String, _FirestoreUser> registeredByPhone = {};
      try {
        // The device read above is what the picker needs first. Server matching
        // is optional and slow (thousands of numbers), so it can be skipped.
        final idToken = matchRegistered
            ? await auth.FirebaseAuth.instance.currentUser?.getIdToken()
            : null;
        if (idToken != null && allNormalized.isNotEmpty) {
          final allList = allNormalized.toList();
          for (int i = 0; i < allList.length; i += 500) {
            final batch = allList.sublist(
              i,
              (i + 500 > allList.length) ? allList.length : i + 500,
            );
            final response = await http
                .post(
                  Uri.parse(AppConfig.matchContactsUrl),
                  headers: await AppCheckService.withAppCheck({
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $idToken',
                  }),
                  body: jsonEncode({
                    'phoneNumbers': batch,
                  }),
                )
                .timeout(const Duration(seconds: 12));

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
                    formattedNumber:
                        rawNumber.isNotEmpty ? rawNumber : '$code$number',
                  ),
                  activityStatus: UserActivityStatus.online,
                ));

                final normalizedRaw = _normalize(rawNumber);
                final normalizedCodeNum = _normalize('$code$number');

                for (final key in PhoneNormalizer.matchKeys(normalizedRaw)) {
                  registeredByPhone[key] = entry;
                }
                for (final key
                    in PhoneNormalizer.matchKeys(normalizedCodeNum)) {
                  registeredByPhone[key] = entry;
                }
              }
            } else {
              debugPrint(
                  '[ContactsRepository] /api/contacts/match returned status: ${response.statusCode}');
            }
          }
        }
      } catch (e) {
        debugPrint(
            '[ContactsRepository] backend /api/contacts/match error: $e');
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

          // Direct match across every stored/typed form of the number.
          _FirestoreUser? match;
          for (final key in PhoneNormalizer.matchKeys(entry.normalizedPhone)) {
            match = registeredByPhone[key];
            if (match != null) break;
          }

          // Try suffix matching (last 10 digits)
          if (match == null && entry.normalizedPhone.length >= 10) {
            final suffix = entry.normalizedPhone
                .substring(entry.normalizedPhone.length - 10);
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

  /// Reads the device address book only — no network, no photos.
  ///
  /// This is deliberately separate from the server matching step: with a few
  /// thousand contacts a single read is already heavy on low-RAM phones, and
  /// doing it twice (once for the list, once for matching) got the app killed
  /// by the low-memory killer. The read itself runs on a worker isolate so the
  /// UI thread never blocks (an ANR came from doing it inline).
  Future<List<Contact>> getDeviceContacts({required User self}) async {
    final result = <Contact>[];
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) return result;

      List<DeviceContactRow> rows;
      try {
        rows = await _readContactsOnWorker();
      } catch (e) {
        debugPrint('[ContactsRepository] worker read failed ($e), inline read');
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: false,
          withPhoto: false,
          withGroups: false,
          withAccounts: false,
          sorted: false,
        );
        rows = contacts
            .map((contact) => DeviceContactRow(
                  id: contact.id,
                  name: contact.displayName,
                  phones: contact.phones
                      .map((phone) => phone.number)
                      .toList(growable: false),
                ))
            .toList(growable: false);
      }

      final selfNormalized = _normalize(self.phone.rawNumber);
      final seenContacts = <String>{};

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        // Yield every so often so a long list never stalls a frame.
        if (i % 100 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        if (seenContacts.contains(row.id)) continue;
        for (final number in row.phones) {
          final normalized = _normalize(number);
          if (normalized.isEmpty) continue;
          if (_isSelfNumber(normalized, selfNormalized)) continue;

          seenContacts.add(row.id);
          result.add(Contact(
            contactId: row.id,
            displayName: row.name,
            phoneNumber: number,
          ));
          break;
        }
      }
    } catch (e) {
      debugPrint('[ContactsRepository] getDeviceContacts error: $e');
    }
    return result;
  }

  /// Matches already-loaded device contacts against registered Livocal users.
  ///
  /// Runs entirely off the cached contact list, so it never re-reads the
  /// address book. Mutates `userId`/`avatarUrl` in place; the caller persists
  /// the updated rows.
  Future<List<Contact>> applyRegisteredMatches({
    required List<Contact> contacts,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (contacts.isEmpty) return contacts;

    try {
      final allKeys = <String>{};
      for (final contact in contacts) {
        allKeys
            .addAll(PhoneNormalizer.matchKeys(_normalize(contact.phoneNumber)));
      }
      if (allKeys.isEmpty) return contacts;

      final idToken =
          await auth.FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return contacts;

      final registeredByPhone = <String, _FirestoreUser>{};
      final keys = allKeys.toList();
      for (var i = 0; i < keys.length; i += 500) {
        final end = (i + 500 > keys.length) ? keys.length : i + 500;
        final batch = keys.sublist(i, end);

        final response = await http
            .post(
              Uri.parse(AppConfig.matchContactsUrl),
              headers: await AppCheckService.withAppCheck({
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              }),
              body: jsonEncode({'phoneNumbers': batch}),
            )
            .timeout(timeout);

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body);
        final matches = data['matches'] as List<dynamic>? ?? [];
        for (final raw in matches) {
          final map = raw as Map<String, dynamic>;
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

          await IsarDb.saveUser(User(
            id: userId,
            name: name,
            avatarUrl: avatarUrl,
            phone: Phone(
              code: code,
              number: number,
              formattedNumber:
                  rawNumber.isNotEmpty ? rawNumber : '$code$number',
            ),
            activityStatus: UserActivityStatus.online,
          ));

          for (final key in PhoneNormalizer.matchKeys(_normalize(rawNumber))) {
            registeredByPhone[key] = entry;
          }
          for (final key
              in PhoneNormalizer.matchKeys(_normalize('$code$number'))) {
            registeredByPhone[key] = entry;
          }
        }
      }

      if (registeredByPhone.isEmpty) return contacts;

      for (final contact in contacts) {
        if (contact.userId != null) continue;
        for (final key
            in PhoneNormalizer.matchKeys(_normalize(contact.phoneNumber))) {
          final match = registeredByPhone[key];
          if (match != null) {
            contact.userId = match.userId;
            contact.avatarUrl = match.avatarUrl;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[ContactsRepository] applyRegisteredMatches error: $e');
    }

    return contacts;
  }

  static bool _isSelfNumber(String normalized, String selfNormalized) {
    if (selfNormalized.isEmpty) return false;
    return normalized == selfNormalized ||
        normalized.endsWith(selfNormalized) ||
        selfNormalized.endsWith(normalized);
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
