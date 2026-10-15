import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: Text(_twoStepEnabled
            ? 'Disable Two-Step Verification'
            : 'Enable Two-Step Verification'),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _twoStepEnabled ? Colors.redAccent : AppColors.primary,
              foregroundColor: Colors.white,
            ),
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
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                setState(() => _twoStepEnabled = false);
                showSnackBar(
                  context: context,
                  content: 'Two-step verification disabled',
                  type: SnacBarType.info,
                );
              } else {
                await SecurePinService.setPin(enteredPin);
                if (!mounted) return;
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                setState(() => _twoStepEnabled = true);
                showSnackBar(
                  context: context,
                  content: 'Two-step verification PIN saved in secure storage',
                  type: SnacBarType.info,
                );
              }
            },
            child: Text(_twoStepEnabled ? 'CONFIRM DISABLE' : 'ENABLE PIN'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: const Text(
          'Delete this account?',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthController.deleteAccount(
                context: context,
                ref: ref,
                userId: widget.user.id,
              );
            },
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.shield_outlined, color: primaryColor),
            title: const Text('Security notifications'),
            subtitle: const Text(
              'Show security notifications when encryption keys change for any contact.',
            ),
            value: _securityNotifications,
            activeTrackColor: AppColors.primary,
            onChanged: (val) async {
              setState(() => _securityNotifications = val);
              await SharedPref.instance.setBool('sec_notifications', val);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.pin_outlined, color: primaryColor),
            title: const Text('Two-step verification'),
            subtitle: Text(
              _twoStepEnabled ? 'Enabled (PIN protection active)' : 'Disabled (Set up a 6-digit PIN)',
              style: TextStyle(
                color: _twoStepEnabled ? primaryColor : Colors.grey,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showTwoStepDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.phone_android_outlined, color: primaryColor),
            title: const Text('Change number'),
            subtitle: Text(
              'Current: ${widget.user.phone.getFormattedNumber()}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Change phone number'),
                  content: const Text(
                    'Migrating your account to a new phone number will transfer all your account info, settings, and encryption keys.',
                  ),
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
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.description_outlined, color: primaryColor),
            title: const Text('Request account info'),
            subtitle: const Text('Request a report of your account info and settings'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Account report request submitted. Ready within 24 hours.',
                type: SnacBarType.info,
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              'Delete my account',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Permanently remove your account and data'),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
