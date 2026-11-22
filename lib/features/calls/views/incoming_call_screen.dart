import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/widgets/call_scaffold.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/features/calls/views/widgets/swipe_to_answer.dart';
import 'package:livocal/features/calls/services/call_kit_service.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';
import 'package:livocal/features/settings/services/block_service.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _answerWithTranslation = true;
  bool _navigated = false;
  bool _ringtoneMuted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // IMPORTANT: Do NOT call endAllCalls() here — it can kill the active call.
    final callerId = ref.read(callControllerProvider).activeSession?.callerId;
    RingtoneManager().startIncomingRingtone(contactId: callerId);
  }

  @override
  void dispose() {
    RingtoneManager().stopRingtone();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_navigated) return;
    _navigated = true;
    await RingtoneManager().stopRingtone();
    final controller = ref.read(callControllerProvider.notifier);
    if (!_answerWithTranslation) {
      await controller.setAudioMode(CallAudioMode.originalOnly);
    } else {
      await controller.setAudioMode(CallAudioMode.ducking);
    }
    await controller.acceptAndConnectCall(
      withTranslation: _answerWithTranslation,
    );
    if (!mounted) return;
    controller.navigateToActiveCall();
  }

  Future<void> _declineCall() async {
    if (_navigated) return;
    _navigated = true;
    await RingtoneManager().stopRingtone();
    final callId = ref.read(callControllerProvider).activeSession?.callId;
    if (callId != null) {
      await CallKitService().endCall(callId);
    }
    await ref.read(callControllerProvider.notifier).endCall(
          endStatus: CallStateStatus.rejected,
          isDeclined: true,
        );
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _muteRingtone() {
    if (_ringtoneMuted) return;
    HapticFeedback.lightImpact();
    RingtoneManager().stopRingtone();
    setState(() => _ringtoneMuted = true);
  }

  Future<void> _showMoreMenu() async {
    final session = ref.read(callControllerProvider).activeSession;
    if (session == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_off_rounded),
              title: const Text('Mute ringtone'),
              onTap: () {
                Navigator.pop(ctx);
                _muteRingtone();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.error),
              title: const Text('Block caller'),
              onTap: () async {
                Navigator.pop(ctx);
                await BlockService.blockContact(
                  contactId: session.peerId,
                  contactName: session.peerName,
                  phone: session.peerPhone,
                );
                await _declineCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded,
                  color: AppColors.error),
              title: const Text('Report caller'),
              onTap: () async {
                Navigator.pop(ctx);
                final self = getCurrentUser();
                if (self != null) {
                  try {
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reporterId': self.id,
                      'reportedUserId': session.peerId,
                      'reason': 'Incoming call report',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  } catch (e) {
                    debugPrint('[IncomingCall] report failed: $e');
                  }
                }
                if (mounted) {
                  showSnackBar(
                    context: context,
                    content: 'Caller reported',
                    type: SnacBarType.info,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeclineWithMessage() async {
    final session = ref.read(callControllerProvider).activeSession;
    if (session == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reply = await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppStrings.tr(ref, 'declineWithMessage'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text("Can't talk now"),
              onTap: () => Navigator.pop(ctx, "Can't talk now"),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Call me later'),
              onTap: () => Navigator.pop(ctx, 'Call me later'),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Wrong number'),
              onTap: () => Navigator.pop(ctx, 'Wrong number'),
            ),
          ],
        ),
      ),
    );
    if (reply == null || !mounted) return;
    _navigated = true;
    await RingtoneManager().stopRingtone();
    await ref.read(callControllerProvider.notifier).declineWithMessage(reply);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallControllerState>(callControllerProvider, (previous, next) {
      if (_navigated || !mounted) return;
      final session = next.activeSession;
      if (session != null && session.status == CallStateStatus.connected) {
        _navigated = true;
        RingtoneManager().stopRingtone();
        ref.read(callControllerProvider.notifier).navigateToActiveCall();
      } else if (session == null ||
          session.status == CallStateStatus.ended ||
          session.status == CallStateStatus.rejected ||
          session.status == CallStateStatus.missed) {
        _navigated = true;
        RingtoneManager().stopRingtone();
        final callId = previous?.activeSession?.callId;
        if (callId != null) {
          CallKitService().endCall(callId);
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    final callState = ref.watch(callControllerProvider);
    final session = callState.activeSession;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final callerName = session?.peerName ?? 'Incoming Caller';
    final callerAvatar = session?.peerAvatar ?? '';
    final callerPhone = session?.peerPhone ?? '';
    final myLang = session?.myLanguage ?? callState.myLanguage;
    final peerLang = session?.peerLanguage ?? callState.peerLanguage;
    final self = getCurrentUser();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        debugPrint('[IncomingCallScreen] Back pressed. Declining incoming call.');
        await _declineCall();
      },
      child: CallScaffold(
        peerName: callerName,
        peerAvatar: callerAvatar,
        peerPhone: callerPhone,
        statusText: AppStrings.tr(ref, 'incomingVoiceCall'),
        badgeText: AppStrings.tr(ref, 'aiTranslatedVoiceCall'),
        badgeIcon: Icons.auto_awesome_rounded,
        pulseAnimation: _pulseController,
        topActions: [
          IconButton(
            tooltip: AppStrings.tr(ref, 'muteBtn'),
            onPressed: _muteRingtone,
            icon: Icon(
              _ringtoneMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          IconButton(
            tooltip: 'More options',
            onPressed: _showMoreMenu,
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
        subStatus: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _Pill(
              icon: Icons.verified_user_outlined,
              label: AppStrings.tr(ref, 'verifiedLivocalUser'),
              color: AppColors.accent,
              isDark: isDark,
            ),
            if (self != null && self.id.isNotEmpty)
              ref.watch(walletStreamProvider(self.id)).when(
                    data: (wallet) => _Pill(
                      icon: Icons.timer_outlined,
                      label: AppStrings.tr(
                        ref,
                        'minutesLeft',
                        args: {
                          'minutes': '${wallet.effectiveRemainingMinutes}',
                        },
                      ),
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
          ],
        ),
        middleWidget: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainer : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.tr(ref, 'answerWithAiTranslation'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Switch(
                      value: _answerWithTranslation,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _answerWithTranslation = val);
                      },
                    ),
                  ],
                ),
                if (_answerWithTranslation) ...[
                  const Divider(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageTile(
                          label: AppStrings.tr(ref, 'callerSpeaks'),
                          value: '${peerLang.flagEmoji} ${peerLang.nativeName}',
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          onTap: () async {
                            final picked = await showUniversalLanguagePicker(
                              context,
                              title: 'Caller language',
                              selectedCode: peerLang.code,
                            );
                            if (picked != null && mounted) {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .setPeerLanguage(picked.code);
                            }
                          },
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      Expanded(
                        child: _LanguageTile(
                          label: AppStrings.tr(ref, 'youHearSpeak'),
                          value: '${myLang.flagEmoji} ${myLang.nativeName}',
                          color: AppColors.primary,
                          onTap: () async {
                            final picked = await showUniversalLanguagePicker(
                              context,
                              title: 'Your language',
                              selectedCode: myLang.code,
                            );
                            if (picked != null && mounted) {
                              final synced = await ref
                                  .read(callControllerProvider.notifier)
                                  .setMyLanguage(picked.code);
                              if (!synced && context.mounted) {
                                showSnackBar(
                                  context: context,
                                  content: AppStrings.tr(
                                    ref,
                                    'languageAppliedLocally',
                                  ),
                                  type: SnacBarType.info,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.tr(ref, 'aiUsesMinutes'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: _showDeclineWithMessage,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(AppStrings.tr(ref, 'declineWithMessage')),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            SwipeToAnswer(
              onAnswer: _acceptCall,
              onDecline: _declineCall,
              label: _answerWithTranslation
                  ? AppStrings.tr(ref, 'swipeToAnswerAi')
                  : AppStrings.tr(ref, 'swipeToAnswer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
