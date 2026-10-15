import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/services/webrtc_call_client.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/theme/theme.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  final ScrollController _transcriptScrollController = ScrollController();

  @override
  void dispose() {
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final callState = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    final session = callState.activeSession;

    ref.listen<int>(
      callControllerProvider.select((s) => s.transcripts.length),
      (prev, next) {
        if (next != prev) _scrollToBottom();
      },
    );

    final myLang = callState.myLanguage;
    final peerLang = callState.peerLanguage;
    final peerName = session?.peerName ?? 'AI Interpreter Call';
    final peerAvatar = session?.peerAvatar ?? '';
    final totalSec = callState.elapsedSeconds;
    final timerMins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final timerSecs = (totalSec % 60).toString().padLeft(2, '0');
    final formattedTime = totalSec >= 3600
        ? '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:$timerMins:$timerSecs'
        : '$timerMins:$timerSecs';

    final dynamicLanguageIndicator = callState.translationEnabled && myLang.code != peerLang.code
        ? '${myLang.nativeName} ⇄ ${peerLang.nativeName}'
        : (callState.translationEnabled ? '${myLang.nativeName} (Direct)' : 'Direct Voice');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await controller.endCall();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Call Status & Peer Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorTheme.appBarColor,
                      backgroundImage: peerAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(peerAvatar)
                          : const AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorTheme.greenColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$formattedTime • $dynamicLanguageIndicator',
                                style: TextStyle(
                                  color: colorTheme.greyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Gemini Live Engine Settings',
                      onPressed: () {
                        showGeminiLiveSettingsSheet(
                          context,
                          onSaved: controller.refreshSettings,
                        );
                      },
                      icon: Icon(
                        Icons.tune_rounded,
                        color: colorTheme.greenColor,
                      ),
                    ),
                  ],
                ),
              ),

              if (callState.webrtcState == WebRtcCallState.disconnected ||
                  callState.webrtcState == WebRtcCallState.failed)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          callState.webrtcState == WebRtcCallState.disconnected
                              ? 'Network connection lost. Reconnecting...'
                              : 'Call connection lost. Disconnecting in 10s...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          controller.retryWebRtc();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Gemini Live AI Status + Dynamic N x N Any-Language Switcher HUD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _borderColorForGeminiState(
                      callState.geminiState,
                      colorTheme.greenColor,
                    ),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _AnimatedVoicePulseDot(
                          state: callState.geminiState,
                          rmsLevel: callState.micRmsLevel,
                          activeColor: colorTheme.greenColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  callState.geminiState.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (callState.geminiState ==
                                  GeminiLiveState.error) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    controller.retryTranslation();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Retry',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: callState.translationEnabled,
                          activeColor: colorTheme.greenColor,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            controller.toggleTranslationEnabled(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Universal N x N Language Pair Selector Row (Change ANY language mid-call!)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showUniversalLanguagePicker(
                                context,
                                title: 'Select My Spoken/Listening Language',
                                selectedCode: myLang.code,
                              );
                              if (picked != null) {
                                await controller.setMyLanguage(picked.code);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111B21),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOU SPEAK & HEAR',
                                    style: TextStyle(
                                      color: colorTheme.greenColor,
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
                                      fontSize: 13.5,
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
                            borderRadius: BorderRadius.circular(20),
                            onTap: controller.swapLanguages,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorTheme.greenColor.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: colorTheme.greenColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showUniversalLanguagePicker(
                                context,
                                title: 'Select Peer Spoken/Listening Language',
                                selectedCode: peerLang.code,
                              );
                              if (picked != null) {
                                await controller.setPeerLanguage(picked.code);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111B21),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PEER SPEAKS & HEARS',
                                    style: TextStyle(
                                      color: Color(0xFF53BDEC),
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
                                      fontSize: 13.5,
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

              // 3. Live Bilingual Subtitle / Transcript Stream Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111B21),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: callState.transcripts.isEmpty
                      ? Center(
                          child: Text(
                            callState.translationEnabled
                                ? 'Speak in ${myLang.nativeName} or ${peerLang.nativeName} — live translated subtitles will appear here.'
                                : 'Direct voice call active (Zero AI latency). Turn on translation above for live bilingual subtitles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorTheme.greyColor,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _transcriptScrollController,
                          itemCount: callState.transcripts.length,
                          itemBuilder: (context, index) {
                            final item = callState.transcripts[index];
                            return _TranscriptBubbleCard(entry: item);
                          },
                        ),
                ),
              ),

              // 5. 3-Way Audio Ducking Mode Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2C34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: CallAudioMode.values.map((mode) {
                      final selected = callState.audioMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setAudioMode(mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorTheme.greenColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              mode.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? Colors.black : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 6. Bottom WhatsApp Call Controls Dock
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2C34),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallControlButton(
                      icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                      label: callState.isMuted ? 'Unmute' : 'Mute',
                      isActive: callState.isMuted,
                      activeColor: Colors.amber,
                      onTap: controller.toggleMute,
                    ),
                    _CallControlButton(
                      icon: callState.isSpeakerphoneOn
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: callState.isSpeakerphoneOn ? 'Speaker' : 'Earpiece',
                      isActive: callState.isSpeakerphoneOn,
                      activeColor: colorTheme.greenColor,
                      onTap: controller.toggleSpeakerphone,
                    ),
                    _CallControlButton(
                      icon: Icons.translate_rounded,
                      label: callState.translationEnabled ? 'Translate On' : 'Translate Off',
                      isActive: callState.translationEnabled,
                      activeColor: const Color(0xFF53BDEC),
                      onTap: () => controller.toggleTranslationEnabled(!callState.translationEnabled),
                    ),
                    InkWell(
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        await controller.endCall();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE53935),
                        child: Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
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

  Color _borderColorForGeminiState(GeminiLiveState state, Color green) {
    switch (state) {
      case GeminiLiveState.speaking:
        return const Color(0xFF53BDEC);
      case GeminiLiveState.translating:
        return Colors.amberAccent;
      case GeminiLiveState.listening:
      case GeminiLiveState.ready:
        return green.withOpacity(0.5);
      case GeminiLiveState.error:
        return Colors.redAccent;
      default:
        return Colors.white24;
    }
  }
}

class _AnimatedVoicePulseDot extends StatelessWidget {
  final GeminiLiveState state;
  final double rmsLevel;
  final Color activeColor;

  const _AnimatedVoicePulseDot({
    required this.state,
    required this.rmsLevel,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = 12.0 + (rmsLevel * 10.0);
    Color dotColor = activeColor;
    if (state == GeminiLiveState.speaking) {
      dotColor = const Color(0xFF53BDEC);
    } else if (state == GeminiLiveState.translating) {
      dotColor = Colors.amber;
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withOpacity(0.55),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranscriptBubbleCard extends StatelessWidget {
  final LiveTranscriptEntry entry;

  const _TranscriptBubbleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final src = entry.sourceLanguage;
    final tgt = entry.targetLanguage;
    final isSelf = entry.isSelf;

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        decoration: BoxDecoration(
          color: isSelf
              ? const Color(0xFF005C4B).withOpacity(0.85)
              : const Color(0xFF1F2C34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelf
                ? const Color(0xFF05A585).withOpacity(0.4)
                : const Color(0xFF53BDEC).withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    entry.speakerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${src.flagEmoji} ${src.codeUpper} ➔ ${tgt.flagEmoji} ${tgt.codeUpper}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              entry.originalText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(color: Colors.white24, height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFF53BDEC),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.translatedText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                isActive ? activeColor.withOpacity(0.25) : Colors.white10,
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : Colors.white70,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
