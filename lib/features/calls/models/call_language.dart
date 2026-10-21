class CallLanguage {
  final String code;
  final String bcp47;
  final String englishName;
  final String nativeName;
  final String flagEmoji;
  final String region;
  final String speechStyleHint;
  final bool isPopular;

  const CallLanguage({
    required this.code,
    required this.bcp47,
    required this.englishName,
    required this.nativeName,
    required this.flagEmoji,
    required this.region,
    required this.speechStyleHint,
    this.isPopular = false,
  });

  String get displayLabel => '$flagEmoji $nativeName ($englishName)';
  String get shortBadge => '$flagEmoji $nativeName';
  String get codeUpper => code.toUpperCase();

  Map<String, dynamic> toMap() => {
        'code': code,
        'bcp47': bcp47,
        'englishName': englishName,
        'nativeName': nativeName,
        'flagEmoji': flagEmoji,
        'region': region,
        'speechStyleHint': speechStyleHint,
        'isPopular': isPopular,
      };
}

/// Universal Registry of all languages supported by Gemini Live Native Audio / Translation.
/// Supports N x N Any-to-Any Language Pairing (any language can be paired with any other language).
class CallLanguageRegistry {
  static const List<CallLanguage> allLanguages = [
    // --- Popular & South Asian Languages ---
    CallLanguage(
      code: 'bn',
      bcp47: 'bn-BD',
      englishName: 'Bengali (Bangladesh)',
      nativeName: 'বাংলা',
      flagEmoji: '🇧🇩',
      region: 'South Asia',
      speechStyleHint:
          'natural spoken conversational Bengali (Chalitobhasha / চলিত ভাষা)',
      isPopular: true,
    ),
    CallLanguage(
      code: 'bn-IN',
      bcp47: 'bn-IN',
      englishName: 'Bengali (India)',
      nativeName: 'বাংলা (ভারত)',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Bengali',
    ),
    CallLanguage(
      code: 'en',
      bcp47: 'en-US',
      englishName: 'English (US)',
      nativeName: 'English',
      flagEmoji: '🇺🇸',
      region: 'Global / Americas',
      speechStyleHint: 'natural conversational American English',
      isPopular: true,
    ),
    CallLanguage(
      code: 'en-GB',
      bcp47: 'en-GB',
      englishName: 'English (UK)',
      nativeName: 'English (UK)',
      flagEmoji: '🇬🇧',
      region: 'Europe',
      speechStyleHint: 'natural conversational British English',
    ),
    CallLanguage(
      code: 'es',
      bcp47: 'es-ES',
      englishName: 'Spanish',
      nativeName: 'Español',
      flagEmoji: '🇪🇸',
      region: 'Europe / Americas',
      speechStyleHint: 'natural conversational Spanish',
      isPopular: true,
    ),
    CallLanguage(
      code: 'es-MX',
      bcp47: 'es-MX',
      englishName: 'Spanish (Latin America)',
      nativeName: 'Español (Latinoamérica)',
      flagEmoji: '🇲🇽',
      region: 'Americas',
      speechStyleHint: 'natural conversational Latin American Spanish',
    ),
    CallLanguage(
      code: 'ar',
      bcp47: 'ar-SA',
      englishName: 'Arabic',
      nativeName: 'العربية',
      flagEmoji: '🇸🇦',
      region: 'Middle East',
      speechStyleHint: 'natural spoken Modern Standard / conversational Arabic',
      isPopular: true,
    ),
    CallLanguage(
      code: 'hi',
      bcp47: 'hi-IN',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Hindi',
      isPopular: true,
    ),
    CallLanguage(
      code: 'ur',
      bcp47: 'ur-PK',
      englishName: 'Urdu',
      nativeName: 'اردو',
      flagEmoji: '🇵🇰',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Urdu',
      isPopular: true,
    ),
    CallLanguage(
      code: 'fr',
      bcp47: 'fr-FR',
      englishName: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
      region: 'Europe',
      speechStyleHint: 'natural conversational French',
      isPopular: true,
    ),
    CallLanguage(
      code: 'de',
      bcp47: 'de-DE',
      englishName: 'German',
      nativeName: 'Deutsch',
      flagEmoji: '🇩🇪',
      region: 'Europe',
      speechStyleHint: 'natural conversational German',
      isPopular: true,
    ),
    CallLanguage(
      code: 'zh',
      bcp47: 'zh-CN',
      englishName: 'Chinese (Mandarin)',
      nativeName: '中文 (普通话)',
      flagEmoji: '🇨🇳',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Mandarin Chinese',
      isPopular: true,
    ),
    CallLanguage(
      code: 'zh-TW',
      bcp47: 'zh-TW',
      englishName: 'Chinese (Traditional)',
      nativeName: '繁體中文',
      flagEmoji: '🇹🇼',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Traditional Mandarin',
    ),
    CallLanguage(
      code: 'ja',
      bcp47: 'ja-JP',
      englishName: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      region: 'East & SE Asia',
      speechStyleHint: 'natural polite conversational Japanese (Desu/Masu)',
      isPopular: true,
    ),
    CallLanguage(
      code: 'ko',
      bcp47: 'ko-KR',
      englishName: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      region: 'East & SE Asia',
      speechStyleHint: 'natural polite conversational Korean (Haeyo-che)',
      isPopular: true,
    ),
    CallLanguage(
      code: 'pt',
      bcp47: 'pt-BR',
      englishName: 'Portuguese (Brazil)',
      nativeName: 'Português (Brasil)',
      flagEmoji: '🇧🇷',
      region: 'Americas',
      speechStyleHint: 'natural conversational Brazilian Portuguese',
      isPopular: true,
    ),
    CallLanguage(
      code: 'pt-PT',
      bcp47: 'pt-PT',
      englishName: 'Portuguese (Portugal)',
      nativeName: 'Português (Portugal)',
      flagEmoji: '🇵🇹',
      region: 'Europe',
      speechStyleHint: 'natural conversational European Portuguese',
    ),
    CallLanguage(
      code: 'ru',
      bcp47: 'ru-RU',
      englishName: 'Russian',
      nativeName: 'Русский',
      flagEmoji: '🇷🇺',
      region: 'Europe',
      speechStyleHint: 'natural conversational Russian',
      isPopular: true,
    ),
    CallLanguage(
      code: 'tr',
      bcp47: 'tr-TR',
      englishName: 'Turkish',
      nativeName: 'Türkçe',
      flagEmoji: '🇹🇷',
      region: 'Middle East / Europe',
      speechStyleHint: 'natural conversational Turkish',
      isPopular: true,
    ),
    CallLanguage(
      code: 'it',
      bcp47: 'it-IT',
      englishName: 'Italian',
      nativeName: 'Italiano',
      flagEmoji: '🇮🇹',
      region: 'Europe',
      speechStyleHint: 'natural conversational Italian',
      isPopular: true,
    ),
    CallLanguage(
      code: 'id',
      bcp47: 'id-ID',
      englishName: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flagEmoji: '🇮🇩',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Indonesian',
      isPopular: true,
    ),
    CallLanguage(
      code: 'ms',
      bcp47: 'ms-MY',
      englishName: 'Malay',
      nativeName: 'Bahasa Melayu',
      flagEmoji: '🇲🇾',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Malay',
      isPopular: true,
    ),

    // --- Additional South Asian Languages ---
    CallLanguage(
      code: 'ta',
      bcp47: 'ta-IN',
      englishName: 'Tamil',
      nativeName: 'தமிழ்',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Tamil',
    ),
    CallLanguage(
      code: 'te',
      bcp47: 'te-IN',
      englishName: 'Telugu',
      nativeName: 'తెలుగు',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Telugu',
    ),
    CallLanguage(
      code: 'mr',
      bcp47: 'mr-IN',
      englishName: 'Marathi',
      nativeName: 'मराठी',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Marathi',
    ),
    CallLanguage(
      code: 'gu',
      bcp47: 'gu-IN',
      englishName: 'Gujarati',
      nativeName: 'ગુજરાતી',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Gujarati',
    ),
    CallLanguage(
      code: 'kn',
      bcp47: 'kn-IN',
      englishName: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Kannada',
    ),
    CallLanguage(
      code: 'ml',
      bcp47: 'ml-IN',
      englishName: 'Malayalam',
      nativeName: 'മലയാളം',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Malayalam',
    ),
    CallLanguage(
      code: 'pa',
      bcp47: 'pa-IN',
      englishName: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Punjabi',
    ),
    CallLanguage(
      code: 'ne',
      bcp47: 'ne-NP',
      englishName: 'Nepali',
      nativeName: 'नेपाली',
      flagEmoji: '🇳🇵',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Nepali',
    ),
    CallLanguage(
      code: 'si',
      bcp47: 'si-LK',
      englishName: 'Sinhala',
      nativeName: 'සිංහල',
      flagEmoji: '🇱🇰',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Sinhala',
    ),
    CallLanguage(
      code: 'as',
      bcp47: 'as-IN',
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Assamese',
    ),
    CallLanguage(
      code: 'or',
      bcp47: 'or-IN',
      englishName: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
      flagEmoji: '🇮🇳',
      region: 'South Asia',
      speechStyleHint: 'natural spoken conversational Odia',
    ),

    // --- East & Southeast Asian Languages ---
    CallLanguage(
      code: 'th',
      bcp47: 'th-TH',
      englishName: 'Thai',
      nativeName: 'ไทย',
      flagEmoji: '🇹🇭',
      region: 'East & SE Asia',
      speechStyleHint: 'natural polite conversational Thai',
    ),
    CallLanguage(
      code: 'vi',
      bcp47: 'vi-VN',
      englishName: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Vietnamese',
    ),
    CallLanguage(
      code: 'tl',
      bcp47: 'fil-PH',
      englishName: 'Filipino (Tagalog)',
      nativeName: 'Filipino',
      flagEmoji: '🇵🇭',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Filipino / Tagalog',
    ),
    CallLanguage(
      code: 'my',
      bcp47: 'my-MM',
      englishName: 'Burmese (Myanmar)',
      nativeName: 'မြန်မာဘာသာ',
      flagEmoji: '🇲🇲',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Burmese',
    ),
    CallLanguage(
      code: 'km',
      bcp47: 'km-KH',
      englishName: 'Khmer (Cambodian)',
      nativeName: 'ភាសាខ្មែរ',
      flagEmoji: '🇰🇭',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Khmer',
    ),
    CallLanguage(
      code: 'lo',
      bcp47: 'lo-LA',
      englishName: 'Lao',
      nativeName: 'ລາວ',
      flagEmoji: '🇱🇦',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Lao',
    ),
    CallLanguage(
      code: 'mn',
      bcp47: 'mn-MN',
      englishName: 'Mongolian',
      nativeName: 'Монгол',
      flagEmoji: '🇲🇳',
      region: 'East & SE Asia',
      speechStyleHint: 'natural conversational Mongolian',
    ),

    // --- Middle East & Central Asia ---
    CallLanguage(
      code: 'fa',
      bcp47: 'fa-IR',
      englishName: 'Persian (Farsi)',
      nativeName: 'فارسی',
      flagEmoji: '🇮🇷',
      region: 'Middle East',
      speechStyleHint: 'natural conversational Persian (Farsi)',
    ),
    CallLanguage(
      code: 'he',
      bcp47: 'he-IL',
      englishName: 'Hebrew',
      nativeName: 'עברית',
      flagEmoji: '🇮🇱',
      region: 'Middle East',
      speechStyleHint: 'natural conversational Hebrew',
    ),
    CallLanguage(
      code: 'ps',
      bcp47: 'ps-AF',
      englishName: 'Pashto',
      nativeName: 'پښتو',
      flagEmoji: '🇦🇫',
      region: 'Middle East / South Asia',
      speechStyleHint: 'natural conversational Pashto',
    ),
    CallLanguage(
      code: 'uz',
      bcp47: 'uz-UZ',
      englishName: 'Uzbek',
      nativeName: 'Oʻzbekcha',
      flagEmoji: '🇺🇿',
      region: 'Central Asia',
      speechStyleHint: 'natural conversational Uzbek',
    ),
    CallLanguage(
      code: 'kk',
      bcp47: 'kk-KZ',
      englishName: 'Kazakh',
      nativeName: 'Қазақ тілі',
      flagEmoji: '🇰🇿',
      region: 'Central Asia',
      speechStyleHint: 'natural conversational Kazakh',
    ),
    CallLanguage(
      code: 'az',
      bcp47: 'az-AZ',
      englishName: 'Azerbaijani',
      nativeName: 'Azərbaycan dili',
      flagEmoji: '🇦🇿',
      region: 'Central Asia / Europe',
      speechStyleHint: 'natural conversational Azerbaijani',
    ),

    // --- European Languages ---
    CallLanguage(
      code: 'nl',
      bcp47: 'nl-NL',
      englishName: 'Dutch',
      nativeName: 'Nederlands',
      flagEmoji: '🇳🇱',
      region: 'Europe',
      speechStyleHint: 'natural conversational Dutch',
    ),
    CallLanguage(
      code: 'pl',
      bcp47: 'pl-PL',
      englishName: 'Polish',
      nativeName: 'Polski',
      flagEmoji: '🇵🇱',
      region: 'Europe',
      speechStyleHint: 'natural conversational Polish',
    ),
    CallLanguage(
      code: 'uk',
      bcp47: 'uk-UA',
      englishName: 'Ukrainian',
      nativeName: 'Українська',
      flagEmoji: '🇺🇦',
      region: 'Europe',
      speechStyleHint: 'natural conversational Ukrainian',
    ),
    CallLanguage(
      code: 'el',
      bcp47: 'el-GR',
      englishName: 'Greek',
      nativeName: 'Ελληνικά',
      flagEmoji: '🇬🇷',
      region: 'Europe',
      speechStyleHint: 'natural conversational Greek',
    ),
    CallLanguage(
      code: 'cs',
      bcp47: 'cs-CZ',
      englishName: 'Czech',
      nativeName: 'Čeština',
      flagEmoji: '🇨🇿',
      region: 'Europe',
      speechStyleHint: 'natural conversational Czech',
    ),
    CallLanguage(
      code: 'ro',
      bcp47: 'ro-RO',
      englishName: 'Romanian',
      nativeName: 'Română',
      flagEmoji: '🇷🇴',
      region: 'Europe',
      speechStyleHint: 'natural conversational Romanian',
    ),
    CallLanguage(
      code: 'hu',
      bcp47: 'hu-HU',
      englishName: 'Hungarian',
      nativeName: 'Magyar',
      flagEmoji: '🇭🇺',
      region: 'Europe',
      speechStyleHint: 'natural conversational Hungarian',
    ),
    CallLanguage(
      code: 'sv',
      bcp47: 'sv-SE',
      englishName: 'Swedish',
      nativeName: 'Svenska',
      flagEmoji: '🇸🇪',
      region: 'Europe',
      speechStyleHint: 'natural conversational Swedish',
    ),
    CallLanguage(
      code: 'da',
      bcp47: 'da-DK',
      englishName: 'Danish',
      nativeName: 'Dansk',
      flagEmoji: '🇩🇰',
      region: 'Europe',
      speechStyleHint: 'natural conversational Danish',
    ),
    CallLanguage(
      code: 'fi',
      bcp47: 'fi-FI',
      englishName: 'Finnish',
      nativeName: 'Suomi',
      flagEmoji: '🇫🇮',
      region: 'Europe',
      speechStyleHint: 'natural conversational Finnish',
    ),
    CallLanguage(
      code: 'no',
      bcp47: 'nb-NO',
      englishName: 'Norwegian',
      nativeName: 'Norsk',
      flagEmoji: '🇳🇴',
      region: 'Europe',
      speechStyleHint: 'natural conversational Norwegian',
    ),
    CallLanguage(
      code: 'bg',
      bcp47: 'bg-BG',
      englishName: 'Bulgarian',
      nativeName: 'Български',
      flagEmoji: '🇧🇬',
      region: 'Europe',
      speechStyleHint: 'natural conversational Bulgarian',
    ),
    CallLanguage(
      code: 'hr',
      bcp47: 'hr-HR',
      englishName: 'Croatian',
      nativeName: 'Hrvatski',
      flagEmoji: '🇭🇷',
      region: 'Europe',
      speechStyleHint: 'natural conversational Croatian',
    ),
    CallLanguage(
      code: 'sr',
      bcp47: 'sr-RS',
      englishName: 'Serbian',
      nativeName: 'Српски',
      flagEmoji: '🇷🇸',
      region: 'Europe',
      speechStyleHint: 'natural conversational Serbian',
    ),
    CallLanguage(
      code: 'sk',
      bcp47: 'sk-SK',
      englishName: 'Slovak',
      nativeName: 'Slovenčina',
      flagEmoji: '🇸🇰',
      region: 'Europe',
      speechStyleHint: 'natural conversational Slovak',
    ),
    CallLanguage(
      code: 'sl',
      bcp47: 'sl-SI',
      englishName: 'Slovenian',
      nativeName: 'Slovenščina',
      flagEmoji: '🇸🇮',
      region: 'Europe',
      speechStyleHint: 'natural conversational Slovenian',
    ),
    CallLanguage(
      code: 'lt',
      bcp47: 'lt-LT',
      englishName: 'Lithuanian',
      nativeName: 'Lietuvių',
      flagEmoji: '🇱🇹',
      region: 'Europe',
      speechStyleHint: 'natural conversational Lithuanian',
    ),
    CallLanguage(
      code: 'lv',
      bcp47: 'lv-LV',
      englishName: 'Latvian',
      nativeName: 'Latviešu',
      flagEmoji: '🇱🇻',
      region: 'Europe',
      speechStyleHint: 'natural conversational Latvian',
    ),
    CallLanguage(
      code: 'et',
      bcp47: 'et-EE',
      englishName: 'Estonian',
      nativeName: 'Eesti',
      flagEmoji: '🇪🇪',
      region: 'Europe',
      speechStyleHint: 'natural conversational Estonian',
    ),
    CallLanguage(
      code: 'ca',
      bcp47: 'ca-ES',
      englishName: 'Catalan',
      nativeName: 'Català',
      flagEmoji: '🇪🇸',
      region: 'Europe',
      speechStyleHint: 'natural conversational Catalan',
    ),

    // --- African Languages ---
    CallLanguage(
      code: 'sw',
      bcp47: 'sw-KE',
      englishName: 'Swahili',
      nativeName: 'Kiswahili',
      flagEmoji: '🇰🇪',
      region: 'Africa',
      speechStyleHint: 'natural conversational Swahili',
    ),
    CallLanguage(
      code: 'am',
      bcp47: 'am-ET',
      englishName: 'Amharic',
      nativeName: 'አማርኛ',
      flagEmoji: '🇪🇹',
      region: 'Africa',
      speechStyleHint: 'natural conversational Amharic',
    ),
    CallLanguage(
      code: 'ha',
      bcp47: 'ha-NG',
      englishName: 'Hausa',
      nativeName: 'Hausa',
      flagEmoji: '🇳🇬',
      region: 'Africa',
      speechStyleHint: 'natural conversational Hausa',
    ),
    CallLanguage(
      code: 'yo',
      bcp47: 'yo-NG',
      englishName: 'Yoruba',
      nativeName: 'Yorùbá',
      flagEmoji: '🇳🇬',
      region: 'Africa',
      speechStyleHint: 'natural conversational Yoruba',
    ),
    CallLanguage(
      code: 'zu',
      bcp47: 'zu-ZA',
      englishName: 'Zulu',
      nativeName: 'isiZulu',
      flagEmoji: '🇿🇦',
      region: 'Africa',
      speechStyleHint: 'natural conversational Zulu',
    ),
    CallLanguage(
      code: 'af',
      bcp47: 'af-ZA',
      englishName: 'Afrikaans',
      nativeName: 'Afrikaans',
      flagEmoji: '🇿🇦',
      region: 'Africa',
      speechStyleHint: 'natural conversational Afrikaans',
    ),
  ];

  static List<CallLanguage> get popularLanguages =>
      allLanguages.where((l) => l.isPopular).toList();

  static CallLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return allLanguages.first;
    final normalized = code.trim().toLowerCase();
    return allLanguages.firstWhere(
      (l) =>
          l.code.toLowerCase() == normalized ||
          l.bcp47.toLowerCase() == normalized,
      orElse: () => allLanguages.firstWhere(
        (l) => l.code.toLowerCase().startsWith(normalized.split('-').first),
        orElse: () => allLanguages.first,
      ),
    );
  }

  static List<CallLanguage> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allLanguages;
    return allLanguages.where((lang) {
      return lang.englishName.toLowerCase().contains(q) ||
          lang.nativeName.toLowerCase().contains(q) ||
          lang.code.toLowerCase().contains(q) ||
          lang.region.toLowerCase().contains(q);
    }).toList();
  }

  static String formatPairBadge(String langACode, String langBCode) {
    final a = fromCode(langACode);
    final b = fromCode(langBCode);
    return '${a.flagEmoji} ${a.nativeName} ⇄ ${b.flagEmoji} ${b.nativeName}';
  }

  static String formatShortPairBadge(String langACode, String langBCode) {
    final a = fromCode(langACode);
    final b = fromCode(langBCode);
    return '${a.flagEmoji} ${a.codeUpper} ⇄ ${b.flagEmoji} ${b.codeUpper}';
  }

  /// Evaluates whether two language codes belong to the exact same language family
  /// (e.g. 'bn' and 'bn-BD' are the same Bengali family; 'en-US' and 'en-GB' are English).
  static bool isSameLanguageFamily(String? codeA, String? codeB) {
    if (codeA == null || codeB == null) return false;
    final cleanA = codeA.toLowerCase().split('-').first.split('_').first.trim();
    final cleanB = codeB.toLowerCase().split('-').first.split('_').first.trim();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    return cleanA == cleanB;
  }

  /// Infers default spoken language from a phone number's country code.
  /// Eliminates the 'bn' default trap for international users who haven't explicitly set their language.
  static String inferLanguageFromPhone(dynamic phone) {
    if (phone == null) return 'en';
    String raw = '';
    String code = '';
    if (phone is String) {
      raw = phone.trim();
    } else {
      try {
        raw = (phone.formattedNumber ?? phone.rawNumber ?? phone.number ?? '').toString().trim();
        code = (phone.code ?? '').toString().trim().replaceAll('+', '');
      } catch (_) {}
    }

    final digits = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (code == '880' || digits.startsWith('880') || (digits.startsWith('01') && digits.length == 11)) {
      return 'bn';
    }
    if (code == '91' || digits.startsWith('91')) {
      return 'hi';
    }
    if (code == '1' || (digits.startsWith('1') && digits.length == 11)) {
      return 'en';
    }
    if (code == '44' || digits.startsWith('44')) {
      return 'en-GB';
    }
    if (code == '966' || digits.startsWith('966') || code == '971' || digits.startsWith('971')) {
      return 'ar';
    }
    if (code == '34' || digits.startsWith('34')) {
      return 'es';
    }
    if (code == '33' || digits.startsWith('33')) {
      return 'fr';
    }
    if (code == '49' || digits.startsWith('49')) {
      return 'de';
    }
    return 'en';
  }
}
