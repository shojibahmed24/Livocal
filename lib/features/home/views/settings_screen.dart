import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/home/views/profile_edit_screen.dart';
import 'package:livocal/features/settings/views/qr_code_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/ui/livocal_app_bar.dart';
import 'package:livocal/shared/ui/livocal_avatar.dart';
import 'package:livocal/shared/ui/livocal_card.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';
import 'package:livocal/theme/theme.dart';
import 'package:livocal/features/settings/views/account_settings_screen.dart';
import 'package:livocal/features/settings/views/privacy_settings_screen.dart';
import 'package:livocal/features/settings/views/notifications_settings_screen.dart';
import 'package:livocal/features/settings/views/storage_settings_screen.dart';
import 'package:livocal/features/settings/views/app_language_screen.dart';
import 'package:livocal/features/settings/views/help_settings_screen.dart';
import 'package:livocal/features/settings/views/voice_persona_screen.dart';
import 'package:livocal/features/settings/views/payment_settings_screen.dart';
import 'package:livocal/features/settings/views/chat_settings_screen.dart';
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
      appBar: livocalAppBar(
        context,
        title: Text(
          AppStrings.tr(ref, 'settings'),
          style: TextStyle(
            fontFamily: CustomTextTheme.display,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: ListView(
        children: [
          // User Profile Header Card with Real QR Code Access
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: LivocalCard(
              padding: const EdgeInsets.all(14),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.08),
                  AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.06),
                ],
              ),
              child: Row(
                children: [
                  LivocalAvatar(
                    name: _currentUser.name,
                    imageUrl: _currentUser.avatarUrl,
                    size: 62,
                    ring: AvatarRing.brand,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.name,
                          style: textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currentUser.phone.getFormattedNumber(),
                          style: textTheme.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SharedPref.instance.getString('user_about') ??
                              'Hey there! I am using Livocal.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
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
          const SizedBox(height: 8),

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
          SettingsRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment Receiving Accounts',
            subtitle: 'Binance Pay, USDT TRC-20/BEP-20, bKash & Nagad',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentSettingsScreen(user: _currentUser),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatSettingsScreen(),
                ),
              );
            },
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
          SettingsSectionHeader(
              title: AppStrings.tr(ref, 'supportAndCommunity')),
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
