import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/calls/views/widgets/call_scaffold.dart';
import 'package:livocal/features/calls/views/widgets/swipe_to_answer.dart';

void main() {
  group('CallScaffold & Initials Helper Tests', () {
    test('getInitials formats two-word names to first letters uppercase', () {
      expect(CallScaffold.getInitials('John Doe'), 'JD');
      expect(CallScaffold.getInitials('rahim karim'), 'RK');
      expect(CallScaffold.getInitials('Alice Bob Charlie'), 'AB');
    });

    test('getInitials formats single-word names to first two characters', () {
      expect(CallScaffold.getInitials('Antigravity'), 'AN');
      expect(CallScaffold.getInitials('A'), 'A');
    });

    test('getInitials handles empty or whitespace-only inputs gracefully', () {
      expect(CallScaffold.getInitials(''), '?');
      expect(CallScaffold.getInitials('   '), '?');
    });

    test('getInitials handles unicode and Bengali names gracefully', () {
      final initials = CallScaffold.getInitials('রাহিম করিম');
      expect(initials.isNotEmpty, true);
    });
  });

  group('SwipeToAnswer Widget Tests', () {
    testWidgets('Renders decline button and swipe track with labels', (tester) async {
      bool answered = false;
      bool declined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToAnswer(
              onAnswer: () {
                answered = true;
              },
              onDecline: () {
                declined = true;
              },
              label: 'Swipe to answer (AI)',
            ),
          ),
        ),
      );

      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Swipe to answer (AI)'), findsOneWidget);
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);

      // Tapping decline button
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.pump();
      expect(declined, true);
      expect(answered, false);
    });
  });
}
