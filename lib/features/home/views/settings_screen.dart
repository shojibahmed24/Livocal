import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/features/home/views/profile_edit_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/theme.dart';

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
          'Are you sure you want to log out? Your local messages and credentials will be cleared.',
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
                ? const Color(0xFF1F2C34)
                : Colors.white,
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF25D366)),
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
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.black,
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
          // User Profile Header Tile
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
                    backgroundColor: Colors.grey[700],
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
                  const Icon(Icons.qr_code_2, color: Color(0xFF25D366)),
                ],
              ),
            ),
          ),
          const Divider(thickness: 0.5),

          // Gemini Live Translation
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Color(0xFF25D366)),
            title: const Text('Gemini Live Voice Translation'),
            subtitle: const Text('API key, live models & AI voice settings'),
            onTap: _showGeminiConfigDialog,
          ),

          // Account
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Account'),
            subtitle: const Text('Security notifications, change number'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Account security is managed securely via Firebase',
                type: SnacBarType.info,
              );
            },
          ),

          // Privacy
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle: const Text('Block contacts, disappearing messages'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Privacy and end-to-end security are active',
                type: SnacBarType.info,
              );
            },
          ),

          // Chats & Theme
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Chats'),
            subtitle: Text(
              'Theme: ${ref.watch(themeModeProvider).name.toUpperCase()}, wallpapers, chat history',
            ),
            onTap: _showThemeSelectionDialog,
          ),

          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            subtitle: const Text('Message, group & call tones'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Notifications are active via Firebase Cloud Messaging',
                type: SnacBarType.info,
              );
            },
          ),

          // Storage and Data
          ListTile(
            leading: const Icon(Icons.data_usage_outlined),
            title: const Text('Storage and data'),
            subtitle: const Text('Network usage, local Isar cache'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Local database is running on Isar DB engine',
                type: SnacBarType.info,
              );
            },
          ),

          // App Language
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('App language'),
            subtitle: const Text('English (device language) / বাংলা'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Livocal supports English & Bengali seamlessly',
                type: SnacBarType.info,
              );
            },
          ),

          // Help
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help'),
            subtitle: const Text('Help centre, contact us, privacy policy'),
            onTap: () {
              showSnackBar(
                context: context,
                content: 'Livocal Help Centre - Version 1.0.0 Production',
                type: SnacBarType.info,
              );
            },
          ),

          // Invite a friend
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Invite a friend'),
            onTap: () {
              Share.share(
                'Join me on Livocal — the next-generation chat app with live speech-to-speech AI voice translation! Download here: https://github.com/shojibahmed24/Livocal',
              );
            },
          ),

          const Divider(thickness: 0.5),

          // Log out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Clear local cache and sign out'),
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
                    color: Color(0xFF25D366),
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
