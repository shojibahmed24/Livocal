import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/utils/contact_filter_strings.dart';
import 'package:livocal/shared/utils/dialer_strings.dart';

void main() {
  group('DialerStrings', () {
    test('covers every supported app language', () {
      for (final lang in const ['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de']) {
        final s = DialerStrings.of(lang);
        expect(s.keypad.isNotEmpty, isTrue, reason: 'keypad missing for $lang');
        expect(s.call.isNotEmpty, isTrue, reason: 'call missing for $lang');
        expect(s.recent.isNotEmpty, isTrue, reason: 'recent missing for $lang');
        expect(s.invalidNumber.isNotEmpty, isTrue,
            reason: 'invalidNumber missing for $lang');
      }
    });

    test('falls back to English for an unknown language', () {
      expect(DialerStrings.of('xx').keypad, DialerStrings.of('en').keypad);
    });
  });

  group('ContactFilterStrings', () {
    test('covers every supported app language', () {
      for (final lang in const ['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de']) {
        final s = ContactFilterStrings.of(lang);
        expect(s.all.isNotEmpty, isTrue, reason: 'all missing for $lang');
        expect(s.invite.isNotEmpty, isTrue, reason: 'invite missing for $lang');
      }
    });
  });
}
