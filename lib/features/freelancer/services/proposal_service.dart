import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/features/freelancer/models/proposal.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Drafts a proposal server-side with Gemini (text only, nothing stored).
class ProposalService {
  ProposalService._();

  static Future<Proposal?> generate({
    required String displayName,
    required String headline,
    required List<String> skills,
    required String clientName,
    required String brief,
    String hints = '',
    double rateAmount = 0,
    String rateCurrency = 'USD',
    String rateBasis = 'hourly',
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return null;

      final body = <String, dynamic>{
        'displayName': displayName,
        'headline': headline,
        'skills': skills.take(20).toList(),
        'clientName': clientName,
        'brief': brief.trim(),
        'hints': hints.trim(),
      };
      if (rateAmount > 0) {
        body['rate'] = {
          'amount': rateAmount,
          'currency': rateCurrency,
          'basis': rateBasis,
        };
      }

      final response = await http
          .post(
            Uri.parse(AppConfig.proposalUrl),
            headers: await AppCheckService.withAppCheck({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        debugPrint('[ProposalService] HTTP ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      if (data is! Map) return null;
      final raw = data['proposal'];
      if (raw is! Map) return null;
      final proposal = Proposal.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (proposal != null) {
        proposal.source = (data['source'] ?? 'ai').toString();
        proposal.reason = (data['reason'] ?? '').toString();
      }
      return proposal;
    } catch (e) {
      debugPrint('[ProposalService] generate failed: $e');
      return null;
    }
  }
}
