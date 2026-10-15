import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('CallLanguageRegistry Tests', () {
    test('Default registry contains Bengali and English', () {
      final bn = CallLanguageRegistry.fromCode('bn');
      final en = CallLanguageRegistry.fromCode('en');

      expect(bn.code, equals('bn'));
      expect(bn.nativeName, equals('বাংলা'));
      expect(en.code, equals('en'));
      expect(en.nativeName, equals('English'));
    });

    test('Supported languages list is not empty and codes are unique', () {
      const all = CallLanguageRegistry.allLanguages;
      expect(all, isNotEmpty);

      final codes = all.map((l) => l.code).toSet();
      expect(codes.length, equals(all.length));
    });

    test('Language inference correctly detects Bengali names', () {
      final lang = CallRepository.inferPeerLanguageCode('user_123', 'হাসান মাহমুদ');
      expect(lang, equals('bn'));
    });

    test('Language inference falls back to English for unknown names', () {
      final lang = CallRepository.inferPeerLanguageCode('user_456', 'John Doe');
      expect(lang, equals('en'));
    });
  });
}
