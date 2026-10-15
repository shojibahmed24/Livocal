import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
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
    _lastSeen = SharedPref.instance.getString('privacy_last_seen') ?? 'Everyone';
    _profilePhoto = SharedPref.instance.getString('privacy_profile_photo') ?? 'Everyone';
    _about = SharedPref.instance.getString('privacy_about') ?? 'Everyone';
    _statusPrivacy = SharedPref.instance.getString('status_privacy') ?? 'contacts';
    _readReceipts = SharedPref.instance.getBool('privacy_read_receipts') ?? true;
    _disappearingTimer = SharedPref.instance.getString('privacy_disappearing') ?? 'Off';
    _fingerprintLock = SharedPref.instance.getBool('privacy_fingerprint') ?? false;
  }

  void _showRadioOptionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: Text(title),
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
                      Navigator.pop(ctx);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Who can see my personal info',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),
          ListTile(
            title: const Text('Last seen and online'),
            subtitle: Text(_lastSeen, style: const TextStyle(color: Colors.grey)),
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
          ListTile(
            title: const Text('Profile photo'),
            subtitle: Text(_profilePhoto, style: const TextStyle(color: Colors.grey)),
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
          ListTile(
            title: const Text('About'),
            subtitle: Text(_about, style: const TextStyle(color: Colors.grey)),
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
          ListTile(
            title: const Text('Status'),
            subtitle: Text(
              _statusPrivacy == 'contacts'
                  ? 'My contacts'
                  : (_statusPrivacy == 'except'
                      ? 'My contacts except...'
                      : 'Only share with...'),
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () => _showRadioOptionDialog(
              title: 'Status privacy',
              options: ['My contacts', 'My contacts except...', 'Only share with...'],
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
          SwitchListTile(
            title: const Text('Read receipts'),
            subtitle: const Text(
              'If turned off, you won\'t send or receive Read receipts (blue ticks).',
            ),
            value: _readReceipts,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _readReceipts = val);
              SharedPref.instance.setBool('privacy_read_receipts', val);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Disappearing messages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),
          ListTile(
            title: const Text('Default message timer'),
            subtitle: Text(_disappearingTimer, style: const TextStyle(color: Colors.grey)),
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
          const Divider(),
          ListTile(
            title: const Text('Blocked contacts'),
            subtitle: const Text('0 contacts', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Blocked contacts'),
                  content: const Text('No blocked contacts.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Fingerprint lock'),
            subtitle: const Text('Require biometric authentication to open Livocal'),
            value: _fingerprintLock,
            activeTrackColor: AppColors.primary,
            onChanged: (val) async {
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
                  await SharedPref.instance.setBool('privacy_fingerprint', val);
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
                if (context.mounted) {
                  showSnackBar(
                    context: context,
                    content: 'Biometric error: $e',
                    type: SnacBarType.error,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
