import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/features/home/views/profile_edit_screen.dart';
import 'package:livocal/features/settings/views/qr_code_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/theme.dart';
import 'package:livocal/features/settings/views/account_settings_screen.dart';
import 'package:livocal/features/settings/views/privacy_settings_screen.dart';
import 'package:livocal/features/settings/views/notifications_settings_screen.dart';
import 'package:livocal/features/settings/views/storage_settings_screen.dart';
import 'package:livocal/features/settings/views/app_language_screen.dart';
import 'package:livocal/features/settings/views/help_settings_screen.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34)
            : Colors.white,
        title: const Text(
          'Log out of Livocal?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out? Your local messages and credentials will be safely preserved in local storage.',
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
              await AuthController.logout(
                context: context,
                ref: ref,
                userId: widget.user.id,
              );
            },
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  void _showGeminiConfigDialog() {
    final apiKeyController =
        TextEditingController(text: GeminiLiveTranslator.getSavedApiKey());
    String selectedModel = GeminiLiveTranslator.getSavedModelId();
    String selectedVoice = GeminiLiveTranslator.getSavedVoiceName();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.lightBackground,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Gemini Live Voice Settings', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini API Key (Optional if Backend Relay is active):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Live Translation Model:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: GeminiLiveTranslator.modelPresets.any((m) => m.id == selectedModel)
                        ? selectedModel
                        : GeminiLiveTranslator.modelPresets.first.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: GeminiLiveTranslator.modelPresets.map((preset) {
                      return DropdownMenuItem(
                        value: preset.id,
                        child: Text(preset.title, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedModel = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Live Voice Persona:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: GeminiLiveTranslator.availableVoices.contains(selectedVoice)
                        ? selectedVoice
                        : GeminiLiveTranslator.availableVoices.first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: GeminiLiveTranslator.availableVoices.map((voice) {
                      return DropdownMenuItem(
                        value: voice,
                        child: Text(voice, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedVoice = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await GeminiLiveTranslator.saveApiKey(apiKeyController.text);
                  await GeminiLiveTranslator.saveModelId(selectedModel);
                  await GeminiLiveTranslator.saveVoiceName(selectedVoice);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    showSnackBar(
                      context: context,
                      content: 'Gemini Live settings saved successfully!',
                      type: SnacBarType.info,
                    );
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final textTheme = Theme.of(context).custom.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.titleLarge.copyWith(color: colorTheme.iconColor),
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
          const SettingsSectionHeader(title: 'Account & Privacy'),
          SettingsRow(
            icon: Icons.key_rounded,
            title: 'Account',
            subtitle: 'Security notifications, two-step verification, change number',
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
            title: 'Privacy',
            subtitle: 'Block contacts, disappearing messages, biometric lock',
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
          const SettingsSectionHeader(title: 'Preferences'),
          SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Chats & Theme',
            subtitle:
                'Theme: ${ref.watch(themeModeProvider).name.toUpperCase()}, wallpapers, chat history',
            onTap: _showThemeSelectionDialog,
          ),
          SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Message, group & incoming call tones, vibration',
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
            title: 'Storage and data',
            subtitle: 'Network usage, cache cleaner, media auto-download',
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
            title: 'App language',
            subtitle: 'English (device language), বাংলা, हिन्दी, العربية...',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppLanguageScreen(),
                ),
              );
            },
          ),

          // Section 3: Advanced & AI Engine (moved from top for clean system-app feel)
          const SettingsSectionHeader(title: 'Advanced & AI Engine'),
          SettingsRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Gemini Live Voice Engine',
            subtitle: 'API key, neural voice presets & speech model config',
            iconColor: const Color(0xFF53BDEC),
            onTap: _showGeminiConfigDialog,
          ),

          // Section 4: Support & Community
          const SettingsSectionHeader(title: 'Support & Community'),
          SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            subtitle: 'Help centre, contact us, terms & privacy policy',
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
            title: 'Invite a friend',
            subtitle: 'Share Livocal with contacts & family',
            onTap: () {
              Share.share(
                'Join me on Livocal — the next-generation chat app with live speech-to-speech AI voice translation! Download here: https://github.com/shojibahmed24/Livocal',
              );
            },
          ),

          // Section 5: Session
          const SettingsSectionHeader(title: 'Session'),
          SettingsRow(
            icon: Icons.logout_rounded,
            title: 'Log out',
            subtitle: 'Clear local credentials and sign out',
            isDestructive: true,
            onTap: _showLogoutDialog,
          ),

          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Text(
                  'from',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'LIVOCAL',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Production Ready)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
