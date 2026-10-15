import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/status/services/status_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/settings_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('StatusService Viewed Cache Tests', () {
    test('getViewedStatusIds returns empty set by default', () {
      final viewed = StatusService.getViewedStatusIds();
      expect(viewed.isEmpty, isTrue);
    });

    test('markStatusAsViewed saves status ID to persistent cache', () async {
      await StatusService.markStatusAsViewed('status_abc');
      final viewed = StatusService.getViewedStatusIds();
      expect(viewed.contains('status_abc'), isTrue);
      expect(viewed.length, equals(1));
    });

    test('markStatusAsViewed prevents duplicate status IDs', () async {
      await StatusService.markStatusAsViewed('status_abc');
      await StatusService.markStatusAsViewed('status_abc');
      await StatusService.markStatusAsViewed('status_xyz');
      final viewed = StatusService.getViewedStatusIds();
      expect(viewed.length, equals(2));
      expect(viewed.contains('status_abc'), isTrue);
      expect(viewed.contains('status_xyz'), isTrue);
    });
  });

  group('SettingsRow Component Tests', () {
    testWidgets('Renders title, subtitle and icon with tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsRow(
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Block contacts, disappearing messages',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Block contacts, disappearing messages'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Privacy & Security'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renders trailing switch when trailing is provided', (tester) async {
      bool switchVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsRow(
                  icon: Icons.notifications,
                  title: 'High priority alerts',
                  trailing: Switch(
                    value: switchVal,
                    onChanged: (val) {
                      setState(() => switchVal = val);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('High priority alerts'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(switchVal, isTrue);
    });

    testWidgets('SettingsSectionHeader renders section title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsSectionHeader(title: 'Account & Security'),
          ),
        ),
      );

      expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
    });
  });
}
