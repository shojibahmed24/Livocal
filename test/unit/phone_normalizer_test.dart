import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer.parse', () {
    test('Bangladesh number with trunk zero resolves to E.164', () {
      final parts = PhoneNormalizer.parse(
        countryCode: '880',
        input: '01775-290702',
      );
      expect(parts, isNotNull);
      expect(parts!.e164, '+8801775290702');
      expect(parts.code, '+880');
      expect(parts.number, '1775290702');
    });

    test('national number without zero resolves the same', () {
      final parts = PhoneNormalizer.parse(
        countryCode: '880',
        input: '1775290702',
      );
      expect(parts!.e164, '+8801775290702');
    });

    test('dial code typed by hand resolves the same', () {
      expect(
        PhoneNormalizer.parse(countryCode: '880', input: '8801775290702')!.e164,
        '+8801775290702',
      );
    });

    test('pasted international number with a duplicate trunk zero', () {
      // The exact string the old confirm dialog showed: +880 01775-290702
      expect(
        PhoneNormalizer.parse(countryCode: '880', input: '+880 01775-290702')!
            .e164,
        '+8801775290702',
      );
      expect(
        PhoneNormalizer.parse(countryCode: '880', input: '+88001775290702')!
            .e164,
        '+8801775290702',
      );
    });

    test('formatted national input with spaces and brackets', () {
      expect(
        PhoneNormalizer.parse(countryCode: '880', input: '(01775) 290 702')!
            .e164,
        '+8801775290702',
      );
    });

    test('pasted foreign number keeps its own dial code', () {
      final parts = PhoneNormalizer.parse(
        countryCode: '880',
        input: '+1 415 555 2671',
      );
      expect(parts!.e164, '+14155552671');
      expect(parts.number, '14155552671');
    });

    test('US number typed with the wrong trunk zero still parses', () {
      expect(
        PhoneNormalizer.parse(countryCode: '1', input: '14155552671')!.e164,
        '+14155552671',
      );
      expect(
        PhoneNormalizer.parse(countryCode: '1', input: '4155552671')!.e164,
        '+14155552671',
      );
    });

    test('rejects empty, letters and too short input', () {
      expect(PhoneNormalizer.parse(countryCode: '880', input: ''), isNull);
      expect(PhoneNormalizer.parse(countryCode: '880', input: '   '), isNull);
      expect(PhoneNormalizer.parse(countryCode: '880', input: 'abc'), isNull);
      expect(PhoneNormalizer.parse(countryCode: '880', input: '0175'), isNull);
      expect(PhoneNormalizer.parse(countryCode: '', input: '01775290702'), isNull);
    });

    test('rejects numbers longer than E.164 allows', () {
      expect(
        PhoneNormalizer.parse(
          countryCode: '880',
          input: '17752907021234567890',
        ),
        isNull,
      );
    });
  });

  group('PhoneNormalizer.matchKeys', () {
    test('covers every stored form of a Bangladesh number', () {
      final keys = PhoneNormalizer.matchKeys('+8801775290702');
      expect(keys, contains('+8801775290702'));
      expect(keys, contains('8801775290702'));
      expect(keys, contains('01775290702'));
      expect(keys, contains('1775290702'));
    });

    test('national input and international input share keys', () {
      final national = PhoneNormalizer.matchKeys('01775290702');
      final international = PhoneNormalizer.matchKeys('+8801775290702');
      expect(national.intersection(international), isNotEmpty);
    });

    test('matchKeys of an empty string is empty', () {
      expect(PhoneNormalizer.matchKeys(''), isEmpty);
    });
  });

  group('PhoneNormalizer.sameNumber and formatDisplay', () {
    test('leading zero and plain international are the same person', () {
      expect(
        PhoneNormalizer.sameNumber('01775290702', '+8801775290702'),
        isTrue,
      );
      expect(
        PhoneNormalizer.sameNumber('01775290702', '+8801888000000'),
        isFalse,
      );
    });

    test('display keeps the dial code separated', () {
      expect(
        PhoneNormalizer.formatDisplay('+8801775290702'),
        '+880 1775290702',
      );
      expect(
        PhoneNormalizer.formatDisplay('+14155552671'),
        '+1 4155552671',
      );
      expect(PhoneNormalizer.formatDisplay('01775290702'), '01775290702');
    });
  });
}
