import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/storage_paths.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  bool _enterIsSend = false;
  bool _mediaVisibility = true;
  String _fontSize = 'Medium';
  String _wallpaper = 'Default';

  @override
  void initState() {
    super.initState();
    _enterIsSend = SharedPref.instance.getBool('chat_enter_is_send') ?? false;
    _mediaVisibility =
        SharedPref.instance.getBool('chat_media_visibility') ?? true;
    _fontSize = SharedPref.instance.getString('chat_font_size') ?? 'Medium';
    _wallpaper = SharedPref.instance.getString('chat_wallpaper') ?? 'Default';
  }

  void _showThemeDialog() {
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
            setState(() {});
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
          label: AppStrings.tr(ref, 'cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showWallpaperPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final solidColors = [
      {'name': 'Teal Slate', 'color': 0xFF0B141A},
      {'name': 'Ocean Navy', 'color': 0xFF101D25},
      {'name': 'Forest Green', 'color': 0xFF0A2E23},
      {'name': 'Warm Amber', 'color': 0xFF2A1F0D},
      {'name': 'Deep Purple', 'color': 0xFF20132E},
      {'name': 'Crimson Dusk', 'color': 0xFF2D1016},
      {'name': 'Charcoal', 'color': 0xFF121212},
      {'name': 'Classic Slate', 'color': 0xFF262D31},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    'Chat Wallpaper',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper_rounded, color: AppColors.primary),
                  title: const Text('Default Doodle Wallpaper'),
                  onTap: () async {
                    await SharedPref.instance.setString('chat_wallpaper', 'Default');
                    if (mounted) setState(() => _wallpaper = 'Default');
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      showSnackBar(
                        context: context,
                        content: 'Wallpaper reset to default',
                        type: SnacBarType.info,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      await SharedPref.instance.setString('chat_wallpaper', image.path);
                      if (mounted) setState(() => _wallpaper = 'Custom Photo');
                      if (mounted) {
                        showSnackBar(
                          context: context,
                          content: 'Custom wallpaper set successfully',
                          type: SnacBarType.info,
                        );
                      }
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Solid Colors',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: solidColors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final item = solidColors[index];
                      final colorVal = item['color'] as int;
                      return GestureDetector(
                        onTap: () async {
                          final key = 'color_$colorVal';
                          await SharedPref.instance.setString('chat_wallpaper', key);
                          if (mounted) setState(() => _wallpaper = item['name'] as String);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            showSnackBar(
                              context: context,
                              content: 'Wallpaper set to ${item['name']}',
                              type: SnacBarType.info,
                            );
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(colorVal),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFontSizeDialog() {
    final options = ['Small', 'Medium', 'Large'];

    showAppDialog(
      context: context,
      title: 'Font Size',
      icon: Icons.format_size_rounded,
      content: RadioGroup<String>(
        groupValue: _fontSize,
        onChanged: (val) {
          if (val != null) {
            setState(() => _fontSize = val);
            SharedPref.instance.setString('chat_font_size', val);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _handleClearAllChats() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Clear all chats?',
      icon: Icons.delete_sweep_outlined,
      iconColor: Colors.redAccent,
      contentText:
          'Messages in all chats will be deleted permanently from this device. Chats will remain empty.',
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: 'CLEAR CHATS',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true && mounted) {
      await IsarDb.clearAllMessages();
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'All chat messages cleared successfully.',
          type: SnacBarType.info,
        );
      }
    }
  }

  Future<void> _handleDeleteAllChats() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Delete all chats?',
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
      contentText:
          'All chats and messages will be permanently deleted from this device.',
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: 'DELETE ALL',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true && mounted) {
      await IsarDb.clearAllMessages();
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'All chats deleted permanently.',
          type: SnacBarType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeTitle = themeMode == ThemeMode.system
        ? AppStrings.tr(ref, 'systemDefault')
        : (themeMode == ThemeMode.dark
            ? AppStrings.tr(ref, 'dark')
            : AppStrings.tr(ref, 'light'));

    String wallpaperLabel = _wallpaper;
    if (_wallpaper.startsWith('color_')) {
      wallpaperLabel = 'Solid Color';
    } else if (_wallpaper.startsWith('/')) {
      wallpaperLabel = 'Custom Photo';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Display'),
          SettingsRow(
            icon: Icons.brightness_6_rounded,
            title: AppStrings.tr(ref, 'theme'),
            subtitle: themeTitle,
            onTap: _showThemeDialog,
          ),
          SettingsRow(
            icon: Icons.wallpaper_rounded,
            title: 'Wallpaper',
            subtitle: wallpaperLabel,
            onTap: _showWallpaperPicker,
          ),
          const Divider(height: 1),

          const SettingsSectionHeader(title: 'Chat settings'),
          SettingsRow(
            icon: Icons.keyboard_return_rounded,
            title: 'Enter is send',
            subtitle: 'Enter key will send your message',
            showChevron: false,
            trailing: Switch(
              value: _enterIsSend,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _enterIsSend = val);
                SharedPref.instance.setBool('chat_enter_is_send', val);
              },
            ),
          ),
          SettingsRow(
            icon: Icons.photo_library_outlined,
            title: 'Media visibility',
            subtitle: "Show newly downloaded media in your phone's gallery",
            showChevron: false,
            trailing: Switch(
              value: _mediaVisibility,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _mediaVisibility = val);
                SharedPref.instance.setBool('chat_media_visibility', val);
                DeviceStorage.syncMediaVisibility();
              },
            ),
          ),
          SettingsRow(
            icon: Icons.format_size_rounded,
            title: 'Font size',
            subtitle: _fontSize,
            onTap: _showFontSizeDialog,
          ),
          const Divider(height: 1),

          const SettingsSectionHeader(title: 'Chat history'),
          SettingsRow(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear all chats',
            subtitle: 'Delete all messages inside conversations',
            isDestructive: true,
            onTap: _handleClearAllChats,
          ),
          SettingsRow(
            icon: Icons.delete_forever_rounded,
            title: 'Delete all chats',
            subtitle: 'Permanently remove all chats and messages',
            isDestructive: true,
            onTap: _handleDeleteAllChats,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
