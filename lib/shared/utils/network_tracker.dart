import 'package:flutter/foundation.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// Centralized utility for recording and querying authentic network data traffic (sent & received).
class NetworkTracker {
  static const String keySent = 'net_bytes_sent';
  static const String keyRecv = 'net_bytes_received';

  /// Records outbound network data payload in bytes.
  static void recordBytesSent(int bytes) {
    if (bytes <= 0) return;
    try {
      final current = SharedPref.instance.getInt(keySent) ?? 0;
      SharedPref.instance.setInt(keySent, current + bytes);
    } catch (e) {
      debugPrint('NetworkTracker.recordBytesSent error: $e');
    }
  }

  /// Records inbound network data payload in bytes.
  static void recordBytesReceived(int bytes) {
    if (bytes <= 0) return;
    try {
      final current = SharedPref.instance.getInt(keyRecv) ?? 0;
      SharedPref.instance.setInt(keyRecv, current + bytes);
    } catch (e) {
      debugPrint('NetworkTracker.recordBytesReceived error: $e');
    }
  }

  /// Returns total bytes sent since app installation or last reset.
  static int getSentBytes() {
    return SharedPref.instance.getInt(keySent) ?? 0;
  }

  /// Returns total bytes received since app installation or last reset.
  static int getReceivedBytes() {
    return SharedPref.instance.getInt(keyRecv) ?? 0;
  }

  /// Resets network usage counters to 0.
  static void resetUsage() {
    SharedPref.instance.setInt(keySent, 0);
    SharedPref.instance.setInt(keyRecv, 0);
  }
}
