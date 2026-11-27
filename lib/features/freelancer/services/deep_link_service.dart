import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/navigator_key.dart';

/// Handles `livocal://chat/<username>` links from the public profile page.
class DeepLinkService {
  DeepLinkService._();

  static bool _started = false;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    final links = AppLinks();
    try {
      final initial = await links.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('[DeepLink] initial failed: $e');
    }
    links.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  static Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'livocal' || uri.host != 'chat') return;
    final username = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first.trim()
        : (uri.queryParameters['username'] ?? '').trim();
    if (username.isEmpty) return;

    final self = getCurrentUser();
    if (self == null) return;

    try {
      final response = await http
          .get(Uri.parse(AppConfig.publicUserUrl(username)))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! Map) return;
      final uid = (data['uid'] ?? '').toString();
      if (uid.isEmpty) return;

      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) return;
      final map = Map<String, dynamic>.from(snap.data() ?? const {});
      map['id'] = uid;
      final peer = User.fromMap(map);

      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            self: self,
            other: peer,
            otherUserContactName: peer.name,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[DeepLink] open chat failed: $e');
    }
  }
}
