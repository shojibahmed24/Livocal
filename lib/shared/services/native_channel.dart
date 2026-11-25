import 'package:flutter/services.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class NativeChannel {
  static const MethodChannel _channel =
      MethodChannel('com.livocal.app/native_channel');

  static Future<void> createNotificationChannels() async {
    try {
      final language = SharedPref.isInitialized
          ? (SharedPref.instance.getString('app_language') ?? 'en')
          : 'en';
      await _channel.invokeMethod('createNotificationChannels', {
        'language': language,
      });
    } catch (_) {}
  }

  static Future<void> stopCallkitVibration() async {
    try {
      await _channel.invokeMethod('stopCallkitVibration');
    } catch (_) {}
  }

  static Future<void> cancelVibrationSuppression() async {
    try {
      await _channel.invokeMethod('cancelVibrationSuppression');
    } catch (_) {}
  }

  static Future<void> setCallkitChannelVibration(bool enabled) async {
    try {
      await _channel
          .invokeMethod('setCallkitChannelVibration', {'enabled': enabled});
    } catch (_) {}
  }
}
