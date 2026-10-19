import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
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

    test('Bangladeshi phone numbers infer peer language as bn, not en', () {
      expect(CallRepository.inferPeerLanguageCode('phone_+8801721013902', 'Baba'), equals('bn'));
      expect(CallRepository.inferPeerLanguageCode('some_id', 'Baba', phone: '01721013902'), equals('bn'));
      expect(CallRepository.inferPeerLanguageCode('some_id', 'Baba', phone: '+8801303456776'), equals('bn'));
    });

    test('Peer translation settings resolves Bangla to Bangla and disables AI translation when languages match', () async {
      const peerId = 'phone_+8801721013902';
      const peerName = 'Baba';
      const peerPhone = '01721013902';

      // Simulate saving preferences in In-Chat AI Live Translation sheet (Bangla to Bangla)
      final prefixes = CallRepository.getCandidatePrefixes(peerId, peerName, phone: peerPhone);
      for (final p in prefixes) {
        await SharedPref.instance.setBool('${p}_enabled', false);
        await SharedPref.instance.setString('${p}_my_lang', 'bn');
        await SharedPref.instance.setString('${p}_peer_lang', 'bn');
      }

      final settings = CallRepository.getPeerTranslationSettings(
        peerId: peerId,
        peerName: peerName,
        peerPhone: peerPhone,
      );

      expect(settings.myLangCode, equals('bn'), reason: 'My language must be Bangla');
      expect(settings.peerLangCode, equals('bn'), reason: 'Peer language must be Bangla (NOT English)');
      expect(settings.isSameLanguage, isTrue, reason: 'Both users speak Bangla');
      expect(settings.isTranslationEnabled, isFalse, reason: 'Translation must be disabled when user toggles off or same language');
      expect(settings.isEffectivelyTranslated, isFalse, reason: 'Must be a Free Direct Voice Call, zero AI translation');
    });

    test('Peer translation settings respects toggle OFF even when languages differ', () async {
      const peerId = 'user_carlos_es';
      const peerName = 'Carlos';
      const peerPhone = '+34612345678';

      // User chooses Spanish for Carlos, but turns live translation toggle OFF
      await SharedPref.instance.setBool('chat_trans_${peerId}_enabled', false);
      await SharedPref.instance.setString('chat_trans_${peerId}_my_lang', 'bn');
      await SharedPref.instance.setString('chat_trans_${peerId}_peer_lang', 'es');

      final settings = CallRepository.getPeerTranslationSettings(
        peerId: peerId,
        peerName: peerName,
        peerPhone: peerPhone,
      );

      expect(settings.myLangCode, equals('bn'));
      expect(settings.peerLangCode, equals('es'));
      expect(settings.isSameLanguage, isFalse);
      expect(settings.isTranslationEnabled, isFalse, reason: 'Explicit toggle OFF must be respected');
      expect(settings.isEffectivelyTranslated, isFalse, reason: 'Call should connect via direct voice without translation');
    });

    test('Peer translation settings enables AI translation when languages differ and toggle is ON', () async {
      const peerId = 'user_john_us';
      const peerName = 'John';
      const peerPhone = '+14155552671';

      // User chooses English for John, and turns live translation toggle ON
      await SharedPref.instance.setBool('chat_trans_${peerId}_enabled', true);
      await SharedPref.instance.setString('chat_trans_${peerId}_my_lang', 'bn');
      await SharedPref.instance.setString('chat_trans_${peerId}_peer_lang', 'en');

      final settings = CallRepository.getPeerTranslationSettings(
        peerId: peerId,
        peerName: peerName,
        peerPhone: peerPhone,
      );

      expect(settings.myLangCode, equals('bn'));
      expect(settings.peerLangCode, equals('en'));
      expect(settings.isSameLanguage, isFalse);
      expect(settings.isTranslationEnabled, isTrue);
      expect(settings.isEffectivelyTranslated, isTrue);
    });
  });
}
