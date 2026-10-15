import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('AppLocalizations & Strings Tests', () {
    test('English dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'en'), equals('CHATS'));
      expect(AppStrings.get('status', 'en'), equals('STATUS'));
      expect(AppStrings.get('calls', 'en'), equals('CALLS'));
      expect(AppStrings.get('settings', 'en'), equals('Settings'));
    });

    test('Bengali dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'bn'), equals('চ্যাট'));
      expect(AppStrings.get('status', 'bn'), equals('স্ট্যাটাস'));
      expect(AppStrings.get('calls', 'bn'), equals('কল'));
      expect(AppStrings.get('settings', 'bn'), equals('সেটিংস'));
    });

    test('Unknown keys gracefully return fallback', () {
      expect(AppStrings.get('non_existent_key_xyz', 'bn'), equals('non_existent_key_xyz'));
    });
  });

  group('Two-Step PIN Verification Storage Tests', () {
    test('Two-step PIN can be set, checked, and disabled in SharedPref', () async {
      expect(SharedPref.instance.getString('two_step_pin'), isNull);

      await SharedPref.instance.setString('two_step_pin', '123456');
      expect(SharedPref.instance.getString('two_step_pin'), equals('123456'));

      final currentPin = SharedPref.instance.getString('two_step_pin');
      expect(currentPin == '123456', isTrue);
      expect(currentPin == '999999', isFalse);

      await SharedPref.instance.remove('two_step_pin');
      expect(SharedPref.instance.getString('two_step_pin'), isNull);
    });
  });
}
