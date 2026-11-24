import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Fetches the spoken sample for the AI Voice Persona picker.
///
/// The relay ([POST /api/voice-preview]) runs a short Gemini 3.5 Live Translate
/// session with the selected voice and returns a WAV file. The first request
/// for a voice+language pair takes several seconds (the live session streams a
/// fixed sample and waits for the translation); the relay and this device both
/// cache the result, so later taps play instantly.
class VoicePreviewService {
  /// Live synthesis is slow on the first tap, so the timeout is generous.
  static const Duration _remoteTimeout = Duration(seconds: 40);

  /// How long a cached sample stays usable on this device.
  static const Duration _cacheMaxAge = Duration(days: 7);

  /// Returns the path of a playable WAV file, or null when synthesis failed.
  static Future<String?> sample({
    required String voice,
    required String langCode,
  }) async {
    final cached = await _readCache(voice: voice, langCode: langCode);
    if (cached != null) return cached;

    final path = await _fetchFromRelay(voice: voice, langCode: langCode);
    return path;
  }

  static Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/voice_previews');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String?> _readCache({
    required String voice,
    required String langCode,
  }) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${voice}_$langCode.wav');
      if (!await file.exists()) return null;
      final age = DateTime.now().difference(await file.lastModified());
      if (age > _cacheMaxAge || await file.length() < 1024) return null;
      return file.path;
    } catch (err) {
      debugPrint('[VoicePreviewService] cache read error: $err');
      return null;
    }
  }

  static Future<String?> _fetchFromRelay({
    required String voice,
    required String langCode,
  }) async {
    try {
      final relayUrl = AppConfig.liveCallWsUrl
          .replaceFirst('ws://', 'http://')
          .replaceFirst('wss://', 'https://')
          .replaceFirst('/ws/live-call', '/api/voice-preview');

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http
          .post(
            Uri.parse(relayUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            }),
            body: jsonEncode({'voice': voice, 'langCode': langCode}),
          )
          .timeout(_remoteTimeout);

      if (response.statusCode != 200) {
        debugPrint(
          '[VoicePreviewService] relay returned HTTP ${response.statusCode}: '
          '${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final base64Audio = data['audioBase64'] as String?;
      if (base64Audio == null || base64Audio.isEmpty) return null;

      final dir = await _cacheDir();
      final file = File('${dir.path}/${voice}_$langCode.wav');
      await file.writeAsBytes(base64Decode(base64Audio), flush: true);
      return file.path;
    } catch (err) {
      debugPrint('[VoicePreviewService] relay error: $err');
      return null;
    }
  }
}
