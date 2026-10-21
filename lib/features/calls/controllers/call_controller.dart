import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/features/chat/models/call_log_helper.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/abc.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:livocal/shared/utils/navigator_key.dart';
import 'package:livocal/features/calls/views/active_call_screen.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/services/call_audio_pipeline.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:livocal/features/calls/services/call_kit_service.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/features/calls/services/webrtc_call_client.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

final callControllerProvider =
    StateNotifierProvider<CallController, CallControllerState>((ref) {
  final repo = ref.read(callRepositoryProvider);
  return CallController(repo: repo, ref: ref);
});

class CallControllerState {
  final CallSession? activeSession;
  final String myLangCode;
  final String peerLangCode;
  final bool translationEnabled;
  final CallAudioMode audioMode;
  final GeminiLiveState geminiState;
  final bool isMuted;
  final bool isSpeakerphoneOn;
  final bool isBidirectionalSingleDevice;
  final int elapsedSeconds;
  final double micRmsLevel;
  final List<LiveTranscriptEntry> transcripts;
  final List<CallHistoryRecord> callHistory;
  final bool hasApiKey;
  final WebRtcCallState webrtcState;
  final CallNetworkQuality networkQuality;
  final bool isLowDataModeAutoEnabled;
  final bool isTranslationExhausted;
  final String? error;
  final CallHistoryRecord? lastEndedCall;

  const CallControllerState({
    this.activeSession,
    required this.myLangCode,
    required this.peerLangCode,
    this.translationEnabled = true,
    this.audioMode = CallAudioMode.translatedOnly,
    this.geminiState = GeminiLiveState.ready,
    this.isMuted = false,
    this.isSpeakerphoneOn = true,
    this.isBidirectionalSingleDevice = true,
    this.elapsedSeconds = 0,
    this.micRmsLevel = 0.0,
    this.transcripts = const [],
    this.callHistory = const [],
    this.hasApiKey = false,
    this.webrtcState = WebRtcCallState.idle,
    this.networkQuality = CallNetworkQuality.good,
    this.isLowDataModeAutoEnabled = false,
    this.isTranslationExhausted = false,
    this.error,
    this.lastEndedCall,
  });

  CallLanguage get myLanguage => CallLanguageRegistry.fromCode(myLangCode);
  CallLanguage get peerLanguage => CallLanguageRegistry.fromCode(peerLangCode);

  bool get isLowDataMode =>
      isLowDataModeAutoEnabled ||
      (SharedPref.instance.getBool('storage_less_data_calls') ?? false);

  CallControllerState copyWith({
    CallSession? activeSession,
    bool clearSession = false,
    String? myLangCode,
    String? peerLangCode,
    bool? translationEnabled,
    CallAudioMode? audioMode,
    GeminiLiveState? geminiState,
    bool? isMuted,
    bool? isSpeakerphoneOn,
    bool? isBidirectionalSingleDevice,
    int? elapsedSeconds,
    double? micRmsLevel,
    List<LiveTranscriptEntry>? transcripts,
    List<CallHistoryRecord>? callHistory,
    bool? hasApiKey,
    WebRtcCallState? webrtcState,
    CallNetworkQuality? networkQuality,
    bool? isLowDataModeAutoEnabled,
    bool? isTranslationExhausted,
    String? error,
    bool clearError = false,
    CallHistoryRecord? lastEndedCall,
    bool clearLastEndedCall = false,
  }) {
    return CallControllerState(
      activeSession:
          clearSession ? null : (activeSession ?? this.activeSession),
      myLangCode: myLangCode ?? this.myLangCode,
      peerLangCode: peerLangCode ?? this.peerLangCode,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      audioMode: audioMode ?? this.audioMode,
      geminiState: geminiState ?? this.geminiState,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerphoneOn: isSpeakerphoneOn ?? this.isSpeakerphoneOn,
      isBidirectionalSingleDevice:
          isBidirectionalSingleDevice ?? this.isBidirectionalSingleDevice,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      micRmsLevel: micRmsLevel ?? this.micRmsLevel,
      transcripts: transcripts ?? this.transcripts,
      callHistory: callHistory ?? this.callHistory,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      webrtcState: webrtcState ?? this.webrtcState,
      networkQuality: networkQuality ?? this.networkQuality,
      isLowDataModeAutoEnabled:
          isLowDataModeAutoEnabled ?? this.isLowDataModeAutoEnabled,
      isTranslationExhausted:
          isTranslationExhausted ?? this.isTranslationExhausted,
      error: clearError ? null : (error ?? this.error),
      lastEndedCall: clearLastEndedCall ? null : (lastEndedCall ?? this.lastEndedCall),
    );
  }
}

class CallController extends StateNotifier<CallControllerState> {
  final CallRepository repo;
  final Ref? ref;
  final WalletRepository? walletRepo;
  final CallAudioPipeline _audioPipeline = CallAudioPipeline();
  final GeminiLiveTranslator _geminiTranslator = GeminiLiveTranslator();
  final WebRtcCallClient _webrtcClient = WebRtcCallClient();

  Timer? _callDurationTimer;
  Timer? _callTimeoutTimer;
  Timer? _networkDropTimer;
  bool _isEndingCall = false;
  StreamSubscription<Uint8List>? _micStreamSub;
  StreamSubscription<double>? _micRmsSub;
  StreamSubscription<Uint8List>? _geminiAudioSub;
  StreamSubscription<GeminiLiveState>? _geminiStateSub;
  StreamSubscription<LiveTranscriptEntry>? _geminiTranscriptSub;
  StreamSubscription<bool>? _geminiInterruptedSub;
  StreamSubscription<BillingUpdateEvent>? _geminiBillingSub;
  StreamSubscription<CallSession?>? _firestoreCallSub;
  StreamSubscription<Uint8List>? _webrtcRemoteTranslatedAudioSub;
  StreamSubscription<WebRtcCallState>? _webrtcStateSub;
  StreamSubscription<CallNetworkQuality>? _webrtcQualitySub;
  bool _isAudioEngineRunning = false;
  String? _currentRunningCallId;
  bool _hasNavigatedToActiveCall = false;

  void navigateToActiveCall() {
    if (_hasNavigatedToActiveCall) return;
    _hasNavigatedToActiveCall = true;
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
      );
    }
  }

  String get _currentAppLang {
    try {
      if (ref != null) {
        return ref!.read(appLocaleProvider).languageCode;
      }
    } catch (_) {}
    return 'en';
  }

  CallController({required this.repo, this.ref, this.walletRepo})
      : super(
          CallControllerState(
            myLangCode: CallRepository.getMyLanguageCode(),
            peerLangCode: CallRepository.getPeerLanguageCode(),
            callHistory: repo.getCallHistory(),
            hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
          ),
        ) {
    try {
      CallKitService().init(
        onAccept: (callId) async {
          debugPrint('[CallController] CallKit onAccept for $callId');
          await acceptAndConnectCall(callId: callId);
          navigateToActiveCall();
        },
        onDecline: (callId) {
          CallKitService().endCall(callId);
          debugPrint('[CallController] CallKit onDecline for $callId');
          if (state.activeSession?.callId == callId &&
              state.activeSession?.status == CallStateStatus.ringing) {
            endCall(endStatus: CallStateStatus.rejected, isDeclined: true);
          }
        },
        onTimeout: (callId) {
          CallKitService().endCall(callId);
          debugPrint('[CallController] CallKit onTimeout for $callId');
          if (state.activeSession?.callId == callId &&
              state.activeSession?.status == CallStateStatus.ringing) {
            endCall(endStatus: CallStateStatus.missed, recordAsMissed: true);
          }
        },
        onEnded: (callId) {
          debugPrint('[CallController] CallKit onEnded for $callId (programmatic cleanup)');
          // CallKit on Android emits actionCallEnded when endCall() is invoked
          // programmatically or when an incoming call notification is dismissed after answer.
          // Do NOT terminate active or dialing call sessions here to avoid false hangups.
        },
        onCallback: (callId, body) {
          debugPrint('[CallController] CallKit onCallback (Call back) for $callId');
          CallKitService().endCall(callId);
        },
      );
      FlutterCallkitIncoming.activeCalls().then((calls) {
        if (calls is List && calls.isNotEmpty) {
          final activeCall = calls.first;
          final callId = activeCall['id'] as String?;
          final isAccepted = activeCall['isAccepted'] == true;
          // Guard: Only connect if user explicitly tapped the native green Accept button on CallKit notification
          if (isAccepted && callId != null && callId.isNotEmpty) {
            debugPrint('[CallController] Resuming accepted CallKit call $callId on app launch');
            acceptAndConnectCall(callId: callId).then((_) {
              navigateToActiveCall();
            });
          } else {
            debugPrint('[CallController] Stale or ringing CallKit call $callId (isAccepted: $isAccepted), suppressing ghost auto-answer');
          }
        }
      }).catchError((err, st) {
        debugPrint('[CallController] FlutterCallkitIncoming.activeCalls error: $err\n$st');
      });
    } catch (e) {
      debugPrint('[CallController] CallKit init suppressed in test/headless environment: $e');
    }
  }

  CallLanguage get myLang => state.myLanguage;
  CallLanguage get peerLang => state.peerLanguage;

  void refreshSettings() {
    state = state.copyWith(
      myLangCode: CallRepository.getMyLanguageCode(),
      peerLangCode: CallRepository.getPeerLanguageCode(),
      callHistory: repo.getCallHistory(),
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );
  }

  Future<void> setMyLanguage(String langCode) async {
    await CallRepository.setMyLanguageCode(langCode);
    state = state.copyWith(myLangCode: langCode);
    if (state.activeSession != null &&
        state.activeSession!.status == CallStateStatus.connected) {
      await _applyLanguagePairUpdate(
        newMyLang: langCode,
        newPeerLang: state.peerLangCode,
      );
    }
  }

  Future<void> setPeerLanguage(String langCode) async {
    await CallRepository.setPeerLanguageCode(langCode);
    CallSession? updatedSession;
    if (state.activeSession != null) {
      final isSame = state.myLangCode.toLowerCase().trim() == langCode.toLowerCase().trim();
      updatedSession = state.activeSession!.copyWith(
        calleeLangCode: langCode,
        translationEnabled: isSame ? false : state.activeSession!.translationEnabled,
      );
    }
    state = state.copyWith(
      peerLangCode: langCode,
      activeSession: updatedSession ?? state.activeSession,
    );
    if (state.activeSession != null &&
        state.activeSession!.status == CallStateStatus.connected) {
      await _applyLanguagePairUpdate(
        newMyLang: state.myLangCode,
        newPeerLang: langCode,
      );
    }
  }

  Future<void> swapLanguages() async {
    final oldMy = state.myLangCode;
    final oldPeer = state.peerLangCode;
    await CallRepository.setMyLanguageCode(oldPeer);
    await CallRepository.setPeerLanguageCode(oldMy);
    CallSession? updatedSession;
    if (state.activeSession != null) {
      updatedSession = state.activeSession!.copyWith(
        callerLangCode: oldPeer,
        calleeLangCode: oldMy,
      );
    }
    state = state.copyWith(
      myLangCode: oldPeer,
      peerLangCode: oldMy,
      activeSession: updatedSession ?? state.activeSession,
    );
    if (state.activeSession != null &&
        state.activeSession!.status == CallStateStatus.connected) {
      await _applyLanguagePairUpdate(newMyLang: oldPeer, newPeerLang: oldMy);
    }
  }

  Future<void> _applyLanguagePairUpdate({
    required String newMyLang,
    required String newPeerLang,
  }) async {
    final langA = CallLanguageRegistry.fromCode(newMyLang);
    final langB = CallLanguageRegistry.fromCode(newPeerLang);

    // Add system caption notifying the mid-call language pair switch
    final switchEntry = LiveTranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      speakerId: 'system',
      speakerName: 'Gemini Live Interpreter',
      isSelf: true,
      sourceLangCode: langA.code,
      targetLangCode: langB.code,
      originalText:
          'Switched live translation pair to: ${langA.shortBadge} ⇄ ${langB.shortBadge}',
      translatedText: AppStrings.get(
        'realtimeTranslationActive',
        _currentAppLang,
        args: {
          'langA': langA.nativeName,
          'langB': langB.nativeName,
        },
      ),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      transcripts: [...state.transcripts, switchEntry],
    );

    if (state.activeSession != null) {
      final isIncoming = state.activeSession!.isIncoming;
      await repo.updateCallLanguages(
        state.activeSession!.callId,
        callerLangCode: isIncoming ? newPeerLang : newMyLang,
        calleeLangCode: isIncoming ? newMyLang : newPeerLang,
      );
    }

    if (langA.code == langB.code) {
      // Both users speak the same language: disconnect Gemini, switch to original voice!
      await _geminiTranslator.disconnect();
      setAudioMode(CallAudioMode.originalOnly);
      _webrtcClient.setRemoteAudioVolume(1.0);
    } else if (state.translationEnabled) {
      if (!_geminiTranslator.isConnected) {
        await _geminiTranslator.connect(
          langA: langA,
          langB: langB,
          bidirectional: state.isBidirectionalSingleDevice,
          callId: state.activeSession?.callId,
        );
      } else {
        await _geminiTranslator.updateLanguagePair(
          newLangA: langA,
          newLangB: langB,
          bidirectional: state.isBidirectionalSingleDevice,
        );
      }
      setAudioMode(CallAudioMode.translatedOnly);
    }
  }

  /// Initiates an outgoing call to [callee]
  Future<CallSession?> startOutgoingCall({
    required User caller,
    required User callee,
    required String calleeDisplayName,
    String? overrideMyLangCode,
    String? overridePeerLangCode,
    bool? translationEnabled,
  }) async {
    await _cleanupActiveResources();

    // Clear any previous error
    state = state.copyWith(clearError: true);

    final settings = CallRepository.getPeerTranslationSettings(
      peerId: callee.id,
      peerName: calleeDisplayName,
      peerPhone: callee.phone.number,
      explicitMyLang: overrideMyLangCode,
      explicitPeerLang: overridePeerLangCode,
      explicitTranslationEnabled: translationEnabled,
    );

    final myLang = settings.myLangCode;
    final inferredPeerLang = settings.peerLangCode;
    final effectiveTranslation = settings.isEffectivelyTranslated;

    await CallRepository.setMyLanguageCode(myLang);
    await CallRepository.setPeerLanguageCode(inferredPeerLang);

    // Pre-call gatekeeper check:
    // Only translated calls (where translation is enabled AND languages differ) require minutes!
    // Same-language or direct voice calls are 100% Free!
    final isTranslated = effectiveTranslation &&
        (myLang.toLowerCase().trim() != inferredPeerLang.toLowerCase().trim());

    if (isTranslated) {
      final wRepo = walletRepo ?? ref?.read(walletRepositoryProvider);
      if (wRepo != null) {
        final wallet = await wRepo.getWallet(caller.id);
        if (!wallet.hasMinutes) {
          debugPrint(
              '[CallController] Outgoing translated call blocked: Insufficient minutes (balance: ${wallet.effectiveRemainingMinutes})');
          state = state.copyWith(
            error: 'INSUFFICIENT_MINUTES',
            activeSession: null,
          );
          return null;
        }
      }
    }

    _hasNavigatedToActiveCall = false;

    // Resolve real callee Firestore UID if dialed with a dummy phone_ prefix
    String resolvedCalleeId = callee.id;
    if (resolvedCalleeId.startsWith('phone_') || resolvedCalleeId.isEmpty) {
      try {
        final fsRepo = ref?.read(firebaseFirestoreRepositoryProvider);
        if (fsRepo != null) {
          final phoneToLookup = callee.phone.formattedNumber ?? callee.phone.number ?? '';
          if (phoneToLookup.isNotEmpty) {
            final foundUser = await fsRepo.getUserByPhone(phoneToLookup);
            if (foundUser != null && foundUser.id.isNotEmpty && !foundUser.id.startsWith('phone_')) {
              resolvedCalleeId = foundUser.id;
              debugPrint('[CallController] Resolved real callee UID: $resolvedCalleeId for phone: $phoneToLookup');
            }
          }
        }
      } catch (e) {
        debugPrint('[CallController] Error resolving callee UID: $e');
      }
    }

    final session = CallSession(
      callId: const Uuid().v4(),
      callerId: caller.id,
      callerName: caller.name,
      callerAvatar: caller.avatarUrl,
      callerPhone: caller.phone.getFormattedNumber(),
      calleeId: resolvedCalleeId,
      calleeName: calleeDisplayName,
      calleeAvatar: callee.avatarUrl,
      calleePhone: callee.phone.getFormattedNumber(),
      callerLangCode: myLang,
      calleeLangCode: inferredPeerLang,
      translationEnabled: effectiveTranslation,
      status: CallStateStatus.dialing,
      isIncoming: false,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      activeSession: session,
      myLangCode: myLang,
      peerLangCode: inferredPeerLang,
      translationEnabled: effectiveTranslation,
      elapsedSeconds: 0,
      transcripts: [],
      isMuted: false,
      isSpeakerphoneOn: true,
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );

    final callCreated = await repo.createCall(session);
    if (!callCreated) {
      debugPrint('[CallController] createCall failed in Firestore. Aborting outgoing call.');
      state = state.copyWith(activeSession: null);
      return null;
    }

    // Always establish real WebRTC session and send high-priority FCM wake-up
    _webrtcClient.startOutgoingCall(session.callId);
    _notifyRemoteCallee(session);

    // Transition from Dialing -> Ringing after 900ms
    Future.delayed(const Duration(milliseconds: 900), () {
      if (state.activeSession?.callId == session.callId &&
          state.activeSession?.status == CallStateStatus.dialing) {
        final ringingSession =
            state.activeSession!.copyWith(status: CallStateStatus.ringing);
        state = state.copyWith(activeSession: ringingSession);
        repo.updateCallStatus(session.callId, CallStateStatus.ringing);
      }
    });

    // 30-second unanswered call timeout
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (state.activeSession?.callId == session.callId &&
          state.activeSession?.status != CallStateStatus.connected) {
        debugPrint('Outgoing call timed out after 30s with no answer');
        endCall(
          endStatus: CallStateStatus.missed,
          recordAsMissed: true,
        );
      }
    });

    // Listen for remote callee accepting, rejecting, language sync, or hanging up via Firestore
    _firestoreCallSub =
        repo.watchCallSession(session.callId, caller.id).listen((remote) {
      if (remote == null) return;
      _handleRemoteCallUpdate(remote);
    });

    return session;
  }

  /// Centralized bidirectional listener for remote call updates (Caller and Callee)
  void _handleRemoteCallUpdate(CallSession remote) {
    if (state.activeSession == null) return;

    // 1. Remote call state transitions
    if (remote.status == CallStateStatus.connected &&
        state.activeSession!.status != CallStateStatus.connected) {
      // CRITICAL FIX: Only the CALLEE should call acceptAndConnectCall() when
      // they detect a connected status transition.
      // The CALLER should NEVER call acceptAndConnectCall() on remote connected signal —
      // the caller is already in connecting state waiting for WebRTC answer.
      // Calling acceptAndConnectCall() on the caller side resets the entire audio pipeline
      // and causes call to go silent/dead after callee answers.
      if (state.activeSession!.isIncoming) {
        // Callee side: remote status changed to connected (e.g. by caller accepting
        // a bidirectional scenario). Connect now.
        acceptAndConnectCall();
      }
      // Caller side: do NOT call acceptAndConnectCall() — just update local state.
      // The caller transitions to connected state only via WebRTC answer exchange.
      else {
        debugPrint('[CallController] Caller detected remote connected status. Initializing caller in-call audio engines...');
        _callTimeoutTimer?.cancel();
        _callTimeoutTimer = null;

        final updatedSession =
            state.activeSession!.copyWith(
              status: CallStateStatus.connected,
              connectedAt: remote.connectedAt ?? DateTime.now(),
            );
        state = state.copyWith(
          activeSession: updatedSession,
          translationEnabled: updatedSession.translationEnabled,
        );

        _startInCallAudioEngines(updatedSession);
      }
    } else if (remote.status == CallStateStatus.rejected ||
        remote.status == CallStateStatus.ended ||
        remote.status == CallStateStatus.busy ||
        remote.status == CallStateStatus.missed) {
      endCall(
        endStatus: remote.status,
        recordAsMissed: remote.status == CallStateStatus.missed,
        isDeclined: remote.status == CallStateStatus.rejected,
      );
      return;
    }

    // 2. Bidirectional language synchronization:
    // For Caller (!isIncoming): remote peer is Callee -> remote.calleeLangCode
    // For Callee (isIncoming): remote peer is Caller -> remote.callerLangCode
    final isCaller = !state.activeSession!.isIncoming;
    final remotePeerLang = isCaller ? remote.calleeLangCode : remote.callerLangCode;

    if (remotePeerLang.isNotEmpty && remotePeerLang != state.peerLangCode) {
      debugPrint('[CallController] Remote peer language updated to $remotePeerLang. Synchronizing...');
      state = state.copyWith(peerLangCode: remotePeerLang);
      CallRepository.setPeerLanguageCode(remotePeerLang);

      // Dynamically re-evaluate translation bypass vs audio routing if active
      if (state.activeSession?.status == CallStateStatus.connected) {
        final langA = CallLanguageRegistry.fromCode(state.myLangCode);
        final langB = CallLanguageRegistry.fromCode(remotePeerLang);

        if (langA.code == langB.code) {
          debugPrint('[CallController] Bypass activated: Both users speak ${langA.code}. Disconnecting Gemini.');
          _geminiTranslator.disconnect();
          setAudioMode(CallAudioMode.originalOnly);
          _webrtcClient.setRemoteAudioVolume(1.0);
        } else if (state.translationEnabled) {
          if (!_geminiTranslator.isConnected) {
            _geminiTranslator.connect(
              langA: langA,
              langB: langB,
              bidirectional: state.isBidirectionalSingleDevice,
              callId: remote.callId,
            );
          } else {
            _geminiTranslator.updateLanguagePair(
              newLangA: langA,
              newLangB: langB,
              bidirectional: state.isBidirectionalSingleDevice,
            );
          }
          setAudioMode(CallAudioMode.translatedOnly);
        }
      }
    }
  }

  Future<void> _notifyRemoteCallee(CallSession session) async {
    try {
      final idToken = await GeminiLiveTranslator.getAuthToken();
      final url = Uri.parse(AppConfig.callNotifyIncomingUrl);
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'targetUserId': session.calleeId,
          'calleeId': session.calleeId,
          'callerName': session.callerName,
          'callerNumber': session.callerPhone,
          'callId': session.callId,
        }),
      );
    } catch (e) {
      debugPrint('Failed to send incoming call push notification: $e');
    }
  }

  /// Creates an incoming call session (from Firestore or Simulated Incoming Call button)
  CallSession receiveIncomingCall({
    required User self,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String callerPhone,
    required String callerLangCode,
    String? callId,
  }) {
    final session = CallSession(
      callId: callId ?? const Uuid().v4(),
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      callerPhone: callerPhone,
      calleeId: self.id,
      calleeName: self.name,
      calleeAvatar: self.avatarUrl,
      calleePhone: self.phone.getFormattedNumber(),
      callerLangCode: callerLangCode,
      calleeLangCode: state.myLangCode,
      translationEnabled: true,
      status: CallStateStatus.ringing,
      isIncoming: true,
      createdAt: DateTime.now(),
    );

    final isForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!isForeground) {
      debugPrint('[CallController] App is in background/locked. Triggering native CallKit UI.');
      CallKitService().showIncomingCall(
        callId: session.callId,
        callerName: callerName,
        callerPhone: callerPhone,
        callerAvatar: callerAvatar,
      );
    } else {
      debugPrint('[CallController] App is in foreground. Suppressing CallKit heads-up banner.');
    }

    state = state.copyWith(
      activeSession: session,
      peerLangCode: callerLangCode,
      elapsedSeconds: 0,
      transcripts: [],
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );

    // 30-second unanswered incoming call timeout -> auto-dismiss and record as missed call
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (state.activeSession?.callId == session.callId &&
          state.activeSession?.status == CallStateStatus.ringing) {
        debugPrint('[CallController] Incoming call timed out after 30s unanswered. Auto-dismissing and marking as missed call.');
        CallKitService().endAllCalls();
        endCall(
          endStatus: CallStateStatus.missed,
          recordAsMissed: true,
        );
      }
    });

    // Watch incoming call session in Firestore while ringing. If caller hangs up before answer, dismiss ringing UI immediately
    _firestoreCallSub?.cancel();
    _firestoreCallSub = repo
        .watchCallSession(session.callId, self.id)
        .listen((remote) {
      if (remote == null) return;
      if (remote.status == CallStateStatus.connected) {
        debugPrint('[CallController] Call answered on another device. Dismissing ringing UI without missed call.');
        _callTimeoutTimer?.cancel();
        _callTimeoutTimer = null;
        CallKitService().endAllCalls();
        endCall(
          endStatus: CallStateStatus.ended,
          recordAsMissed: false,
        );
        return;
      }
      if (remote.status == CallStateStatus.ended ||
          remote.status == CallStateStatus.rejected ||
          remote.status == CallStateStatus.missed) {
        debugPrint('[CallController] Remote caller cancelled incoming call while ringing. Dismissing ringing UI.');
        _callTimeoutTimer?.cancel();
        _callTimeoutTimer = null;
        CallKitService().endAllCalls();
        endCall(
          endStatus: remote.status,
          recordAsMissed: remote.status == CallStateStatus.missed,
          isDeclined: remote.status == CallStateStatus.rejected,
        );
      }
    });

    return session;
  }

  /// Connects the call, starts Full-Duplex Audio + Hardware AEC + Gemini Live WebSocket
  Future<void> acceptAndConnectCall({bool? withTranslation, String? callId}) async {
    var current = state.activeSession;
    if (current == null && callId != null && callId.isNotEmpty) {
      try {
        final doc = await repo.firestore?.collection('calls').doc(callId).get();
        if (doc != null && doc.exists && doc.data() != null) {
          final ownUser = getCurrentUser();
          current = CallSession.fromMap(doc.data()!, ownId: ownUser?.id ?? '');
          state = state.copyWith(activeSession: current);
        }
      } catch (e) {
        debugPrint('Failed to restore CallSession from Firestore for $callId: $e');
      }
    }
    if (current == null) return;

    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;

    final enableTrans = withTranslation ?? state.translationEnabled;
    final connectedSession = current.copyWith(
      status: CallStateStatus.connected,
      translationEnabled: enableTrans,
      connectedAt: DateTime.now(),
    );

    state = state.copyWith(
      activeSession: connectedSession,
      translationEnabled: enableTrans,
      geminiState: GeminiLiveState.connecting,
      elapsedSeconds: 0,
    );

    // Only callee needs to dismiss native CallKit notification
    if (current.isIncoming) {
      await CallKitService().endCall(current.callId);
    }

    await repo.updateCallStatus(current.callId, CallStateStatus.connected);

    // If real incoming call, establish WebRTC answer
    if (current.isIncoming) {
      try {
        // Retry up to 5 times with 600ms delay — caller may still be uploading the offer
        Map<String, dynamic>? offerData;
        for (int attempt = 0; attempt < 5; attempt++) {
          final doc = await repo.firestore?.collection('calls').doc(current.callId).get();
          final data = doc?.data();
          if (data != null && data['offer'] is Map<String, dynamic>) {
            offerData = data['offer'] as Map<String, dynamic>;
            debugPrint('[CallController] WebRTC offer fetched on attempt ${attempt + 1}');
            break;
          }
          debugPrint('[CallController] WebRTC offer not ready (attempt ${attempt + 1}/5), retrying in 600ms...');
          await Future.delayed(const Duration(milliseconds: 600));
        }
        if (offerData != null) {
          await _webrtcClient.answerIncomingCall(current.callId, offerData);
        } else {
          debugPrint('[CallController] WebRTC offer was never available after retries. Aborting call.');
          state = state.copyWith(error: 'CALL_CONNECTION_FAILED');
          await endCall(endStatus: CallStateStatus.ended);
          return;
        }
      } catch (e) {
        debugPrint('[CallController] WebRTC answerIncomingCall error: $e');
        state = state.copyWith(error: 'CALL_CONNECTION_FAILED');
        await endCall(endStatus: CallStateStatus.ended);
        return;
      }
    }

    // Listen for remote call updates (Caller or Callee ending the call, changing languages, etc.)
    await _firestoreCallSub?.cancel();
    final ownUser = getCurrentUser();
    _firestoreCallSub = repo
        .watchCallSession(current.callId, ownUser?.id ?? current.calleeId)
        .listen((remote) {
      if (remote == null) return;
      _handleRemoteCallUpdate(remote);
    });

    // Exchange languages and auto-sync peer language code
    if (current.isIncoming) {
      repo.updateCallLanguages(current.callId, calleeLangCode: state.myLangCode);
      if (current.callerLangCode.isNotEmpty && current.callerLangCode != state.peerLangCode) {
        state = state.copyWith(peerLangCode: current.callerLangCode);
        CallRepository.setPeerLanguageCode(current.callerLangCode);
      }
    } else {
      // Caller syncing Callee's language code from remote call doc snapshot
      try {
        final callDoc = await repo.firestore?.collection('calls').doc(current.callId).get();
        final remoteCalleeLang = callDoc?.data()?['calleeLangCode'] as String?;
        if (remoteCalleeLang != null && remoteCalleeLang.isNotEmpty && remoteCalleeLang != state.peerLangCode) {
          debugPrint('[CallController] Caller detected remote calleeLangCode: $remoteCalleeLang on connect. Syncing...');
          state = state.copyWith(peerLangCode: remoteCalleeLang);
          CallRepository.setPeerLanguageCode(remoteCalleeLang);
        }
      } catch (e) {
        debugPrint('[CallController] Error checking initial calleeLangCode: $e');
      }
    }

    await _startInCallAudioEngines(connectedSession);
  }

  /// Shared engine initialization for BOTH Caller and Callee when call transitions to connected
  Future<void> _startInCallAudioEngines(CallSession connectedSession) async {
    if (_isAudioEngineRunning && _currentRunningCallId == connectedSession.callId) {
      debugPrint('[CallController] _startInCallAudioEngines already running for ${connectedSession.callId}, skipping redundant duplicate start');
      return;
    }
    _isAudioEngineRunning = true;
    _currentRunningCallId = connectedSession.callId;

    // Subscribe to WebRTC connection state to detect network drops & reconnect
    _webrtcStateSub?.cancel();
    _webrtcStateSub = _webrtcClient.stateStream.listen((wState) {
      debugPrint('[CallController] WebRtcCallState changed to $wState');
      state = state.copyWith(webrtcState: wState);
      if (wState == WebRtcCallState.connected) {
        final wasReconnecting = _networkDropTimer != null;
        _networkDropTimer?.cancel();
        _networkDropTimer = null;

        // CRITICAL: When WebRTC peer connection becomes fully connected on CALLER side,
        // update the session to connected state (remote Firestore update drives this too,
        // but WebRTC connected is the authoritative local signal for audio readiness).
        if (state.activeSession?.status != CallStateStatus.connected &&
            !(state.activeSession?.isIncoming ?? true)) {
          debugPrint('[CallController] WebRTC P2P connected on caller side. Marking session as connected.');
          final updatedSession =
              state.activeSession?.copyWith(status: CallStateStatus.connected, connectedAt: DateTime.now());
          if (updatedSession != null) {
            state = state.copyWith(activeSession: updatedSession);
            repo.updateCallStatus(updatedSession.callId, CallStateStatus.connected);
            // Ensure caller audio is fully open
            _webrtcClient.setMicrophoneMute(false);
            _webrtcClient.setRemoteAudioVolume(1.0);
            // Navigate caller to active call screen
            navigateToActiveCall();
          }
        }
        if (wasReconnecting) {
          final reconnectedBubble = LiveTranscriptEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            speakerId: 'system',
            speakerName: 'System',
            isSelf: false,
            sourceLangCode: 'en',
            targetLangCode: _currentAppLang,
            originalText: 'Call reconnected.',
            translatedText: _currentAppLang == 'bn'
                ? 'কল পুনরায় সংযুক্ত হয়েছে।'
                : 'Call reconnected.',
            timestamp: DateTime.now(),
          );
          state = state.copyWith(
            transcripts: [...state.transcripts, reconnectedBubble],
          );
        }
      } else if (wState == WebRtcCallState.disconnected) {
        debugPrint('[CallController] WebRTC disconnected, triggering ICE restart and starting 10s timer');
        _webrtcClient.restartIce();
        _networkDropTimer?.cancel();
        final reconnectingBubble = LiveTranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          speakerId: 'system',
          speakerName: 'System',
          isSelf: false,
          sourceLangCode: 'en',
          targetLangCode: _currentAppLang,
          originalText: 'Connection lost. Reconnecting call...',
          translatedText: _currentAppLang == 'bn'
              ? 'সংযোগ বিচ্ছিন্ন হয়েছে। কল পুনরায় সংযুক্ত করা হচ্ছে...'
              : 'Connection lost. Reconnecting call...',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          transcripts: [...state.transcripts, reconnectingBubble],
        );
        _networkDropTimer = Timer(const Duration(seconds: 10), () {
          if (state.webrtcState == WebRtcCallState.disconnected && state.activeSession != null) {
            debugPrint('[CallController] WebRTC disconnected for >10s. Auto hanging up.');
            endCall();
          }
        });
      } else if (wState == WebRtcCallState.failed) {
        debugPrint('[CallController] WebRTC connection failed, starting 10s timer');
        _networkDropTimer?.cancel();
        _networkDropTimer = Timer(const Duration(seconds: 10), () {
          if (state.webrtcState == WebRtcCallState.failed && state.activeSession != null) {
            debugPrint('[CallController] WebRTC connection failed for >10s. Auto hanging up.');
            endCall();
          }
        });
      }
    });

    // Subscribe to network quality updates to dynamically toggle low data mode (B2 & B5)
    _webrtcQualitySub?.cancel();
    _webrtcQualitySub = _webrtcClient.networkQualityStream.listen((quality) {
      final isPoor = quality == CallNetworkQuality.poor;
      debugPrint('[CallController] Network quality changed to: $quality (autoLowData: $isPoor)');
      state = state.copyWith(
        networkQuality: quality,
        isLowDataModeAutoEnabled: isPoor,
      );
    });

    // 1. Start call duration timer (Wall-clock immune to Android Doze mode)
    // Server-side relay is the authoritative single source of truth for minute metering.
    _callDurationTimer?.cancel();
    final connectedAt = connectedSession.connectedAt ?? DateTime.now();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final actualElapsed = DateTime.now().difference(connectedAt).inSeconds;
      state = state.copyWith(elapsedSeconds: actualElapsed);
    });

    final hasGeminiKey = GeminiLiveTranslator.getSavedApiKey().isNotEmpty;
    final hasRelay = GeminiLiveTranslator.getSavedRelayUrl().isNotEmpty;
    final hasTranslationEngine = hasGeminiKey || hasRelay;
    final isSameLanguage = CallLanguageRegistry.isSameLanguageFamily(state.myLangCode, state.peerLangCode);
    final shouldTranslate = state.translationEnabled && !isSameLanguage && hasTranslationEngine;

    if (!shouldTranslate) {
      // 100% Direct P2P Audio Call - WebRTC handles native mic & speaker with hardware AEC
      _webrtcClient.setMicrophoneMute(false);
      _webrtcClient.setRemoteAudioVolume(1.0);

      final directBubble = LiveTranscriptEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speakerId: 'system',
        speakerName: isSameLanguage
            ? 'Direct Voice Call'
            : (!hasTranslationEngine ? 'Direct Call (Relay/API Key Not Set)' : 'Direct Call (Translation Off)'),
        isSelf: false,
        sourceLangCode: myLang.code,
        targetLangCode: peerLang.code,
        originalText: isSameLanguage
            ? '📞 Direct Voice Call Active: Both participants speak ${myLang.nativeName} (${myLang.englishName}). WebRTC audio streaming directly with zero AI translation.'
            : (!hasGeminiKey
                ? '📞 Direct Voice Call Active: Gemini API key not configured yet. Calling directly over WebRTC voice with zero delay.'
                : '📞 Direct Voice Call Active: AI translation is turned off. Direct WebRTC audio active.'),
        translatedText: isSameLanguage
            ? AppStrings.get(
                'sameLanguageDirectCallNotice',
                _currentAppLang,
                args: {'lang': myLang.nativeName},
              )
            : AppStrings.get(
                'directVoiceCallActiveNotice',
                _currentAppLang,
              ),
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        geminiState: GeminiLiveState.ready,
        audioMode: CallAudioMode.originalOnly,
        transcripts: [directBubble],
        hasApiKey: hasGeminiKey,
      );
      return;
    }

    // 2. Start Full-Duplex Audio Pipeline for Live Translation (16kHz Mic + 24kHz Speaker + Hardware AEC)
    try {
      await _audioPipeline.startFullDuplex();

      _micRmsSub = _audioPipeline.micRmsStream.listen((rms) {
        state = state.copyWith(micRmsLevel: rms);
      });

      _micStreamSub = _audioPipeline.outgoingMicPcmStream.listen((pcm16k) {
        if (state.translationEnabled && _geminiTranslator.isConnected) {
          _geminiTranslator.sendAudioChunk(pcm16k);
        }
      });
    } catch (e) {
      debugPrint('AudioPipeline start error: $e');
    }

    // Apply WebRTC audio volume and mic mute based on active audioMode
    // During connecting phase, ensure direct voice remains open so users are never left in silence
    if (state.audioMode == CallAudioMode.translatedOnly && _geminiTranslator.isConnected) {
      _webrtcClient.setRemoteAudioVolume(0.0);
      _webrtcClient.setMicrophoneMute(true);
    } else if (state.audioMode == CallAudioMode.ducking) {
      _webrtcClient.setRemoteAudioVolume(0.15);
      _webrtcClient.setMicrophoneMute(state.isMuted);
    } else {
      _webrtcClient.setRemoteAudioVolume(1.0);
      _webrtcClient.setMicrophoneMute(state.isMuted);
    }

    // 3. Connect Gemini Live WebSocket Engine for (myLanguage <-> peerLanguage)
    _geminiStateSub = _geminiTranslator.stateStream.listen((gState) {
      _audioPipeline.setAiSpeakingState(gState == GeminiLiveState.speaking);
      state = state.copyWith(geminiState: gState);

      final isCallConnected =
          state.activeSession?.status == CallStateStatus.connected;

      if (gState == GeminiLiveState.error ||
          gState == GeminiLiveState.disconnected ||
          (gState == GeminiLiveState.connecting && isCallConnected)) {
        if (state.audioMode != CallAudioMode.originalOnly) {
          // Immediately fallback to direct WebRTC voice so users are NEVER left in silence (eliminates dead-air gap)!
          _webrtcClient.setMicrophoneMute(state.isMuted);
          _webrtcClient.setRemoteAudioVolume(1.0);
          setAudioMode(CallAudioMode.originalOnly);

          if (!state.isTranslationExhausted) {
            final hasRecentFallback = state.transcripts.isNotEmpty &&
                (state.transcripts.last.id.startsWith('fb_') ||
                    state.transcripts.last.id.startsWith('reconnecting_'));
            if (!hasRecentFallback) {
              final fallbackBubble = LiveTranscriptEntry(
                id: (gState == GeminiLiveState.connecting)
                    ? 'reconnecting_${DateTime.now().millisecondsSinceEpoch}'
                    : 'fb_${DateTime.now().millisecondsSinceEpoch}',
                speakerId: 'system',
                speakerName: (gState == GeminiLiveState.connecting)
                    ? 'AI Reconnecting — Direct Voice Active'
                    : 'AI Offline — Direct Voice Active',
                isSelf: false,
                sourceLangCode: myLang.code,
                targetLangCode: peerLang.code,
                originalText: (gState == GeminiLiveState.connecting)
                    ? 'AI Interpreter reconnecting. Switched to direct WebRTC voice.'
                    : 'AI Interpreter unavailable. Connected via direct WebRTC voice.',
                translatedText:
                    AppStrings.get('aiUnavailableDirectFallback', _currentAppLang),
                timestamp: DateTime.now(),
              );
              state = state.copyWith(
                transcripts: [...state.transcripts, fallbackBubble],
              );
            }
          }
        }
      } else if (gState == GeminiLiveState.listening &&
          isCallConnected &&
          state.translationEnabled &&
          state.myLangCode != state.peerLangCode &&
          state.audioMode == CallAudioMode.originalOnly &&
          !state.isTranslationExhausted) {
        // Auto-restored after successful reconnection!
        setAudioMode(CallAudioMode.translatedOnly);
        final chime =
            GeminiLiveTranslator.generateTestVoiceTonePcm24k(durationMs: 360);
        _audioPipeline.feedTranslatedAiPcm(chime);
        final restoredBubble = LiveTranscriptEntry(
          id: 'restored_${DateTime.now().millisecondsSinceEpoch}',
          speakerId: 'system',
          speakerName: 'AI Live Interpreter',
          isSelf: false,
          sourceLangCode: myLang.code,
          targetLangCode: peerLang.code,
          originalText:
              'AI Interpreter reconnected. Live translation active.',
          translatedText: AppStrings.get(
                  'callTranslationActiveNotice', _currentAppLang)
              .replaceAll('{langA}', state.myLanguage.nativeName)
              .replaceAll('{langB}', state.peerLanguage.nativeName),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          transcripts: [...state.transcripts, restoredBubble],
        );
      }
    });

    _geminiAudioSub =
        _geminiTranslator.translatedAudioStream.listen((pcm24kBytes) {
      if (state.isBidirectionalSingleDevice) {
        _audioPipeline.feedTranslatedAiPcm(pcm24kBytes);
      } else {
        // Real P2P call: stream translated 24kHz PCM to remote peer via WebRTC DataChannel
        _webrtcClient.sendTranslatedAudio(pcm24kBytes);
      }
    });

    // Wire WebRTC remote translated audio stream to local audio pipeline for playback
    _webrtcRemoteTranslatedAudioSub?.cancel();
    _webrtcRemoteTranslatedAudioSub =
        _webrtcClient.remoteTranslatedAudioStream.listen((pcm24kBytes) {
      _audioPipeline.feedTranslatedAiPcm(pcm24kBytes);
    });

    _geminiInterruptedSub =
        _geminiTranslator.interruptedStream.listen((interrupted) {
      if (interrupted) {
        _audioPipeline.flushAiPlayerBuffer();
      }
    });

    _geminiTranscriptSub =
        _geminiTranslator.transcriptStream.listen((entry) {
      final updated = [...state.transcripts, entry];
      state = state.copyWith(transcripts: updated);
      repo.sendTranscriptToCall(connectedSession.callId, entry);
    });

    _geminiBillingSub?.cancel();
    _geminiBillingSub =
        _geminiTranslator.billingUpdateStream.listen((bEvent) {
      if (bEvent.isCallee) {
        debugPrint('[CallController] Callee role confirmed: Translation is free.');
        return;
      }
      if (bEvent.lowBalanceWarning && !_lowBalanceAlerted) {
        _lowBalanceAlerted = true;
        final warningBubble = LiveTranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          speakerId: 'system',
          speakerName: 'Livocal Billing',
          isSelf: true,
          sourceLangCode: 'en',
          targetLangCode: _currentAppLang,
          originalText: '⚠️ Low Balance Warning: You have ${bEvent.remainingMinutes} minute(s) remaining.',
          translatedText: AppStrings.get('callWarningRemainingMinutes', _currentAppLang)
              .replaceAll('{minutes}', '${bEvent.remainingMinutes}'),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(transcripts: [...state.transcripts, warningBubble]);
      }
      if (bEvent.isExhausted) {
        final isCallee = state.activeSession?.isIncoming ?? false;
        final originalNotice = isCallee
            ? "Caller's translation minutes exhausted. Switched to direct voice call."
            : "Translation minutes exhausted. Switched to direct voice call. Recharge to resume live translation.";
        final translatedNotice = isCallee
            ? AppStrings.get('callerMinutesExhaustedDirectVoiceDesc', _currentAppLang)
            : '${AppStrings.get('minutesExhaustedAlert', _currentAppLang)} ${AppStrings.get('callContinuingDirectVoiceDesc', _currentAppLang)}';

        final exhaustedBubble = LiveTranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          speakerId: 'system',
          speakerName: 'Livocal Billing',
          isSelf: true,
          sourceLangCode: 'en',
          targetLangCode: _currentAppLang,
          originalText: originalNotice,
          translatedText: translatedNotice,
          timestamp: DateTime.now(),
        );

        // Fall back gracefully to direct voice audio instead of abruptly terminating the call!
        _webrtcClient.setMicrophoneMute(state.isMuted);
        _webrtcClient.setRemoteAudioVolume(1.0);
        setAudioMode(CallAudioMode.originalOnly);

        state = state.copyWith(
          transcripts: [...state.transcripts, exhaustedBubble],
          error: 'MINUTES_EXHAUSTED',
          isTranslationExhausted: true,
          translationEnabled: false,
        );
      }
    });

    final connectedWs = await _geminiTranslator.connect(
      langA: myLang,
      langB: peerLang,
      bidirectional: state.isBidirectionalSingleDevice,
      callId: connectedSession.callId,
    );

    if (!connectedWs) {
      debugPrint('[CallController] Gemini connection failed/missing key. Falling back to direct WebRTC audio.');
      _webrtcClient.setMicrophoneMute(state.isMuted);
      _webrtcClient.setRemoteAudioVolume(1.0);
      setAudioMode(CallAudioMode.originalOnly);

      if (!state.isTranslationExhausted) {
        final fallbackBubble = LiveTranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          speakerId: 'system',
          speakerName: 'AI Offline — Direct Voice Active',
          isSelf: false,
          sourceLangCode: myLang.code,
          targetLangCode: peerLang.code,
          originalText: 'AI Interpreter unavailable (missing key/relay). Connected via direct WebRTC voice.',
          translatedText: AppStrings.get('aiUnavailableDirectFallback', _currentAppLang),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          geminiState: GeminiLiveState.error,
          transcripts: [...state.transcripts, fallbackBubble],
        );
      }
      return;
    }

    // Play a pleasant connection chime through the 24kHz PCM stream
    final chime = GeminiLiveTranslator.generateTestVoiceTonePcm24k(durationMs: 360);
    _audioPipeline.feedTranslatedAiPcm(chime);

    // Add initial welcome bilingual transcript bubble
    final initialBubble = LiveTranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      speakerId: 'system',
      speakerName: 'Gemini 3.5 Live Interpreter',
      isSelf: false,
      sourceLangCode: myLang.code,
      targetLangCode: peerLang.code,
      originalText: connectedWs
          ? '🟢 Live Neural Audio Interpreter Active: Speak in ${myLang.nativeName} (${myLang.englishName}) or ${peerLang.nativeName} (${peerLang.englishName}).'
          : '⚡ Live Interpreter Ready (${myLang.shortBadge} ⇄ ${peerLang.shortBadge}). Speak into mic or tap quick test phrases below.',
      translatedText: AppStrings.get('callTranslationActiveNotice', _currentAppLang)
          .replaceAll('{myEmoji}', myLang.flagEmoji)
          .replaceAll('{myName}', myLang.nativeName)
          .replaceAll('{peerEmoji}', peerLang.flagEmoji)
          .replaceAll('{peerName}', peerLang.nativeName),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      geminiState:
          connectedWs ? GeminiLiveState.listening : GeminiLiveState.ready,
      transcripts: [initialBubble],
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );

    // Ensure single push of ActiveCallScreen
    navigateToActiveCall();
  }


  void toggleMute() {
    final nextMute = !state.isMuted;
    _audioPipeline.setMuted(nextMute);
    if (!state.translationEnabled || state.audioMode != CallAudioMode.translatedOnly) {
      _webrtcClient.setMicrophoneMute(nextMute);
    } else {
      // In translatedOnly mode, raw mic is kept muted to conserve mobile bandwidth
      _webrtcClient.setMicrophoneMute(true);
    }
    if (nextMute) {
      _geminiTranslator.sendAudioStreamEnd();
    }
    state = state.copyWith(isMuted: nextMute);
  }

  Future<void> toggleSpeakerphone() async {
    final nextSpeaker = !state.isSpeakerphoneOn;
    await _audioPipeline.setSpeakerphone(nextSpeaker);
    _webrtcClient.setSpeakerphone(nextSpeaker);
    state = state.copyWith(isSpeakerphoneOn: nextSpeaker);
  }

  Future<void> setAudioMode(CallAudioMode mode) async {
    await _audioPipeline.setAudioMode(mode);
    if (mode == CallAudioMode.translatedOnly) {
      _webrtcClient.setRemoteAudioVolume(0.0);
      _webrtcClient.setMicrophoneMute(true);
    } else if (mode == CallAudioMode.ducking) {
      _webrtcClient.setRemoteAudioVolume(0.15);
      _webrtcClient.setMicrophoneMute(state.isMuted);
    } else {
      _webrtcClient.setRemoteAudioVolume(1.0);
      _webrtcClient.setMicrophoneMute(state.isMuted);
    }
    state = state.copyWith(audioMode: mode);
  }

  void toggleTranslationEnabled(bool enabled) async {
    state = state.copyWith(translationEnabled: enabled);
    if (!enabled) {
      setAudioMode(CallAudioMode.originalOnly);
      _webrtcClient.setMicrophoneMute(state.isMuted);
      _webrtcClient.setRemoteAudioVolume(1.0);
      await _geminiTranslator.disconnect();
    } else {
      if (state.myLangCode != state.peerLangCode) {
        setAudioMode(CallAudioMode.translatedOnly);
        _webrtcClient.setMicrophoneMute(true);
        if (!_geminiTranslator.isConnected) {
          final ok = await _geminiTranslator.connect(
            langA: state.myLanguage,
            langB: state.peerLanguage,
            bidirectional: state.isBidirectionalSingleDevice,
            callId: state.activeSession?.callId,
          );
          if (!ok) {
            _webrtcClient.setMicrophoneMute(state.isMuted);
            _webrtcClient.setRemoteAudioVolume(1.0);
            setAudioMode(CallAudioMode.originalOnly);
          }
        }
      } else {
        setAudioMode(CallAudioMode.originalOnly);
        _webrtcClient.setMicrophoneMute(state.isMuted);
        _webrtcClient.setRemoteAudioVolume(1.0);
      }
    }
  }

  Future<void> retryTranslation() async {
    debugPrint('[CallController] User triggered retryTranslation');
    state = state.copyWith(geminiState: GeminiLiveState.connecting);
    await _geminiTranslator.disconnect();
    final ok = await _geminiTranslator.connect(
      langA: state.myLanguage,
      langB: state.peerLanguage,
      bidirectional: state.isBidirectionalSingleDevice,
      callId: state.activeSession?.callId,
    );
    if (!ok) {
      state = state.copyWith(geminiState: GeminiLiveState.error);
      _webrtcClient.setMicrophoneMute(state.isMuted);
      _webrtcClient.setRemoteAudioVolume(1.0);
      setAudioMode(CallAudioMode.originalOnly);
    } else {
      state = state.copyWith(geminiState: GeminiLiveState.listening);
      if (state.translationEnabled) {
        setAudioMode(CallAudioMode.translatedOnly);
        _webrtcClient.setMicrophoneMute(true);
      }
    }
  }

  Future<void> retryWebRtc() async {
    debugPrint('[CallController] User triggered retryWebRtc');
    await _webrtcClient.restartIce();
  }

  Future<void> resumeTranslationAfterRecharge() async {
    final current = state.activeSession;
    if (current == null || current.status != CallStateStatus.connected) return;

    debugPrint('[CallController] Resuming translation after wallet recharge...');
    state = state.copyWith(
      isTranslationExhausted: false,
      translationEnabled: true,
      clearError: true,
      geminiState: GeminiLiveState.connecting,
    );

    _webrtcClient.setRemoteAudioVolume(0.0);
    _webrtcClient.setMicrophoneMute(true);
    setAudioMode(CallAudioMode.translatedOnly);

    final ok = await _geminiTranslator.connect(
      langA: state.myLanguage,
      langB: state.peerLanguage,
      bidirectional: state.isBidirectionalSingleDevice,
      callId: current.callId,
    );

    if (ok) {
      final resumedBubble = LiveTranscriptEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speakerId: 'system',
        speakerName: 'Livocal Billing',
        isSelf: true,
        sourceLangCode: 'en',
        targetLangCode: _currentAppLang,
        originalText: '✅ Translation resumed successfully after recharge.',
        translatedText: _currentAppLang == 'bn'
            ? '✅ রিচার্জের পর অনুবাদ সফলভাবে পুনরায় চালু হয়েছে।'
            : '✅ Translation resumed successfully after recharge.',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        geminiState: GeminiLiveState.listening,
        transcripts: [...state.transcripts, resumedBubble],
      );
    } else {
      debugPrint('[CallController] Failed to resume translation after recharge. Staying in direct voice.');
      _webrtcClient.setMicrophoneMute(state.isMuted);
      _webrtcClient.setRemoteAudioVolume(1.0);
      setAudioMode(CallAudioMode.originalOnly);
    }
  }

  bool _lowBalanceAlerted = false;


  Future<void> endCall({
    CallStateStatus? endStatus,
    bool recordAsMissed = false,
    bool isDeclined = false,
  }) async {
    if (_isEndingCall) return;
    _isEndingCall = true;
    CallHistoryRecord? lastEndedRecord;
    try {
      final current = state.activeSession;
      final duration = state.elapsedSeconds;

      if (current != null) {
        await CallKitService().endCall(current.callId);

        // Determine definitive status across Firestore, History and In-Chat Log
        final CallStateStatus definitiveStatus;
        final String statusStr;
        final bool isMissed;

        if (isDeclined || endStatus == CallStateStatus.rejected) {
          definitiveStatus = CallStateStatus.rejected;
          statusStr = 'declined';
          isMissed = false;
        } else if (recordAsMissed ||
            endStatus == CallStateStatus.missed ||
            (duration == 0 && current.status == CallStateStatus.ringing)) {
          definitiveStatus = CallStateStatus.missed;
          statusStr = 'missed';
          isMissed = true;
        } else {
          definitiveStatus = CallStateStatus.ended;
          statusStr = 'answered';
          isMissed = false;
        }

        await repo.updateCallStatus(current.callId, definitiveStatus);

        // Finalize call billing record if caller in translated call
        if (!current.isIncoming && current.isTranslatedCall) {
          final totalMinutesBilled = (duration + 59) ~/ 60;
          final wRepo = walletRepo ?? ref?.read(walletRepositoryProvider);
          wRepo?.finalizeCallBilling(
            callId: current.callId,
            totalDurationSeconds: duration,
            totalMinutesBilled: totalMinutesBilled,
            isTranslatedCall: true,
          );
        }

        if (isMissed && current.isIncoming) {
          CallKitService().showMissedCallNotification(
            callId: current.callId,
            callerName: current.peerName,
            callerPhone: current.peerPhone,
            callerAvatar: current.peerAvatar,
          );
        }

        final record = CallHistoryRecord(
          callId: current.callId,
          peerId: current.peerId,
          peerName: current.peerName,
          peerAvatar: current.peerAvatar,
          peerPhone: current.peerPhone,
          timestamp: DateTime.now(),
          durationSeconds: duration,
          isIncoming: current.isIncoming,
          isMissed: isMissed,
          translationEnabled: state.translationEnabled,
          myLangCode: state.myLangCode,
          peerLangCode: state.peerLangCode,
        );

        await repo.addCallHistoryRecord(record);

        // WhatsApp-style Inline Call Log message into chat conversation
        try {
          final logContent = CallLogHelper.encode(
            direction: current.isIncoming ? 'incoming' : 'outgoing',
            status: statusStr,
            duration: duration,
            isTranslated: current.isTranslatedCall,
          );

          // Deterministic unique message ID scoped per participant to prevent double-write and conflict when syncing
          final myId = current.isIncoming ? current.calleeId : current.callerId;
          final peerId = current.isIncoming ? current.callerId : current.calleeId;
          final callLogMessage = Message(
            id: 'call_${current.callId}_$myId',
            content: logContent,
            senderId: myId,
            receiverId: peerId,
            timestamp: Timestamp.now(),
            status: MessageStatus.delivered,
          );

          // Save locally in Isar DB for this user's conversation (no peer remote inbox overwrite)
          await IsarDb.addMessage(callLogMessage);
        } catch (e) {
          debugPrint('[CallController] Error creating call log message: $e');
        }

        lastEndedRecord = record;
      }

      await _cleanupActiveResources();

      state = state.copyWith(
        clearSession: true,
        elapsedSeconds: 0,
        micRmsLevel: 0.0,
        geminiState: GeminiLiveState.ready,
        callHistory: repo.getCallHistory(),
        networkQuality: CallNetworkQuality.good,
        isLowDataModeAutoEnabled: false,
        lastEndedCall: lastEndedRecord,
      );
    } finally {
      _isEndingCall = false;
    }
  }

  Future<void> _cleanupActiveResources() async {
    _lowBalanceAlerted = false;
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
    _networkDropTimer?.cancel();
    _networkDropTimer = null;

    await _micStreamSub?.cancel();
    _micStreamSub = null;
    await _micRmsSub?.cancel();
    _micRmsSub = null;
    await _geminiAudioSub?.cancel();
    _geminiAudioSub = null;
    await _geminiStateSub?.cancel();
    _geminiStateSub = null;
    await _geminiTranscriptSub?.cancel();
    _geminiTranscriptSub = null;
    await _geminiInterruptedSub?.cancel();
    _geminiInterruptedSub = null;
    await _geminiBillingSub?.cancel();
    _geminiBillingSub = null;
    await _firestoreCallSub?.cancel();
    _firestoreCallSub = null;
    await _webrtcRemoteTranslatedAudioSub?.cancel();
    _webrtcRemoteTranslatedAudioSub = null;
    await _webrtcStateSub?.cancel();
    _webrtcStateSub = null;
    await _webrtcQualitySub?.cancel();
    _webrtcQualitySub = null;

    await _webrtcClient.endCall();
    await _geminiTranslator.disconnect();
    await _audioPipeline.dispose();
    _isAudioEngineRunning = false;
    _currentRunningCallId = null;
    _hasNavigatedToActiveCall = false;
  }
}
