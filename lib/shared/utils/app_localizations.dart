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
      if (saved != null && (saved == 'bn' || saved == 'en')) {
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
