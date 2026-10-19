import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:uuid/uuid.dart';

/// Provides a persistent, tamper-resistant device fingerprint bound to
/// physical hardware to enforce the Freemium trial policy and prevent trial abuse.
class DeviceFingerprintService {
  static const String _key = 'livocal_hardware_fingerprint';
  static final DeviceFingerprintService _instance = DeviceFingerprintService._internal();

  factory DeviceFingerprintService() => _instance;

  DeviceFingerprintService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  String? _cachedFingerprint;

  /// Retrieves or generates a permanent hardware-bound device fingerprint.
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

      // 3. Generate hardware-bound fingerprint using real device info
      if (fingerprint == null || fingerprint.isEmpty) {
        fingerprint = await _generateHardwareFingerprint();
        await _saveFingerprint(fingerprint);
      } else {
        await _saveFingerprint(fingerprint);
      }

      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Keystore read error, falling back: $e');
      final fallback = SharedPref.instance.getString(_key);
      if (fallback != null && fallback.isNotEmpty) {
        _cachedFingerprint = fallback;
        return fallback;
      }
      final generated = await _generateHardwareFingerprint();
      _cachedFingerprint = generated;
      return generated;
    }
  }

  Future<String> _generateHardwareFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String rawHardwareId = '';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        rawHardwareId = 'web_${webInfo.vendor}_${webInfo.userAgent}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Bind to immutable hardware characteristics that survive app reinstall
        rawHardwareId = 'android_${androidInfo.id}_${androidInfo.model}_${androidInfo.brand}_${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawHardwareId = 'ios_${iosInfo.identifierForVendor ?? ''}_${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        rawHardwareId = 'win_${windowsInfo.deviceId}_${windowsInfo.computerName}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        rawHardwareId = 'mac_${macInfo.systemGUID ?? ''}_${macInfo.model}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        rawHardwareId = 'linux_${linuxInfo.machineId ?? ''}';
      } else {
        rawHardwareId = 'generic_${const Uuid().v4()}';
      }

      // Cryptographically hash the raw hardware specs into a clean, permanent 64-char hex string
      final hash = sha256.convert(utf8.encode(rawHardwareId)).toString();
      return 'hw_$hash';
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Failed to read hardware info: $e');
      final fallbackHash = sha256.convert(utf8.encode('${DateTime.now().toIso8601String()}_${const Uuid().v4()}')).toString();
      return 'hw_$fallbackHash';
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
