import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/ui/livocal_buttons.dart';
import 'package:livocal/shared/ui/livocal_card.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Call',
              icon: Icons.call_rounded,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Call'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
    });

    testWidgets('does not fire while disabled or loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(label: 'Call', onPressed: null),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Call',
              loading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SecondaryButton', () {
    testWidgets('renders and fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Invite',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Invite'), findsOneWidget);
      await tester.tap(find.byType(SecondaryButton));
      expect(taps, 1);
    });
  });

  group('LivocalCard', () {
    testWidgets('fires onTap and shows its child', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LivocalCard(
              onTap: () => taps++,
              child: const Text('Minutes 20'),
            ),
          ),
        ),
      );

      expect(find.text('Minutes 20'), findsOneWidget);
      await tester.tap(find.text('Minutes 20'));
      expect(taps, 1);
    });

    testWidgets('is inert without onTap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivocalCard(child: Text('Static')),
          ),
        ),
      );
      expect(find.text('Static'), findsOneWidget);
    });
  });
}
