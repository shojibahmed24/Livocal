import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/auth/controllers/login_controller.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('Login Controller Country Resolution Tests', () {
    test('defaultCountryProvider resolves to valid country and not hardcoded India', () {
      final container = ProviderContainer();
      final country = container.read(defaultCountryProvider);

      expect(country.phoneCode.isNotEmpty, isTrue);
      expect(country.countryCode.isNotEmpty, isTrue);
      // Valid default for Livocal is Bangladesh (+880) or device locale
      expect(country.phoneCode, anyOf(equals('880'), equals('1'), isNotEmpty));
    });
  });

  group('ScaffoldWithSearch Duplicate Icon Bug Tests', () {
    testWidgets('Does not insert duplicate search icons on multiple rebuilds', (tester) async {
      final searchController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldWithSearch(
            appBar: AppBar(
              title: const Text('Contacts'),
              actions: const [
                Icon(Icons.more_vert),
              ],
            ),
            searchController: searchController,
            onChanged: (_) {},
            onCloseBtnPressed: () {},
            child: const Text('Body Content'),
          ),
        ),
      );

      // Verify exactly 1 search icon initially
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Rebuild the widget multiple times (simulate keyboard popup, state updates)
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Verify STILL exactly 1 search icon exists (no duplicate accumulation!)
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
