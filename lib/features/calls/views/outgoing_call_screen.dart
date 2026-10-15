import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/shared/models/user.dart';

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
  Timer? _ringbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ringbackTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      HapticFeedback.lightImpact();
    });

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
    _ringbackTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_navigated) return;
    _navigated = true;
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A221E),
              Color(0xFF0B141A),
              Color(0xFF070D11),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Encryption & Gemini Live Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'DTLS-SRTP Encrypted • Gemini Live 3.5 AI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.calleeDisplayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: const TextStyle(
                  color: Color(0xFF00E5B0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Pulsing Concentric Avatar Rings
              SizedBox(
                width: 240,
                height: 240,
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Builder(
                            builder: (context) {
                              final progress =
                                  (_ringController.value + (i * 0.33)) % 1.0;
                              final size = 120.0 + (progress * 115.0);
                              final opacity = (1.0 - progress) * 0.35;
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00A884)
                                        .withOpacity(opacity),
                                    width: 2.0,
                                  ),
                                  color: const Color(0xFF00A884)
                                      .withOpacity(opacity * 0.25),
                                ),
                              );
                            },
                          ),
                        child!,
                      ],
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF1F2C34),
                    backgroundImage: widget.callee.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.callee.avatarUrl)
                        : null,
                    child: widget.callee.avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
              ),
              const Spacer(),
              // Universal Language Pair Selector Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18252D).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF00A884).withOpacity(0.45),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            color: Color(0xFF00E5B0),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE VOICE TRANSLATION PAIR (N × N)',
                            style: TextStyle(
                              color: Color(0xFF00E5B0),
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
                                final picked =
                                    await showUniversalLanguagePicker(
                                  context,
                                  title: 'Select Your Language',
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
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'You Speak & Hear',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(callControllerProvider.notifier)
                                  .swapLanguages();
                            },
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Color(0xFF00E5B0),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final picked =
                                    await showUniversalLanguagePicker(
                                  context,
                                  title: 'Select Peer Language',
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
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Peer Speaks & Hears',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
              const SizedBox(height: 20),
              // Bottom Call Control Bar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      onTap: () => ref
                          .read(callControllerProvider.notifier)
                          .toggleSpeakerphone(),
                    ),
                    _DialControlButton(
                      icon: callState.isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: 'Mute',
                      isActive: callState.isMuted,
                      onTap: () => ref
                          .read(callControllerProvider.notifier)
                          .toggleMute(),
                    ),
                    GestureDetector(
                      onTap: _endCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'End',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
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
              color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
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
