import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(_getInitialLocale());

  static Locale _getInitialLocale() {
    try {
      final saved = SharedPref.instance.getString('app_language');
      const supported = {'en', 'bn', 'hi', 'ar', 'es', 'fr', 'de'};
      if (saved != null && supported.contains(saved)) {
        return Locale(saved);
      }
    } catch (e) {
      debugPrint('[AppLocaleNotifier] Error getting initial locale: $e');
    }
    return const Locale('en');
  }

  Future<void> setLocale(String langCode) async {
    state = Locale(langCode);
    try {
      await SharedPref.instance.setString('app_language', langCode);
    } catch (e) {
      debugPrint('[AppLocaleNotifier] Error saving locale: $e');
    }
  }
}

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'chats': 'CHATS',
      'status': 'STATUS',
      'calls': 'CALLS',
      'settings': 'Settings',
      'search': 'Search...',
      'typeMessage': 'Message',
      'starredMessages': 'Starred messages',
      'linkedDevices': 'Linked devices',
      'statusPrivacy': 'Status privacy',
      'clearCallLog': 'Clear call log',
      'logout': 'Log out',
      'cancel': 'Cancel',
      'ok': 'OK',
      'account': 'Account',
      'privacy': 'Privacy',
      'notifications': 'Notifications',
      'storage': 'Storage and data',
      'appLanguage': 'App language',
      'help': 'Help',
      'newGroup': 'New group',
      'newBroadcast': 'New broadcast',
      'accountAndPrivacy': 'Account & Privacy',
      'accountSub': 'Security notifications, two-step verification, change number',
      'privacySub': 'Block contacts, disappearing messages, biometric lock',
      'preferences': 'Preferences',
      'chatsAndTheme': 'Chats & Theme',
      'chatsAndThemeSub': 'Wallpapers, theme, chat history',
      'notificationsSub': 'Message, group & incoming call tones, vibration',
      'storageSub': 'Network usage, cache cleaner, media auto-download',
      'appLanguageSub': 'English, বাংলা, हिन्दी, العربية...',
      'advancedAiEngine': 'Advanced & AI Engine',
      'geminiVoiceEngine': 'Gemini Live Voice Engine',
      'geminiVoiceEngineSub': 'API key, neural voice presets & speech model config',
      'supportAndCommunity': 'Support & Community',
      'helpSub': 'Help centre, contact us, terms & privacy policy',
      'inviteFriend': 'Invite a friend',
      'inviteFriendSub': 'Share Livocal with contacts & family',
      'session': 'Session',
      'logoutSub': 'Clear local credentials and sign out',
      'chooseTheme': 'Choose Theme',
      'systemDefault': 'System default',
      'light': 'Light',
      'dark': 'Dark',
      'save': 'Save',
      'chooseLanguage': 'Choose Interface Language',
      'languageNote': 'Changing language updates all UI screens, notifications, dialogs and voice call prompts instantly.',
      'logoutDialogTitle': 'Log out of Livocal?',
      'logoutDialogContent': 'Are you sure you want to log out? Local data and credentials will be cleared.',
      'from': 'from',
      'version': 'Version 1.0.0 (Production Ready)',
    },
    'bn': {
      'chats': 'চ্যাট',
      'status': 'স্ট্যাটাস',
      'calls': 'কল',
      'settings': 'সেটিংস',
      'search': 'অনুসন্ধান করুন...',
      'typeMessage': 'মেসেজ লিখুন...',
      'starredMessages': 'স্টার করা মেসেজ',
      'linkedDevices': 'সংযুক্ত ডিভাইস',
      'statusPrivacy': 'স্ট্যাটাস প্রাইভেসী',
      'clearCallLog': 'কল লগ মুছুন',
      'logout': 'লগ আউট',
      'cancel': 'বাতিল',
      'ok': 'ঠিক আছে',
      'account': 'অ্যাকাউন্ট',
      'privacy': 'প্রাইভেসি',
      'notifications': 'নোটিফিকেশন',
      'storage': 'স্টোরেজ ও ডেটা',
      'appLanguage': 'অ্যাপের ভাষা',
      'help': 'সহায়তা',
      'newGroup': 'নতুন গ্রুপ',
      'newBroadcast': 'নতুন ব্রডকাস্ট',
      'accountAndPrivacy': 'অ্যাকাউন্ট ও প্রাইভেসি',
      'accountSub': 'নিরাপত্তা বিজ্ঞপ্তি, দ্বি-ধাপ যাচাইকরণ, নম্বর পরিবর্তন',
      'privacySub': 'পরিচিতি ব্লক, স্বয়ংক্রিয় মুছে যাওয়া মেসেজ, বায়োমেট্রিক লক',
      'preferences': 'পছন্দসমূহ',
      'chatsAndTheme': 'চ্যাট ও থিম',
      'chatsAndThemeSub': 'ওয়ালপেপার, থিম, চ্যাট হিস্ট্রি',
      'notificationsSub': 'মেসেজ, গ্রুপ ও ইনকামিং কল টোন, ভাইব্রেশন',
      'storageSub': 'নেটওয়ার্ক ব্যবহার, ক্যাশ ক্লিনার, মিডিয়া অটো-ডাউনলোড',
      'appLanguageSub': 'ইংরেজি, বাংলা, হিন্দি, আরবি...',
      'advancedAiEngine': 'অ্যাডভান্সড ও এআই ইঞ্জিন',
      'geminiVoiceEngine': 'জেমিনাই লাইভ ভয়েস ইঞ্জিন',
      'geminiVoiceEngineSub': 'এপিআই কী, নিউরাল ভয়েস প্রিসেট ও স্পিচ মডেল',
      'supportAndCommunity': 'সাপোর্ট ও কমিউনিটি',
      'helpSub': 'সহায়তা কেন্দ্র, যোগাযোগ, শর্তাবলী ও গোপনীয়তা নীতি',
      'inviteFriend': 'বন্ধুকে আমন্ত্রণ জানান',
      'inviteFriendSub': 'পরিচিত ও পরিবারের সাথে লিভোকাল শেয়ার করুন',
      'session': 'সেশন',
      'logoutSub': 'স্থানীয় তথ্য মুছে সাইন আউট করুন',
      'chooseTheme': 'থিম নির্বাচন করুন',
      'systemDefault': 'সিস্টেম ডিফল্ট',
      'light': 'লাইট',
      'dark': 'ডার্ক',
      'save': 'সংরক্ষণ',
      'chooseLanguage': 'অ্যাপের ভাষা নির্বাচন করুন',
      'languageNote': 'ভাষা পরিবর্তন করলে সমস্ত স্ক্রিন, নোটিফিকেশন, ডায়ালগ ও ভয়েস কল প্রম্পট সাথে সাথে আপডেট হবে।',
      'logoutDialogTitle': 'লিভোকাল থেকে লগ আউট করবেন?',
      'logoutDialogContent': 'আপনি কি নিশ্চিত যে লগ আউট করতে চান? স্থানীয় ডেটা ও লগইন তথ্য মুছে যাবে।',
      'from': 'উৎস',
      'version': 'ভার্সন ১.০.০ (প্রোডাকশন রেডি)',
    },
    'hi': {
      'chats': 'चैट',
      'status': 'स्टेटस',
      'calls': 'कॉल',
      'settings': 'सेटिंग्स',
      'search': 'खोजें...',
      'typeMessage': 'संदेश लिखें...',
      'starredMessages': 'तारांकित संदेश',
      'linkedDevices': 'लिंक किए गए डिवाइस',
      'statusPrivacy': 'स्टेटस प्राइवेसी',
      'clearCallLog': 'कॉल लॉग साफ़ करें',
      'logout': 'लॉग आउट',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'account': 'अकाउंट',
      'privacy': 'गोपनीयता',
      'notifications': 'सूचनाएं',
      'storage': 'स्टोरेज और डेटा',
      'appLanguage': 'ऐप की भाषा',
      'help': 'सहायता',
      'newGroup': 'नया ग्रुप',
      'newBroadcast': 'नया ब्रॉडकास्ट',
    },
    'ar': {
      'chats': 'الدردشات',
      'status': 'الحالة',
      'calls': 'المكالمات',
      'settings': 'الإعدادات',
      'search': 'بحث...',
      'typeMessage': 'اكتب رسالة...',
      'starredMessages': 'الرسائل المميزة بنجمة',
      'linkedDevices': 'الأجهزة المرتبطة',
      'statusPrivacy': 'خصوصية الحالة',
      'clearCallLog': 'مسح سجل المكالمات',
      'logout': 'تسجيل الخروج',
      'cancel': 'إلغاء',
      'ok': 'موافق',
      'account': 'الحساب',
      'privacy': 'الخصوصية',
      'notifications': 'الإشعارات',
      'storage': 'التخزين والبيانات',
      'appLanguage': 'لغة التطبيق',
      'help': 'المساعدة',
      'newGroup': 'مجموعة جديدة',
      'newBroadcast': 'رسالة جماعية جديدة',
    },
    'es': {
      'chats': 'CHATS',
      'status': 'ESTADOS',
      'calls': 'LLAMADAS',
      'settings': 'Ajustes',
      'search': 'Buscar...',
      'typeMessage': 'Mensaje',
      'starredMessages': 'Mensajes destacados',
      'linkedDevices': 'Dispositivos vinculados',
      'statusPrivacy': 'Privacidad de estados',
      'clearCallLog': 'Borrar registro de llamadas',
      'logout': 'Cerrar sesión',
      'cancel': 'Cancelar',
      'ok': 'OK',
      'account': 'Cuenta',
      'privacy': 'Privacidad',
      'notifications': 'Notificaciones',
      'storage': 'Almacenamiento y datos',
      'appLanguage': 'Idioma de la aplicación',
      'help': 'Ayuda',
      'newGroup': 'Nuevo grupo',
      'newBroadcast': 'Nueva difusión',
    },
    'fr': {
      'chats': 'DISCUSSIONS',
      'status': 'STATUT',
      'calls': 'APPELS',
      'settings': 'Paramètres',
      'search': 'Rechercher...',
      'typeMessage': 'Message',
      'starredMessages': 'Messages importants',
      'linkedDevices': 'Appareils connectés',
      'statusPrivacy': 'Confidentialité du statut',
      'clearCallLog': 'Effacer le journal d\'appels',
      'logout': 'Déconnexion',
      'cancel': 'Annuler',
      'ok': 'OK',
      'account': 'Compte',
      'privacy': 'Confidentialité',
      'notifications': 'Notifications',
      'storage': 'Stockage et données',
      'appLanguage': 'Langue de l\'application',
      'help': 'Aide',
      'newGroup': 'Nouveau groupe',
      'newBroadcast': 'Nouvelle diffusion',
    },
    'de': {
      'chats': 'CHATS',
      'status': 'STATUS',
      'calls': 'ANRUFE',
      'settings': 'Einstellungen',
      'search': 'Suchen...',
      'typeMessage': 'Nachricht',
      'starredMessages': 'Mit Stern markierte',
      'linkedDevices': 'Verknüpfte Geräte',
      'statusPrivacy': 'Status-Datenschutz',
      'clearCallLog': 'Anrufliste leeren',
      'logout': 'Abmelden',
      'cancel': 'Abbrechen',
      'ok': 'OK',
      'account': 'Konto',
      'privacy': 'Datenschutz',
      'notifications': 'Benachrichtigungen',
      'storage': 'Speicher und Daten',
      'appLanguage': 'App-Sprache',
      'help': 'Hilfe',
      'newGroup': 'Neue Gruppe',
      'newBroadcast': 'Neuer Broadcast',
    },
  };

  static String get(String key, String lang) {
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static String tr(WidgetRef ref, String key) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    return get(key, lang);
  }

  static String trContext(BuildContext context, WidgetRef ref, String key) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    return get(key, lang);
  }
}
