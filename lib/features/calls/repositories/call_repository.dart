import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(firestore: FirebaseFirestore.instance);
});

class PeerTranslationSettings {
  final bool isTranslationEnabled;
  final String myLangCode;
  final String peerLangCode;

  const PeerTranslationSettings({
    required this.isTranslationEnabled,
    required this.myLangCode,
    required this.peerLangCode,
  });

  bool get isSameLanguage =>
      myLangCode.toLowerCase().trim() == peerLangCode.toLowerCase().trim();

  bool get isEffectivelyTranslated => isTranslationEnabled && !isSameLanguage;
}

class CallRepository {
  static const String prefMyLang = 'call_my_preferred_lang_code';
  static const String prefPeerLang = 'call_peer_preferred_lang_code';
  static const String prefCallHistory = 'call_history_records_v1';

  final FirebaseFirestore? firestore;

  CallRepository({this.firestore});

  static String getMyLanguageCode() =>
      SharedPref.instance.getString(prefMyLang) ?? 'bn';

  static Future<void> setMyLanguageCode(String code) async =>
      await SharedPref.instance.setString(prefMyLang, code);

  static String getPeerLanguageCode() =>
      SharedPref.instance.getString(prefPeerLang) ?? 'en';

  static Future<void> setPeerLanguageCode(String code) async =>
      await SharedPref.instance.setString(prefPeerLang, code);

  /// Infers default target language from peer ID/name/phone if known, else falls back to saved peer language.
  static String inferPeerLanguageCode(
    String peerId,
    String peerName, {
    String? phone,
  }) {
    // 1. Check if peer has explicit saved preference in chat_trans_
    final savedPeer = getSavedPeerLang(peerId, peerName, phone: phone);
    if (savedPeer != null && savedPeer.isNotEmpty) return savedPeer;

    // 2. Check phone number prefix / country code (e.g. BD 017..., +880...)
    final candidates = [phone, peerId, peerName].whereType<String>();
    for (final raw in candidates) {
      final clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
      if (clean.startsWith('+880') ||
          clean.startsWith('880') ||
          RegExp(r'^01[3-9]\d{8}$').hasMatch(clean)) {
        return 'bn'; // Bangladesh
      }
      if (clean.startsWith('+91') ||
          (clean.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(clean))) {
        return 'hi'; // India
      }
      if (clean.startsWith('+966') ||
          clean.startsWith('+971') ||
          clean.startsWith('+965') ||
          clean.startsWith('+974')) {
        return 'ar'; // Gulf / Middle East
      }
      if (clean.startsWith('+34')) return 'es';
      if (clean.startsWith('+33')) return 'fr';
      if (clean.startsWith('+49')) return 'de';
    }

    // 3. Name & ID keywords
    final lowerId = peerId.toLowerCase();
    final lowerName = peerName.toLowerCase();
    if (lowerId.contains('_en_') || lowerName.contains('english')) return 'en';
    if (lowerId.contains('_es_') || lowerName.contains('español') || lowerName.contains('spanish')) return 'es';
    if (lowerId.contains('_ar_') || lowerName.contains('العربية') || lowerName.contains('arabic')) return 'ar';
    final hasBengaliChars = RegExp(r'[\u0980-\u09FF]').hasMatch(peerName);
    if (lowerId.contains('_bn_') || lowerName.contains('বাংলা') || lowerName.contains('bangla') || hasBengaliChars) return 'bn';
    if (lowerId.contains('_hi_') || lowerName.contains('हिन्दी') || lowerName.contains('hindi')) return 'hi';
    if (lowerId.contains('_fr_') || lowerName.contains('français') || lowerName.contains('french')) return 'fr';
    if (lowerId.contains('_de_') || lowerName.contains('deutsch') || lowerName.contains('german')) return 'de';

    return getPeerLanguageCode();
  }

  /// Extracts all candidate keys for looking up peer-specific preferences
  static List<String> getCandidatePrefixes(
    String peerId,
    String peerName, {
    String? phone,
  }) {
    final prefixes = <String>[];
    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final val = raw.trim();
      final p1 = 'chat_trans_$val';
      if (!prefixes.contains(p1)) prefixes.add(p1);
      if (val.startsWith('phone_')) {
        final p2 = 'chat_trans_${val.replaceFirst('phone_', '')}';
        if (!prefixes.contains(p2)) prefixes.add(p2);
      }
      final clean = val.replaceAll(RegExp(r'[^0-9+]'), '');
      if (clean.isNotEmpty) {
        final p3 = 'chat_trans_$clean';
        if (!prefixes.contains(p3)) prefixes.add(p3);
      }
    }

    add(peerId);
    add(phone);
    add(peerName);
    return prefixes;
  }

  /// Reads explicit peer language code if saved in chat_trans_ preferences
  static String? getSavedPeerLang(
    String peerId,
    String peerName, {
    String? phone,
  }) {
    final prefs = SharedPref.instance;
    for (final prefix in getCandidatePrefixes(peerId, peerName, phone: phone)) {
      final lang = prefs.getString('${prefix}_peer_lang');
      if (lang != null && lang.isNotEmpty) return lang;
    }
    return null;
  }

  /// Fully resolves peer language, my language, and whether translation should be active
  static PeerTranslationSettings getPeerTranslationSettings({
    required String peerId,
    required String peerName,
    String? peerPhone,
    String? explicitMyLang,
    String? explicitPeerLang,
    bool? explicitTranslationEnabled,
  }) {
    final prefs = SharedPref.instance;
    final prefixes = getCandidatePrefixes(peerId, peerName, phone: peerPhone);

    // 1. Resolve translation enabled
    bool? resolvedEnabled = explicitTranslationEnabled;
    if (resolvedEnabled == null) {
      for (final p in prefixes) {
        if (prefs.containsKey('${p}_enabled')) {
          resolvedEnabled = prefs.getBool('${p}_enabled');
          break;
        }
      }
    }

    // 2. Resolve my language
    String? resolvedMy = explicitMyLang;
    if (resolvedMy == null || resolvedMy.isEmpty) {
      for (final p in prefixes) {
        final val = prefs.getString('${p}_my_lang');
        if (val != null && val.isNotEmpty) {
          resolvedMy = val;
          break;
        }
      }
      resolvedMy ??= getMyLanguageCode();
    }

    // 3. Resolve peer language
    String? resolvedPeer = explicitPeerLang;
    if (resolvedPeer == null || resolvedPeer.isEmpty) {
      for (final p in prefixes) {
        final val = prefs.getString('${p}_peer_lang');
        if (val != null && val.isNotEmpty) {
          resolvedPeer = val;
          break;
        }
      }
      resolvedPeer ??= inferPeerLanguageCode(peerId, peerName, phone: peerPhone);
    }

    // If both speak the same language, translation is NOT needed!
    if (resolvedMy.toLowerCase().trim() == resolvedPeer.toLowerCase().trim()) {
      resolvedEnabled = false;
    } else {
      resolvedEnabled ??= true;
    }

    return PeerTranslationSettings(
      isTranslationEnabled: resolvedEnabled,
      myLangCode: resolvedMy,
      peerLangCode: resolvedPeer,
    );
  }

  /// Creates call document in Firestore
  Future<bool> createCall(CallSession session) async {
    if (firestore == null) return true;
    try {
      await firestore!
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
    if (firestore == null) return;
    try {
      final updates = <String, dynamic>{
        'status': status.value,
      };
      if (status == CallStateStatus.connected) {
        updates['connectedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
      await firestore!
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
    if (firestore == null) return;
    try {
      final updates = <String, dynamic>{};
      if (callerLangCode != null) updates['callerLangCode'] = callerLangCode;
      if (calleeLangCode != null) updates['calleeLangCode'] = calleeLangCode;
      if (updates.isEmpty) return;
      await firestore!
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
    if (firestore == null) return;
    try {
      await firestore!
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
    if (firestore == null) return const Stream.empty();
    return firestore!
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

  Stream<CallSession?> watchIncomingCalls(String ownId, {String? ownPhone}) {
    if (firestore == null) return const Stream.empty();

    // Query strictly with isEqualTo: ownId.
    // In Firestore Security Rules: 'allow read: if resource.data.calleeId == request.auth.uid'
    // Rules are NOT filters. Using whereIn with non-auth IDs causes Firestore to reject the query
    // with PERMISSION_DENIED. Querying with calleeId == ownId is 100% secure and guaranteed to succeed.
    return firestore!
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
    if (firestore == null) return const Stream.empty();
    return firestore!
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
