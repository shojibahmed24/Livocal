import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class AppLanguageScreen extends ConsumerStatefulWidget {
  const AppLanguageScreen({super.key});

  @override
  ConsumerState<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _AppLanguageScreenState extends ConsumerState<AppLanguageScreen> {
  String _selectedLang = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English (device\'s language)'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা (Bangla)'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी (Hindi)'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية (Arabic)'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español (Spanish)'},
    {'code': 'fr', 'name': 'French', 'native': 'Français (French)'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch (German)'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLang = SharedPref.instance.getString('app_language') ?? 'en';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'App language',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Choose Language'),
          ..._languages.map((lang) {
            final isSelected = _selectedLang == lang['code'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(
                    lang['native']!,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  subtitle: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF8696A0)
                          : Colors.grey.shade600,
                    ),
                  ),
                  value: lang['code']!,
                  groupValue: _selectedLang,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedLang = val);
                      await ref.read(appLocaleProvider.notifier).setLocale(val);
                      if (context.mounted) {
                        showSnackBar(
                          context: context,
                          content: 'App language set to ${lang['name']}',
                          type: SnacBarType.info,
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}
