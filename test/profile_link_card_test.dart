import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/widgets/profile_link_card.dart';

void main() {
  group('ProfileLinkCard', () {
    late int copies;
    late int shares;
    late int previews;
    late int guestCalls;
    late int qrTaps;

    String t(String key) => key;

    Future<void> pumpCard(WidgetTester tester, {bool published = true}) async {
      copies = 0;
      shares = 0;
      previews = 0;
      guestCalls = 0;
      qrTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileLinkCard(
              url: 'https://livocal.app/u/shojib',
              published: published,
              t: t,
              onCopy: () => copies++,
              onShare: () => shares++,
              onPreview: () => previews++,
              onRegenerate: () {},
              onQr: () => qrTaps++,
              onGuestCall: () => guestCalls++,
            ),
          ),
        ),
      );
    }

    testWidgets('shows the guest call action when published', (tester) async {
      await pumpCard(tester);
      expect(find.text('guestCall'), findsOneWidget);
    });

    testWidgets('tapping guest call fires the callback', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.text('guestCall'));
      await tester.pump();
      expect(guestCalls, 1);
      expect(previews, 0);
    });

    testWidgets('hides actions until the page is published', (tester) async {
      await pumpCard(tester, published: false);
      expect(find.text('guestCall'), findsNothing);
      expect(find.text('copyProfileLink'), findsNothing);
    });
  });
}
