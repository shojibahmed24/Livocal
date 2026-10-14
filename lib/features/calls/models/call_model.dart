import 'dart:convert';
import 'package:whatsapp_clone/features/calls/models/call_language.dart';

enum CallStateStatus {
  idle('idle'),
  dialing('dialing'),
  ringing('ringing'),
  connectingAi('connecting_ai'),
  connected('connected'),
  ended('ended'),
  rejected('rejected'),
  missed('missed'),
  busy('busy');

  final String value;
  const CallStateStatus(this.value);

  factory CallStateStatus.fromValue(String? value) {
    return CallStateStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CallStateStatus.idle,
    );
  }
}

enum CallAudioMode {
  translatedOnly('translated_only', '🤖 AI Only'),
  ducking('ducking', '🔉 15% Ducking'),
  originalOnly('original_only', '🗣️ Original');

  final String value;
  final String label;
  const CallAudioMode(this.value, this.label);
}

enum GeminiLiveState {
  disconnected('Disconnected'),
  connecting('Connecting Gemini Live AI...'),
  ready('AI Interpreter Ready'),
  listening('Listening & Translating...'),
  translating('Gemini 3.5 Live Translating...'),
  speaking('Speaking Translated Audio...'),
  error('AI Connection Warning');

  final String label;
  const GeminiLiveState(this.label);
}

class LiveTranscriptEntry {
  final String id;
  final String speakerId;
  final String speakerName;
  final bool isSelf;
  final String sourceLangCode;
  final String targetLangCode;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;
  final bool isFinal;

  const LiveTranscriptEntry({
    required this.id,
    required this.speakerId,
    required this.speakerName,
    required this.isSelf,
    required this.sourceLangCode,
    required this.targetLangCode,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
    this.isFinal = true,
  });

  CallLanguage get sourceLanguage => CallLanguageRegistry.fromCode(sourceLangCode);
  CallLanguage get targetLanguage => CallLanguageRegistry.fromCode(targetLangCode);

  LiveTranscriptEntry copyWith({
    String? originalText,
    String? translatedText,
    bool? isFinal,
  }) {
    return LiveTranscriptEntry(
      id: id,
      speakerId: speakerId,
      speakerName: speakerName,
      isSelf: isSelf,
      sourceLangCode: sourceLangCode,
      targetLangCode: targetLangCode,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      timestamp: timestamp,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'speakerId': speakerId,
        'speakerName': speakerName,
        'isSelf': isSelf,
        'sourceLangCode': sourceLangCode,
        'targetLangCode': targetLangCode,
        'originalText': originalText,
        'translatedText': translatedText,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isFinal': isFinal,
      };

  factory LiveTranscriptEntry.fromMap(Map<String, dynamic> map, String ownId) {
    final speakerId = map['speakerId'] as String? ?? '';
    return LiveTranscriptEntry(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      speakerId: speakerId,
      speakerName: map['speakerName'] as String? ?? 'Speaker',
      isSelf: speakerId == ownId,
      sourceLangCode: map['sourceLangCode'] as String? ?? 'bn',
      targetLangCode: map['targetLangCode'] as String? ?? 'en',
      originalText: map['originalText'] as String? ?? '',
      translatedText: map['translatedText'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isFinal: map['isFinal'] as bool? ?? true,
    );
  }
}

class CallSession {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String callerPhone;
  final String calleeId;
  final String calleeName;
  final String calleeAvatar;
  final String calleePhone;
  final String callerLangCode;
  final String calleeLangCode;
  final bool translationEnabled;
  final CallStateStatus status;
  final bool isIncoming;
  final DateTime createdAt;
  final DateTime? connectedAt;

  const CallSession({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.callerPhone,
    required this.calleeId,
    required this.calleeName,
    required this.calleeAvatar,
    required this.calleePhone,
    required this.callerLangCode,
    required this.calleeLangCode,
    this.translationEnabled = true,
    this.status = CallStateStatus.dialing,
    this.isIncoming = false,
    required this.createdAt,
    this.connectedAt,
  });

  String get peerId => isIncoming ? callerId : calleeId;
  String get peerName => isIncoming ? callerName : calleeName;
  String get peerAvatar => isIncoming ? callerAvatar : calleeAvatar;
  String get peerPhone => isIncoming ? callerPhone : calleePhone;

  String get myLangCode => isIncoming ? calleeLangCode : callerLangCode;
  String get peerLangCode => isIncoming ? callerLangCode : calleeLangCode;

  CallLanguage get myLanguage => CallLanguageRegistry.fromCode(myLangCode);
  CallLanguage get peerLanguage => CallLanguageRegistry.fromCode(peerLangCode);

  CallSession copyWith({
    String? callerLangCode,
    String? calleeLangCode,
    bool? translationEnabled,
    CallStateStatus? status,
    DateTime? connectedAt,
  }) {
    return CallSession(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      callerPhone: callerPhone,
      calleeId: calleeId,
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
      calleePhone: calleePhone,
      callerLangCode: callerLangCode ?? this.callerLangCode,
      calleeLangCode: calleeLangCode ?? this.calleeLangCode,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      status: status ?? this.status,
      isIncoming: isIncoming,
      createdAt: createdAt,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName,
        'callerAvatar': callerAvatar,
        'callerPhone': callerPhone,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'calleeAvatar': calleeAvatar,
        'calleePhone': calleePhone,
        'callerLangCode': callerLangCode,
        'calleeLangCode': calleeLangCode,
        'translationEnabled': translationEnabled,
        'status': status.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'connectedAt': connectedAt?.millisecondsSinceEpoch,
      };

  factory CallSession.fromMap(Map<String, dynamic> map, {required String ownId}) {
    final callerId = map['callerId'] as String? ?? '';
    return CallSession(
      callId: map['callId'] as String? ?? '',
      callerId: callerId,
      callerName: map['callerName'] as String? ?? 'Unknown',
      callerAvatar: map['callerAvatar'] as String? ?? '',
      callerPhone: map['callerPhone'] as String? ?? '',
      calleeId: map['calleeId'] as String? ?? '',
      calleeName: map['calleeName'] as String? ?? 'Unknown',
      calleeAvatar: map['calleeAvatar'] as String? ?? '',
      calleePhone: map['calleePhone'] as String? ?? '',
      callerLangCode: map['callerLangCode'] as String? ?? 'bn',
      calleeLangCode: map['calleeLangCode'] as String? ?? 'en',
      translationEnabled: map['translationEnabled'] as bool? ?? true,
      status: CallStateStatus.fromValue(map['status'] as String?),
      isIncoming: callerId != ownId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      connectedAt: map['connectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['connectedAt'] as num).toInt())
          : null,
    );
  }
}

class CallHistoryRecord {
  final String callId;
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String peerPhone;
  final DateTime timestamp;
  final int durationSeconds;
  final bool isIncoming;
  final bool isMissed;
  final bool translationEnabled;
  final String myLangCode;
  final String peerLangCode;

  const CallHistoryRecord({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
    required this.peerPhone,
    required this.timestamp,
    required this.durationSeconds,
    required this.isIncoming,
    required this.isMissed,
    required this.translationEnabled,
    required this.myLangCode,
    required this.peerLangCode,
  });

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'peerId': peerId,
        'peerName': peerName,
        'peerAvatar': peerAvatar,
        'peerPhone': peerPhone,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        'isIncoming': isIncoming,
        'isMissed': isMissed,
        'translationEnabled': translationEnabled,
        'myLangCode': myLangCode,
        'peerLangCode': peerLangCode,
      };

  factory CallHistoryRecord.fromMap(Map<String, dynamic> map) {
    return CallHistoryRecord(
      callId: map['callId'] as String? ?? '',
      peerId: map['peerId'] as String? ?? '',
      peerName: map['peerName'] as String? ?? 'Unknown',
      peerAvatar: map['peerAvatar'] as String? ?? '',
      peerPhone: map['peerPhone'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      isIncoming: map['isIncoming'] as bool? ?? false,
      isMissed: map['isMissed'] as bool? ?? false,
      translationEnabled: map['translationEnabled'] as bool? ?? true,
      myLangCode: map['myLangCode'] as String? ?? 'bn',
      peerLangCode: map['peerLangCode'] as String? ?? 'en',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CallHistoryRecord.fromJson(String source) =>
      CallHistoryRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
