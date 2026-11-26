import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:livocal/features/freelancer/models/proposal.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/services/app_check_service.dart';

/// Publishes a proposal snapshot with a share token.
class ProposalShareService {
  ProposalShareService._();

  static String _newToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(24, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  static Future<String> publish({
    required String ownerUid,
    required String ownerName,
    required String clientName,
    required Proposal proposal,
  }) async {
    final body = {
      'ownerName': ownerName,
      'clientName': clientName,
      'headline': proposal.headline,
      'scope': proposal.scope,
      'timeline': proposal.timeline,
      'price': proposal.price,
      'terms': proposal.terms,
    };

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        final response = await http
            .post(
              Uri.parse(AppConfig.shareProposalUrl),
              headers: await AppCheckService.withAppCheck({
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final share = (data is Map) ? data['token']?.toString() : null;
          if (share != null && share.isNotEmpty) return share;
        }
      }
    } catch (e) {
      debugPrint('[ProposalShareService] endpoint failed: $e');
    }

    // Fallback: direct Firestore snapshot.
    final token = _newToken();
    try {
      await FirebaseFirestore.instance
          .collection('public_proposals')
          .doc(token)
          .set({
        ...body,
        'ownerUid': ownerUid,
        'createdAt': DateTime.now().toIso8601String()
      });
    } catch (e) {
      debugPrint('[ProposalShareService] publish failed: $e');
    }
    return token;
  }
}
