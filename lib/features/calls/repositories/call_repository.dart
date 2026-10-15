import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

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
    final hasBengaliChars = RegExp(r'[\u0980-\u09FF]').hasMatch(peerName);
    if (lowerId.contains('_bn_') || lowerName.contains('বাংলা') || lowerName.contains('bangla') || hasBengaliChars) return 'bn';
    if (lowerId.contains('_hi_') || lowerName.contains('हिन्दी') || lowerName.contains('hindi')) return 'hi';
    if (lowerId.contains('_fr_') || lowerName.contains('français') || lowerName.contains('french')) return 'fr';
    return getPeerLanguageCode();
  }

  /// Creates call document in Firestore
  Future<bool> createCall(CallSession session) async {
    try {
      await firestore
          .collection('calls')
          .doc(session.callId)
          .set(session.toMap())
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('[CallRepository] createCall failed for ${session.callId}: $e');
      return false;
    }
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
    } catch (e) {
      debugPrint('[CallRepository] updateCallStatus failed for $callId ($status): $e');
    }
  }

  Future<void> updateCallLanguages(
    String callId, {
    String? callerLangCode,
    String? calleeLangCode,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (callerLangCode != null) updates['callerLangCode'] = callerLangCode;
      if (calleeLangCode != null) updates['calleeLangCode'] = calleeLangCode;
      if (updates.isEmpty) return;
      await firestore
          .collection('calls')
          .doc(callId)
          .update(updates)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[CallRepository] updateCallLanguages failed for $callId: $e');
    }
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
    } catch (e) {
      debugPrint('[CallRepository] sendTranscriptToCall failed for $callId: $e');
    }
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
        .handleError((err) {
          debugPrint('[CallRepository] watchCallSession error for $callId: $err');
          return null;
        });
  }

  Stream<CallSession?> watchIncomingCalls(String ownId) {
    return firestore
        .collection('calls')
        .where('calleeId', isEqualTo: ownId)
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) return null;
          for (final doc in query.docs) {
            final data = doc.data();
            final session = CallSession.fromMap(data, ownId: ownId);
            final isRinging = session.status == CallStateStatus.dialing ||
                session.status == CallStateStatus.ringing;
            if (!isRinging) continue;
            final ageSec =
                DateTime.now().difference(session.createdAt).inSeconds.abs();
            if (ageSec <= 60) {
              return session;
            }
          }
          return null;
        })
        .handleError((e) {
          debugPrint('watchIncomingCalls error: $e');
          return null;
        });
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
      return [];
    }
    try {
      return rawList
          .map((item) => CallHistoryRecord.fromJson(item))
          .toList();
    } catch (e, st) {
      debugPrint('[CallRepository] getCallHistory deserialization error: $e\n$st');
      return [];
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
}
