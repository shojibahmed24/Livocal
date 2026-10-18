import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/secure_pin_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SharedPref.init();
  });

  group('AppLocalizations & Multilingual Strings Tests', () {
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

    test('Hindi dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'hi'), equals('चैट'));
      expect(AppStrings.get('status', 'hi'), equals('स्टेटस'));
      expect(AppStrings.get('calls', 'hi'), equals('कॉल'));
      expect(AppStrings.get('settings', 'hi'), equals('सेटिंग्स'));
    });

    test('Arabic dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'ar'), equals('الدردشات'));
      expect(AppStrings.get('status', 'ar'), equals('الحالة'));
      expect(AppStrings.get('calls', 'ar'), equals('المكالمات'));
      expect(AppStrings.get('settings', 'ar'), equals('الإعدادات'));
    });

    test('Spanish dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'es'), equals('CHATS'));
      expect(AppStrings.get('status', 'es'), equals('ESTADOS'));
      expect(AppStrings.get('calls', 'es'), equals('LLAMADAS'));
      expect(AppStrings.get('settings', 'es'), equals('Ajustes'));
    });

    test('French dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'fr'), equals('DISCUSSIONS'));
      expect(AppStrings.get('status', 'fr'), equals('STATUT'));
      expect(AppStrings.get('calls', 'fr'), equals('APPELS'));
      expect(AppStrings.get('settings', 'fr'), equals('Paramètres'));
    });

    test('German dictionary contains key system translations', () {
      expect(AppStrings.get('chats', 'de'), equals('CHATS'));
      expect(AppStrings.get('status', 'de'), equals('STATUS'));
      expect(AppStrings.get('calls', 'de'), equals('ANRUFE'));
      expect(AppStrings.get('settings', 'de'), equals('Einstellungen'));
    });

    test('100% Key Parity: All 7 supported locales have identical key sets with non-empty values', () {
      final supportedLocales = AppStrings.supportedLanguages;
      expect(supportedLocales, unorderedEquals(['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de']));

      final enKeys = AppStrings.allKeys;
      expect(enKeys.length, greaterThanOrEqualTo(150), reason: 'All sub-screens must be included');

      for (final lang in supportedLocales) {
        final langDict = AppStrings.localizedValues[lang];
        expect(langDict, isNotNull, reason: 'Language $lang must have a dictionary');

        final langKeys = langDict!.keys.toSet();
        final missingKeys = enKeys.difference(langKeys);
        expect(missingKeys, isEmpty,
            reason: 'Language $lang is missing ${missingKeys.length} keys: $missingKeys');

        for (final entry in langDict.entries) {
          expect(entry.value.trim().isNotEmpty, isTrue,
              reason: 'Language $lang key "${entry.key}" must not have empty value');
        }
      }
    });

    test('All 6 Settings Sub-screens have complete translations across all 7 locales', () {
      const subScreenSampleKeys = [
        // Account screen
        'account', 'securityAndAccess', 'twoStepVerification', 'changeNumber', 'deleteMyAccount',
        // Privacy screen
        'privacy', 'whoCanSeeMyInfo', 'lastSeenAndOnline', 'disappearingMessages', 'fingerprintLock',
        // Notifications screen
        'notifications', 'conversationTones', 'messagesHeader', 'notificationTone', 'callRingtoneTitle',
        // Storage screen
        'storage', 'manageStorage', 'storageBreakdown', 'networkUsage', 'whenUsingMobileData',
        // Help screen
        'help', 'helpCentre', 'contactSupport', 'faqTitle', 'aboutLivocal',
        // QR Code screen
        'qrCode', 'copyLink', 'shareQrCode', 'qrCodeDesc',
      ];

      for (final key in subScreenSampleKeys) {
        for (final lang in AppStrings.supportedLanguages) {
          final translated = AppStrings.get(key, lang);
          expect(translated, isNot(equals(key)),
              reason: 'Key "$key" should be translated in locale "$lang"');
          expect(translated.trim().isNotEmpty, isTrue);
        }
      }
    });

    test('Unknown keys gracefully return fallback', () {
      expect(AppStrings.get('non_existent_key_xyz', 'bn'), equals('non_existent_key_xyz'));
    });
  });

  group('Hardware-Backed SecurePinService Tests', () {
    test('PIN lifecycle: set, check, verify, disable, and auto-clean plaintext', () async {
      await SecurePinService.disablePin();
      expect(await SecurePinService.isPinSet(), isFalse);

      await SecurePinService.setPin('654321');
      expect(await SecurePinService.isPinSet(), isTrue);
      expect(await SecurePinService.verifyPin('654321'), isTrue);
      expect(await SecurePinService.verifyPin('111111'), isFalse);
      expect(SharedPref.instance.getString('two_step_pin'), isNull);

      await SecurePinService.disablePin();
      expect(await SecurePinService.isPinSet(), isFalse);
      expect(await SecurePinService.verifyPin('654321'), isFalse);
    });

    test('Legacy migration: plaintext PIN in SharedPref is migrated to Keystore and purged', () async {
      await SecurePinService.disablePin();
      await SharedPref.instance.setString('two_step_pin', '987654');

      expect(await SecurePinService.isPinSet(), isTrue);
      expect(await SecurePinService.verifyPin('987654'), isTrue);
      expect(SharedPref.instance.getString('two_step_pin'), isNull);
    });

    test('Brute-force lockout: 5 consecutive failed attempts trigger lockout', () async {
      await SecurePinService.disablePin();
      await SecurePinService.setPin('123456');

      expect(SecurePinService.getRemainingLockoutSeconds(), equals(0));

      // Attempt 4 failed tries
      for (int i = 0; i < 4; i++) {
        expect(await SecurePinService.verifyPin('000000'), isFalse);
        expect(SecurePinService.getRemainingLockoutSeconds(), equals(0));
      }

      // 5th failed try triggers lockout
      expect(await SecurePinService.verifyPin('000000'), isFalse);
      expect(SecurePinService.getRemainingLockoutSeconds(), greaterThan(0));

      // During lockout, even correct PIN is rejected
      expect(await SecurePinService.verifyPin('123456'), isFalse);

      // Disabling PIN clears lockout
      await SecurePinService.disablePin();
      expect(SecurePinService.getRemainingLockoutSeconds(), equals(0));
    });
  });

  group('Locale Persistence & Restart Tests', () {
    test('App language persists and loads for all 7 supported locales', () async {
      const allLocales = ['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de'];
      for (final code in allLocales) {
        await SharedPref.instance.setString('app_language', code);
        final notifier = AppLocaleNotifier();
        expect(notifier.state.languageCode, equals(code));
      }
    });
  });

  group('Centralized AppConfig Tests', () {
    test('Default relay endpoints resolve properly', () {
      expect(AppConfig.relayHttpBaseUrl, contains('https://livocal-relay.onrender.com'));
      expect(AppConfig.relayWsBaseUrl, contains('wss://livocal-relay.onrender.com'));
      expect(AppConfig.callNotifyIncomingUrl, endsWith('/api/call/notify-incoming'));
      expect(AppConfig.chatNotifyMessageUrl, endsWith('/api/notify/chat-message'));
      expect(AppConfig.matchContactsUrl, endsWith('/api/contacts/match'));
      expect(AppConfig.iceServersUrl, endsWith('/api/webrtc/ice-servers'));
      expect(AppConfig.liveCallWsUrl, endsWith('/ws/live-call'));
    });
  });
}
