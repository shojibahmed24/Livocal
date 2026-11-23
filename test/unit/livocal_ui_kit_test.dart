import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/ui/livocal_card.dart';
import 'package:livocal/shared/ui/livocal_tabs.dart';
import 'package:livocal/shared/ui/pill_chip.dart';

void main() {
  group('LivocalTabs', () {
    testWidgets('renders every label and switches controller index',
        (tester) async {
      final controller = TabController(length: 3, vsync: const TestVSync());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LivocalTabs(
                  controller: controller,
                  labels: const ['Chats', 'Updates', 'Calls'],
                ),
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: const [
                      Center(child: Text('chats-body')),
                      Center(child: Text('updates-body')),
                      Center(child: Text('calls-body')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('chats-body'), findsOneWidget);

      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();

      expect(controller.index, 2);
      expect(find.text('calls-body'), findsOneWidget);

      controller.dispose();
    });
  });

  group('PillChip', () {
    testWidgets('shows its label and reacts to taps', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PillChip(
                label: 'বাংলা ⇄ English',
                icon: Icons.translate_rounded,
                tone: ChipTone.accent,
                onTap: () => tapped++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('বাংলা ⇄ English'), findsOneWidget);
      await tester.tap(find.byType(PillChip));
      expect(tapped, 1);
    });
  });

  group('EmptyState', () {
    testWidgets('renders title, body and action', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.call_rounded,
              title: 'No calls yet',
              body: 'Your recent calls will appear here.',
              actionLabel: 'Start a call',
              onAction: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No calls yet'), findsOneWidget);
      expect(find.text('Your recent calls will appear here.'), findsOneWidget);

      await tester.tap(find.text('Start a call'));
      expect(pressed, isTrue);
    });
  });

  group('LivocalSectionHeader', () {
    testWidgets('uppercases nothing and shows the title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivocalSectionHeader(title: 'Account'),
          ),
        ),
      );
      expect(find.text('Account'), findsOneWidget);
    });
  });
}
