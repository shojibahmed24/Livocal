import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Writes the CV summary server-side (English only, nothing stored).
class AiSummaryService {
  AiSummaryService._();

  static Future<String?> generate({
    required FreelancerProfile profile,
    String tone = 'professional',
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return null;

      final body = <String, dynamic>{
        'displayName': profile.displayName,
        'headline': profile.headline,
        'skills': profile.skills.take(20).toList(),
        'experience': profile.experienceEntries
            .take(8)
            .map((item) => {
                  'role': item['role'] ?? '',
                  'company': item['company'] ?? '',
                  'start': item['start'] ?? '',
                  'end': item['end'] ?? '',
                  'summary': item['summary'] ?? '',
                })
            .toList(),
        'education': profile.educationEntries
            .take(5)
            .map((item) => {
                  'school': item['school'] ?? '',
                  'degree': item['degree'] ?? '',
                })
            .toList(),
        'services': profile.serviceEntries
            .map((item) => item['title'] ?? '')
            .where((title) => title.isNotEmpty)
            .take(8)
            .toList(),
        'languages': profile.languageEntries
            .map((item) => '${item['code']} ${item['level']}'.trim())
            .take(8)
            .toList(),
        'yearsExperience': profile.yearsExperience,
        'tone': tone,
      };
      if (profile.rateAmount > 0) {
        body['rate'] = {
          'amount': profile.rateAmount,
          'currency': profile.rateCurrency,
          'basis': profile.rateBasis,
        };
      }

      final response = await http
          .post(
            Uri.parse(AppConfig.aiSummaryUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        debugPrint('[AiSummaryService] HTTP ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      if (data is! Map) return null;
      final text = (data['text'] ?? '').toString().trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      debugPrint('[AiSummaryService] generate failed: $e');
      return null;
    }
  }
}
