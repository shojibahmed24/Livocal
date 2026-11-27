import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/models/proposal.dart';

void main() {
  group('Proposal', () {
    test('parses a bilingual payload', () {
      final proposal = Proposal.fromJson({
        'headline': 'Landing page build / ল্যান্ডিং পেজ তৈরি',
        'scope': 'Design + build / ডিজাইন + বিল্ড',
        'timeline': '5 days / ৫ দিন',
        'price': 'USD 300 / ৩০০ ডলার',
        'terms': '50% advance / ৫০% অগ্রিম',
      });

      expect(proposal, isNotNull);
      expect(proposal!.headline, contains('ল্যান্ডিং'));
      expect(proposal.timeline, contains('৫ দিন'));
    });

    test('rejects payloads missing required fields', () {
      expect(Proposal.fromJson(null), isNull);
      expect(
        Proposal.fromJson({'headline': 'Only a headline'}),
        isNull,
      );
    });

    test('plain text includes all sections', () {
      final proposal = Proposal(
        headline: 'Website',
        scope: 'Build 3 pages',
        timeline: '7 days',
        price: 'USD 400',
        terms: '50% advance',
      );

      final text = proposal.toPlainText(
        title: 'Proposal',
        scopeLabel: 'Scope',
        timelineLabel: 'Timeline',
        priceLabel: 'Price',
        termsLabel: 'Terms',
      );

      expect(text, contains('Website'));
      expect(text, contains('Build 3 pages'));
      expect(text, contains('7 days'));
      expect(text, contains('USD 400'));
      expect(text, contains('50% advance'));
    });
  });
}
