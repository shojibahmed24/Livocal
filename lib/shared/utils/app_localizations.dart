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
