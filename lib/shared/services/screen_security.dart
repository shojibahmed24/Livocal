import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android `FLAG_SECURE`: blocks screenshots, screen recording and hides the
/// app-switcher preview while enabled. Used on sensitive screens (OTP, chat,
/// media viewer). No-op on platforms without the channel.
class ScreenSecurity {
  ScreenSecurity._();

  static const MethodChannel _channel =
      MethodChannel('com.livocal.app/secure_screen');

  static Future<void> enable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('enable');
    } catch (e) {
      debugPrint('[ScreenSecurity] enable failed: $e');
    }
  }

  static Future<void> disable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('disable');
    } catch (e) {
      debugPrint('[ScreenSecurity] disable failed: $e');
    }
  }
}
