import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Device-local reminders for CRM follow-ups (no server needed).
class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'livocal_followups';
  static const _channelName = 'Follow-ups';

  static Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[ReminderService] timezone lookup failed: $e');
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[ReminderService] init failed: $e');
    }
  }

  /// Schedules (or replaces) the reminder for one CRM entry.
  static Future<void> scheduleFollowUp({
    required int id,
    required String clientName,
    required DateTime at,
  }) async {
    await _ensureReady();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
      if (at.isBefore(DateTime.now())) return;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.requestNotificationsPermission();
      } catch (_) {}

      await _plugin.zonedSchedule(
        id: id,
        title: 'Follow up with $clientName',
        body: '$clientName · Livocal CRM\n$clientName-এর সাথে ফলো-আপ',
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Client follow-up reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[ReminderService] schedule failed: $e');
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _ensureReady();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[ReminderService] cancel failed: $e');
    }
  }
}
