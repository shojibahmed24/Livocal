import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livocal/features/home/data/repositories/contact_repository.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/phone_normalizer.dart';
import 'package:livocal/theme/app_colors.dart';

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  // Never block the picker on the network or a permission prompt: show the
  // cached list immediately and refresh in the background.
  List<Contact> cached = const [];
  try {
    cached = await IsarDb.getContacts().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('[contactsProvider] cache read failed: $e');
  }

  if (cached.isEmpty) {
    try {
      await IsarDb.refreshContacts().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[contactsProvider] first refresh failed: $e');
    }
    try {
      return await IsarDb.getContacts().timeout(const Duration(seconds: 8));
    } catch (_) {
      return const [];
    }
  }

  unawaited(IsarDb.refreshContacts());
  return cached;
});

final contactPickerControllerProvider =
    StateNotifierProvider.autoDispose<ContactPickerController, List<Contact>>(
  (ref) => ContactPickerController(ref),
);

const shareMsg =
    'Let\'s connect on Livocal! It\'s a fast, simple, and secure app with real-time AI voice translation to call and message each other for free. Get it at https://github.com/shojibahmed24/Livocal';

class ContactPickerController extends StateNotifier<List<Contact>> {
  late List<Contact> _contacts;

  final TextEditingController searchController = TextEditingController();
  final AutoDisposeStateNotifierProviderRef ref;
  bool contactsRefreshing = false;

  ContactPickerController(this.ref) : super([]);

  Future<void> init() async {
    _contacts = await ref.read(contactsProvider.future);
    state = _contacts;

    ref.listen(contactsProvider, (previous, next) {
      next.whenData(
        (value) {
          _contacts = value;
          updateSearchResults(searchController.text);
        },
      );
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openContacts() {
    ref.read(contactsRepositoryProvider).openContacts();
  }

  String _s(String key) =>
      AppStrings.get(key, ref.read(appLocaleProvider).languageCode);

  /// Asks for contacts access with a way back from a permanent denial.
  Future<bool> requestContactsPermission(BuildContext context) async {
    try {
      final status = await Permission.contacts.status;
      if (status.isGranted || status.isLimited) {
        refreshContactsList();
        return true;
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) await _showOpenSettingsDialog(context);
        return false;
      }

      final result = await Permission.contacts.request();
      if (result.isGranted || result.isLimited) {
        refreshContactsList();
        return true;
      }
      if (result.isPermanentlyDenied && context.mounted) {
        await _showOpenSettingsDialog(context);
      }
      return false;
    } catch (e) {
      debugPrint(
          '[ContactPickerController] requestContactsPermission error: $e');
      return false;
    }
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    await showAppDialog(
      context: context,
      title: _s('contactsPermissionOffTitle'),
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.primary,
      contentText: _s('contactsPermissionDenied'),
      actions: [
        AppDialogAction(
          label: _s('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: _s('openSettings'),
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
        ),
      ],
    );
  }

  void refreshContactsList() {
    ref.invalidate(contactsProvider);
  }

  void pickContact(BuildContext context, User sender, Contact contact) async {
    final fetched = await IsarDb.getUserById(contact.userId!);
    final parts = PhoneNormalizer.parse(
      countryCode: '880',
      input: contact.phoneNumber,
    );
    final User targetReceiver = fetched ??
        User(
          id: contact.userId!,
          name: contact.displayName,
          avatarUrl: contact.avatarUrl ?? '',
          phone: Phone(
            code: parts?.code ?? '+880',
            number: parts?.number ?? contact.phoneNumber,
            formattedNumber: parts?.e164 ?? contact.phoneNumber,
          ),
          activityStatus: UserActivityStatus.online,
        );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          self: sender,
          other: targetReceiver,
          otherUserContactName: contact.displayName,
        ),
        settings: const RouteSettings(name: 'chat'),
      ),
    );
  }

  void createNewContact() {
    ref.read(contactsRepositoryProvider).createNewContact();
  }

  void shareInviteLink(RenderBox? box) {
    Share.share(
      shareMsg,
      subject: 'Livocal: Real-Time AI Live Translation & Chat',
      sharePositionOrigin: box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  Future<void> sendSms(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: <String, String>{
        'body': shareMsg,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Error launching SMS URL: $e');
    }

    await Share.share(
      '$shareMsg\n\nInvite: $cleanNumber',
      subject: 'Livocal: Real-Time AI Live Translation & Chat',
    );
  }

  void showHelp(BuildContext context) {
    showAppDialog(
      context: context,
      title: _s('contactsHelp'),
      icon: Icons.contacts_rounded,
      iconColor: AppColors.primary,
      contentText: _s('contactsPermissionBody'),
      actions: [
        AppDialogAction(
          label: _s('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: _s('openSettings'),
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
        ),
      ],
    );
  }

  void onCloseBtnPressed() {
    searchController.clear();
    state = _contacts;
  }

  void updateSearchResults(String query) {
    query = query.toLowerCase().trim();

    state = _contacts.where((contact) {
      final nameMatches = contact.displayName.toLowerCase().contains(query);
      final cleanQuery = query.replaceAll(RegExp(r'\s+'), '');
      final cleanPhone = contact.phoneNumber.replaceAll(RegExp(r'\s+'), '');
      final phoneMatches = cleanPhone.contains(cleanQuery);
      return nameMatches || phoneMatches;
    }).toList();
  }
}
