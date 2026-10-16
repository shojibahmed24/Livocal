import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

import '../../features/chat/models/message.dart';
import '../../features/calls/services/call_kit_service.dart';
import '../../features/calls/services/gemini_live_translator.dart';
import '../../features/calls/services/ringtone_manager.dart';
import 'package:livocal/shared/constants/app_config.dart';

final pushNotificationsRepoProvider = Provider(
  (ref) => PushNotificationsRepo(FirebaseMessaging.instance, ref),
);

class PushNotificationsRepo {
  final FirebaseMessaging instance;
  final ProviderRef ref;

  PushNotificationsRepo(this.instance, this.ref);

  Future<void> init({
    required Future<void> Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    try {
      await instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e, st) {
      debugPrint('[PushNotificationsRepo] requestPermission error: $e\n$st');
    }

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationsRepo] Foreground notification received: ${message.data}');
      if (message.data['type'] != 'INCOMING_CALL') {
        RingtoneManager().playMessageNotificationTone();
      }
    });
    instance.onTokenRefresh.listen((token) => handleTokenRefresh(token, ref));

    try {
      final initialToken = await instance.getToken();
      if (initialToken != null && initialToken.isNotEmpty) {
        handleTokenRefresh(initialToken, ref);
      }
    } catch (e, st) {
      debugPrint('[PushNotificationsRepo] getToken error: $e\n$st');
    }
  }

  Future<void> sendPushNotification(Message message) async {
    final String url = AppConfig.chatNotifyMessageUrl;
    final idToken = await GeminiLiveTranslator.getAuthToken();
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      if (idToken != null) "Authorization": "Bearer $idToken",
    };

    String messageContent = message.content;
    if (message.attachment != null) {
      messageContent = "Sent an attachment";
    }

    final user = getCurrentUser();
    if (user == null) return;

    // Security: Only pass recipient ID and message details.
    // The backend uses Admin SDK to lookup recipient's private FCM token and verifies author identity.
    final String messageJson = jsonEncode(
      {
        'receiverId': message.receiverId,
        'messageId': message.id,
        'messageContent': messageContent,
        'authorId': user.id,
      },
    );

    try {
      final res = await post(
        Uri.parse(url),
        headers: headers,
        body: messageJson,
      );
      if (res.statusCode != 200) {
        debugPrint('[PushNotificationsRepo] push notification returned status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[PushNotificationsRepo] sendPushNotification failed for msg ${message.id}: $e');
    }
  }
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;

  // 1. Wake up phone for Incoming Voice Call
  if (data['type'] == 'INCOMING_CALL') {
    final callId = data['callId'] ?? '';
    final callerName = data['callerName'] ?? 'Incoming Call';
    final callerNumber = data['callerNumber'] ?? '';
    await CallKitService().showIncomingCall(
      callId: callId,
      callerName: callerName,
      callerPhone: callerNumber,
    );
    return;
  }

  // 2. Chat message delivered status update
  if (data['messageId'] != null) {
    await ProviderContainer()
        .read(firebaseFirestoreRepositoryProvider)
        .sendSystemMessage(
          message: SystemMessage(
            targetId: data['messageId'],
            action: MessageAction.statusUpdate,
            update: MessageStatus.delivered.value,
          ),
          receiverId: data['authorId'],
        );
  }
}

void handleTokenRefresh(String newToken, ProviderRef ref) {
  final oldToken = SharedPref.instance.getString('fcmToken');
  if (newToken == oldToken) return;

  SharedPref.instance.setString('fcmToken', newToken);
  ref.read(firebaseFirestoreRepositoryProvider).setFcmToken(newToken);
}
