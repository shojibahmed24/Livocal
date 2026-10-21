import 'dart:convert';
import 'package:flutter/widgets.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

import 'package:livocal/features/settings/services/block_service.dart';
import '../../features/chat/models/message.dart';
import '../../features/calls/services/call_kit_service.dart';
import '../../features/calls/services/gemini_live_translator.dart';
import '../../features/calls/services/ringtone_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/constants/app_config.dart';
import '../../firebase_options.dart';

final pushNotificationsRepoProvider = Provider(
  (ref) => PushNotificationsRepo(FirebaseMessaging.instance, ref),
);

class PushNotificationsRepo {
  final FirebaseMessaging instance;
  final Ref ref;

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

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationsRepo] Foreground notification received: ${message.data}');
      final contactId = message.data['authorId'] as String? ??
          message.data['senderId'] as String? ??
          message.data['callerId'] as String?;
      if (contactId != null && BlockService.isBlocked(contactId)) {
        debugPrint('[PushNotificationsRepo] Suppressing foreground notification from blocked contact: $contactId');
        return;
      }
      if (contactId != null &&
          SharedPref.isInitialized &&
          (SharedPref.instance.getBool('contact_muted_$contactId') ?? false)) {
        debugPrint('[PushNotificationsRepo] Suppressing foreground notification tone for muted contact: $contactId');
        return;
      }
      if (message.data['type'] != 'INCOMING_CALL') {
        RingtoneManager().playMessageNotificationTone(contactId: contactId);
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

    final customEnabled = SharedPref.isInitialized &&
        (SharedPref.instance.getBool('custom_notif_enabled_${message.receiverId}') ?? false);
    final isHighPriority = SharedPref.isInitialized &&
        (customEnabled
            ? (SharedPref.instance.getBool('contact_high_priority_${message.receiverId}') ??
                SharedPref.instance.getBool('notif_high_priority') ??
                true)
            : (SharedPref.instance.getBool('notif_high_priority') ?? true));

    // Security: Only pass recipient ID and message details.
    // The backend uses Admin SDK to lookup recipient's private FCM token and verifies author identity.
    final String messageJson = jsonEncode(
      {
        'receiverId': message.receiverId,
        'messageId': message.id,
        'messageContent': messageContent,
        'authorId': user.id,
        'highPriority': isHighPriority,
        if (message.expiresAt != null)
          'expiresAt': message.expiresAt!.millisecondsSinceEpoch.toString(),
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[PushNotificationsRepo] Background Firebase.initializeApp error: $e');
  }

  try {
    await SharedPref.init();
  } catch (e) {
    debugPrint('[PushNotificationsRepo] Background SharedPref.init error: $e');
  }

  final data = message.data;

  // 1. Wake up phone for Incoming Voice Call
  if (data['type'] == 'INCOMING_CALL') {
    final callerId = data['callerId'] as String? ?? '';
    try {
      if (callerId.isNotEmpty) {
        bool blocked = false;
        try {
          blocked = BlockService.isBlocked(callerId);
        } catch (blockErr) {
          debugPrint('[PushNotificationsRepo] isBlocked check error: $blockErr');
          blocked = false;
        }
        if (blocked) {
          debugPrint('[PushNotificationsRepo] Suppressing background call from blocked caller: $callerId');
          return;
        }
      }
    } catch (e) {
      debugPrint('[PushNotificationsRepo] Error checking block status: $e');
    }

    try {
      if (callerId.isNotEmpty && data['isMuted'] == 'true' && SharedPref.isInitialized) {
        await SharedPref.instance.setBool('contact_muted_$callerId', true);
      }
      final isMuted = data['isMuted'] == 'true' ||
          (callerId.isNotEmpty &&
              SharedPref.isInitialized &&
              (SharedPref.instance.getBool('contact_muted_$callerId') ?? false));

      if (isMuted) {
        debugPrint('[PushNotificationsRepo] Completely suppressing CallKit popup for muted caller: $callerId');
        return;
      }

      final callId = data['callId'] ?? '';
      final callerName = data['callerName'] ?? 'Incoming Call';
      final callerPhone = data['callerNumber'] ?? data['callerPhone'] ?? '';
      final callerAvatar = data['callerAvatar'] as String?;
      await CallKitService().showIncomingCall(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerPhone: callerPhone,
        callerAvatar: callerAvatar,
      );
    } catch (e, st) {
      debugPrint('[PushNotificationsRepo] CallKitService showIncomingCall error: $e\n$st');
    }
    return;
  }

  // 2. Remote Delete for Everyone / Purge synchronization in background
  if (data['type'] == 'DELETE_MESSAGE' || data['type'] == 'PURGE_EXPIRED') {
    final msgId = data['messageId'] as String?;
    try {
      await IsarDb.init();
      if (msgId != null && msgId.isNotEmpty) {
        await IsarDb.deleteMessage(msgId);
      }
      await IsarDb.purgeDisappearingMessages();
    } catch (e) {
      debugPrint('[PushNotificationsRepo] Background delete message sync error: $e');
    }
    return;
  }

  // 3. Chat message delivered status update & local Isar persistence
  if (data['messageId'] != null) {
    try {
      final authorId = data['authorId'] as String? ?? '';
      if (authorId.isNotEmpty) {
        bool blocked = false;
        try {
          blocked = BlockService.isBlocked(authorId);
        } catch (_) {}
        if (blocked) {
          debugPrint(
              '[PushNotificationsRepo] Dropping background message from blocked author: $authorId');
          return;
        }
      }
      await IsarDb.init();
      // Opportunistically purge any expired disappearing messages from local Isar in the background isolate
      await IsarDb.purgeDisappearingMessages();

      final msgId = data['messageId'] as String;
      final content = data['messageContent'] as String? ?? data['body'] as String? ?? '';
      String currentUid = '';
      if (SharedPref.isInitialized) {
        final rawUser = SharedPref.instance.getString('user');
        if (rawUser != null) {
          try {
            final u = jsonDecode(rawUser);
            currentUid = u['id'] ?? '';
          } catch (_) {}
        }
      }

      Timestamp? expiresAt;
      if (data['expiresAt'] != null) {
        try {
          final expMs = int.tryParse(data['expiresAt'].toString());
          if (expMs != null) {
            expiresAt = Timestamp.fromMillisecondsSinceEpoch(expMs);
          }
        } catch (_) {}
      }

      if (msgId.isNotEmpty && authorId.isNotEmpty) {
        await IsarDb.addMessage(Message(
          id: msgId,
          content: content,
          status: MessageStatus.delivered,
          senderId: authorId,
          receiverId: currentUid,
          timestamp: Timestamp.now(),
          expiresAt: expiresAt,
        ));
      }
    } catch (e) {
      debugPrint('[PushNotificationsRepo] Background message Isar save error: $e');
    }

    try {
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
    } catch (e) {
      debugPrint('[PushNotificationsRepo] Background delivered status update error: $e');
    }
  }
}

void handleTokenRefresh(String newToken, Ref ref) {
  final oldToken = SharedPref.instance.getString('fcmToken');
  if (newToken == oldToken) return;

  SharedPref.instance.setString('fcmToken', newToken);
  ref.read(firebaseFirestoreRepositoryProvider).setFcmToken(newToken);
}
