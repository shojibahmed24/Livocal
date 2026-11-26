import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/models/call_summary.dart';

void main() {
  group('CallSummary', () {
    test('parses a full server payload', () {
      final summary = CallSummary.fromJson({
        'summary':
            'Client needs a landing page. / ক্লায়েন্ট একটি ল্যান্ডিং পেজ চায়।',
        'decisions': ['Start Monday', ''],
        'actionItems': [
          {'text': 'Send proposal', 'owner': 'me'},
          {'text': 'Share logo', 'owner': 'client'},
        ],
        'clientHints': 'Budget 300 USD, 2 weeks',
      });

      expect(summary, isNotNull);
      expect(summary!.decisions, ['Start Monday']);
      expect(summary.actionItems.length, 2);
      expect(summary.actionItems.first.isMine, isTrue);
      expect(summary.actionItems.last.isMine, isFalse);
      expect(summary.clientHints, contains('300'));
    });

    test('rejects payloads without a summary', () {
      expect(CallSummary.fromJson(null), isNull);
      expect(CallSummary.fromJson({'summary': '   '}), isNull);
    });

    test('plain text includes every non-empty section', () {
      const summary = CallSummary(
        summary: 'Scope agreed.',
        decisions: ['Use Flutter'],
        actionItems: [
          CallActionItem(text: 'Send quote', owner: 'me'),
          CallActionItem(text: 'Confirm budget', owner: 'client'),
        ],
        clientHints: 'Budget 500 USD',
      );

      final text = summary.toPlainText(
        title: 'Call summary',
        decisionsLabel: 'Decisions',
        actionsLabel: 'Action items',
        hintsLabel: 'Client hints',
        meLabel: 'Me',
        clientLabel: 'Client',
      );

      expect(text, contains('Scope agreed.'));
      expect(text, contains('Use Flutter'));
      expect(text, contains('[Me] Send quote'));
      expect(text, contains('[Client] Confirm budget'));
      expect(text, contains('Budget 500 USD'));
    });
  });
}
