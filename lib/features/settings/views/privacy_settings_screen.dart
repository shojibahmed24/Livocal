import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/app_auth_guard.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String _lastSeen = 'Everyone';
  String _profilePhoto = 'Everyone';
  String _about = 'Everyone';
  String _statusPrivacy = 'contacts';
  bool _readReceipts = true;
  String _disappearingTimer = 'Off';
  bool _fingerprintLock = false;

  @override
  void initState() {
    super.initState();
    _lastSeen =
        SharedPref.instance.getString('privacy_last_seen') ?? 'Everyone';
    _profilePhoto =
        SharedPref.instance.getString('privacy_profile_photo') ?? 'Everyone';
    _about = SharedPref.instance.getString('privacy_about') ?? 'Everyone';
    _statusPrivacy =
        SharedPref.instance.getString('status_privacy') ?? 'contacts';
    _readReceipts =
        SharedPref.instance.getBool('privacy_read_receipts') ?? true;
    _disappearingTimer =
        SharedPref.instance.getString('privacy_disappearing') ?? 'Off';
    _fingerprintLock =
        SharedPref.instance.getBool('privacy_fingerprint') ?? false;
  }

  String _localizeOption(String opt) {
    switch (opt) {
      case 'Everyone':
        return AppStrings.tr(ref, 'everyone');
      case 'My contacts':
        return AppStrings.tr(ref, 'myContacts');
      case 'Nobody':
        return AppStrings.tr(ref, 'nobody');
      case 'My contacts except...':
        return AppStrings.tr(ref, 'myContactsExcept');
      case 'Only share with...':
        return AppStrings.tr(ref, 'onlyShareWith');
      case 'Off':
        return AppStrings.tr(ref, 'off');
      case '24 hours':
        return AppStrings.tr(ref, 'hours24');
      case '7 days':
        return AppStrings.tr(ref, 'days7');
      case '90 days':
        return AppStrings.tr(ref, 'days90');
      default:
        return opt;
    }
  }

  void _showRadioOptionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showAppDialog(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (opt) => RadioListTile<String>(
                title: Text(_localizeOption(opt)),
                value: opt,
                groupValue: currentValue,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                    Navigator.pop(context);
                  }
                },
              ),
            )
            .toList(),
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.tr(ref, 'privacy'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          SettingsSectionHeader(title: AppStrings.tr(ref, 'whoCanSeeMyInfo')),
          SettingsRow(
            icon: Icons.visibility_outlined,
            title: AppStrings.tr(ref, 'lastSeenAndOnline'),
            subtitle: _localizeOption(_lastSeen),
            onTap: () => _showRadioOptionDialog(
              title: AppStrings.tr(ref, 'lastSeenAndOnline'),
              options: ['Everyone', 'My contacts', 'Nobody'],
              currentValue: _lastSeen,
              onSelected: (val) {
                setState(() => _lastSeen = val);
                SharedPref.instance.setString('privacy_last_seen', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.account_circle_outlined,
            title: AppStrings.tr(ref, 'profilePhoto'),
            subtitle: _localizeOption(_profilePhoto),
            onTap: () => _showRadioOptionDialog(
              title: AppStrings.tr(ref, 'profilePhoto'),
              options: ['Everyone', 'My contacts', 'Nobody'],
              currentValue: _profilePhoto,
              onSelected: (val) {
                setState(() => _profilePhoto = val);
                SharedPref.instance.setString('privacy_profile_photo', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.info_outline,
            title: AppStrings.tr(ref, 'about'),
            subtitle: _localizeOption(_about),
            onTap: () => _showRadioOptionDialog(
              title: AppStrings.tr(ref, 'about'),
              options: ['Everyone', 'My contacts', 'Nobody'],
              currentValue: _about,
              onSelected: (val) {
                setState(() => _about = val);
                SharedPref.instance.setString('privacy_about', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.donut_large_outlined,
            title: AppStrings.tr(ref, 'status'),
            subtitle: _statusPrivacy == 'contacts'
                ? AppStrings.tr(ref, 'myContacts')
                : (_statusPrivacy == 'except'
                    ? AppStrings.tr(ref, 'myContactsExcept')
                    : AppStrings.tr(ref, 'onlyShareWith')),
            onTap: () => _showRadioOptionDialog(
              title: AppStrings.tr(ref, 'statusPrivacy'),
              options: [
                'My contacts',
                'My contacts except...',
                'Only share with...'
              ],
              currentValue: _statusPrivacy == 'contacts'
                  ? 'My contacts'
                  : (_statusPrivacy == 'except'
                      ? 'My contacts except...'
                      : 'Only share with...'),
              onSelected: (val) {
                final code = val == 'My contacts'
                    ? 'contacts'
                    : (val == 'My contacts except...' ? 'except' : 'only');
                setState(() => _statusPrivacy = code);
                SharedPref.instance.setString('status_privacy', code);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.done_all_outlined,
            title: AppStrings.tr(ref, 'readReceipts'),
            subtitle: AppStrings.tr(ref, 'readReceiptsSub'),
            showChevron: false,
            trailing: Switch(
              value: _readReceipts,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _readReceipts = val);
                SharedPref.instance.setBool('privacy_read_receipts', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'disappearingMessages')),
          SettingsRow(
            icon: Icons.timer_outlined,
            title: AppStrings.tr(ref, 'defaultMessageTimer'),
            subtitle: _localizeOption(_disappearingTimer),
            onTap: () => _showRadioOptionDialog(
              title: AppStrings.tr(ref, 'defaultMessageTimer'),
              options: ['Off', '24 hours', '7 days', '90 days'],
              currentValue: _disappearingTimer,
              onSelected: (val) {
                setState(() => _disappearingTimer = val);
                SharedPref.instance.setString('privacy_disappearing', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'securityAndAppLock')),
          SettingsRow(
            icon: Icons.block_flipped,
            title: AppStrings.tr(ref, 'blockedContacts'),
            subtitle: AppStrings.tr(ref, 'blockedContactsCount'),
            onTap: () {
              showAppDialog(
                context: context,
                title: AppStrings.tr(ref, 'blockedContacts'),
                icon: Icons.block_flipped,
                contentText: AppStrings.tr(ref, 'noBlockedContacts'),
                actions: [
                  AppDialogAction(
                    label: AppStrings.tr(ref, 'ok'),
                    isPrimary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.fingerprint_rounded,
            title: AppStrings.tr(ref, 'fingerprintLock'),
            subtitle: AppStrings.tr(ref, 'fingerprintLockSub'),
            showChevron: false,
            trailing: Switch(
              value: _fingerprintLock,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) async {
                AppAuthGuard.isSystemAuthenticating = true;
                try {
                  final auth = LocalAuthentication();
                  final canCheck = await auth.canCheckBiometrics;
                  final isSupported = await auth.isDeviceSupported();
                  if (!canCheck && !isSupported) {
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: AppStrings.tr(ref, 'biometricNotSupported'),
                        type: SnacBarType.error,
                      );
                    }
                    return;
                  }

                  final authenticated = await auth.authenticate(
                    localizedReason: val
                        ? AppStrings.tr(ref, 'confirmFingerprintEnable')
                        : AppStrings.tr(ref, 'confirmFingerprintDisable'),
                    biometricOnly: false,
                    persistAcrossBackgrounding: true,
                  );

                  if (authenticated) {
                    AppAuthGuard.markUnlocked();
                    await SharedPref.instance
                        .setBool('privacy_fingerprint', val);
                    if (mounted) {
                      setState(() => _fingerprintLock = val);
                    }
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: val
                            ? AppStrings.tr(ref, 'fingerprintLockEnabled')
                            : AppStrings.tr(ref, 'fingerprintLockDisabled'),
                        type: SnacBarType.info,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: AppStrings.tr(ref, 'biometricCancelled'),
                        type: SnacBarType.error,
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('PrivacySettingsScreen biometric auth error: $e');
                  if (context.mounted) {
                    showSnackBar(
                      context: context,
                      content: '${AppStrings.tr(ref, 'biometricError')}: $e',
                      type: SnacBarType.error,
                    );
                  }
                } finally {
                  AppAuthGuard.isSystemAuthenticating = false;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
