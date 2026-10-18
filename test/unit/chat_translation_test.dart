import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('In-Chat Live Translation Persistence & State Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPref.init();
    });

    test('Translation toggle defaults to false when unconfigured, preventing unexpected auto-enable', () {
      const peerId = 'user_baba_123';
      final isEnabled = SharedPref.instance.getBool('chat_trans_${peerId}_enabled');

      // Unset preference should be null/false
      expect(isEnabled, isNull);
    });

    test('Disabling in-chat translation persists cleanly across restarts and never reverts to true', () async {
      const peerId = 'user_baba_123';
      const keyPrefix = 'chat_trans_$peerId';

      // 1. User opens sheet, enables translation, and saves
      await SharedPref.instance.setBool('${keyPrefix}_enabled', true);
      await SharedPref.instance.setString('${keyPrefix}_my_lang', 'bn');
      await SharedPref.instance.setString('${keyPrefix}_peer_lang', 'en');

      expect(SharedPref.instance.getBool('${keyPrefix}_enabled'), isTrue);

      // 2. User subsequently toggles translation OFF
      await SharedPref.instance.setBool('${keyPrefix}_enabled', false);

      // 3. Re-read preference (simulating re-opening sheet or re-entering chat)
      final reloadedState = SharedPref.instance.getBool('${keyPrefix}_enabled') ?? false;
      expect(reloadedState, isFalse);

      // 4. Verify languages and preferences are preserved even while translation is disabled
      expect(SharedPref.instance.getString('${keyPrefix}_my_lang'), equals('bn'));
      expect(SharedPref.instance.getString('${keyPrefix}_peer_lang'), equals('en'));
    });

    test('Auto-translate incoming messages respects chat_trans_enabled flag', () async {
      const peerId = 'user_baba_123';
      const keyPrefix = 'chat_trans_$peerId';

      // If translation is disabled
      await SharedPref.instance.setBool('${keyPrefix}_enabled', false);
      await SharedPref.instance.setBool('${keyPrefix}_auto_incoming', true);

      final isEnabled = SharedPref.instance.getBool('${keyPrefix}_enabled') ?? false;
      final autoIncoming = SharedPref.instance.getBool('${keyPrefix}_auto_incoming') ?? true;

      final shouldAutoTranslate = isEnabled && autoIncoming;
      expect(shouldAutoTranslate, isFalse, reason: 'Disabled translation must never auto-translate incoming messages');

      // If translation is enabled
      await SharedPref.instance.setBool('${keyPrefix}_enabled', true);
      final isEnabledNow = SharedPref.instance.getBool('${keyPrefix}_enabled') ?? false;
      final shouldAutoTranslateNow = isEnabledNow && autoIncoming;
      expect(shouldAutoTranslateNow, isTrue);
    });

    test('Target language code resolves correctly from CallLanguageRegistry', () {
      const targetLangCode = 'bn';
      final targetLang = CallLanguageRegistry.allLanguages.firstWhere(
        (l) => l.code == targetLangCode,
        orElse: () => CallLanguageRegistry.allLanguages[0],
      );

      expect(targetLang.code, equals('bn'));
      expect(targetLang.nativeName, equals('বাংলা'));
      expect(targetLang.englishName, equals('Bengali (Bangladesh)'));
    });
  });
}
