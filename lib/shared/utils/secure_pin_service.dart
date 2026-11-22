import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class SecurePinService {
  static const _storageKey = 'livocal_two_step_pin';
  static const _hashPrefix = 'v2';
  static const _iterations = 40000;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static bool _isHashed(String value) => value.startsWith('$_hashPrefix\$');

  static String _newSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  /// PBKDF2-HMAC-SHA256 (single 32-byte block). The Keystore/Keychain remains
  /// the primary protection; this prevents a plaintext PIN from being readable
  /// if the secure-storage blob is ever extracted.
  static String _deriveHash(String pin, String saltB64) {
    final salt = base64Decode(saltB64);
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.from(block);
    for (var i = 1; i < _iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= block[j];
      }
    }
    return base64Encode(out);
  }

  static String _hashPin(String pin) {
    final salt = _newSalt();
    return '$_hashPrefix\$$salt\$${_deriveHash(pin, salt)}';
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static bool _matches(String stored, String pin) {
    if (_isHashed(stored)) {
      final parts = stored.split('\$');
      if (parts.length != 3) return false;
      return _constantTimeEquals(parts[2], _deriveHash(pin, parts[1]));
    }
    // Legacy plaintext record; upgraded to a hash after successful verify.
    return _constantTimeEquals(stored, pin);
  }

  /// Checks if two-step verification PIN is active.
  /// Automatically migrates legacy plaintext PIN from SharedPreferences.
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
        // Keep the value for verifyPin() to upgrade to a salted hash.
        await _secureStorage.write(key: _storageKey, value: legacyPin);
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

  /// Verifies entered PIN against the stored salted hash with brute-force
  /// protection. Legacy plaintext PINs are upgraded on successful verify.
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

      final isMatch = actualPin != null && _matches(actualPin, enteredPin);
      if (isMatch) {
        // Upgrade legacy plaintext to a salted hash on first success.
        if (!_isHashed(actualPin)) {
          try {
            await _secureStorage.write(
              key: _storageKey,
              value: _hashPin(enteredPin),
            );
          } catch (e) {
            debugPrint('[SecurePinService] PIN hash upgrade error: $e');
          }
        }
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

  /// Sets or updates the PIN as a salted hash in hardware-encrypted storage.
  static Future<void> setPin(String pin) async {
    try {
      await _secureStorage.write(key: _storageKey, value: _hashPin(pin));
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

  /// Completely wipes all PINs and secure keys from hardware storage on logout.
  static Future<void> wipe() async {
    try {
      await _secureStorage.deleteAll();
      await SharedPref.instance.remove(_attemptsKey);
      await SharedPref.instance.remove(_lockoutUntilKey);
      await SharedPref.instance.remove('two_step_pin');
      await SharedPref.instance.remove('two_step_verification_enabled');
      await SharedPref.instance.remove('two_step_verification_pin');
      debugPrint('[SecurePinService] Wiped all hardware secure storage and PIN keys');
    } catch (e) {
      debugPrint('[SecurePinService] wipe error: $e');
    }
  }
}
