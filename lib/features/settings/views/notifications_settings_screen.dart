import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
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
  String _msgTone = 'Livocal Chime (Default)';
  String _msgVibrate = 'Default';
  bool _highPriority = true;
  bool _reactionNotifications = true;
  String _callRingtone = 'Livocal Harmony (Default)';
  String _callVibrate = 'Default';

  @override
  void initState() {
    super.initState();
    _conversationTones =
        SharedPref.instance.getBool('notif_conv_tones') ?? true;
    _msgTone =
        SharedPref.instance.getString('notif_msg_tone') ?? 'Livocal Chime (Default)';
    _msgVibrate =
        SharedPref.instance.getString('notif_msg_vibrate') ?? 'Default';
    _highPriority =
        SharedPref.instance.getBool('notif_high_priority') ?? true;
    _reactionNotifications =
        SharedPref.instance.getBool('notif_reactions') ?? true;
    _callRingtone =
        SharedPref.instance.getString('notif_call_ringtone') ?? 'Livocal Harmony (Default)';
    _callVibrate =
        SharedPref.instance.getString('notif_call_vibrate') ?? 'Default';
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
          children: options
              .map(
                (opt) => RadioListTile<String>(
                  title: Text(_localizeOption(opt)),
                  value: opt,
                ),
              )
              .toList(),
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

  /// Interactive Tone Picker with built-in presets, custom audio file picker from storage, and live sound preview.
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
    String? customPath = SharedPref.instance.getString(
      isCallRingtone ? 'notif_custom_ringtone_path' : 'notif_custom_msg_tone_path',
    );
    String? playingTone;

    showAppDialog(
      context: context,
      title: title,
      icon: isCallRingtone ? Icons.ring_volume_rounded : Icons.music_note_rounded,
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                        color: isPlaying ? const Color(0xFFE53935) : AppColors.primary,
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
                const Divider(),
                if (customPath != null &&
                    customPath!.isNotEmpty &&
                    File(customPath!).existsSync()) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Radio<String>(
                      value: 'custom',
                    ),
                  title: Text(
                    '${AppStrings.tr(ref, 'customLabel')}${File(customPath!).uri.pathSegments.last}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: currentSelection == 'custom' ? FontWeight.bold : FontWeight.w500,
                      color: currentSelection == 'custom' ? AppColors.primary : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      playingTone == 'custom' ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                      color: playingTone == 'custom' ? const Color(0xFFE53935) : AppColors.primary,
                      size: 28,
                    ),
                    onPressed: () async {
                      if (playingTone == 'custom') {
                        await RingtoneManager().stopPreview();
                        setDialogState(() => playingTone = null);
                      } else {
                        setDialogState(() => playingTone = 'custom');
                        await RingtoneManager().previewTone('custom', customPath: customPath);
                      }
                    },
                  ),
                  onTap: () => setDialogState(() => currentSelection = 'custom'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.audio_file_outlined, size: 20),
                label: Text(AppStrings.tr(ref, 'chooseAudioFromPhone')),
                onPressed: () async {
                  await RingtoneManager().stopPreview();
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.single.path != null) {
                    final path = result.files.single.path!;
                    final name = result.files.single.name;
                    setDialogState(() {
                      customPath = path;
                      currentSelection = 'custom';
                    });
                    if (isCallRingtone) {
                      setState(() => _callRingtone = name);
                      SharedPref.instance.setString('notif_call_ringtone', name);
                      SharedPref.instance.setString('notif_custom_ringtone_path', path);
                    } else {
                      setState(() => _msgTone = name);
                      SharedPref.instance.setString('notif_msg_tone', name);
                      SharedPref.instance.setString('notif_custom_msg_tone_path', path);
                    }
                    if (mounted && dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                      showSnackBar(
                        context: context,
                        content: '$title set to custom audio: $name',
                        type: SnacBarType.info,
                      );
                    }
                  }
                },
              ),
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
          label: AppStrings.tr(ref, 'save').toUpperCase(),
          isPrimary: true,
          onPressed: () async {
            await RingtoneManager().stopPreview();
            if (currentSelection != 'custom') {
              if (isCallRingtone) {
                setState(() => _callRingtone = currentSelection);
                SharedPref.instance.setString('notif_call_ringtone', currentSelection);
                SharedPref.instance.setString('notif_custom_ringtone_path', '');
              } else {
                setState(() => _msgTone = currentSelection);
                SharedPref.instance.setString('notif_msg_tone', currentSelection);
                SharedPref.instance.setString('notif_custom_msg_tone_path', '');
              }
            }
            if (mounted) {
              Navigator.pop(context);
              showSnackBar(
                context: context,
                content: '$title ${AppStrings.tr(ref, 'toneUpdatedSuccess')}',
                type: SnacBarType.info,
              );
            }
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
          AppStrings.tr(ref, 'notifications'),
          style: const TextStyle(
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
                  PopupMenuItem(
                    value: 'reset',
                    child: Text(AppStrings.tr(ref, 'resetNotifications')),
                  ),
                ],
              ).then((value) {
                if (!mounted) return;
                if (value == 'reset') {
                  setState(() {
                    _conversationTones = true;
                    _msgTone = 'Livocal Chime (Default)';
                    _msgVibrate = 'Default';
                    _highPriority = true;
                    _reactionNotifications = true;
                    _callRingtone = 'Livocal Harmony (Default)';
                    _callVibrate = 'Default';
                  });
                  SharedPref.instance.setBool('notif_conv_tones', true);
                  SharedPref.instance.setString('notif_msg_tone', 'Livocal Chime (Default)');
                  SharedPref.instance.setString('notif_msg_vibrate', 'Default');
                  SharedPref.instance.setBool('notif_high_priority', true);
                  SharedPref.instance.setBool('notif_reactions', true);
                  SharedPref.instance.setString('notif_call_ringtone', 'Livocal Harmony (Default)');
                  SharedPref.instance.setString('notif_call_vibrate', 'Default');
                  SharedPref.instance.setString('notif_custom_ringtone_path', '');
                  SharedPref.instance.setString('notif_custom_msg_tone_path', '');
                  if (context.mounted) {
                    showSnackBar(
                      context: context,
                      content: AppStrings.tr(ref, 'resetNotificationsSuccess'),
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
          SettingsRow(
            icon: Icons.volume_up_outlined,
            title: AppStrings.tr(ref, 'conversationTones'),
            subtitle: AppStrings.tr(ref, 'conversationTonesSub'),
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
          SettingsSectionHeader(title: AppStrings.tr(ref, 'messagesHeader')),
          SettingsRow(
            icon: Icons.music_note_outlined,
            title: AppStrings.tr(ref, 'notificationTone'),
            subtitle: _localizeOption(_msgTone),
            onTap: () => _showTonePickerDialog(isCallRingtone: false),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.vibration_outlined,
            title: AppStrings.tr(ref, 'vibrate'),
            subtitle: _localizeOption(_msgVibrate),
            onTap: () => _showRadioDialog(
              title: AppStrings.tr(ref, 'vibrate'),
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
            title: AppStrings.tr(ref, 'useHighPriority'),
            subtitle: AppStrings.tr(ref, 'useHighPrioritySub'),
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
            title: AppStrings.tr(ref, 'reactionNotifications'),
            subtitle: AppStrings.tr(ref, 'reactionNotificationsSub'),
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
          SettingsSectionHeader(title: AppStrings.tr(ref, 'callsHeader')),
          SettingsRow(
            icon: Icons.ring_volume_outlined,
            title: AppStrings.tr(ref, 'ringtone'),
            subtitle: _localizeOption(_callRingtone),
            onTap: () => _showTonePickerDialog(isCallRingtone: true),
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.vibration_outlined,
            title: AppStrings.tr(ref, 'vibrate'),
            subtitle: _localizeOption(_callVibrate),
            onTap: () => _showRadioDialog(
              title: AppStrings.tr(ref, 'vibrate'),
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
