import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global 1-minute ticker for updating relative timestamps (e.g. "Just now", "5m ago").
///
/// Replaces hundreds of individual [Timer.periodic] instances across chat items,
/// preserving battery life and avoiding CPU wake-lock spikes.
class TimeTicker {
  TimeTicker._();

  static final ValueNotifier<DateTime> minuteTicker =
      ValueNotifier<DateTime>(DateTime.now());

  static Timer? _timer;

  /// Start the periodic timer once if not already running.
  static void ensureStarted() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      minuteTicker.value = DateTime.now();
    });
  }

  /// Stop the ticker when app is shutting down or paused.
  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
