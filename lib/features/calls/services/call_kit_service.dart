import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  StreamSubscription? _callKitSubscription;

  void Function(String callId)? onCallAccepted;
  void Function(String callId)? onCallDeclined;
  void Function(String callId)? onCallTimeout;
  void Function(String callId)? onCallEnded;
  void Function(String callId, Map<String, dynamic>? body)? onCallCallback;

  void init({
    void Function(String callId)? onAccept,
    void Function(String callId)? onDecline,
    void Function(String callId)? onTimeout,
    void Function(String callId)? onEnded,
    void Function(String callId, Map<String, dynamic>? body)? onCallback,
  }) {
    onCallAccepted = onAccept;
    onCallDeclined = onDecline;
    onCallTimeout = onTimeout;
    onCallEnded = onEnded;
    onCallCallback = onCallback;

    _callKitSubscription?.cancel();
    _callKitSubscription =
        FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      debugPrint('CallKit Event: ${event.event} - Body: ${event.body}');

      final callId = event.body?['id']?.toString() ?? '';

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint('User accepted call from CallKit: $callId');
          onCallAccepted?.call(callId);
          break;
        case Event.actionCallDecline:
          debugPrint('User declined call from CallKit: $callId');
          onCallDeclined?.call(callId);
          break;
        case Event.actionCallTimeout:
          debugPrint('Call timed out in CallKit: $callId');
          onCallTimeout?.call(callId);
          break;
        case Event.actionCallEnded:
          debugPrint('Call ended in CallKit: $callId');
          onCallEnded?.call(callId);
          break;
        case Event.actionCallCallback:
          debugPrint('Call back tapped from CallKit: $callId');
          onCallCallback?.call(callId, event.body);
          break;
        default:
          break;
      }
    });
  }

  /// Displays full-screen native incoming call UI (works even when phone is locked or app is in background)
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    required String callerPhone,
    String? callerAvatar,
    String? callerId,
    String subtitle = 'Livocal Voice Call • AI Interpreter Active',
  }) async {
    final isMuted = callerId != null &&
        callerId.isNotEmpty &&
        SharedPref.isInitialized &&
        (SharedPref.instance.getBool('contact_muted_$callerId') ?? false);

    final customEnabled = callerId != null &&
        callerId.isNotEmpty &&
        SharedPref.isInitialized &&
        (SharedPref.instance.getBool('custom_notif_enabled_$callerId') ?? false);

    final customPath = customEnabled
        ? (SharedPref.isInitialized ? SharedPref.instance.getString('contact_custom_ringtone_path_$callerId') : null)
        : (SharedPref.isInitialized ? SharedPref.instance.getString('notif_custom_ringtone_path') : null);

    String ringtone = 'livocal_harmony';
    if (isMuted) {
      ringtone = 'silent';
    } else if (customPath != null &&
        customPath.isNotEmpty &&
        File(customPath).existsSync()) {
      ringtone = customPath;
    } else if (SharedPref.isInitialized) {
      final selectedTone = customEnabled
          ? (SharedPref.instance.getString('contact_call_ringtone_$callerId') ??
              SharedPref.instance.getString('notif_call_ringtone') ??
              'Livocal Harmony (Default)')
          : (SharedPref.instance.getString('notif_call_ringtone') ??
              'Livocal Harmony (Default)');

      if (selectedTone.contains('Digital Pulse')) {
        ringtone = 'digital_pulse';
      } else if (selectedTone.contains('Marimba')) {
        ringtone = 'marimba_bloom';
      } else if (selectedTone.contains('Classic Bell')) {
        ringtone = 'classic_bell';
      } else if (selectedTone.contains('Livocal Harmony')) {
        ringtone = 'livocal_harmony';
      }
    }

    final CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Livocal',
      avatar: (callerAvatar != null && callerAvatar.isNotEmpty)
          ? callerAvatar
          : '',
      handle: callerPhone,
      type: 0, // 0: Audio Call, 1: Video Call
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: false,
        isShowCallback: false,
        subtitle: 'Missed Call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{
        'callId': callId,
        'callerId': callerId ?? '',
        'callerName': callerName,
        'callerPhone': callerPhone,
        'callerAvatar': callerAvatar ?? '',
      },
      headers: <String, dynamic>{'apiKey': 'LivocalCall'},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: ringtone,
        backgroundColor: '#091014',
        actionColor: '#00A884',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: isMuted
            ? 'Livocal Muted Calls'
            : 'Livocal Incoming Calls',
        missedCallNotificationChannelName: 'Livocal Missed Calls',
        isShowFullLockedScreen: !isMuted,
      ),
      ios: IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: !isMuted,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: isMuted
            ? 'silent.wav'
            : (ringtone.contains('/')
                ? ringtone
                : (ringtone.endsWith('.wav') ? ringtone : '$ringtone.wav')),
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }

  /// Displays native missed call notification with "Call back" action
  Future<void> showMissedCallNotification({
    required String callId,
    required String callerName,
    required String callerPhone,
    String? callerAvatar,
  }) async {
    final CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Livocal',
      avatar: (callerAvatar != null && callerAvatar.isNotEmpty)
          ? callerAvatar
          : '',
      handle: callerPhone,
      type: 0,
      extra: <String, dynamic>{
        'callId': callId,
        'callerName': callerName,
        'callerPhone': callerPhone,
      },
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed Call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#091014',
        actionColor: '#00A884',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Livocal Incoming Calls',
        missedCallNotificationChannelName: 'Livocal Missed Calls',
        isShowFullLockedScreen: true,
      ),
    );

    try {
      await FlutterCallkitIncoming.showMissCallNotification(callKitParams);
    } catch (e) {
      debugPrint('[CallKitService] showMissCallNotification error: $e');
    }
  }

  /// Dismisses native call screen when answered or hung up
  Future<void> endCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('[CallKitService] endCall suppressed in test/headless: $e');
    }
  }

  /// Dismisses all ongoing CallKit notifications
  Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('[CallKitService] endAllCalls suppressed in test/headless: $e');
    }
  }

  void dispose() {
    _callKitSubscription?.cancel();
    _callKitSubscription = null;
  }
}
