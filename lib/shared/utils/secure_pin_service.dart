import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class SecurePinService {
  static const _storageKey = 'livocal_two_step_pin';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  /// Checks if two-step verification PIN is active.
  /// Automatically migrates legacy plaintext PIN from SharedPreferences to Keystore.
  static Future<bool> isPinSet() async {
    try {
      // 1. Check secure storage first
      final securePin = await _secureStorage.read(key: _storageKey);
      if (securePin != null && securePin.isNotEmpty) {
        // Clean up any lingering plaintext in SharedPreferences
        if (SharedPref.instance.containsKey('two_step_pin')) {
          await SharedPref.instance.remove('two_step_pin');
        }
        return true;
      }

      // 2. Migration: check legacy plaintext SharedPref
      final legacyPin = SharedPref.instance.getString('two_step_pin');
      if (legacyPin != null && legacyPin.isNotEmpty) {
        // Save to hardware-backed secure storage
        await _secureStorage.write(key: _storageKey, value: legacyPin);
        // Wipe plaintext immediately
        await SharedPref.instance.remove('two_step_pin');
        return true;
      }
    } catch (e) {
      debugPrint('[SecurePinService] isPinSet error: $e');
    }
    return false;
  }

  static const _attemptsKey = 'livocal_pin_failed_attempts';
  static const _lockoutUntilKey = 'livocal_pin_lockout_until';

  /// Returns remaining lockout time in seconds, or 0 if not locked out.
  static int getRemainingLockoutSeconds() {
    try {
      final lockoutUntilMs = SharedPref.instance.getInt(_lockoutUntilKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (lockoutUntilMs > nowMs) {
        return ((lockoutUntilMs - nowMs) / 1000).ceil();
      }
    } catch (e) {
      debugPrint('[SecurePinService] Lockout check error: $e');
    }
    return 0;
  }

  /// Verifies entered PIN against hardware-encrypted secure storage with brute-force protection.
  static Future<bool> verifyPin(String enteredPin) async {
    final lockoutSeconds = getRemainingLockoutSeconds();
    if (lockoutSeconds > 0) {
      return false;
    }

    try {
      String? actualPin = await _secureStorage.read(key: _storageKey);
      if (actualPin == null || actualPin.isEmpty) {
        // Check legacy fallback & migrate
        final legacy = SharedPref.instance.getString('two_step_pin');
        if (legacy != null && legacy.isNotEmpty) {
          await _secureStorage.write(key: _storageKey, value: legacy);
          await SharedPref.instance.remove('two_step_pin');
          actualPin = legacy;
        }
      }

      final isMatch = actualPin != null && actualPin == enteredPin;
      if (isMatch) {
        // Successful verification: reset attempt counter and lockout
        await SharedPref.instance.remove(_attemptsKey);
        await SharedPref.instance.remove(_lockoutUntilKey);
        return true;
      } else {
        // Incorrect PIN: increment failed attempts counter
        final attempts = (SharedPref.instance.getInt(_attemptsKey) ?? 0) + 1;
        await SharedPref.instance.setInt(_attemptsKey, attempts);

        if (attempts >= 10) {
          // Lock out for 5 minutes
          final until =
              DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
          await SharedPref.instance.setInt(_lockoutUntilKey, until);
        } else if (attempts >= 8) {
          // Lock out for 1 minute
          final until =
              DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch;
          await SharedPref.instance.setInt(_lockoutUntilKey, until);
        } else if (attempts >= 5) {
          // Lock out for 30 seconds
          final until =
              DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
          await SharedPref.instance.setInt(_lockoutUntilKey, until);
        }
        return false;
      }
    } catch (e) {
      debugPrint('[SecurePinService] verifyPin error: $e');
      return false;
    }
  }

  /// Sets or updates the PIN in hardware-encrypted secure storage.
  static Future<void> setPin(String pin) async {
    try {
      await _secureStorage.write(key: _storageKey, value: pin);
      // Reset lockout and attempts
      await SharedPref.instance.remove(_attemptsKey);
      await SharedPref.instance.remove(_lockoutUntilKey);
      await SharedPref.instance.remove('two_step_pin');
    } catch (e) {
      debugPrint('[SecurePinService] setPin error: $e');
      rethrow;
    }
  }

  /// Disables the PIN and purges it completely from all storage.
  static Future<void> disablePin() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      await SharedPref.instance.remove(_attemptsKey);
      await SharedPref.instance.remove(_lockoutUntilKey);
      await SharedPref.instance.remove('two_step_pin');
    } catch (e) {
      debugPrint('[SecurePinService] disablePin error: $e');
    }
  }
}
