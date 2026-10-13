import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/calls/models/call_model.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(firestore: FirebaseFirestore.instance);
});

class CallRepository {
  static const String prefMyLang = 'call_my_preferred_lang_code';
  static const String prefPeerLang = 'call_peer_preferred_lang_code';
  static const String prefCallHistory = 'call_history_records_v1';

  final FirebaseFirestore firestore;

  CallRepository({required this.firestore});

  static String getMyLanguageCode() =>
      SharedPref.instance.getString(prefMyLang) ?? 'bn';

  static Future<void> setMyLanguageCode(String code) async =>
      await SharedPref.instance.setString(prefMyLang, code);

  static String getPeerLanguageCode() =>
      SharedPref.instance.getString(prefPeerLang) ?? 'en';

  static Future<void> setPeerLanguageCode(String code) async =>
      await SharedPref.instance.setString(prefPeerLang, code);

  /// Infers default target language from peer ID/name if known, else falls back to saved peer language.
  static String inferPeerLanguageCode(String peerId, String peerName) {
    final lowerId = peerId.toLowerCase();
    final lowerName = peerName.toLowerCase();
    if (lowerId.contains('_en_') || lowerName.contains('english')) return 'en';
    if (lowerId.contains('_es_') || lowerName.contains('español') || lowerName.contains('spanish')) return 'es';
    if (lowerId.contains('_ar_') || lowerName.contains('العربية') || lowerName.contains('arabic')) return 'ar';
    if (lowerId.contains('_ja_') || lowerName.contains('日本語') || lowerName.contains('japanese')) return 'ja';
    if (lowerId.contains('_bn_') || lowerName.contains('বাংলা') || lowerName.contains('bangla')) return 'bn';
    if (lowerId.contains('_hi_') || lowerName.contains('हिन्दी') || lowerName.contains('hindi')) return 'hi';
    if (lowerId.contains('_fr_') || lowerName.contains('français') || lowerName.contains('french')) return 'fr';
    return getPeerLanguageCode();
  }

  /// Creates call document in Firestore (non-blocking if Firestore is offline/restricted)
  Future<void> createCall(CallSession session) async {
    try {
      await firestore
          .collection('calls')
          .doc(session.callId)
          .set(session.toMap())
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> updateCallStatus(String callId, CallStateStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.value,
      };
      if (status == CallStateStatus.connected) {
        updates['connectedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
      await firestore
          .collection('calls')
          .doc(callId)
          .update(updates)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> updateCallLanguages(
    String callId, {
    required String callerLangCode,
    required String calleeLangCode,
  }) async {
    try {
      await firestore
          .collection('calls')
          .doc(callId)
          .update({
            'callerLangCode': callerLangCode,
            'calleeLangCode': calleeLangCode,
          })
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> sendTranscriptToCall(
    String callId,
    LiveTranscriptEntry entry,
  ) async {
    try {
      await firestore
          .collection('calls')
          .doc(callId)
          .collection('transcripts')
          .doc(entry.id)
          .set(entry.toMap())
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Stream<CallSession?> watchCallSession(String callId, String ownId) {
    return firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          return CallSession.fromMap(snap.data()!, ownId: ownId);
        })
        .handleError((_) => null);
  }

  Stream<CallSession?> watchIncomingCalls(String ownId) {
    return firestore
        .collection('calls')
        .where('calleeId', isEqualTo: ownId)
        .where('status', whereIn: ['dialing', 'ringing'])
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) return null;
          final doc = query.docs.first.data();
          final session = CallSession.fromMap(doc, ownId: ownId);
          final ageSec =
              DateTime.now().difference(session.createdAt).inSeconds.abs();
          if (ageSec > 45) return null;
          return session;
        })
        .handleError((_) => null);
  }

  Stream<List<LiveTranscriptEntry>> watchCallTranscripts(
    String callId,
    String ownId,
  ) {
    return firestore
        .collection('calls')
        .doc(callId)
        .collection('transcripts')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => LiveTranscriptEntry.fromMap(d.data(), ownId))
              .toList();
        })
        .handleError((_) => <LiveTranscriptEntry>[]);
  }

  // --- Local Call History Persistence ---

  List<CallHistoryRecord> getCallHistory() {
    final rawList = SharedPref.instance.getStringList(prefCallHistory);
    if (rawList == null || rawList.isEmpty) {
      final seeded = _defaultSeededHistory();
      saveCallHistoryList(seeded);
      return seeded;
    }
    try {
      return rawList
          .map((item) => CallHistoryRecord.fromJson(item))
          .toList();
    } catch (_) {
      return _defaultSeededHistory();
    }
  }

  Future<void> addCallHistoryRecord(CallHistoryRecord record) async {
    final current = getCallHistory();
    current.removeWhere((r) => r.callId == record.callId);
    current.insert(0, record);
    if (current.length > 50) {
      current.removeRange(50, current.length);
    }
    await saveCallHistoryList(current);
  }

  Future<void> clearCallHistory() async {
    await SharedPref.instance.setStringList(prefCallHistory, []);
  }

  Future<void> saveCallHistoryList(List<CallHistoryRecord> list) async {
    await SharedPref.instance.setStringList(
      prefCallHistory,
      list.map((e) => e.toJson()).toList(),
    );
  }

  List<CallHistoryRecord> _defaultSeededHistory() {
    final now = DateTime.now();
    return [
      CallHistoryRecord(
        callId: 'seed_call_1',
        peerId: 'demo_en_john',
        peerName: 'John Smith 🇺🇸 (English)',
        peerAvatar: 'https://i.pravatar.cc/150?img=11',
        peerPhone: '+1 555-0101',
        timestamp: now.subtract(const Duration(minutes: 25)),
        durationSeconds: 184,
        isIncoming: false,
        isMissed: false,
        translationEnabled: true,
        myLangCode: 'bn',
        peerLangCode: 'en',
      ),
      CallHistoryRecord(
        callId: 'seed_call_2',
        peerId: 'demo_es_carlos',
        peerName: 'Carlos Rivera 🇪🇸 (Español)',
        peerAvatar: 'https://i.pravatar.cc/150?img=12',
        peerPhone: '+34 600-0202',
        timestamp: now.subtract(const Duration(hours: 2)),
        durationSeconds: 95,
        isIncoming: true,
        isMissed: false,
        translationEnabled: true,
        myLangCode: 'bn',
        peerLangCode: 'es',
      ),
      CallHistoryRecord(
        callId: 'seed_call_3',
        peerId: 'demo_ar_ahmed',
        peerName: 'Ahmed Al-Mansoor 🇸🇦 (العربية)',
        peerAvatar: 'https://i.pravatar.cc/150?img=13',
        peerPhone: '+966 50-0303',
        timestamp: now.subtract(const Duration(hours: 5)),
        durationSeconds: 142,
        isIncoming: false,
        isMissed: false,
        translationEnabled: true,
        myLangCode: 'en',
        peerLangCode: 'ar',
      ),
    ];
  }
}
