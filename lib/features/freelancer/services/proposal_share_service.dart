import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:livocal/features/freelancer/models/proposal.dart';

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
    final token = _newToken();
    try {
      await FirebaseFirestore.instance
          .collection('public_proposals')
          .doc(token)
          .set({
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'clientName': clientName,
        'headline': proposal.headline,
        'scope': proposal.scope,
        'timeline': proposal.timeline,
        'price': proposal.price,
        'terms': proposal.terms,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ProposalShareService] publish failed: $e');
    }
    return token;
  }
}
