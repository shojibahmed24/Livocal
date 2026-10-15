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

  /// Verifies entered PIN against hardware-encrypted secure storage.
  static Future<bool> verifyPin(String enteredPin) async {
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
      return actualPin != null && actualPin == enteredPin;
    } catch (e) {
      debugPrint('[SecurePinService] verifyPin error: $e');
      return false;
    }
  }

  /// Sets or updates the PIN in hardware-encrypted secure storage.
  static Future<void> setPin(String pin) async {
    try {
      await _secureStorage.write(key: _storageKey, value: pin);
      // Ensure no plaintext remains
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
      await SharedPref.instance.remove('two_step_pin');
    } catch (e) {
      debugPrint('[SecurePinService] disablePin error: $e');
    }
  }
}
