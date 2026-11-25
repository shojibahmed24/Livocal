import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/call_ended_summary_sheet.dart';
import 'package:livocal/features/calls/views/widgets/call_scaffold.dart';
import 'package:livocal/features/calls/views/widgets/insufficient_minutes_sheet.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/navigator_key.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  final User caller;
  final User callee;
  final String calleeDisplayName;
  final String? overrideMyLangCode;
  final String? overridePeerLangCode;
  final bool? initialTranslationEnabled;

  const OutgoingCallScreen({
    super.key,
    required this.caller,
    required this.callee,
    required this.calleeDisplayName,
    this.overrideMyLangCode,
    this.overridePeerLangCode,
    this.initialTranslationEnabled,
  });

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final PeerTranslationSettings _resolvedSettings;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _resolvedSettings = CallRepository.getPeerTranslationSettings(
      peerId: widget.callee.id,
      peerName: widget.calleeDisplayName,
      peerPhone: widget.callee.phone.number,
      explicitMyLang: widget.overrideMyLangCode,
      explicitPeerLang: widget.overridePeerLangCode,
      explicitTranslationEnabled: widget.initialTranslationEnabled,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Explain why the mic is needed before the OS dialog appears — this is
      // the first trust-sensitive permission a caller meets.
      final micReady = await _ensureMicPermission();
      if (!micReady || !mounted) return;

      final session =
          await ref.read(callControllerProvider.notifier).startOutgoingCall(
                caller: widget.caller,
                callee: widget.callee,
                calleeDisplayName: widget.calleeDisplayName,
                overrideMyLangCode: _resolvedSettings.myLangCode,
                overridePeerLangCode: _resolvedSettings.peerLangCode,
                translationEnabled: _resolvedSettings.isTranslationEnabled,
              );
      if (session == null && mounted) {
        _navigated = true;
        final callState = ref.read(callControllerProvider);
        if (callState.error == 'CONTACT_NOT_ON_LIVOCAL') {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          showSnackBar(
            context: context,
            content: AppStrings.tr(ref, 'contactNotOnLivocal'),
            type: SnacBarType.error,
          );
          return;
        }
        if (callState.error == 'INSUFFICIENT_MINUTES') {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          InsufficientMinutesSheet.show(
            context,
            onRechargePressed: () {
              showMinuteRechargeSheet(context, user: widget.caller);
            },
            onCallWithoutTranslation: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OutgoingCallScreen(
                    caller: widget.caller,
                    callee: widget.callee,
                    calleeDisplayName: widget.calleeDisplayName,
                    overrideMyLangCode: widget.overrideMyLangCode,
                    overridePeerLangCode: widget.overridePeerLangCode,
                    initialTranslationEnabled: false,
                  ),
                ),
              );
            },
          );
        } else {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          _showFailureSheet();
        }
      }
    });
  }

  void _showFailureSheet() {
    final targetCtx = appNavigatorKey.currentContext;
    if (targetCtx == null) return;
    final isDark = Theme.of(targetCtx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: targetCtx,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.call_missed_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 8),
            const Text(
              'Call failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Try again'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(targetCtx).push(
                  MaterialPageRoute(
                    builder: (_) => OutgoingCallScreen(
                      caller: widget.caller,
                      callee: widget.callee,
                      calleeDisplayName: widget.calleeDisplayName,
                      overrideMyLangCode: widget.overrideMyLangCode,
                      overridePeerLangCode: widget.overridePeerLangCode,
                      initialTranslationEnabled:
                          widget.initialTranslationEnabled,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(
                AppStrings.get(
                  'sendMessage',
                  Localizations.localeOf(targetCtx).languageCode,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(targetCtx).push(
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      self: widget.caller,
                      other: widget.callee,
                      otherUserContactName: widget.calleeDisplayName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  /// Asks for the microphone with an explanation first. Returns false when the
  /// caller declines, in which case the call is abandoned instead of connecting
  /// with no audio.
  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (!mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr(ref, 'micPermissionTitle')),
        content: Text(AppStrings.tr(ref, 'micPermissionBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.tr(ref, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.tr(ref, 'allow')),
          ),
        ],
      ),
    );
    if (proceed != true) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return false;
    }

    final result = await Permission.microphone.request();
    if (!result.isGranted) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return false;
    }
    return true;
  }

  Future<void> _endCall() async {
    if (_navigated) return;
    _navigated = true;
    HapticFeedback.heavyImpact();
    final duration = ref.read(callControllerProvider).elapsedSeconds;
    await ref.read(callControllerProvider.notifier).endCall(
          recordAsMissed: false,
        );
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      final targetCtx = appNavigatorKey.currentContext;
      if (targetCtx != null) {
        CallEndedSummarySheet.show(
          targetCtx,
          peerUser: widget.callee,
          currentUser: widget.caller,
          durationSeconds: duration,
          isMissed: duration == 0,
          isTranslated: widget.initialTranslationEnabled ?? false,
        );
      }
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
          MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
        );
      } else if (session == null &&
          previous?.activeSession != null &&
          previous?.activeSession?.status != CallStateStatus.connected) {
        _navigated = true;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          final targetCtx = appNavigatorKey.currentContext;
          if (targetCtx != null) {
            CallEndedSummarySheet.show(
              targetCtx,
              peerUser: widget.callee,
              currentUser: widget.caller,
              durationSeconds: 0,
              isMissed: true,
              isTranslated: widget.initialTranslationEnabled ?? false,
            );
          }
        }
      }
    });

    final callState = ref.watch(callControllerProvider);
    final session = callState.activeSession;
    final myLang = session?.myLanguage ??
        (callState.activeSession != null
            ? callState.myLanguage
            : CallLanguageRegistry.fromCode(_resolvedSettings.myLangCode));
    final peerLang = session?.peerLanguage ??
        (callState.activeSession != null
            ? callState.peerLanguage
            : CallLanguageRegistry.fromCode(_resolvedSettings.peerLangCode));
    final status = session?.status ?? CallStateStatus.dialing;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusText = switch (status) {
      CallStateStatus.dialing => 'Calling...',
      CallStateStatus.ringing => 'Ringing...',
      CallStateStatus.connectingAi ||
      CallStateStatus.connected =>
        'Connecting AI interpreter...',
      CallStateStatus.rejected => 'Call declined',
      CallStateStatus.busy => 'User busy',
      CallStateStatus.missed => 'No answer',
      _ => 'Calling...',
    };

    final effectiveTrans = session != null
        ? session.translationEnabled
        : _resolvedSettings.isEffectivelyTranslated;
    final isTranslatedCall = effectiveTrans &&
        (myLang.code.toLowerCase().trim() !=
            peerLang.code.toLowerCase().trim());
    final isDialing = status == CallStateStatus.dialing ||
        status == CallStateStatus.ringing ||
        status == CallStateStatus.connectingAi;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        debugPrint('[OutgoingCallScreen] Back pressed. Ending call cleanly.');
        await _endCall();
      },
      child: CallScaffold(
        peerName: widget.calleeDisplayName,
        peerAvatar: widget.callee.avatarUrl,
        peerPhone: widget.callee.phone.getFormattedNumber(),
        statusText: statusText,
        badgeText: isTranslatedCall
            ? 'AI translated call • Gemini Live'
            : 'Free direct call • DTLS-SRTP',
        badgeIcon: isTranslatedCall
            ? Icons.auto_awesome_rounded
            : Icons.lock_outline_rounded,
        pulseAnimation: _ringController,
        subStatus: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _Chip(
              icon: Icons.translate_rounded,
              label:
                  isTranslatedCall ? 'AI translation ON' : 'Free direct call',
              color: isTranslatedCall ? AppColors.accent : AppColors.success,
              isDark: isDark,
            ),
            ref.watch(walletStreamProvider(widget.caller.id)).when(
                  data: (wallet) => _Chip(
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
        bottomWidget: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainer : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.radiusXl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DialControlButton(
                icon: callState.isSpeakerphoneOn
                    ? Icons.volume_up_rounded
                    : Icons.hearing_rounded,
                label: AppStrings.tr(ref, 'speakerBtn'),
                isActive: callState.isSpeakerphoneOn,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(callControllerProvider.notifier)
                      .toggleSpeakerphone();
                },
              ),
              _DialControlButton(
                icon: callState.isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: AppStrings.tr(ref, 'muteBtn'),
                isActive: callState.isMuted,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(callControllerProvider.notifier).toggleMute();
                },
              ),
              _DialControlButton(
                icon: Icons.call_end_rounded,
                label: isDialing
                    ? AppStrings.tr(ref, 'cancel')
                    : AppStrings.tr(ref, 'endCallBtn'),
                isActive: false,
                isDark: isDark,
                danger: true,
                onTap: _endCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final bool danger;
  final VoidCallback onTap;

  const _DialControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : (isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.lightSurfaceContainer);
    final fg = danger || isActive
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    return Semantics(
      button: true,
      label: label,
      toggled: isActive,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: danger
                      ? [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: fg, size: 24),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
