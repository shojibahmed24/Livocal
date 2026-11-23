/// Phone number normalisation for Livocal.
///
/// The app accepts a number typed with or without the national trunk `0`
/// (e.g. `01775-290702` and `+8801775290702` both mean `+8801775290702`).
/// Everything that talks to Firebase Auth, Firestore or contact matching must
/// use the single E.164 form produced here so the same person is never stored
/// under two different keys.
class PhoneParts {
  /// Full E.164 form, e.g. `+8801775290702`.
  final String e164;

  /// Dial code with a plus, e.g. `+880`.
  final String code;

  /// National significant number without the trunk zero, e.g. `1775290702`.
  final String number;

  const PhoneParts({
    required this.e164,
    required this.code,
    required this.number,
  });

  @override
  String toString() => e164;

  @override
  bool operator ==(Object other) => other is PhoneParts && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;
}

class PhoneNormalizer {
  PhoneNormalizer._();

  static final RegExp _nonDigits = RegExp(r'[^\d]');

  /// Digits only, no `+`, no separators.
  static String digitsOnly(String raw) => raw.replaceAll(_nonDigits, '');

  static bool _looksNational(String digits) =>
      digits.length >= 6 && digits.length <= 13 && !digits.startsWith('0');

  /// Parses [input] using [countryCode] (digits, e.g. `880`).
  ///
  /// Accepted shapes: `01775-290702`, `1775290702`, `8801775290702`,
  /// `+880 01775-290702`, `+8801775290702`. A pasted foreign number
  /// (`+14155552671` while Bangladesh is selected) keeps its own digits.
  /// Returns `null` when the result cannot be a real E.164 number.
  static PhoneParts? parse({
    required String countryCode,
    required String input,
  }) {
    final cc = digitsOnly(countryCode);
    if (cc.isEmpty) return null;

    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final hasPlus = trimmed.startsWith('+');

    var digits = digitsOnly(trimmed);
    if (digits.isEmpty) return null;

    // Already carrying this country's dial code (with or without a trunk zero).
    if (digits.startsWith(cc)) {
      var rest = digits.substring(cc.length);
      if (rest.startsWith('0')) rest = rest.substring(1);
      if (_looksNational(rest)) {
        digits = rest;
      }
    } else if (hasPlus) {
      // A full international number for another country: keep its digits.
      if (digits.length < 8 || digits.length > 15) return null;
      return PhoneParts(e164: '+$digits', code: '+$cc', number: digits);
    }

    // National trunk prefix is not part of E.164.
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!_looksNational(digits)) return null;

    final e164 = '+$cc$digits';
    if (e164.length - 1 > 15) return null;
    return PhoneParts(e164: e164, code: '+$cc', number: digits);
  }

  /// E.164 without the `+`, safe for Firebase and Firestore keys.
  static String? toE164({required String countryCode, required String input}) =>
      parse(countryCode: countryCode, input: input)?.e164;

  /// Keys that may identify [raw] in Firestore, Isar or a call document.
  ///
  /// Covers the forms the app has written over time: `+8801…`, `8801…`,
  /// `01…` and `1…`. [defaultCountryCode] keeps the historical Bangladesh
  /// assumption for numbers stored as bare national digits.
  static Set<String> matchKeys(
    String raw, {
    String defaultCountryCode = '880',
  }) {
    final digits = digitsOnly(raw);
    final keys = <String>{};
    if (digits.isEmpty) return keys;

    void add(String value) {
      if (value.isEmpty) return;
      keys.add(value);
      keys.add('+$value');
      if (value.startsWith('+')) keys.add(value.substring(1));
    }

    add(digits);

    final bare = digits.startsWith('+') ? digits.substring(1) : digits;

    if (bare.startsWith(defaultCountryCode)) {
      final rest = bare.substring(defaultCountryCode.length);
      if (rest.isNotEmpty) {
        add(rest);
        add('0$rest');
      }
    } else if (bare.startsWith('0')) {
      final rest = bare.substring(1);
      add(rest);
      add('$defaultCountryCode$rest');
    } else {
      add('$defaultCountryCode$bare');
      add('0$bare');
    }

    return keys;
  }

  /// True when [a] and [b] clearly describe the same subscriber.
  static bool sameNumber(String a, String b) {
    final left = matchKeys(a);
    final right = matchKeys(b);
    return left.any(right.contains);
  }

  /// Human-readable form, e.g. `+880 1775290702`.
  ///
  /// [countryCode] wins when known; otherwise 1-digit codes (NANP, Russia) and
  /// the common 3-digit case are handled.
  static String formatDisplay(String raw, {String? countryCode}) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('+')) return trimmed;

    final digits = digitsOnly(trimmed);
    if (digits.isEmpty) return trimmed;

    var codeLength = countryCode == null ? 0 : digitsOnly(countryCode).length;
    if (codeLength == 0 || codeLength >= digits.length) {
      codeLength = digits.startsWith('1') || digits.startsWith('7') ? 1 : 3;
    }
    if (digits.length <= codeLength) return '+$digits';
    return '+${digits.substring(0, codeLength)} ${digits.substring(codeLength)}';
  }
}
