import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  final User user;
  const AccountSettingsScreen({super.key, required this.user});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _securityNotifications = true;
  bool _twoStepEnabled = false;

  @override
  void initState() {
    super.initState();
    _securityNotifications =
        SharedPref.instance.getBool('sec_notifications') ?? true;
    _checkTwoStepStatus();
  }

  Future<void> _checkTwoStepStatus() async {
    final enabled = await SecurePinService.isPinSet();
    if (mounted) {
      setState(() => _twoStepEnabled = enabled);
    }
  }

  void _showTwoStepDialog() {
    final pinController = TextEditingController();
    showAppDialog(
      context: context,
      title: _twoStepEnabled
          ? 'Disable Two-Step Verification'
          : 'Enable Two-Step Verification',
      icon: Icons.pin_outlined,
      iconColor: _twoStepEnabled ? Colors.redAccent : AppColors.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _twoStepEnabled
                ? 'Enter your current 6-digit PIN to confirm disabling Two-Step Verification:'
                : 'Enter a 6-digit PIN which will be required to access and secure your Livocal account:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '• • • • • •',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: _twoStepEnabled ? 'CONFIRM DISABLE' : 'ENABLE PIN',
          isDestructive: _twoStepEnabled,
          isPrimary: !_twoStepEnabled,
          onPressed: () async {
            final enteredPin = pinController.text.trim();
            if (enteredPin.length != 6) {
              showSnackBar(
                context: context,
                content: 'Please enter a valid 6-digit PIN',
                type: SnacBarType.error,
              );
              return;
            }

            if (_twoStepEnabled) {
              final isCorrect = await SecurePinService.verifyPin(enteredPin);
              if (!mounted) return;
              if (!isCorrect) {
                showSnackBar(
                  context: context,
                  content: 'Incorrect PIN. Verification failed.',
                  type: SnacBarType.error,
                );
                return;
              }
              await SecurePinService.disablePin();
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => _twoStepEnabled = false);
              showSnackBar(
                context: context,
                content: 'Two-step verification disabled',
                type: SnacBarType.info,
              );
            } else {
              await SecurePinService.setPin(enteredPin);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => _twoStepEnabled = true);
              showSnackBar(
                context: context,
                content: 'Two-step verification PIN saved in secure storage',
                type: SnacBarType.info,
              );
            }
          },
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showAppDialog(
      context: context,
      title: 'Delete this account?',
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deleting your account will:'),
          SizedBox(height: 8),
          Text('• Delete your account info and profile photo'),
          Text('• Delete all local message history from this device'),
          Text('• Remove you from your contacts’ Livocal lists'),
        ],
      ),
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'DELETE ACCOUNT',
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);
            await AuthController.deleteAccount(
              context: context,
              ref: ref,
              userId: widget.user.id,
            );
          },
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
          'Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Security & Access'),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: 'Security notifications',
            subtitle:
                'Show security notifications when encryption keys change for any contact.',
            showChevron: false,
            trailing: Switch(
              value: _securityNotifications,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) async {
                setState(() => _securityNotifications = val);
                await SharedPref.instance.setBool('sec_notifications', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.pin_outlined,
            title: 'Two-step verification',
            subtitle: _twoStepEnabled
                ? 'Enabled (PIN protection active)'
                : 'Disabled (Set up a 6-digit PIN)',
            onTap: _showTwoStepDialog,
          ),
          const SettingsSectionHeader(title: 'Account Management'),
          SettingsRow(
            icon: Icons.phone_android_outlined,
            title: 'Change number',
            subtitle: 'Current: ${widget.user.phone.getFormattedNumber()}',
            onTap: () {
              showAppDialog(
                context: context,
                title: 'Change phone number',
                icon: Icons.phone_android_outlined,
                contentText:
                    'Migrating your account to a new phone number will transfer all your account info, settings, and encryption keys.',
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
            icon: Icons.description_outlined,
            title: 'Request account info',
            subtitle: 'Request a report of your account info and settings',
            onTap: () {
              showSnackBar(
                context: context,
                content:
                    'Account report request submitted. Ready within 24 hours.',
                type: SnacBarType.info,
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.delete_outline,
            title: 'Delete my account',
            subtitle: 'Permanently remove your account and data',
            isDestructive: true,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
