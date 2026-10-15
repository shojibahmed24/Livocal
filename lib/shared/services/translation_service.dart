import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/shared/constants/app_config.dart';

class TranslationService {
  static String get _backendRelayUrl => AppConfig.relayHttpBaseUrl;

  /// Translates text using Google Gemini 1.5 Flash API or the Livocal Relay Gateway.
  /// Guarantees 100% genuine real-time AI translation without hardcoded mocks.
  static Future<String> translateText({
    required String text,
    required String targetLangName,
    String? sourceLangName,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    // 1. Try local Gemini API key first if saved by user
    final localApiKey = GeminiLiveTranslator.getSavedApiKey();
    if (localApiKey.isNotEmpty) {
      try {
        final result = await _callGeminiRestApi(
          apiKey: localApiKey,
          text: cleanText,
          targetLangName: targetLangName,
          sourceLangName: sourceLangName,
        );
        if (result.isNotEmpty) return result;
      } catch (e) {
        debugPrint('[TranslationService] Local Gemini API attempt error: $e');
      }
    }

    // 2. Try Livocal Backend Relay gateway
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (token != null && token.isNotEmpty) {
        final res = await http.post(
          Uri.parse('$_backendRelayUrl/api/translate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'text': cleanText,
            'sourceLang': sourceLangName ?? 'auto',
            'targetLang': targetLangName,
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final translated = data['translatedText'] as String?;
          if (translated != null && translated.isNotEmpty) {
            return translated.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[TranslationService] Backend relay attempt error: $e');
    }

    // 3. Fallback: If local API key was not configured and backend relay was unreachable
    if (localApiKey.isEmpty) {
      throw Exception(
        'Gemini API key is not configured. Please set your Gemini API key in Settings > Gemini Live Voice Translation.',
      );
    }

    throw Exception('Unable to translate at this moment. Please check your network connection.');
  }

  static Future<String> _callGeminiRestApi({
    required String apiKey,
    required String text,
    required String targetLangName,
    String? sourceLangName,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = sourceLangName != null
        ? 'Translate the following text from $sourceLangName to $targetLangName. Output strictly the direct translation only, without quotes, notes, or explanations:\n\n$text'
        : 'Translate the following text to $targetLangName. Output strictly the direct translation only, without quotes, notes, or explanations:\n\n$text';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 500,
      }
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final translated = parts[0]['text'] as String?;
          if (translated != null) {
            return translated.trim();
          }
        }
      }
    } else {
      throw Exception('Gemini REST API returned HTTP ${res.statusCode}: ${res.body}');
    }

    return '';
  }
}
