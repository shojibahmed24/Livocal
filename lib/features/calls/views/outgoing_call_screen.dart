import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/call_scaffold.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/theme/app_colors.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  final User caller;
  final User callee;
  final String calleeDisplayName;
  final String? overrideMyLangCode;
  final String? overridePeerLangCode;

  const OutgoingCallScreen({
    super.key,
    required this.caller,
    required this.callee,
    required this.calleeDisplayName,
    this.overrideMyLangCode,
    this.overridePeerLangCode,
  });

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    // Note: Timer haptic spam removed; ringback tone & network state handle feedback.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final session = await ref.read(callControllerProvider.notifier).startOutgoingCall(
            caller: widget.caller,
            callee: widget.callee,
            calleeDisplayName: widget.calleeDisplayName,
            overrideMyLangCode: widget.overrideMyLangCode,
            overridePeerLangCode: widget.overridePeerLangCode,
          );
      if (session == null && mounted) {
        _navigated = true;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate call. Please check your network connection.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_navigated) return;
    _navigated = true;
    HapticFeedback.heavyImpact();
    await ref.read(callControllerProvider.notifier).endCall(
          recordAsMissed: false,
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ActiveCallScreen(),
          ),
        );
      } else if (session == null &&
          previous?.activeSession != null &&
          previous?.activeSession?.status != CallStateStatus.connected) {
        _navigated = true;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    final callState = ref.watch(callControllerProvider);
    final session = callState.activeSession;
    final myLang = session?.myLanguage ?? callState.myLanguage;
    final peerLang = session?.peerLanguage ?? callState.peerLanguage;
    final status = session?.status ?? CallStateStatus.dialing;

    String statusText;
    switch (status) {
      case CallStateStatus.dialing:
        statusText = 'Calling...';
        break;
      case CallStateStatus.ringing:
        statusText = 'Ringing...';
        break;
      case CallStateStatus.connectingAi:
      case CallStateStatus.connected:
        statusText = 'Connecting AI Interpreter...';
        break;
      case CallStateStatus.rejected:
        statusText = 'Call Declined';
        break;
      case CallStateStatus.busy:
        statusText = 'User Busy';
        break;
      case CallStateStatus.missed:
        statusText = 'No Answer';
        break;
      default:
        statusText = 'Calling...';
    }

    return CallScaffold(
      peerName: widget.calleeDisplayName,
      peerAvatar: widget.callee.avatarUrl,
      peerPhone: widget.callee.phoneNumber,
      statusText: statusText,
      badgeText: 'DTLS-SRTP Encrypted • Gemini Live 3.5 AI',
      badgeIcon: Icons.lock_outline_rounded,
      pulseAnimation: _ringController,
      middleWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF18252D).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LIVE VOICE TRANSLATION PAIR (N × N)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F191F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOU SPEAK',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${myLang.flagEmoji} ${myLang.nativeName}',
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(callControllerProvider.notifier).swapLanguages();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showUniversalLanguagePicker(
                          context,
                          title: 'Peer Language',
                          selectedCode: peerLang.code,
                        );
                        if (picked != null && mounted) {
                          await ref
                              .read(callControllerProvider.notifier)
                              .setPeerLanguage(picked.code);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F191F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PEER HEARS',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomWidget: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF18252D),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DialControlButton(
              icon: callState.isSpeakerphoneOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              label: 'Speaker',
              isActive: callState.isSpeakerphoneOn,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(callControllerProvider.notifier).toggleSpeakerphone();
              },
            ),
            _DialControlButton(
              icon: callState.isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              label: 'Mute',
              isActive: callState.isMuted,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(callControllerProvider.notifier).toggleMute();
              },
            ),
            GestureDetector(
              onTap: _endCall,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE53935),
                    child: Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'End',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DialControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0B141A) : Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
