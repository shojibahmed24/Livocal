/// Page-wise strings for the keypad tab (7 languages).
class DialerStrings {
  final String keypad;
  final String enterNumber;
  final String paste;
  final String recent;
  final String onLivocal;
  final String notOnLivocal;
  final String call;
  final String noRecents;
  final String invalidNumber;
  final String clear;

  const DialerStrings({
    required this.keypad,
    required this.enterNumber,
    required this.paste,
    required this.recent,
    required this.onLivocal,
    required this.notOnLivocal,
    required this.call,
    required this.noRecents,
    required this.invalidNumber,
    required this.clear,
  });

  static DialerStrings of(String languageCode) =>
      _values[languageCode] ?? _values['en']!;

  static const Map<String, DialerStrings> _values = {
    'en': DialerStrings(
      keypad: 'Keypad',
      enterNumber: 'Enter a number',
      paste: 'Paste',
      recent: 'Recent',
      onLivocal: 'On Livocal',
      notOnLivocal: 'Not on Livocal yet',
      call: 'Call',
      noRecents: 'Your recent calls will appear here',
      invalidNumber: 'Enter a valid phone number',
      clear: 'Clear',
    ),
    'bn': DialerStrings(
      keypad: 'কীপ্যাড',
      enterNumber: 'নাম্বার লিখুন',
      paste: 'পেস্ট',
      recent: 'সাম্প্রতিক',
      onLivocal: 'Livocal-এ আছেন',
      notOnLivocal: 'এখনো Livocal-এ নেই',
      call: 'কল',
      noRecents: 'সাম্প্রতিক কলগুলো এখানে দেখা যাবে',
      invalidNumber: 'সঠিক ফোন নাম্বার দিন',
      clear: 'মুছুন',
    ),
    'hi': DialerStrings(
      keypad: 'कीपैड',
      enterNumber: 'नंबर दर्ज करें',
      paste: 'पेस्ट',
      recent: 'हाल के',
      onLivocal: 'Livocal पर हैं',
      notOnLivocal: 'अभी Livocal पर नहीं',
      call: 'कॉल',
      noRecents: 'आपकी हाल की कॉल यहाँ दिखेंगी',
      invalidNumber: 'मान्य फ़ोन नंबर दर्ज करें',
      clear: 'साफ़ करें',
    ),
    'ar': DialerStrings(
      keypad: 'لوحة الأرقام',
      enterNumber: 'أدخل رقمًا',
      paste: 'لصق',
      recent: 'الأحدث',
      onLivocal: 'على Livocal',
      notOnLivocal: 'ليس على Livocal بعد',
      call: 'اتصال',
      noRecents: 'ستظهر مكالماتك الأخيرة هنا',
      invalidNumber: 'أدخل رقم هاتف صحيح',
      clear: 'مسح',
    ),
    'es': DialerStrings(
      keypad: 'Teclado',
      enterNumber: 'Introduce un número',
      paste: 'Pegar',
      recent: 'Recientes',
      onLivocal: 'En Livocal',
      notOnLivocal: 'Aún no está en Livocal',
      call: 'Llamar',
      noRecents: 'Tus llamadas recientes aparecerán aquí',
      invalidNumber: 'Introduce un número válido',
      clear: 'Borrar',
    ),
    'fr': DialerStrings(
      keypad: 'Clavier',
      enterNumber: 'Saisissez un numéro',
      paste: 'Coller',
      recent: 'Récents',
      onLivocal: 'Sur Livocal',
      notOnLivocal: 'Pas encore sur Livocal',
      call: 'Appeler',
      noRecents: 'Vos appels récents apparaîtront ici',
      invalidNumber: 'Saisissez un numéro valide',
      clear: 'Effacer',
    ),
    'de': DialerStrings(
      keypad: 'Tastenfeld',
      enterNumber: 'Nummer eingeben',
      paste: 'Einfügen',
      recent: 'Zuletzt',
      onLivocal: 'Auf Livocal',
      notOnLivocal: 'Noch nicht auf Livocal',
      call: 'Anrufen',
      noRecents: 'Deine letzten Anrufe erscheinen hier',
      invalidNumber: 'Gültige Telefonnummer eingeben',
      clear: 'Löschen',
    ),
  };
}
