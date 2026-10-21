import 'package:flutter/services.dart';

class NativeChannel {
  static const MethodChannel _channel = MethodChannel('com.livocal.app/native_channel');

  static Future<void> createNotificationChannels() async {
    try {
      await _channel.invokeMethod('createNotificationChannels');
    } catch (_) {}
  }

  static Future<void> stopCallkitVibration() async {
    try {
      await _channel.invokeMethod('stopCallkitVibration');
    } catch (_) {}
  }

  static Future<void> setCallkitChannelVibration(bool enabled) async {
    try {
      await _channel.invokeMethod('setCallkitChannelVibration', {'enabled': enabled});
    } catch (_) {}
  }
}
