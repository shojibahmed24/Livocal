import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
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
          ? AppStrings.tr(ref, 'disableTwoStep')
          : AppStrings.tr(ref, 'enableTwoStep'),
      icon: Icons.pin_outlined,
      iconColor: _twoStepEnabled ? Colors.redAccent : AppColors.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _twoStepEnabled
                ? AppStrings.tr(ref, 'enterCurrentPin')
                : AppStrings.tr(ref, 'enterNewPin'),
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
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: _twoStepEnabled
              ? AppStrings.tr(ref, 'confirmDisable')
              : AppStrings.tr(ref, 'enablePin'),
          isDestructive: _twoStepEnabled,
          isPrimary: !_twoStepEnabled,
          onPressed: () async {
            final enteredPin = pinController.text.trim();
            if (enteredPin.length != 6) {
              showSnackBar(
                context: context,
                content: AppStrings.tr(ref, 'enterValid6DigitPin'),
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
                  content: AppStrings.tr(ref, 'incorrectPin'),
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
                content: AppStrings.tr(ref, 'twoStepDisabledSuccess'),
                type: SnacBarType.info,
              );
            } else {
              await SecurePinService.setPin(enteredPin);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => _twoStepEnabled = true);
              showSnackBar(
                context: context,
                content: AppStrings.tr(ref, 'twoStepSavedSuccess'),
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
      title: AppStrings.tr(ref, 'deleteAccountTitle'),
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr(ref, 'deleteAccountDesc')),
          const SizedBox(height: 8),
          Text(AppStrings.tr(ref, 'deleteAccountBullet1')),
          Text(AppStrings.tr(ref, 'deleteAccountBullet2')),
          Text(AppStrings.tr(ref, 'deleteAccountBullet3')),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppStrings.tr(ref, 'deleteAccountButton'),
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
        title: Text(
          AppStrings.tr(ref, 'account'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          SettingsSectionHeader(title: AppStrings.tr(ref, 'securityAndAccess')),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: AppStrings.tr(ref, 'securityNotifications'),
            subtitle: AppStrings.tr(ref, 'securityNotificationsSub'),
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
            title: AppStrings.tr(ref, 'twoStepVerification'),
            subtitle: _twoStepEnabled
                ? AppStrings.tr(ref, 'twoStepEnabledSub')
                : AppStrings.tr(ref, 'twoStepDisabledSub'),
            onTap: _showTwoStepDialog,
          ),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'accountManagement')),
          SettingsRow(
            icon: Icons.phone_android_outlined,
            title: AppStrings.tr(ref, 'changeNumber'),
            subtitle:
                '${AppStrings.tr(ref, 'currentNumber')}${widget.user.phone.getFormattedNumber()}',
            onTap: () {
              showAppDialog(
                context: context,
                title: AppStrings.tr(ref, 'changeNumber'),
                icon: Icons.phone_android_outlined,
                contentText: AppStrings.tr(ref, 'changeNumberDialogContent'),
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
            icon: Icons.description_outlined,
            title: AppStrings.tr(ref, 'requestAccountInfo'),
            subtitle: AppStrings.tr(ref, 'requestAccountInfoSub'),
            onTap: () {
              showSnackBar(
                context: context,
                content: AppStrings.tr(ref, 'accountReportSubmitted'),
                type: SnacBarType.info,
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.delete_outline,
            title: AppStrings.tr(ref, 'deleteMyAccount'),
            subtitle: AppStrings.tr(ref, 'deleteMyAccountSub'),
            isDestructive: true,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
