import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/utils/call_filter_strings.dart';
import 'package:livocal/shared/utils/dialer_strings.dart';

void main() {
  const languages = ['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de'];

  group('CallFilterStrings', () {
    test('covers every supported app language', () {
      for (final lang in languages) {
        final s = CallFilterStrings.of(lang);
        expect(s.all.isNotEmpty, isTrue, reason: 'all missing for $lang');
        expect(s.missed.isNotEmpty, isTrue, reason: 'missed missing for $lang');
        expect(s.translated.isNotEmpty, isTrue,
            reason: 'translated missing for $lang');
      }
    });

    test('falls back to English for an unknown language', () {
      expect(CallFilterStrings.of('xx').all, 'All');
    });
  });

  group('DialerStrings keypad label stays short enough for 4 pill tabs', () {
    test('no label exceeds 12 characters', () {
      for (final lang in languages) {
        expect(
          DialerStrings.of(lang).keypad.length <= 12,
          isTrue,
          reason: 'keypad label too long for $lang',
        );
      }
    });
  });
}
