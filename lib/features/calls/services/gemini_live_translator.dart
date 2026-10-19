import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/network_tracker.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class BillingUpdateEvent {
  final int billedMinutes;
  final int remainingMinutes;
  final bool lowBalanceWarning;
  final bool isCallee;
  final bool isExhausted;

  const BillingUpdateEvent({
    required this.billedMinutes,
    required this.remainingMinutes,
    required this.lowBalanceWarning,
    this.isCallee = false,
    this.isExhausted = false,
  });
}

class GeminiModelPreset {
  final String id;
  final String title;
  final String subtitle;

  const GeminiModelPreset({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class GeminiLiveTranslator {
  static const String prefApiKey = 'gemini_live_api_key';
  static const String prefModelId = 'gemini_live_model_id';
  static const String prefVoiceName = 'gemini_live_voice_name';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static String? _cachedApiKey;

  /// Initializes secure storage and migrates any legacy plaintext key out of SharedPreferences
  static Future<void> initSecureStorage() async {
    try {
      _cachedApiKey = await _secureStorage.read(key: prefApiKey);

      // Safe migration: If key was previously in unencrypted SharedPreferences, move it to secure storage
      final legacy = SharedPref.instance.getString(prefApiKey)?.trim();
      if ((_cachedApiKey == null || _cachedApiKey!.isEmpty) && legacy != null && legacy.isNotEmpty) {
        _cachedApiKey = legacy;
        await _secureStorage.write(key: prefApiKey, value: legacy);
        await SharedPref.instance.remove(prefApiKey);
      } else if (legacy != null) {
        await SharedPref.instance.remove(prefApiKey);
      }
    } catch (e, st) {
      debugPrint('[GeminiLiveTranslator] initSecureStorage error: $e\n$st');
    }
  }

  static const List<GeminiModelPreset> modelPresets = [
    GeminiModelPreset(
      id: 'models/gemini-3.5-live-translate-preview',
      title: 'Gemini 3.5 Live Translate',
      subtitle:
          'Low-latency, real-time speech-to-speech translation between 70+ languages',
    ),
  ];

  static const List<String> availableVoices = [
    'Aoede',
    'Puck',
    'Kore',
    'Charon',
    'Fenrir',
  ];

  static String getSavedApiKey() {
    return _cachedApiKey ?? '';
  }

  static Future<void> saveApiKey(String key) async {
    _cachedApiKey = key.trim();
    try {
      await _secureStorage.write(key: prefApiKey, value: key.trim());
      // Ensure plaintext SharedPreferences never holds the secret key
      await SharedPref.instance.remove(prefApiKey);
    } catch (e, st) {
      debugPrint('[GeminiLiveTranslator] saveApiKey secure storage error: $e\n$st');
    }
  }

  static String getSavedModelId() {
    final saved = SharedPref.instance.getString(prefModelId)?.trim();
    if (saved == null || saved.isEmpty) {
      return modelPresets.first.id;
    }
    return saved;
  }

  static Future<void> saveModelId(String modelId) async {
    final normalized =
        modelId.startsWith('models/') ? modelId.trim() : 'models/${modelId.trim()}';
    await SharedPref.instance.setString(prefModelId, normalized);
  }

  static String getSavedVoiceName() =>
      SharedPref.instance.getString(prefVoiceName)?.trim() ?? 'Aoede';

  static Future<void> saveVoiceName(String voice) async =>
      await SharedPref.instance.setString(prefVoiceName, voice.trim());

  WebSocket? _ws;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _setupCompleted = false;
  bool _disposed = false;

  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  bool _isExplicitDisconnect = false;
  bool _isReconnecting = false;

  CallLanguage _langA = CallLanguageRegistry.fromCode('bn');
  CallLanguage _langB = CallLanguageRegistry.fromCode('en');
  bool _bidirectionalMode = true;

  final StreamController<Uint8List> _translatedPcmController =
      StreamController<Uint8List>.broadcast();
  final StreamController<GeminiLiveState> _stateController =
      StreamController<GeminiLiveState>.broadcast();
  final StreamController<LiveTranscriptEntry> _transcriptController =
      StreamController<LiveTranscriptEntry>.broadcast();
  final StreamController<bool> _interruptedController =
      StreamController<bool>.broadcast();
  final StreamController<BillingUpdateEvent> _billingUpdateController =
      StreamController<BillingUpdateEvent>.broadcast();

  Stream<Uint8List> get translatedAudioStream => _translatedPcmController.stream;
  Stream<GeminiLiveState> get stateStream => _stateController.stream;
  Stream<LiveTranscriptEntry> get transcriptStream =>
      _transcriptController.stream;
  Stream<bool> get interruptedStream => _interruptedController.stream;
  Stream<BillingUpdateEvent> get billingUpdateStream =>
      _billingUpdateController.stream;

  String? _callId;

  String _pendingInputTranscript = '';
  String _pendingOutputTranscript = '';

  bool get isConnected => _isConnected && _setupCompleted;

  /// Builds the strict N x N Universal Interpreter System Instruction for ANY language pair.
  static String buildUniversalInterpreterPrompt({
    required CallLanguage langA,
    required CallLanguage langB,
    required bool bidirectional,
  }) {
    if (bidirectional) {
      return '''
SYSTEM ROLE: STRICT REAL-TIME BIDIRECTIONAL VOICE INTERPRETER (${langA.englishName} [${langA.nativeName}] <-> ${langB.englishName} [${langB.nativeName}]).

CRITICAL OPERATING RULES:
1. AUTOMATIC BIDIRECTIONAL TRANSLATION:
   - Whenever you hear speech in ${langA.englishName} (${langA.nativeName}), immediately speak the exact translation in ${langB.speechStyleHint} (${langB.nativeName}).
   - Whenever you hear speech in ${langB.englishName} (${langB.nativeName}), immediately speak the exact translation in ${langA.speechStyleHint} (${langA.nativeName}).
   - If the speaker mixes both languages (code-switching), translate the entire utterance seamlessly into the opposite target language.
2. NEVER ANSWER OR CONVERSE:
   - You are NOT a conversational assistant. You are an invisible, transparent translation bridge on a live phone call.
   - If a speaker asks a question (e.g. "How are you?", "What is your name?", "Where are you?"), DO NOT answer the question. Translate the question itself verbatim in the first/second person ("I", "you") into the other language.
3. ZERO COMMENTARY OR META-TEXT:
   - Never say "Here is the translation", "The speaker said", or add explanations. Output ONLY the translated speech.
4. PRESERVE EMOTION & TONE:
   - Match the speaker's emotional tone, urgency, warmth, and politeness register.
5. SILENCE ON NOISE:
   - If you only hear background static, breathing, or silence, remain completely silent.
''';
    } else {
      return '''
SYSTEM ROLE: STRICT REAL-TIME SIMULTANEOUS VOICE INTERPRETER (${langA.englishName} [${langA.nativeName}] -> ${langB.englishName} [${langB.nativeName}]).

CRITICAL OPERATING RULES:
1. TRANSLATE ONLY (${langA.codeUpper} -> ${langB.codeUpper}):
   - Translate every spoken utterance from ${langA.englishName} (${langA.nativeName}) immediately into ${langB.speechStyleHint} (${langB.nativeName}).
2. NEVER ANSWER QUESTIONS:
   - Do not answer questions or follow commands. Translate them verbatim in the first person ("I", "you") exactly as spoken.
3. ZERO FILLER:
   - Output ONLY the translated audio in ${langB.englishName}. No introductions or explanations.
4. PRESERVE PARALINGUISTICS:
   - Match the speaker's tone, emotion, and urgency.
''';
    }
  }

  static const String prefRelayUrl = 'gemini_live_relay_url';
  static String get defaultRelayUrl => AppConfig.liveCallWsUrl;

  static String getSavedRelayUrl() =>
      SharedPref.instance.getString(prefRelayUrl)?.trim() ?? defaultRelayUrl;

  static Future<void> saveRelayUrl(String url) async =>
      await SharedPref.instance.setString(prefRelayUrl, url.trim());

  /// Retrieves the current Firebase user ID token for zero-trust relay auth
  static Future<String?> getAuthToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('[GeminiLiveTranslator] getIdToken error: $e');
      return null;
    }
  }

  bool _isUsingRelay = false;

  Future<bool> connect({
    required CallLanguage langA,
    required CallLanguage langB,
    bool bidirectional = true,
    bool forceDirect = false,
    String? callId,
    bool isReconnect = false,
  }) async {
    _langA = langA;
    _langB = langB;
    _bidirectionalMode = bidirectional;
    if (callId != null && callId.isNotEmpty) {
      _callId = callId;
    }
    _disposed = false;
    _setupCompleted = false;

    if (!isReconnect) {
      _isExplicitDisconnect = false;
      _isReconnecting = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempts = 0;
    }

    _stateController.add(GeminiLiveState.connecting);

    final modelId = getSavedModelId();
    final voiceName = getSavedVoiceName();
    final relayUrl = getSavedRelayUrl();
    final apiKey = getSavedApiKey();

    // 1. Try Backend Relay Server first (Zero-Trust Architecture) unless forced direct
    if (!forceDirect && relayUrl.isNotEmpty) {
      try {
        debugPrint('Connecting to Gemini Live Backend Relay: $relayUrl');
        final idToken = await getAuthToken();
        final headers = <String, dynamic>{
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        };
        _ws = await WebSocket.connect(
          relayUrl,
          headers: headers,
        ).timeout(
          const Duration(seconds: 4),
        );
        _ws!.pingInterval = const Duration(seconds: 15);
        _isConnected = true;
        _isUsingRelay = true;

        _wsSubscription = _ws!.listen(
          _handleServerFrame,
          onError: (err) {
            debugPrint('Gemini Relay WS Error: $err');
            if (!_disposed && !_isExplicitDisconnect) {
              _triggerReconnect();
            }
          },
          onDone: () {
            _isConnected = false;
            _setupCompleted = false;
            final code = _ws?.closeCode;
            debugPrint('Relay WS closed (code: $code)');
            if (!_disposed && !_isExplicitDisconnect) {
              if (code == 4402) {
                debugPrint('[GeminiLiveTranslator] Relay closed with code 4402 (MINUTES_EXHAUSTED / INSUFFICIENT_BALANCE)');
                _billingUpdateController.add(const BillingUpdateEvent(
                  billedMinutes: 0,
                  remainingMinutes: 0,
                  lowBalanceWarning: false,
                  isExhausted: true,
                ));
                _stateController.add(GeminiLiveState.disconnected);
              } else if (code == 4403) {
                debugPrint('[GeminiLiveTranslator] Relay rejected with code 4403 (MISSING_API_KEY)');
                _stateController.add(GeminiLiveState.error);
                if (apiKey.isNotEmpty) {
                  debugPrint('Attempting auto-fallback to direct Gemini endpoint with saved API key');
                  connect(langA: _langA, langB: _langB, forceDirect: true, callId: _callId);
                  return;
                }
              } else if (code == 1000) {
                _stateController.add(GeminiLiveState.disconnected);
              } else {
                _triggerReconnect();
              }
            }
          },
        );

        // Send setup handshake to Backend Relay with verified user token
        final setupPayload = {
          'type': 'setup',
          if (idToken != null) 'token': idToken,
          if (_callId != null && _callId!.isNotEmpty) 'callId': _callId,
          'model': modelId,
          'voice': voiceName,
          'autoDetect': true,
          'langA': {
            'code': _langA.code,
            'englishName': _langA.englishName,
            'nativeName': _langA.nativeName,
            'speechStyleHint': _langA.speechStyleHint,
          },
          'langB': {
            'code': _langB.code,
            'englishName': _langB.englishName,
            'nativeName': _langB.nativeName,
            'speechStyleHint': _langB.speechStyleHint,
          },
        };

        _ws!.add(jsonEncode(setupPayload));
        debugPrint('Sent setup handshake to Backend Relay');
        return true;
      } catch (relayErr) {
        debugPrint('Backend Relay connection attempt failed: $relayErr');
        // If relay failed and no direct API key is set, set error state
        if (apiKey.isEmpty) {
          if (!isReconnect) {
            _stateController.add(GeminiLiveState.error);
          }
          return false;
        }
      }
    }

    // 2. Direct Fallback to Google Live endpoint if API key exists locally
    if (apiKey.isEmpty) {
      if (!isReconnect) {
        _stateController.add(GeminiLiveState.error);
      }
      return false;
    }

    _isUsingRelay = false;
    final uriV1Beta = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    try {
      _ws = await WebSocket.connect(uriV1Beta.toString()).timeout(
        const Duration(seconds: 8),
      );
      _ws!.pingInterval = const Duration(seconds: 15);
      _isConnected = true;

      _wsSubscription = _ws!.listen(
        _handleServerFrame,
        onError: (err) {
          debugPrint('Gemini Live WS Error: $err');
          if (!_disposed && !_isExplicitDisconnect) {
            _triggerReconnect();
          }
        },
        onDone: () {
          _isConnected = false;
          _setupCompleted = false;
          final code = _ws?.closeCode;
          if (!_disposed && !_isExplicitDisconnect) {
            if (code == 1000) {
              _stateController.add(GeminiLiveState.disconnected);
            } else {
              _triggerReconnect();
            }
          }
        },
      );

      // Send setup frame
      final setupPayload = {
        'setup': {
          'model': modelId,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'temperature': 0.2,
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': voiceName,
                },
              },
            },
          },
          'systemInstruction': {
            'parts': [
              {
                'text': buildUniversalInterpreterPrompt(
                  langA: _langA,
                  langB: _langB,
                  bidirectional: _bidirectionalMode,
                ),
              },
            ],
          },
          'realtimeInputConfig': {
            'automaticActivityDetection': {
              'disabled': false,
              'startOfSpeechSensitivity': 'START_SENSITIVITY_HIGH',
              'endOfSpeechSensitivity': 'END_SENSITIVITY_HIGH',
              'prefixPaddingMs': 40,
              'silenceDurationMs': 450,
            },
          },
          'inputAudioTranscription': {},
          'outputAudioTranscription': {},
        },
      };

      _ws!.add(jsonEncode(setupPayload));
      return true;
    } catch (e) {
      debugPrint('Failed to connect Gemini Live WS: $e');
      _isConnected = false;
      if (!isReconnect) {
        _stateController.add(GeminiLiveState.error);
      }
      return false;
    }
  }

  void _triggerReconnect() {
    if (_disposed || _isExplicitDisconnect || _isReconnecting) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('[GeminiLiveTranslator] Max reconnect attempts ($maxReconnectAttempts) exhausted. Falling back to offline direct audio.');
      _isReconnecting = false;
      _stateController.add(GeminiLiveState.disconnected);
      _stateController.add(GeminiLiveState.error);
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    final delaySeconds = 1 << (_reconnectAttempts - 1); // 1s, 2s, 4s
    debugPrint('[GeminiLiveTranslator] Connection dropped mid-call. Retrying in ${delaySeconds}s (attempt $_reconnectAttempts/$maxReconnectAttempts)...');
    _stateController.add(GeminiLiveState.connecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      _isReconnecting = false;
      if (_disposed || _isExplicitDisconnect) return;
      try {
        await _wsSubscription?.cancel();
        _wsSubscription = null;
        try {
          await _ws?.close();
        } catch (_) {}
        _ws = null;

        debugPrint('[GeminiLiveTranslator] Executing reconnect attempt #$_reconnectAttempts...');
        final success = await connect(
          langA: _langA,
          langB: _langB,
          bidirectional: _bidirectionalMode,
          callId: _callId,
          isReconnect: true,
        );
        if (success) {
          debugPrint('[GeminiLiveTranslator] Reconnection #$_reconnectAttempts established successfully.');
        } else {
          debugPrint('[GeminiLiveTranslator] Reconnection #$_reconnectAttempts failed.');
          if (!_disposed && !_isExplicitDisconnect) {
            _triggerReconnect();
          }
        }
      } catch (e) {
        debugPrint('[GeminiLiveTranslator] Reconnect exception: $e');
        if (!_disposed && !_isExplicitDisconnect) {
          _triggerReconnect();
        }
      }
    });
  }

  /// Dynamically switch language pair mid-call (reconnects session with new N x N pair)
  Future<void> updateLanguagePair({
    required CallLanguage newLangA,
    required CallLanguage newLangB,
    bool? bidirectional,
  }) async {
    _langA = newLangA;
    _langB = newLangB;
    if (bidirectional != null) _bidirectionalMode = bidirectional;

    await disconnect();
    await connect(
      langA: _langA,
      langB: _langB,
      bidirectional: _bidirectionalMode,
    );
  }

  /// Stream 16kHz PCM16 mono chunk from microphone to Gemini Live
  void sendAudioChunk(Uint8List pcm16kBytes) {
    if (!_isConnected || !_setupCompleted || _ws == null || pcm16kBytes.isEmpty) {
      return;
    }
    try {
      if (_isUsingRelay) {
        // Send binary PCM directly to Backend Relay for ultra-low latency & zero base64 overhead
        _ws!.add(pcm16kBytes);
      } else {
        final frame = {
          'realtimeInput': {
            'mediaChunks': [
              {
                'mimeType': 'audio/pcm;rate=16000',
                'data': base64Encode(pcm16kBytes),
              },
            ],
          },
        };
        _ws!.add(jsonEncode(frame));
      }
      NetworkTracker.recordBytesSent(pcm16kBytes.length);
    } catch (e) {
      debugPrint('Error sending audio chunk: $e');
    }
  }

  /// Signal end of current speech turn if user pauses or mutes
  void sendAudioStreamEnd() {
    if (!_isConnected || !_setupCompleted || _ws == null) return;
    try {
      _ws!.add(jsonEncode({
        'realtimeInput': {
          'audioStreamEnd': true,
        },
      }));
    } catch (e, st) {
      debugPrint('[GeminiLiveTranslator] signalAudioStreamEnd error: $e\n$st');
    }
  }

  void _handleServerFrame(dynamic rawFrame) {
    if (_disposed) return;
    try {
      final String jsonStr;
      if (rawFrame is String) {
        jsonStr = rawFrame;
      } else if (rawFrame is List<int>) {
        jsonStr = utf8.decode(rawFrame, allowMalformed: true);
      } else {
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      // 0. Handle Backend Relay Events
      if (data.containsKey('type')) {
        final eventType = data['type']?.toString();
        if (eventType == 'ready') {
          _setupCompleted = true;
          _reconnectAttempts = 0;
          _isReconnecting = false;
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          final role = data['role']?.toString();
          if (role == 'callee') {
            _billingUpdateController.add(const BillingUpdateEvent(
              billedMinutes: 0,
              remainingMinutes: 9999,
              lowBalanceWarning: false,
              isCallee: true,
            ));
          }
          _stateController.add(GeminiLiveState.listening);
          return;
        } else if (eventType == 'billing_update') {
          final billed = data['billedMinutes'] as int? ?? 1;
          final remaining = data['remainingMinutes'] as int? ?? 0;
          final isWarning = data['lowBalanceWarning'] as bool? ?? (remaining <= 2);
          final role = data['role']?.toString();
          _billingUpdateController.add(BillingUpdateEvent(
            billedMinutes: billed,
            remainingMinutes: remaining,
            lowBalanceWarning: isWarning,
            isCallee: role == 'callee',
          ));
          return;
        } else if (eventType == 'audio_out') {
          final b64Audio = data['data']?.toString();
          if (b64Audio != null && b64Audio.isNotEmpty) {
            final audioBytes = base64Decode(b64Audio);
            if (audioBytes.isNotEmpty) {
              NetworkTracker.recordBytesReceived(audioBytes.length);
              _stateController.add(GeminiLiveState.speaking);
              _translatedPcmController.add(audioBytes);
            }
          }
          return;
        } else if (eventType == 'transcript') {
          final text = data['text']?.toString() ?? '';
          if (text.isNotEmpty) {
            _transcriptController.add(
              LiveTranscriptEntry(
                id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
                speakerId: 'ai_relay',
                speakerName: 'AI Interpreter',
                isSelf: false,
                sourceLangCode: _langA.code,
                targetLangCode: _langB.code,
                originalText: '',
                translatedText: text,
                timestamp: DateTime.now(),
              ),
            );
          }
          return;
        } else if (eventType == 'interrupted') {
          _interruptedController.add(true);
          _stateController.add(GeminiLiveState.listening);
          return;
        } else if (eventType == 'error') {
          final errCode = data['code']?.toString();
          debugPrint('Backend Relay Error: ${data['message']} (code: $errCode)');
          if (errCode == 'MINUTES_EXHAUSTED' || errCode == 'INSUFFICIENT_BALANCE') {
            _billingUpdateController.add(const BillingUpdateEvent(
              billedMinutes: 0,
              remainingMinutes: 0,
              lowBalanceWarning: false,
              isExhausted: true,
            ));
          }
          _stateController.add(GeminiLiveState.error);
          if (errCode == 'MISSING_API_KEY') {
            final savedKey = getSavedApiKey();
            if (savedKey.isNotEmpty) {
              debugPrint('MISSING_API_KEY received: falling back to direct API key');
              connect(langA: _langA, langB: _langB, forceDirect: true, callId: _callId);
            }
          }
          return;
        }
      }

      if (data.containsKey('setupComplete')) {
        _setupCompleted = true;
        _reconnectAttempts = 0;
        _isReconnecting = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _stateController.add(GeminiLiveState.listening);
        return;
      }

      final serverContent = data['serverContent'] as Map<String, dynamic>?;
      if (serverContent == null) return;

      // 1. Check interruption
      if (serverContent['interrupted'] == true) {
        _interruptedController.add(true);
        _stateController.add(GeminiLiveState.listening);
      }

      // 2. Parse input transcription (what the speaker said)
      final inputTrans =
          serverContent['inputTranscription'] as Map<String, dynamic>?;
      if (inputTrans != null && inputTrans['text'] != null) {
        final chunk = inputTrans['text'].toString();
        _pendingInputTranscript += chunk;
        _stateController.add(GeminiLiveState.translating);
      }

      // 3. Parse output transcription (translated subtitle)
      final outputTrans =
          serverContent['outputTranscription'] as Map<String, dynamic>?;
      if (outputTrans != null && outputTrans['text'] != null) {
        final chunk = outputTrans['text'].toString();
        _pendingOutputTranscript += chunk;
      }

      // 4. Parse modelTurn audio (24kHz PCM16 mono) & text parts
      final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
      if (modelTurn != null) {
        final parts = modelTurn['parts'] as List<dynamic>?;
        if (parts != null) {
          for (final part in parts) {
            if (part is! Map<String, dynamic>) continue;

            if (part['text'] != null) {
              final textPart = part['text'].toString();
              if (_pendingOutputTranscript.isEmpty) {
                _pendingOutputTranscript += textPart;
              }
            }

            final inlineData = part['inlineData'] as Map<String, dynamic>?;
            if (inlineData != null && inlineData['data'] != null) {
              final mimeType = inlineData['mimeType']?.toString() ?? '';
              if (mimeType.contains('audio/pcm')) {
                final audioBytes =
                    base64Decode(inlineData['data'].toString());
                if (audioBytes.isNotEmpty) {
                  _stateController.add(GeminiLiveState.speaking);
                  _translatedPcmController.add(audioBytes);
                }
              }
            }
          }
        }
      }

      // 5. Emit live transcript bubble update
      if (_pendingInputTranscript.trim().isNotEmpty ||
          _pendingOutputTranscript.trim().isNotEmpty) {
        final isTurnComplete = serverContent['turnComplete'] == true;
        final entry = LiveTranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          speakerId: 'live_speaker',
          speakerName: '${_langA.shortBadge} ⇄ ${_langB.shortBadge}',
          isSelf: true,
          sourceLangCode: _langA.code,
          targetLangCode: _langB.code,
          originalText: _pendingInputTranscript.trim().isEmpty
              ? '...'
              : _pendingInputTranscript.trim(),
          translatedText: _pendingOutputTranscript.trim().isEmpty
              ? 'Translating...'
              : _pendingOutputTranscript.trim(),
          timestamp: DateTime.now(),
          isFinal: isTurnComplete,
        );

        if (isTurnComplete) {
          _transcriptController.add(entry);
          _pendingInputTranscript = '';
          _pendingOutputTranscript = '';
          _stateController.add(GeminiLiveState.listening);
        }
      } else if (serverContent['turnComplete'] == true) {
        _stateController.add(GeminiLiveState.listening);
      }
    } catch (e) {
      debugPrint('Error parsing Gemini frame: $e');
    }
  }

  /// Generates a realistic confirmation tone / chime in 24kHz PCM16 for test feedback
  static Uint8List generateTestVoiceTonePcm24k({int durationMs = 420}) {
    const sampleRate = 24000;
    final totalSamples = (sampleRate * durationMs) ~/ 1000;
    final byteData = ByteData(totalSamples * 2);
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freq = i < totalSamples ~/ 2 ? 523.25 : 659.25; // C5 -> E5 pleasant chime
      final envelope = math.sin((i / totalSamples) * math.pi);
      final sample = (math.sin(2 * math.pi * freq * t) * 0.25 * envelope * 32767)
          .round()
          .clamp(-32768, 32767);
      byteData.setInt16(i * 2, sample, Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> disconnect() async {
    _isExplicitDisconnect = true;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _isConnected = false;
    _setupCompleted = false;
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    try {
      await _ws?.close();
    } catch (e, st) {
      debugPrint('[GeminiLiveTranslator] _ws.close error: $e\n$st');
    }
    _ws = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _translatedPcmController.close();
    await _stateController.close();
    await _transcriptController.close();
    await _interruptedController.close();
    await _billingUpdateController.close();
  }
}
