import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _conversationTones = true;
  String _msgTone = 'Default (Livocal)';
  String _msgVibrate = 'Default';
  bool _highPriority = true;
  bool _reactionNotifications = true;
  String _callRingtone = 'Default (Livocal)';
  String _callVibrate = 'Default';

  @override
  void initState() {
    super.initState();
    _conversationTones =
        SharedPref.instance.getBool('notif_conv_tones') ?? true;
    _msgTone =
        SharedPref.instance.getString('notif_msg_tone') ?? 'Default (Livocal)';
    _msgVibrate =
        SharedPref.instance.getString('notif_msg_vibrate') ?? 'Default';
    _highPriority =
        SharedPref.instance.getBool('notif_high_priority') ?? true;
    _reactionNotifications =
        SharedPref.instance.getBool('notif_reactions') ?? true;
    _callRingtone =
        SharedPref.instance.getString('notif_call_ringtone') ?? 'Default (Livocal)';
    _callVibrate =
        SharedPref.instance.getString('notif_call_vibrate') ?? 'Default';
  }

  void _showRadioDialog({
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
                    SystemSound.play(SystemSoundType.click);
                    HapticFeedback.selectionClick();
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
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset notification settings'),
                  ),
                ],
              ).then((value) {
                if (!mounted) return;
                if (value == 'reset') {
                  setState(() {
                    _conversationTones = true;
                    _msgTone = 'Default (Livocal)';
                    _msgVibrate = 'Default';
                    _highPriority = true;
                    _reactionNotifications = true;
                    _callRingtone = 'Default (Livocal)';
                    _callVibrate = 'Default';
                  });
                  SharedPref.instance.setBool('notif_conv_tones', true);
                  SharedPref.instance.setString('notif_msg_tone', 'Default (Livocal)');
                  SharedPref.instance.setString('notif_msg_vibrate', 'Default');
                  SharedPref.instance.setBool('notif_high_priority', true);
                  SharedPref.instance.setBool('notif_reactions', true);
                  SharedPref.instance.setString('notif_call_ringtone', 'Default (Livocal)');
                  SharedPref.instance.setString('notif_call_vibrate', 'Default');
                  if (context.mounted) {
                    showSnackBar(
                      context: context,
                      content: 'Notification settings reset to defaults',
                      type: SnacBarType.info,
                    );
                  }
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'General'),
          SettingsRow(
            icon: Icons.volume_up_outlined,
            title: 'Conversation tones',
            subtitle: 'Play sounds for incoming and outgoing messages',
            showChevron: false,
            trailing: Switch(
              value: _conversationTones,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _conversationTones = val);
                SharedPref.instance.setBool('notif_conv_tones', val);
              },
            ),
          ),
          const Divider(height: 1),
          const SettingsSectionHeader(title: 'Messages'),
          SettingsRow(
            icon: Icons.music_note_outlined,
            title: 'Notification tone',
            subtitle: _msgTone,
            onTap: () => _showRadioDialog(
              title: 'Notification tone',
              options: ['Default (Livocal)', 'Chime', 'Bell', 'Note', 'Silent'],
              currentValue: _msgTone,
              onSelected: (val) {
                setState(() => _msgTone = val);
                SharedPref.instance.setString('notif_msg_tone', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.vibration_outlined,
            title: 'Vibrate',
            subtitle: _msgVibrate,
            onTap: () => _showRadioDialog(
              title: 'Vibrate',
              options: ['Default', 'Short', 'Long', 'Off'],
              currentValue: _msgVibrate,
              onSelected: (val) {
                setState(() => _msgVibrate = val);
                SharedPref.instance.setString('notif_msg_vibrate', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.priority_high_outlined,
            title: 'Use high priority notifications',
            subtitle: 'Show previews of notifications at the top of the screen',
            showChevron: false,
            trailing: Switch(
              value: _highPriority,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _highPriority = val);
                SharedPref.instance.setBool('notif_high_priority', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.add_reaction_outlined,
            title: 'Reaction notifications',
            subtitle: 'Show notifications for reactions to messages you send',
            showChevron: false,
            trailing: Switch(
              value: _reactionNotifications,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() => _reactionNotifications = val);
                SharedPref.instance.setBool('notif_reactions', val);
              },
            ),
          ),
          const Divider(height: 1),
          const SettingsSectionHeader(title: 'Calls'),
          SettingsRow(
            icon: Icons.ring_volume_outlined,
            title: 'Ringtone',
            subtitle: _callRingtone,
            onTap: () => _showRadioDialog(
              title: 'Ringtone',
              options: ['Default (Livocal)', 'Digital Phone', 'Marimba', 'Classic Bell'],
              currentValue: _callRingtone,
              onSelected: (val) {
                setState(() => _callRingtone = val);
                SharedPref.instance.setString('notif_call_ringtone', val);
              },
            ),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.vibration_outlined,
            title: 'Vibrate',
            subtitle: _callVibrate,
            onTap: () => _showRadioDialog(
              title: 'Vibrate',
              options: ['Default', 'Short', 'Long', 'Off'],
              currentValue: _callVibrate,
              onSelected: (val) {
                setState(() => _callVibrate = val);
                SharedPref.instance.setString('notif_call_vibrate', val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
