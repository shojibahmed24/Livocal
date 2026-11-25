/// Helpers for text that comes from users (names, message previews, file names).
///
/// Flutter's paragraph builder throws `Invalid argument(s): string is not
/// well-formed UTF-16` when a string contains half of a surrogate pair, which
/// happens whenever emoji are truncated with `substring`. Every truncation in
/// the app must go through these helpers.
library;

/// Replaces unpaired UTF-16 surrogates with U+FFFD so the string is always
/// safe to hand to a Text widget.
String sanitizeUtf16(String input) {
  if (!_hasSurrogate(input)) return input;

  final units = input.codeUnits;
  final out = <int>[];
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      final hasLow = i + 1 < units.length &&
          units[i + 1] >= 0xDC00 &&
          units[i + 1] <= 0xDFFF;
      if (hasLow) {
        out.add(unit);
        out.add(units[i + 1]);
        i++;
      } else {
        out.add(0xFFFD);
      }
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      out.add(0xFFFD);
    } else {
      out.add(unit);
    }
  }
  return String.fromCharCodes(out);
}

bool _hasSurrogate(String input) {
  for (final unit in input.codeUnits) {
    if (unit >= 0xD800 && unit <= 0xDFFF) return true;
  }
  return false;
}

/// First user-perceived character, never a broken half of an emoji.
String firstRune(String input, {String fallback = '?'}) {
  final clean = sanitizeUtf16(input).trim();
  if (clean.isEmpty) return fallback;
  return String.fromCharCode(clean.runes.first);
}

/// One or two letter avatar initials, emoji-safe.
String initialsOf(String name, {int maxChars = 2}) {
  final clean = sanitizeUtf16(name).trim();
  if (clean.isEmpty) return '?';

  final parts =
      clean.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) {
    return (firstRune(parts[0]) + firstRune(parts[1])).toUpperCase();
  }
  return String.fromCharCodes(clean.runes.take(maxChars)).toUpperCase();
}

/// Truncates by runes, so emoji are never cut in half.
String truncateRunes(String text, int maxRunes, {String ellipsis = '…'}) {
  final clean = sanitizeUtf16(text);
  final runes = clean.runes;
  if (runes.length <= maxRunes) return clean;
  return '${String.fromCharCodes(runes.take(maxRunes))}$ellipsis';
}
