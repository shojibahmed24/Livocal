import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper so crash reporting stays consistent and PII-free.
///
/// Only an opaque user id and coarse flow tags are attached; no phone numbers,
/// names or message content ever reach Crashlytics.
class CrashReporting {
  CrashReporting._();

  static void setUser(String uid) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(uid);
    } catch (_) {}
  }

  static void clearUser() {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (_) {}
  }

  /// Breadcrumb for the current session (visible in the crash timeline).
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[Crashlytics] $message');
    }
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Non-fatal error, e.g. a call that failed to connect or a relay error.
  static void record(
    Object error, {
    StackTrace? stack,
    String? reason,
  }) {
    debugPrint('[CrashReporting] $reason: $error');
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {}
  }

  static void setKey(String key, String value) {
    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {}
  }
}
