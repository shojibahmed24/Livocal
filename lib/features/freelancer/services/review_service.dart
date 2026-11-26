import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// One rating per participant per call, aggregated on the relay.
class ReviewService {
  ReviewService._();

  static String _key(String callId) => 'reviewed_$callId';

  static bool alreadyReviewed(String callId) {
    if (callId.isEmpty) return true;
    return SharedPref.instance.getBool(_key(callId)) ?? false;
  }

  static Future<bool> submit({
    required String callId,
    required String targetUid,
    required int rating,
    String comment = '',
  }) async {
    if (callId.isEmpty || targetUid.isEmpty || rating < 1 || rating > 5) {
      return false;
    }
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse(AppConfig.callReviewUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({
              'callId': callId,
              'targetUid': targetUid,
              'rating': rating,
              'comment': comment.trim().slice(500),
            }),
          )
          .timeout(const Duration(seconds: 15));

      // 409 = already reviewed on another device; treat as done.
      if (response.statusCode == 200 || response.statusCode == 409) {
        await SharedPref.instance.setBool(_key(callId), true);
        return true;
      }
      debugPrint('[ReviewService] HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('[ReviewService] submit failed: $e');
      return false;
    }
  }
}

extension on String {
  String slice(int max) => length <= max ? this : substring(0, max);
}
