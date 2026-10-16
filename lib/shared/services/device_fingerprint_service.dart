import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:uuid/uuid.dart';

/// Provides a persistent, tamper-resistant device fingerprint to enforce
/// the 14-day 20-minute Freemium trial policy and prevent trial abuse.
class DeviceFingerprintService {
  static const String _key = 'livocal_hardware_fingerprint';
  static final DeviceFingerprintService _instance = DeviceFingerprintService._internal();

  factory DeviceFingerprintService() => _instance;

  DeviceFingerprintService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  String? _cachedFingerprint;

  /// Retrieves or generates a permanent device fingerprint.
  Future<String> getDeviceFingerprint() async {
    if (_cachedFingerprint != null && _cachedFingerprint!.isNotEmpty) {
      return _cachedFingerprint!;
    }

    try {
      // 1. Try Hardware Keystore (FlutterSecureStorage survives app resets)
      String? fingerprint = await _secureStorage.read(key: _key);

      // 2. Fallback to Shared Preferences if Keystore was fresh
      if (fingerprint == null || fingerprint.isEmpty) {
        fingerprint = SharedPref.instance.getString(_key);
      }

      // 3. Generate a new cryptographically unique hardware seed if completely new
      if (fingerprint == null || fingerprint.isEmpty) {
        fingerprint = 'dev_${const Uuid().v4()}';
        await _saveFingerprint(fingerprint);
      } else {
        // Ensure synchronization across both storage engines
        await _saveFingerprint(fingerprint);
      }

      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Keystore read error, falling back: $e');
      final fallback = SharedPref.instance.getString(_key) ?? 'dev_${DateTime.now().millisecondsSinceEpoch}';
      _cachedFingerprint = fallback;
      SharedPref.instance.setString(_key, fallback);
      return fallback;
    }
  }

  Future<void> _saveFingerprint(String fingerprint) async {
    try {
      await _secureStorage.write(key: _key, value: fingerprint);
    } catch (e) {
      debugPrint('[DeviceFingerprintService] SecureStorage write error: $e');
    }
    SharedPref.instance.setString(_key, fingerprint);
  }
}
