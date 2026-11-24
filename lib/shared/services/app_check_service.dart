import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Supplies Firebase App Check tokens so the relay can reject repackaged or
/// automated clients. Tokens are short-lived; fetch them per request instead of
/// caching them for long periods.
class AppCheckService {
  AppCheckService._();

  static Future<String?> token() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      debugPrint('[AppCheckService] token error: $e');
      return null;
    }
  }

  /// Copies [base] and adds `X-Firebase-AppCheck` when a token is available.
  static Future<Map<String, String>> withAppCheck(
    Map<String, String> base,
  ) async {
    final headers = Map<String, String>.from(base);
    final value = await token();
    if (value != null && value.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = value;
    }
    return headers;
  }
}
