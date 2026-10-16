import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  StreamSubscription? _callKitSubscription;

  void Function(String callId)? onCallAccepted;
  void Function(String callId)? onCallDeclined;

  void init({
    void Function(String callId)? onAccept,
    void Function(String callId)? onDecline,
  }) {
    onCallAccepted = onAccept;
    onCallDeclined = onDecline;

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
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          debugPrint('Call ended or timed out in CallKit');
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
    String subtitle = 'Livocal Voice Call • AI Interpreter Active',
  }) async {
    final CallKitParams callKitParams = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Livocal',
      avatar: callerAvatar ?? 'https://i.pravatar.cc/150?u=$callId',
      handle: callerPhone,
      type: 0, // 0: Audio Call, 1: Video Call
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed AI Voice Call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{
        'callId': callId,
        'callerName': callerName,
        'callerPhone': callerPhone,
      },
      headers: <String, dynamic>{'apiKey': 'LivocalCall'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#00B386',
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
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
