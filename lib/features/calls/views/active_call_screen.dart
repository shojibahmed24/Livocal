import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/views/widgets/call_ended_summary_sheet.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/navigator_key.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/services/webrtc_call_client.dart';
import 'package:livocal/features/calls/views/widgets/language_picker_sheet.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/color_theme.dart';
import 'package:livocal/theme/theme.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  final ScrollController _transcriptScrollController = ScrollController();
  bool _userScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _transcriptScrollController.addListener(_onTranscriptScroll);
  }

  void _onTranscriptScroll() {
    if (!_transcriptScrollController.hasClients) return;
    final maxScroll = _transcriptScrollController.position.maxScrollExtent;
    final currentScroll = _transcriptScrollController.position.pixels;
    final isScrolledUp = currentScroll < maxScroll - 50;
    if (isScrolledUp != _userScrolledUp) {
      setState(() {
        _userScrolledUp = isScrolledUp;
      });
    }
  }

  @override
  void dispose() {
    _transcriptScrollController.removeListener(_onTranscriptScroll);
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool force = false}) {
    if (_userScrolledUp && !force) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 250),
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

    ref.listen<CallSession?>(
      callControllerProvider.select((s) => s.activeSession),
      (prev, next) {
        if (next == null && mounted) {
          final error = ref.read(callControllerProvider).error;
          final lastEnded = ref.read(callControllerProvider).lastEndedCall;
          final ownUser = getCurrentUser();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          final targetCtx = appNavigatorKey.currentContext;
          if (targetCtx != null && lastEnded != null && ownUser != null) {
            final peerUser = User(
              id: lastEnded.peerId,
              name: lastEnded.peerName,
              avatarUrl: lastEnded.peerAvatar,
              phone: Phone(
                code: '+880',
                number: lastEnded.peerPhone,
                formattedNumber: lastEnded.peerPhone,
              ),
              activityStatus: UserActivityStatus.offline,
            );
            CallEndedSummarySheet.show(
              targetCtx,
              peerUser: peerUser,
              currentUser: ownUser,
              durationSeconds: lastEnded.durationSeconds,
              isMissed: lastEnded.isMissed,
              isTranslated: lastEnded.translationEnabled,
              isIncoming: lastEnded.isIncoming,
            );
          }
          if (error == 'MINUTES_EXHAUSTED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.tr(ref, 'minutesExhaustedAlert')),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              ),
            );
          } else if (error == 'CALL_CONNECTION_FAILED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.tr(ref, 'callAudioFailed')),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      },
    );

    final myLang = callState.myLanguage;
    final peerLang = callState.peerLanguage;
    final peerName =
        session?.peerName ?? AppStrings.tr(ref, 'aiInterpreterCall');
    final peerAvatar = session?.peerAvatar ?? '';
    final totalSec = callState.elapsedSeconds;
    final timerMins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final timerSecs = (totalSec % 60).toString().padLeft(2, '0');
    final formattedTime = totalSec >= 3600
        ? '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:$timerMins:$timerSecs'
        : '$timerMins:$timerSecs';

    final dynamicLanguageIndicator =
        callState.translationEnabled && myLang.code != peerLang.code
            ? '${myLang.nativeName} ⇄ ${peerLang.nativeName}'
            : (callState.translationEnabled
                ? '${myLang.nativeName} · ${AppStrings.tr(ref, 'directVoice')}'
                : AppStrings.tr(ref, 'directVoice'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldEnd = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppStrings.tr(ref, 'endCallTitle'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            content: Text(AppStrings.tr(ref, 'endCallBody'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppStrings.tr(ref, 'keepTalking'),
                    style: TextStyle(color: AppColors.primary)),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppStrings.tr(ref, 'endCall'),
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (shouldEnd == true) {
          await controller.endCall();
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Call Status & Peer Header
              Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorTheme.appBarColor,
                      backgroundImage: peerAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(peerAvatar)
                          : AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: callState.networkQuality ==
                                          CallNetworkQuality.poor
                                      ? Colors.redAccent
                                      : (callState.networkQuality ==
                                              CallNetworkQuality.fair
                                          ? Colors.amber
                                          : colorTheme.greenColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '$formattedTime • $dynamicLanguageIndicator',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorTheme.greyColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (callState.networkQuality !=
                                  CallNetworkQuality.good) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: callState.networkQuality ==
                                            CallNetworkQuality.poor
                                        ? Colors.red.shade900
                                            .withValues(alpha: 0.85)
                                        : Colors.amber.shade900
                                            .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        callState.networkQuality.emoji,
                                        style: TextStyle(fontSize: 8.5),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        callState.networkQuality.label,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (callState.isLowDataMode &&
                                  callState.networkQuality ==
                                      CallNetworkQuality.good) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade900
                                        .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          size: 10),
                                      SizedBox(width: 2),
                                      Text(
                                        AppStrings.tr(ref, 'lowDataChip'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.tr(ref, 'geminiSettings'),
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
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          callState.webrtcState == WebRtcCallState.disconnected
                              ? AppStrings.tr(ref, 'reconnectingNetwork')
                              : AppStrings.tr(ref, 'connectionLost'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          controller.retryWebRtc();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(width: 4),
                              Text(
                                AppStrings.tr(ref, 'retry'),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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

              if (callState.webrtcState == WebRtcCallState.connected &&
                  callState.networkQuality == CallNetworkQuality.poor)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr(ref, 'unstableLowData'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Translation Minutes Exhausted Banner with Recharge CTA
              if (callState.isTranslationExhausted)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amberAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amberAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr(ref, 'minutesExhaustedTitle'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              (session?.isIncoming ?? false)
                                  ? AppStrings.tr(ref,
                                      'callerMinutesExhaustedDirectVoiceDesc')
                                  : AppStrings.tr(
                                      ref, 'callContinuingDirectVoiceDesc'),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!(session?.isIncoming ?? false)) ...[
                        SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final currentUser = getCurrentUser();
                            if (currentUser != null) {
                              showMinuteRechargeSheet(
                                context,
                                user: currentUser,
                                onRecharged: () {
                                  controller.resumeTranslationAfterRecharge();
                                },
                              );
                            }
                          },
                          child: Text(
                            AppStrings.tr(ref, 'rechargeNowBtn'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // 2. Gemini Live AI Status + Dynamic N x N Any-Language Switcher HUD
              Container(
                margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
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
                        SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  callState.geminiState.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (callState.geminiState ==
                                  GeminiLiveState.error) ...[
                                SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    controller.retryTranslation();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          AppStrings.tr(ref, 'retry'),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
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
                        Switch(
                          value: callState.translationEnabled,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor:
                              Theme.of(context).colorScheme.onSurface,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            controller.toggleTranslationEnabled(val);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Universal N x N Language Pair Selector Row (Change ANY language mid-call!)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showUniversalLanguagePicker(
                                context,
                                title:
                                    AppStrings.tr(ref, 'selectMyLanguageTitle'),
                                selectedCode: myLang.code,
                              );
                              if (picked != null) {
                                final synced =
                                    await controller.setMyLanguage(picked.code);
                                if (!synced && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Language applied locally (cloud sync offline).'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.tr(ref, 'youSpeakHear'),
                                    style: TextStyle(
                                      color: colorTheme.greenColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${myLang.flagEmoji} ${myLang.nativeName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: controller.swapLanguages,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorTheme.greenColor
                                    .withValues(alpha: 0.18),
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
                                title: AppStrings.tr(ref, 'selectPeerLanguage'),
                                selectedCode: peerLang.code,
                              );
                              if (picked != null) {
                                await controller.setPeerLanguage(picked.code);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.tr(ref, 'peerSpeaksHears'),
                                    style: TextStyle(
                                      color: Color(0xFF53BDEC),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${peerLang.flagEmoji} ${peerLang.nativeName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                    ),
                  ),
                  child: callState.transcripts.isEmpty
                      ? Center(
                          child: Text(
                            callState.translationEnabled
                                ? AppStrings.tr(
                                    ref,
                                    'callSubtitleTranslated',
                                    args: {
                                      'my': myLang.nativeName,
                                      'peer': peerLang.nativeName,
                                    },
                                  )
                                : AppStrings.tr(ref, 'callSubtitleDirect'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorTheme.greyColor,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _transcriptScrollController,
                              itemCount: callState.transcripts.length,
                              itemBuilder: (context, index) {
                                final item = callState.transcripts[index];
                                return _TranscriptBubbleCard(entry: item);
                              },
                            ),
                            if (_userScrolledUp)
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _userScrolledUp = false);
                                    _scrollToBottom(force: true);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_downward,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            size: 13),
                                        SizedBox(width: 4),
                                        Text(
                                          AppStrings.tr(ref, 'latest'),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              // 5. 3-Way Audio Ducking Mode Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: CallAudioMode.values.map((mode) {
                      final selected = callState.audioMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setAudioMode(mode),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 7),
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
                                color: selected
                                    ? Colors.black
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                margin: EdgeInsets.only(top: 6),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallControlButton(
                      icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                      label: AppStrings.tr(
                        ref,
                        callState.isMuted ? 'unmuteBtn' : 'muteBtn',
                      ),
                      isActive: callState.isMuted,
                      activeColor: Colors.amber,
                      onTap: controller.toggleMute,
                    ),
                    _CallControlButton(
                      icon: callState.isSpeakerphoneOn
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: AppStrings.tr(
                        ref,
                        callState.isSpeakerphoneOn
                            ? 'speakerBtn'
                            : 'earpieceBtn',
                      ),
                      isActive: callState.isSpeakerphoneOn,
                      activeColor: colorTheme.greenColor,
                      onTap: controller.toggleSpeakerphone,
                    ),
                    _CallControlButton(
                      icon: Icons.translate_rounded,
                      label: AppStrings.tr(
                        ref,
                        callState.translationEnabled
                            ? 'translateOnBtn'
                            : 'translateOffBtn',
                      ),
                      isActive: callState.translationEnabled,
                      activeColor: Color(0xFF53BDEC),
                      onTap: () => controller.toggleTranslationEnabled(
                          !callState.translationEnabled),
                    ),
                    Semantics(
                      button: true,
                      label: AppStrings.tr(ref, 'endCallBtn'),
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          await controller.endCall();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(32),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFE53935),
                          child: Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
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
        return Color(0xFF53BDEC);
      case GeminiLiveState.translating:
        return Colors.amberAccent;
      case GeminiLiveState.listening:
      case GeminiLiveState.ready:
        return green.withValues(alpha: 0.5);
      case GeminiLiveState.error:
        return Colors.redAccent;
      default:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }
}

class _AnimatedVoicePulseDot extends StatelessWidget {
  final GeminiLiveState state;
  final double rmsLevel;
  final Color activeColor;

  _AnimatedVoicePulseDot({
    required this.state,
    required this.rmsLevel,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = 12.0 + (rmsLevel * 10.0);
    Color dotColor = activeColor;
    if (state == GeminiLiveState.speaking) {
      dotColor = Color(0xFF53BDEC);
    } else if (state == GeminiLiveState.translating) {
      dotColor = Colors.amber;
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.55),
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

  _TranscriptBubbleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final src = entry.sourceLanguage;
    final tgt = entry.targetLanguage;
    final isSelf = entry.isSelf;

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        decoration: BoxDecoration(
          color: isSelf
              ? Color(0xFF3F4ED8).withValues(alpha: 0.85)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelf
                ? AppColors.primary.withValues(alpha: 0.4)
                : Color(0xFF53BDEC).withValues(alpha: 0.35),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${src.flagEmoji} ${src.codeUpper} ➔ ${tgt.flagEmoji} ${tgt.codeUpper}',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              entry.originalText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFF53BDEC),
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.translatedText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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

  _CallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Screen readers get one clear toggle target instead of an unlabeled icon
    // followed by a duplicate text node.
    return Semantics(
      button: true,
      toggled: isActive,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
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
                backgroundColor: isActive
                    ? activeColor.withValues(alpha: 0.25)
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Icon(
                  icon,
                  color: isActive
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
