import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/call_scaffold.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/features/calls/views/widgets/swipe_to_answer.dart';
import 'package:livocal/features/calls/services/call_kit_service.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';
import 'package:livocal/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // IMPORTANT: Do NOT call endAllCalls() here — it can kill the active call session.
    // Only stop any existing native CallKit UI sound and start our in-app ringtone.
    RingtoneManager().startIncomingRingtone();
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ActiveCallScreen(),
      ),
    );
  }

  Future<void> _declineCall() async {
    if (_navigated) return;
    _navigated = true;
    await RingtoneManager().stopRingtone();
    await ref.read(callControllerProvider.notifier).endCall(
          recordAsMissed: true,
        );
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
        CallKitService().endAllCalls();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
        );
      } else if (session == null ||
          session.status == CallStateStatus.ended ||
          session.status == CallStateStatus.rejected ||
          session.status == CallStateStatus.missed) {
        _navigated = true;
        RingtoneManager().stopRingtone();
        CallKitService().endAllCalls();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    final callState = ref.watch(callControllerProvider);
    final session = callState.activeSession;

    final callerName = session?.peerName ?? 'Incoming Caller';
    final callerAvatar = session?.peerAvatar ?? '';
    final callerPhone = session?.peerPhone ?? '';
    final myLang = session?.myLanguage ?? callState.myLanguage;
    final peerLang = session?.peerLanguage ?? callState.peerLanguage;

    return CallScaffold(
      peerName: callerName,
      peerAvatar: callerAvatar,
      peerPhone: callerPhone,
      statusText: 'Incoming Voice Call...',
      badgeText: 'Livocal AI Translated Voice Call',
      badgeIcon: Icons.auto_awesome_rounded,
      pulseAnimation: _pulseController,
      middleWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF18252D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Answer with Gemini Live AI Translation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _answerWithTranslation,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _answerWithTranslation = val;
                      });
                    },
                  ),
                ],
              ),
              if (_answerWithTranslation) ...[
                const Divider(color: Colors.white12, height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showUniversalLanguagePicker(
                            context,
                            title: 'Caller Language',
                            selectedCode: peerLang.code,
                          );
                          if (picked != null && mounted) {
                            await ref
                                .read(callControllerProvider.notifier)
                                .setPeerLanguage(picked.code);
                          }
                        },
                        child: Column(
                          children: [
                            const Text(
                              'Caller Speaks',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${peerLang.flagEmoji} ${peerLang.nativeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showUniversalLanguagePicker(
                            context,
                            title: 'Your Language',
                            selectedCode: myLang.code,
                          );
                          if (picked != null && mounted) {
                            await ref
                                .read(callControllerProvider.notifier)
                                .setMyLanguage(picked.code);
                          }
                        },
                        child: Column(
                          children: [
                            const Text(
                              'You Hear & Speak',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${myLang.flagEmoji} ${myLang.nativeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomWidget: SwipeToAnswer(
        onAnswer: _acceptCall,
        onDecline: _declineCall,
        label: _answerWithTranslation ? 'Swipe to answer (AI)' : 'Swipe to answer',
      ),
    );
  }
}
