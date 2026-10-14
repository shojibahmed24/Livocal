import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/features/calls/services/call_kit_service.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _vibrateTimer;
  bool _answerWithTranslation = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_navigated) return;
    _navigated = true;
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
        CallKitService().endAllCalls();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
        );
      } else if (session == null ||
          session.status == CallStateStatus.ended ||
          session.status == CallStateStatus.rejected ||
          session.status == CallStateStatus.missed) {
        _navigated = true;
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C2A24),
              Color(0xFF0B141A),
              Color(0xFF070D11),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00A884).withOpacity(0.45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF00E5B0),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Livocal AI Translated Voice Call',
                      style: TextStyle(
                        color: Color(0xFF00E5B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (callerPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  callerPhone,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Incoming Voice Call...',
                style: TextStyle(
                  color: Color(0xFF00E5B0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Animated Caller Avatar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.14);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale * 1.18,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00A884).withOpacity(0.12),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00E5B0).withOpacity(0.5),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: const Color(0xFF1F2C34),
                  backgroundImage: callerAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(callerAvatar)
                      : null,
                  child: callerAvatar.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 54,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
              const Spacer(),
              // Language Pair Preview & Switcher Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18252D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF00A884).withOpacity(0.45),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            color: Color(0xFF00E5B0),
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
                            activeColor: const Color(0xFF00E5B0),
                            onChanged: (val) {
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
                                  final picked =
                                      await showUniversalLanguagePicker(
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
                              color: Color(0xFF00E5B0),
                              size: 18,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked =
                                      await showUniversalLanguagePicker(
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
                                        color: Color(0xFF00E5B0),
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
              const SizedBox(height: 32),
              // Accept / Decline Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(42, 0, 42, 34),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline
                    GestureDetector(
                      onTap: _declineCall,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66E53935),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Accept
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A884),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x6600A884),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _answerWithTranslation ? 'Accept (AI)' : 'Accept',
                            style: const TextStyle(
                              color: Color(0xFF00E5B0),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
