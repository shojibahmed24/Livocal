import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
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
                      SystemSound.play(SystemSoundType.click);
                      HapticFeedback.selectionClick();
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
                  showSnackBar(
                    context: context,
                    content: 'Notification settings reset to defaults',
                    type: SnacBarType.info,
                  );
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Conversation tones'),
            subtitle: const Text('Play sounds for incoming and outgoing messages'),
            value: _conversationTones,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _conversationTones = val);
              SharedPref.instance.setBool('notif_conv_tones', val);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),
          ListTile(
            title: const Text('Notification tone'),
            subtitle: Text(_msgTone, style: const TextStyle(color: Colors.grey)),
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
          ListTile(
            title: const Text('Vibrate'),
            subtitle: Text(_msgVibrate, style: const TextStyle(color: Colors.grey)),
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
          SwitchListTile(
            title: const Text('Use high priority notifications'),
            subtitle: const Text('Show previews of notifications at the top of the screen'),
            value: _highPriority,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _highPriority = val);
              SharedPref.instance.setBool('notif_high_priority', val);
            },
          ),
          SwitchListTile(
            title: const Text('Reaction notifications'),
            subtitle: const Text('Show notifications for reactions to messages you send'),
            value: _reactionNotifications,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _reactionNotifications = val);
              SharedPref.instance.setBool('notif_reactions', val);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Calls',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
            ),
          ),
          ListTile(
            title: const Text('Ringtone'),
            subtitle: Text(_callRingtone, style: const TextStyle(color: Colors.grey)),
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
          ListTile(
            title: const Text('Vibrate'),
            subtitle: Text(_callVibrate, style: const TextStyle(color: Colors.grey)),
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
