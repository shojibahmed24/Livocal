import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whatsapp_clone/shared/utils/abc.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/features/calls/models/call_language.dart';
import 'package:whatsapp_clone/features/calls/models/call_model.dart';
import 'package:whatsapp_clone/features/calls/repositories/call_repository.dart';
import 'package:whatsapp_clone/features/calls/services/call_audio_pipeline.dart';
import 'package:whatsapp_clone/features/calls/services/call_kit_service.dart';
import 'package:whatsapp_clone/features/calls/services/gemini_live_translator.dart';
import 'package:whatsapp_clone/features/calls/services/webrtc_call_client.dart';
import 'package:whatsapp_clone/shared/models/user.dart';

final callControllerProvider =
    StateNotifierProvider<CallController, CallControllerState>((ref) {
  final repo = ref.read(callRepositoryProvider);
  return CallController(repo: repo);
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
  });

  CallLanguage get myLanguage => CallLanguageRegistry.fromCode(myLangCode);
  CallLanguage get peerLanguage => CallLanguageRegistry.fromCode(peerLangCode);

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
    );
  }
}

class CallController extends StateNotifier<CallControllerState> {
  final CallRepository repo;
  final CallAudioPipeline _audioPipeline = CallAudioPipeline();
  final GeminiLiveTranslator _geminiTranslator = GeminiLiveTranslator();
  final WebRtcCallClient _webrtcClient = WebRtcCallClient();

  Timer? _callDurationTimer;
  Timer? _ringingAutoAnswerTimer;
  StreamSubscription<Uint8List>? _micStreamSub;
  StreamSubscription<double>? _micRmsSub;
  StreamSubscription<Uint8List>? _geminiAudioSub;
  StreamSubscription<GeminiLiveState>? _geminiStateSub;
  StreamSubscription<LiveTranscriptEntry>? _geminiTranscriptSub;
  StreamSubscription<bool>? _geminiInterruptedSub;
  StreamSubscription<CallSession?>? _firestoreCallSub;

  CallController({required this.repo})
      : super(
          CallControllerState(
            myLangCode: CallRepository.getMyLanguageCode(),
            peerLangCode: CallRepository.getPeerLanguageCode(),
            callHistory: repo.getCallHistory(),
            hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
          ),
        ) {
    CallKitService().init(
      onAccept: (callId) {
        acceptAndConnectCall(callId: callId);
      },
      onDecline: (callId) {
        endCall();
      },
    );
  }

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
    state = state.copyWith(peerLangCode: langCode);
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
    state = state.copyWith(myLangCode: oldPeer, peerLangCode: oldMy);
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
      translatedText:
          '${langA.nativeName} ⇄ ${langB.nativeName} রিয়েল-টাইম অনুবাদ সক্রিয় করা হয়েছে',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      transcripts: [...state.transcripts, switchEntry],
    );

    if (state.activeSession != null) {
      await repo.updateCallLanguages(
        state.activeSession!.callId,
        callerLangCode: newMyLang,
        calleeLangCode: newPeerLang,
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
  Future<CallSession> startOutgoingCall({
    required User caller,
    required User callee,
    required String calleeDisplayName,
    String? overrideMyLangCode,
    String? overridePeerLangCode,
    bool isSimulatedDemo = false,
  }) async {
    await _cleanupActiveResources();

    final myLang = overrideMyLangCode ?? state.myLangCode;
    final inferredPeerLang = overridePeerLangCode ??
        CallRepository.inferPeerLanguageCode(callee.id, calleeDisplayName);

    await CallRepository.setMyLanguageCode(myLang);
    await CallRepository.setPeerLanguageCode(inferredPeerLang);

    final session = CallSession(
      callId: const Uuid().v4(),
      callerId: caller.id,
      callerName: caller.name,
      callerAvatar: caller.avatarUrl,
      callerPhone: caller.phone.getFormattedNumber(),
      calleeId: callee.id,
      calleeName: calleeDisplayName,
      calleeAvatar: callee.avatarUrl,
      calleePhone: callee.phone.getFormattedNumber(),
      callerLangCode: myLang,
      calleeLangCode: inferredPeerLang,
      translationEnabled: state.translationEnabled,
      status: CallStateStatus.dialing,
      isIncoming: false,
      isSimulatedTest:
          isSimulatedDemo || callee.id.startsWith('demo_'),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      activeSession: session,
      myLangCode: myLang,
      peerLangCode: inferredPeerLang,
      elapsedSeconds: 0,
      transcripts: [],
      isMuted: false,
      isSpeakerphoneOn: true,
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );

    await repo.createCall(session);

    if (!session.isSimulatedTest) {
      _webrtcClient.startOutgoingCall(session.callId);
      _notifyRemoteCallee(session);
    }

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

    // If calling a Demo Contact or AI Test Call, auto-answer after 2.4s so user can test immediately!
    if (session.isSimulatedTest) {
      _ringingAutoAnswerTimer = Timer(const Duration(milliseconds: 2400), () {
        if (state.activeSession?.callId == session.callId &&
            (state.activeSession?.status == CallStateStatus.dialing ||
                state.activeSession?.status == CallStateStatus.ringing)) {
          acceptAndConnectCall();
        }
      });
    } else {
      // Listen for remote callee accepting or rejecting via Firestore
      _firestoreCallSub =
          repo.watchCallSession(session.callId, caller.id).listen((remote) {
        if (remote == null || state.activeSession == null) return;
        if (remote.status == CallStateStatus.connected &&
            state.activeSession!.status != CallStateStatus.connected) {
          acceptAndConnectCall();
        } else if (remote.status == CallStateStatus.rejected ||
            remote.status == CallStateStatus.ended ||
            remote.status == CallStateStatus.busy) {
          endCall(recordAsMissed: false);
        }
      });
    }

    return session;
  }

  Future<void> _notifyRemoteCallee(CallSession session) async {
    try {
      final url = Uri.parse(
          'https://livocal-relay.onrender.com/api/call/notify-incoming');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
    bool isSimulated = false,
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
      isSimulatedTest: isSimulated,
      createdAt: DateTime.now(),
    );

    if (!isSimulated) {
      CallKitService().showIncomingCall(
        callId: session.callId,
        callerName: callerName,
        callerPhone: callerPhone,
        callerAvatar: callerAvatar,
      );
    }

    state = state.copyWith(
      activeSession: session,
      peerLangCode: callerLangCode,
      elapsedSeconds: 0,
      transcripts: [],
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );

    return session;
  }

  /// Connects the call, starts Full-Duplex Audio + Hardware AEC + Gemini Live WebSocket
  Future<void> acceptAndConnectCall({bool? withTranslation, String? callId}) async {
    _ringingAutoAnswerTimer?.cancel();
    var current = state.activeSession;
    if (current == null && callId != null && callId.isNotEmpty) {
      try {
        final doc = await repo.firestore.collection('calls').doc(callId).get();
        if (doc.exists && doc.data() != null) {
          final ownUser = getCurrentUser();
          current = CallSession.fromMap(doc.data()!, ownId: ownUser?.id ?? '');
          state = state.copyWith(activeSession: current);
        }
      } catch (e) {
        debugPrint('Failed to restore CallSession from Firestore for $callId: $e');
      }
    }
    if (current == null) return;

    await CallKitService().endCall(current.callId);

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

    await repo.updateCallStatus(current.callId, CallStateStatus.connected);

    // If real incoming call, establish WebRTC answer
    if (!current.isSimulatedTest && current.isIncoming) {
      try {
        final doc =
            await repo.firestore.collection('calls').doc(current.callId).get();
        final offerData = doc.data()?['offer'];
        if (offerData != null && offerData is Map<String, dynamic>) {
          await _webrtcClient.answerIncomingCall(current.callId, offerData);
        }
      } catch (e) {
        debugPrint('WebRTC answerIncomingCall error: $e');
      }
    }

    // 1. Start call duration timer
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    // 2. Start Full-Duplex Audio Pipeline (16kHz Mic + 24kHz Speaker + Hardware AEC)
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
    } catch (_) {}

    // 3. Connect Gemini Live WebSocket Engine for (myLanguage <-> peerLanguage)
    final myLang = state.myLanguage;
    final peerLang = state.peerLanguage;

    _geminiStateSub = _geminiTranslator.stateStream.listen((gState) {
      _audioPipeline.setAiSpeakingState(gState == GeminiLiveState.speaking);
      state = state.copyWith(geminiState: gState);
    });

    _geminiAudioSub =
        _geminiTranslator.translatedAudioStream.listen((pcm24kBytes) {
      if (state.isBidirectionalSingleDevice || connectedSession.isSimulatedTest) {
        _audioPipeline.feedTranslatedAiPcm(pcm24kBytes);
      }
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

    final isSameLanguage = myLang.code == peerLang.code;
    final shouldTranslate = state.translationEnabled && !isSameLanguage;

    if (!shouldTranslate) {
      // 100% Direct P2P Audio Call - No Gemini WebSocket Needed!
      _webrtcClient.setRemoteAudioVolume(1.0);

      final directBubble = LiveTranscriptEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speakerId: 'system',
        speakerName: isSameLanguage ? 'Direct Voice Call' : 'Direct Call (Translation Off)',
        isSelf: false,
        sourceLangCode: myLang.code,
        targetLangCode: peerLang.code,
        originalText: isSameLanguage
            ? '📞 Direct Voice Call Active: Both participants speak ${myLang.nativeName} (${myLang.englishName}). WebRTC audio streaming directly with zero AI translation.'
            : '📞 Direct Voice Call Active: AI translation is turned off. Direct WebRTC audio active.',
        translatedText: isSameLanguage
            ? 'উভয় ব্যবহারকারীর ভাষা একই (${myLang.nativeName})। সরাসরি আসল কণ্ঠে কোনো ট্রান্সলেশন ছাড়াই কথা বলুন।'
            : 'সরাসরি ভয়েস কল সক্রিয় রয়েছে।',
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        geminiState: GeminiLiveState.ready,
        audioMode: CallAudioMode.originalOnly,
        transcripts: [directBubble],
        hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
      );
      return;
    }

    final connectedWs = await _geminiTranslator.connect(
      langA: myLang,
      langB: peerLang,
      bidirectional: state.isBidirectionalSingleDevice,
    );

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
      translatedText:
          '${myLang.flagEmoji} ${myLang.nativeName} ⇄ ${peerLang.flagEmoji} ${peerLang.nativeName} রিয়েল-টাইম ভয়েস ট্রান্সলেশন চালু হয়েছে। যেকোনো ভাষায় কথা বলুন!',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      geminiState:
          connectedWs ? GeminiLiveState.listening : GeminiLiveState.ready,
      transcripts: [initialBubble],
      hasApiKey: GeminiLiveTranslator.getSavedApiKey().isNotEmpty,
    );
  }

  /// Simulates speaking a phrase in [sourceLangCode] and translating it to [targetLangCode]
  /// (Allows testing any N x N language pair like Bangla <-> English, English <-> Spanish, Spanish <-> Bangla immediately!)
  Future<void> triggerSampleTranslation({
    required String sourceLangCode,
    required String targetLangCode,
    required bool isFromSelf,
  }) async {
    final src = CallLanguageRegistry.fromCode(sourceLangCode);
    final tgt = CallLanguageRegistry.fromCode(targetLangCode);

    state = state.copyWith(geminiState: GeminiLiveState.translating);

    await Future.delayed(const Duration(milliseconds: 350));

    state = state.copyWith(geminiState: GeminiLiveState.speaking);
    final tone = GeminiLiveTranslator.generateTestVoiceTonePcm24k(durationMs: 450);
    _audioPipeline.feedTranslatedAiPcm(tone);

    final samplePhrases = _getSamplePhraseForLanguage(src.code);
    final translatedPhrases = _getSamplePhraseForLanguage(tgt.code);

    final index = state.transcripts.length % samplePhrases.length;

    final entry = LiveTranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      speakerId: isFromSelf ? 'self' : 'peer',
      speakerName: isFromSelf
          ? 'You (${src.shortBadge})'
          : '${state.activeSession?.peerName ?? "Peer"} (${src.shortBadge})',
      isSelf: isFromSelf,
      sourceLangCode: src.code,
      targetLangCode: tgt.code,
      originalText: samplePhrases[index],
      translatedText: translatedPhrases[index],
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      transcripts: [...state.transcripts, entry],
    );

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(geminiState: GeminiLiveState.listening);
  }

  List<String> _getSamplePhraseForLanguage(String code) {
    final baseCode = code.split('-').first.toLowerCase();
    switch (baseCode) {
      case 'bn':
        return [
          'হ্যালো! আপনি কেমন আছেন? আমাদের প্রজেক্টের কাজ কেমন চলছে?',
          'আমি বাংলায় কথা বলছি এবং আপনি আপনার নিজের ভাষায় সাথে সাথে শুনতে পাচ্ছেন।',
          'আগামীকাল সকাল ১০টায় আমরা মিটিং শুরু করব, ধন্যবাদ!',
        ];
      case 'en':
        return [
          'Hello! How are you doing? How is our project progressing?',
          'I am speaking in my language and you are hearing it in your own language in real time.',
          'We will start the meeting tomorrow at 10 AM, thank you!',
        ];
      case 'es':
        return [
          '¡Hola! ¿Cómo estás? ¿Cómo avanza nuestro proyecto?',
          'Estoy hablando en mi idioma y lo estás escuchando en tu propio idioma en tiempo real.',
          'Comenzaremos la reunión mañana a las 10 de la mañana, ¡muchas gracias!',
        ];
      case 'ar':
        return [
          'مرحباً! كيف حالك؟ كيف يسير مشروعنا؟',
          'أنا أتحدث بلغتي وأنت تسمعها بلغتك الخاصة في الوقت الفعلي.',
          'سنبدأ الاجتماع غداً في تمام الساعة العاشرة صباحاً، شكراً لك!',
        ];
      case 'hi':
        return [
          'नमस्ते! आप कैसे हैं? हमारे प्रोजेक्ट का काम कैसा चल रहा है?',
          'मैं अपनी भाषा में बोल रहा हूँ और आप इसे रियल-टाइम में अपनी भाषा में सुन रहे हैं।',
          'हम कल सुबह 10 बजे मीटिंग शुरू करेंगे, धन्यवाद!',
        ];
      case 'ja':
        return [
          'こんにちは！お元気ですか？プロジェクトの進捗はいかがでしょうか？',
          '私は自分の言語で話していますが、リアルタイムであなたの言語に翻訳されて聞こえています。',
          '明日の午前10時に会議を始めます。ありがとうございます！',
        ];
      case 'fr':
        return [
          'Bonjour ! Comment allez-vous ? Comment avance notre projet ?',
          'Je parle dans ma langue et vous l\'entendez dans votre propre langue en temps réel.',
          'Nous commencerons la réunion demain à 10h00, merci beaucoup !',
        ];
      case 'de':
        return [
          'Hallo! Wie geht es Ihnen? Wie kommt unser Projekt voran?',
          'Ich spreche in meiner Sprache und Sie hören es in Echtzeit in Ihrer eigenen Sprache.',
          'Wir beginnen das Treffen morgen um 10 Uhr, vielen Dank!',
        ];
      case 'zh':
        return [
          '你好！你最近怎么样？我们的项目进展如何？',
          '我用我的语言说话，你正在实时听到用你的语言翻译的声音。',
          '我们明天上午10点开始开会，非常感谢！',
        ];
      default:
        final lang = CallLanguageRegistry.fromCode(code);
        return [
          '[${lang.nativeName}] Hello! How are you doing? How is our project progressing?',
          '[${lang.nativeName}] Real-time voice translation is active between ${lang.englishName} and your language.',
          '[${lang.nativeName}] We will start the meeting tomorrow at 10 AM, thank you!',
        ];
    }
  }

  void toggleMute() {
    final nextMute = !state.isMuted;
    _audioPipeline.setMuted(nextMute);
    _webrtcClient.setMicrophoneMute(nextMute);
    if (nextMute) {
      _geminiTranslator.sendAudioStreamEnd();
    }
    state = state.copyWith(isMuted: nextMute);
  }

  Future<void> toggleSpeakerphone() async {
    final nextSpeaker = !state.isSpeakerphoneOn;
    await _audioPipeline.setSpeakerphone(nextSpeaker);
    state = state.copyWith(isSpeakerphoneOn: nextSpeaker);
  }

  Future<void> setAudioMode(CallAudioMode mode) async {
    await _audioPipeline.setAudioMode(mode);
    if (mode == CallAudioMode.translatedOnly) {
      _webrtcClient.setRemoteAudioVolume(0.0);
    } else if (mode == CallAudioMode.ducking) {
      _webrtcClient.setRemoteAudioVolume(0.15);
    } else {
      _webrtcClient.setRemoteAudioVolume(1.0);
    }
    state = state.copyWith(audioMode: mode);
  }

  void toggleTranslationEnabled(bool enabled) async {
    state = state.copyWith(translationEnabled: enabled);
    if (!enabled) {
      setAudioMode(CallAudioMode.originalOnly);
      await _geminiTranslator.disconnect();
    } else {
      if (state.myLangCode != state.peerLangCode) {
        setAudioMode(CallAudioMode.translatedOnly);
        if (!_geminiTranslator.isConnected) {
          await _geminiTranslator.connect(
            langA: state.myLanguage,
            langB: state.peerLanguage,
            bidirectional: state.isBidirectionalSingleDevice,
          );
        }
      } else {
        setAudioMode(CallAudioMode.originalOnly);
      }
    }
  }

  Future<void> endCall({bool recordAsMissed = false}) async {
    final current = state.activeSession;
    final duration = state.elapsedSeconds;

    if (current != null) {
      await CallKitService().endCall(current.callId);
      await repo.updateCallStatus(
        current.callId,
        recordAsMissed ? CallStateStatus.missed : CallStateStatus.ended,
      );

      final record = CallHistoryRecord(
        callId: current.callId,
        peerId: current.peerId,
        peerName: current.peerName,
        peerAvatar: current.peerAvatar,
        peerPhone: current.peerPhone,
        timestamp: DateTime.now(),
        durationSeconds: duration,
        isIncoming: current.isIncoming,
        isMissed: recordAsMissed,
        translationEnabled: state.translationEnabled,
        myLangCode: state.myLangCode,
        peerLangCode: state.peerLangCode,
      );

      await repo.addCallHistoryRecord(record);
    }

    await _cleanupActiveResources();

    state = state.copyWith(
      clearSession: true,
      elapsedSeconds: 0,
      micRmsLevel: 0.0,
      geminiState: GeminiLiveState.ready,
      callHistory: repo.getCallHistory(),
    );
  }

  Future<void> _cleanupActiveResources() async {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _ringingAutoAnswerTimer?.cancel();
    _ringingAutoAnswerTimer = null;

    await _micStreamSub?.cancel();
    await _micRmsSub?.cancel();
    await _geminiAudioSub?.cancel();
    await _geminiStateSub?.cancel();
    await _geminiTranscriptSub?.cancel();
    await _geminiInterruptedSub?.cancel();
    await _firestoreCallSub?.cancel();

    await _webrtcClient.endCall();
    await _geminiTranslator.disconnect();
    await _audioPipeline.dispose();
  }
}
