import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/home/views/profile_edit_screen.dart';
import 'package:livocal/features/settings/views/qr_code_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';
import 'package:livocal/features/settings/views/account_settings_screen.dart';
import 'package:livocal/features/settings/views/privacy_settings_screen.dart';
import 'package:livocal/features/settings/views/notifications_settings_screen.dart';
import 'package:livocal/features/settings/views/storage_settings_screen.dart';
import 'package:livocal/features/settings/views/app_language_screen.dart';
import 'package:livocal/features/settings/views/help_settings_screen.dart';
import 'package:livocal/features/settings/views/voice_persona_screen.dart';
import 'package:livocal/shared/utils/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final User user;
  const SettingsScreen({super.key, required this.user});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _showThemeSelectionDialog() {
    final currentTheme = ref.read(themeModeProvider);

    showAppDialog(
      context: context,
      title: AppStrings.tr(ref, 'chooseTheme'),
      icon: Icons.brightness_6_rounded,
      content: RadioGroup<ThemeMode>(
        groupValue: currentTheme,
        onChanged: (mode) {
          if (mode != null) {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(AppStrings.tr(ref, 'systemDefault')),
              value: ThemeMode.system,
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppStrings.tr(ref, 'light')),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppStrings.tr(ref, 'dark')),
              value: ThemeMode.dark,
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showAppDialog(
      context: context,
      title: AppStrings.tr(ref, 'logoutDialogTitle'),
      icon: Icons.logout_rounded,
      iconColor: Colors.redAccent,
      contentText: AppStrings.tr(ref, 'logoutDialogContent'),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppStrings.tr(ref, 'logout').toUpperCase(),
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);
            await AuthController.logout(
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
    final textTheme = Theme.of(context).custom.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch locale so entire screen updates in real time when language changes
    ref.watch(appLocaleProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.tr(ref, 'settings'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // User Profile Header Tile with Real QR Code Access
          InkWell(
            onTap: () async {
              final updated = await Navigator.push<User>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEditScreen(user: _currentUser),
                ),
              );
              if (updated != null && mounted) {
                setState(() => _currentUser = updated);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _currentUser.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(_currentUser.avatarUrl)
                        : null,
                    child: _currentUser.avatarUrl.isEmpty
                        ? Text(
                            _currentUser.name.isNotEmpty
                                ? _currentUser.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.name,
                          style: textTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.phone.getFormattedNumber(),
                          style: textTheme.caption.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SharedPref.instance.getString('user_about') ??
                              'Hey there! I am using Livocal.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
                    tooltip: 'View QR Code',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrCodeScreen(user: _currentUser),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 0.5, height: 1),

          // Section 1: Account & Privacy
          SettingsSectionHeader(title: AppStrings.tr(ref, 'accountAndPrivacy')),
          SettingsRow(
            icon: Icons.key_rounded,
            title: AppStrings.tr(ref, 'account'),
            subtitle: AppStrings.tr(ref, 'accountSub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountSettingsScreen(user: _currentUser),
                ),
              );
            },
          ),
          SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: AppStrings.tr(ref, 'privacy'),
            subtitle: AppStrings.tr(ref, 'privacySub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),

          // Section 2: Preferences
          SettingsSectionHeader(title: AppStrings.tr(ref, 'preferences')),
          SettingsRow(
            icon: Icons.palette_outlined,
            title: AppStrings.tr(ref, 'chatsAndTheme'),
            subtitle:
                '${ref.watch(themeModeProvider).name.toUpperCase()}, ${AppStrings.tr(ref, 'chatsAndThemeSub')}',
            onTap: _showThemeSelectionDialog,
          ),
          SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: AppStrings.tr(ref, 'notifications'),
            subtitle: AppStrings.tr(ref, 'notificationsSub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),
          SettingsRow(
            icon: Icons.data_usage_rounded,
            title: AppStrings.tr(ref, 'storage'),
            subtitle: AppStrings.tr(ref, 'storageSub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StorageSettingsScreen(),
                ),
              );
            },
          ),
          SettingsRow(
            icon: Icons.language_rounded,
            title: AppStrings.tr(ref, 'appLanguage'),
            subtitle: AppStrings.tr(ref, 'appLanguageSub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppLanguageScreen(),
                ),
              );
            },
          ),

          // Section 3: Advanced & AI Engine
          SettingsSectionHeader(title: AppStrings.tr(ref, 'advancedAiEngine')),
          SettingsRow(
            icon: Icons.auto_awesome_rounded,
            title: AppStrings.tr(ref, 'geminiVoiceEngine'),
            subtitle: AppStrings.tr(ref, 'geminiVoiceEngineSub'),
            iconColor: const Color(0xFF53BDEC),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VoicePersonaScreen(),
                ),
              );
            },
          ),

          // Section 4: Support & Community
          SettingsSectionHeader(title: AppStrings.tr(ref, 'supportAndCommunity')),
          SettingsRow(
            icon: Icons.help_outline_rounded,
            title: AppStrings.tr(ref, 'help'),
            subtitle: AppStrings.tr(ref, 'helpSub'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpSettingsScreen(),
                ),
              );
            },
          ),
          SettingsRow(
            icon: Icons.people_outline_rounded,
            title: AppStrings.tr(ref, 'inviteFriend'),
            subtitle: AppStrings.tr(ref, 'inviteFriendSub'),
            onTap: () {
              Share.share(
                'Join me on Livocal — the next-generation chat app with live speech-to-speech AI voice translation! Download here: https://github.com/shojibahmed24/Livocal',
              );
            },
          ),

          // Section 5: Session
          SettingsSectionHeader(title: AppStrings.tr(ref, 'session')),
          SettingsRow(
            icon: Icons.logout_rounded,
            title: AppStrings.tr(ref, 'logout'),
            subtitle: AppStrings.tr(ref, 'logoutSub'),
            isDestructive: true,
            onTap: _showLogoutDialog,
          ),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  AppStrings.tr(ref, 'from'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text(
                  'LIVOCAL',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr(ref, 'version'),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
