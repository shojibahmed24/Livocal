import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';

class CustomNotificationsScreen extends ConsumerStatefulWidget {
  final User contact;
  final String contactName;

  const CustomNotificationsScreen({
    super.key,
    required this.contact,
    required this.contactName,
  });

  @override
  ConsumerState<CustomNotificationsScreen> createState() =>
      _CustomNotificationsScreenState();
}

class _CustomNotificationsScreenState
    extends ConsumerState<CustomNotificationsScreen> {
  bool _useCustomNotifications = false;

  String _msgTone = 'Livocal Chime (Default)';
  String _msgVibrate = 'Default';
  bool _highPriority = true;

  String _callRingtone = 'Livocal Harmony (Default)';
  String _callVibrate = 'Default';

  String get _contactId => widget.contact.id;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final pref = SharedPref.instance;
    _useCustomNotifications =
        pref.getBool('custom_notif_enabled_$_contactId') ?? false;

    _msgTone = pref.getString('contact_tone_$_contactId') ??
        pref.getString('notif_msg_tone') ??
        'Livocal Chime (Default)';

    _msgVibrate = pref.getString('contact_vibrate_$_contactId') ??
        pref.getString('notif_msg_vibrate') ??
        'Default';

    _highPriority = pref.getBool('contact_high_priority_$_contactId') ??
        pref.getBool('notif_high_priority') ??
        true;

    _callRingtone = pref.getString('contact_call_ringtone_$_contactId') ??
        pref.getString('notif_call_ringtone') ??
        'Livocal Harmony (Default)';

    _callVibrate = pref.getString('contact_call_vibrate_$_contactId') ??
        pref.getString('notif_call_vibrate') ??
        'Default';
  }

  Future<void> _setUseCustom(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _useCustomNotifications = value);
    await SharedPref.instance
        .setBool('custom_notif_enabled_$_contactId', value);
  }

  String _localizeOption(String opt) {
    switch (opt) {
      case 'Default':
        return AppStrings.tr(ref, 'vibrateDefault');
      case 'Short':
        return AppStrings.tr(ref, 'vibrateShort');
      case 'Long':
        return AppStrings.tr(ref, 'vibrateLong');
      case 'Off':
        return AppStrings.tr(ref, 'vibrateOff');
      case 'Livocal Harmony (Default)':
        return AppStrings.tr(ref, 'livocalHarmonyPreset');
      case 'Digital Pulse':
        return AppStrings.tr(ref, 'digitalPulsePreset');
      case 'Marimba Bloom':
        return AppStrings.tr(ref, 'marimbaBloomPreset');
      case 'Classic Bell':
        return AppStrings.tr(ref, 'classicBellPreset');
      case 'Livocal Chime (Default)':
        return AppStrings.tr(ref, 'livocalChimePreset');
      case 'Subtle Ding':
        return AppStrings.tr(ref, 'subtleDingPreset');
      case 'Crystal Pop':
        return AppStrings.tr(ref, 'crystalPopPreset');
      default:
        return opt;
    }
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
      content: RadioGroup<String>(
        groupValue: currentValue,
        onChanged: (val) {
          if (val != null) {
            SystemSound.play(SystemSoundType.click);
            HapticFeedback.selectionClick();
            onSelected(val);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String>(
              value: opt,
              title: Text(_localizeOption(opt)),
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
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

  void _showTonePickerDialog({required bool isCallRingtone}) {
    final title = isCallRingtone
        ? AppStrings.tr(ref, 'callRingtoneTitle')
        : AppStrings.tr(ref, 'messageNotificationTone');
    final presets = isCallRingtone
        ? [
            'Livocal Harmony (Default)',
            'Digital Pulse',
            'Marimba Bloom',
            'Classic Bell',
          ]
        : [
            'Livocal Chime (Default)',
            'Subtle Ding',
            'Crystal Pop',
          ];

    String currentSelection = isCallRingtone ? _callRingtone : _msgTone;
    String? playingTone;

    showAppDialog(
      context: context,
      title: title,
      icon: isCallRingtone
          ? Icons.ring_volume_rounded
          : Icons.music_note_rounded,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return RadioGroup<String>(
            groupValue: currentSelection,
            onChanged: (val) {
              if (val != null) {
                setDialogState(() => currentSelection = val);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...presets.map((preset) {
                  final isSelected = currentSelection == preset;
                  final isPlaying = playingTone == preset;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: preset,
                    ),
                    title: Text(
                      _localizeOption(preset),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        color: isPlaying
                            ? const Color(0xFFE53935)
                            : AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (isPlaying) {
                          await RingtoneManager().stopPreview();
                          setDialogState(() => playingTone = null);
                        } else {
                          setDialogState(() => playingTone = preset);
                          await RingtoneManager().previewTone(preset);
                        }
                      },
                    ),
                    onTap: () {
                      setDialogState(() => currentSelection = preset);
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () async {
            await RingtoneManager().stopPreview();
            if (mounted) Navigator.pop(context);
          },
        ),
        AppDialogAction(
          label: AppStrings.tr(ref, 'ok').toUpperCase(),
          onPressed: () async {
            await RingtoneManager().stopPreview();
            if (isCallRingtone) {
              setState(() => _callRingtone = currentSelection);
              await SharedPref.instance.setString(
                'contact_call_ringtone_$_contactId',
                currentSelection,
              );
            } else {
              setState(() => _msgTone = currentSelection);
              await SharedPref.instance.setString(
                'contact_tone_$_contactId',
                currentSelection,
              );
            }
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer;
    const primaryColor = AppColors.primary;
    final disabledColor = isDark ? Colors.white24 : Colors.black26;

    final isBangla = ref.watch(appLocaleProvider).languageCode == 'bn';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          isBangla ? 'কাস্টম নোটিফিকেশন' : 'Custom notifications',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      body: ListView(
        children: [
          // Top Toggle: Use custom notifications
          Container(
            color: cardBg,
            child: SwitchListTile(
              secondary: Icon(
                Icons.tune_rounded,
                color: _useCustomNotifications ? primaryColor : Colors.grey,
              ),
              title: Text(
                isBangla
                    ? 'কাস্টম নোটিফিকেশন ব্যবহার করুন'
                    : 'Use custom notifications',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
              ),
              subtitle: Text(
                isBangla
                    ? '${widget.contactName}-এর মেসেজ ও কলের জন্য আলাদা নোটিফিকেশন সেট করুন'
                    : 'Use custom notification settings for messages and calls from ${widget.contactName}',
                style: const TextStyle(fontSize: 12.5),
              ),
              value: _useCustomNotifications,
              activeThumbColor: primaryColor,
              onChanged: _setUseCustom,
            ),
          ),

          const SizedBox(height: 12),

          // Message Notifications Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isBangla ? 'মেসেজ নোটিফিকেশন' : 'Message notifications',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _useCustomNotifications ? primaryColor : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Message Notifications Container
          Container(
            color: cardBg,
            child: Column(
              children: [
                ListTile(
                  enabled: _useCustomNotifications,
                  leading: Icon(
                    Icons.music_note_outlined,
                    color: _useCustomNotifications
                        ? const Color(0xFF8696A0)
                        : disabledColor,
                  ),
                  title: Text(
                    AppStrings.tr(ref, 'notificationTone'),
                    style: TextStyle(
                      color: _useCustomNotifications ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    _localizeOption(_msgTone),
                    style: TextStyle(
                      color: _useCustomNotifications
                          ? Colors.grey
                          : disabledColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: _useCustomNotifications
                        ? Colors.grey
                        : disabledColor,
                  ),
                  onTap: _useCustomNotifications
                      ? () => _showTonePickerDialog(isCallRingtone: false)
                      : null,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  enabled: _useCustomNotifications,
                  leading: Icon(
                    Icons.vibration_outlined,
                    color: _useCustomNotifications
                        ? const Color(0xFF8696A0)
                        : disabledColor,
                  ),
                  title: Text(
                    AppStrings.tr(ref, 'vibrate'),
                    style: TextStyle(
                      color: _useCustomNotifications ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    _localizeOption(_msgVibrate),
                    style: TextStyle(
                      color: _useCustomNotifications
                          ? Colors.grey
                          : disabledColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: _useCustomNotifications
                        ? Colors.grey
                        : disabledColor,
                  ),
                  onTap: _useCustomNotifications
                    ? () {
                        _showRadioDialog(
                          title: AppStrings.tr(ref, 'vibrate'),
                          options: const ['Off', 'Default', 'Short', 'Long'],
                          currentValue: _msgVibrate,
                          onSelected: (val) {
                            setState(() => _msgVibrate = val);
                            SharedPref.instance.setString(
                              'contact_vibrate_$_contactId',
                              val,
                            );
                          },
                        );
                      }
                    : null,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Icon(
                    Icons.priority_high_rounded,
                    color: _useCustomNotifications
                        ? const Color(0xFF8696A0)
                        : disabledColor,
                  ),
                  title: Text(
                    isBangla
                        ? 'উচ্চ অগ্রাধিকার নোটিফিকেশন'
                        : 'Use high priority notifications',
                    style: TextStyle(
                      color: _useCustomNotifications ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    isBangla
                        ? 'স্ক্রিনের উপরে প্রিভিউ নোটিফিকেশন দেখান'
                        : 'Show previews of notifications at the top of the screen',
                    style: TextStyle(
                      fontSize: 12,
                      color: _useCustomNotifications
                          ? Colors.grey
                          : disabledColor,
                    ),
                  ),
                  value: _highPriority,
                  activeThumbColor: primaryColor,
                  onChanged: _useCustomNotifications
                      ? (val) {
                          setState(() => _highPriority = val);
                          SharedPref.instance.setBool(
                            'contact_high_priority_$_contactId',
                            val,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Call Notifications Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isBangla ? 'কল নোটিফিকেশন' : 'Call notifications',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _useCustomNotifications ? primaryColor : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Call Notifications Container
          Container(
            color: cardBg,
            child: Column(
              children: [
                ListTile(
                  enabled: _useCustomNotifications,
                  leading: Icon(
                    Icons.ring_volume_outlined,
                    color: _useCustomNotifications
                        ? const Color(0xFF8696A0)
                        : disabledColor,
                  ),
                  title: Text(
                    AppStrings.tr(ref, 'ringtone'),
                    style: TextStyle(
                      color: _useCustomNotifications ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    _localizeOption(_callRingtone),
                    style: TextStyle(
                      color: _useCustomNotifications
                          ? Colors.grey
                          : disabledColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: _useCustomNotifications
                        ? Colors.grey
                        : disabledColor,
                  ),
                  onTap: _useCustomNotifications
                      ? () => _showTonePickerDialog(isCallRingtone: true)
                      : null,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  enabled: _useCustomNotifications,
                  leading: Icon(
                    Icons.vibration_outlined,
                    color: _useCustomNotifications
                        ? const Color(0xFF8696A0)
                        : disabledColor,
                  ),
                  title: Text(
                    AppStrings.tr(ref, 'vibrate'),
                    style: TextStyle(
                      color: _useCustomNotifications ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    _localizeOption(_callVibrate),
                    style: TextStyle(
                      color: _useCustomNotifications
                          ? Colors.grey
                          : disabledColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: _useCustomNotifications
                        ? Colors.grey
                        : disabledColor,
                  ),
                  onTap: _useCustomNotifications
                    ? () {
                        _showRadioDialog(
                          title: AppStrings.tr(ref, 'vibrate'),
                          options: const ['Off', 'Default', 'Short', 'Long'],
                          currentValue: _callVibrate,
                          onSelected: (val) {
                            setState(() => _callVibrate = val);
                            SharedPref.instance.setString(
                              'contact_call_vibrate_$_contactId',
                              val,
                            );
                          },
                        );
                      }
                    : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
