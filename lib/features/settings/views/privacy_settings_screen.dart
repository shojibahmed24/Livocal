import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
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
                title: Text(opt),
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
          label: 'CANCEL',
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
        title: const Text(
          'Privacy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Who can see my personal info'),
          SettingsRow(
            icon: Icons.visibility_outlined,
            title: 'Last seen and online',
            subtitle: _lastSeen,
            onTap: () => _showRadioOptionDialog(
              title: 'Last seen and online',
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
            title: 'Profile photo',
            subtitle: _profilePhoto,
            onTap: () => _showRadioOptionDialog(
              title: 'Profile photo',
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
            title: 'About',
            subtitle: _about,
            onTap: () => _showRadioOptionDialog(
              title: 'About',
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
            title: 'Status',
            subtitle: _statusPrivacy == 'contacts'
                ? 'My contacts'
                : (_statusPrivacy == 'except'
                    ? 'My contacts except...'
                    : 'Only share with...'),
            onTap: () => _showRadioOptionDialog(
              title: 'Status privacy',
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
            title: 'Read receipts',
            subtitle:
                'If turned off, you won\'t send or receive Read receipts (blue ticks).',
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
          const SettingsSectionHeader(title: 'Disappearing messages'),
          SettingsRow(
            icon: Icons.timer_outlined,
            title: 'Default message timer',
            subtitle: _disappearingTimer,
            onTap: () => _showRadioOptionDialog(
              title: 'Default message timer',
              options: ['Off', '24 hours', '7 days', '90 days'],
              currentValue: _disappearingTimer,
              onSelected: (val) {
                setState(() => _disappearingTimer = val);
                SharedPref.instance.setString('privacy_disappearing', val);
              },
            ),
          ),
          const Divider(height: 1),
          const SettingsSectionHeader(title: 'Security & App Lock'),
          SettingsRow(
            icon: Icons.block_flipped,
            title: 'Blocked contacts',
            subtitle: '0 contacts',
            onTap: () {
              showAppDialog(
                context: context,
                title: 'Blocked contacts',
                icon: Icons.block_flipped,
                contentText: 'No blocked contacts.',
                actions: [
                  AppDialogAction(
                    label: 'OK',
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
            title: 'Fingerprint lock',
            subtitle: 'Require biometric authentication to open Livocal',
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
                        content:
                            'Biometric authentication is not supported on this device.',
                        type: SnacBarType.error,
                      );
                    }
                    return;
                  }

                  final authenticated = await auth.authenticate(
                    localizedReason: val
                        ? 'Confirm your fingerprint or biometric credential to enable lock'
                        : 'Confirm your biometric credential to disable lock',
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
                            ? 'Fingerprint lock enabled'
                            : 'Fingerprint lock disabled',
                        type: SnacBarType.info,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: 'Biometric verification cancelled.',
                        type: SnacBarType.error,
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('PrivacySettingsScreen biometric auth error: $e');
                  if (context.mounted) {
                    showSnackBar(
                      context: context,
                      content: 'Biometric error: $e',
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
