import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/freelancer/models/call_summary.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Turns the live transcript of a translated call into a summary.
///
/// Only final lines are sent, deduplicated, capped at 300 entries. The raw
/// transcript is not persisted anywhere; the relay keeps just the summary.
class CallSummaryService {
  CallSummaryService._();

  static Future<CallSummary?> generate({
    required String callId,
    required int durationSeconds,
    required List<LiveTranscriptEntry> entries,
    required String myLang,
    required String peerLang,
  }) async {
    if (callId.isEmpty) return null;

    final transcript = <Map<String, String>>[];
    String? lastKey;
    for (final entry in entries) {
      if (!entry.isFinal) continue;
      // System captions (language switch, reconnect) are not speech.
      if (entry.speakerId == 'system') continue;
      final translated = entry.translatedText.trim();
      final original = entry.originalText.trim();
      final text = translated.isNotEmpty ? translated : original;
      if (text.isEmpty) continue;

      final key = '${entry.isSelf}:$text';
      if (key == lastKey) continue;
      lastKey = key;

      transcript.add({
        'speaker': entry.isSelf ? 'me' : 'client',
        'text': text.length > 1900 ? text.substring(0, 1900) : text,
      });
    }
    if (transcript.isEmpty) return null;

    final capped = transcript.length > 300
        ? transcript.sublist(transcript.length - 300)
        : transcript;

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return null;

      final response = await http
          .post(
            Uri.parse(AppConfig.callSummaryUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({
              'callId': callId,
              'durationSeconds': durationSeconds,
              'langPair': {'a': myLang, 'b': peerLang},
              'transcript': capped,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        debugPrint('[CallSummaryService] HTTP ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map) return null;
      final summary = data['summary'];
      if (summary is! Map) return null;
      return CallSummary.fromJson(
        summary.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (e) {
      debugPrint('[CallSummaryService] generate failed: $e');
      return null;
    }
  }
}
