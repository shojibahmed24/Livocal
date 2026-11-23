/// Call-log filter labels (7 languages).
class CallFilterStrings {
  final String all;
  final String missed;
  final String translated;

  const CallFilterStrings({
    required this.all,
    required this.missed,
    required this.translated,
  });

  static CallFilterStrings of(String languageCode) =>
      _values[languageCode] ?? _values['en']!;

  static const Map<String, CallFilterStrings> _values = {
    'en': CallFilterStrings(all: 'All', missed: 'Missed', translated: 'AI'),
    'bn': CallFilterStrings(all: 'সব', missed: 'মিসড', translated: 'এআই'),
    'hi': CallFilterStrings(all: 'सभी', missed: 'छूटीं', translated: 'एआई'),
    'ar': CallFilterStrings(all: 'الكل', missed: 'فائتة', translated: 'ذكاء'),
    'es': CallFilterStrings(all: 'Todas', missed: 'Perdidas', translated: 'IA'),
    'fr': CallFilterStrings(all: 'Tous', missed: 'Manqués', translated: 'IA'),
    'de': CallFilterStrings(all: 'Alle', missed: 'Verpasst', translated: 'KI'),
  };
}
