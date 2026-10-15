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
    {'code': 'en', 'name': 'English', 'native': 'English (Device language)', 'flag': '🇺🇸'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা (Bangla)', 'flag': '🇧🇩'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية (Arabic)', 'flag': '🇸🇦'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español (Spanish)', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'native': 'Français (French)', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch (German)', 'flag': '🇩🇪'},
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
          const SettingsSectionHeader(title: 'Choose Interface Language'),
          ..._languages.map((lang) {
            final isSelected = _selectedLang == lang['code'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsRow(
                  icon: Icons.language_rounded,
                  title: lang['native']!,
                  subtitle: lang['name']!,
                  showChevron: false,
                  iconColor: isSelected ? Colors.white : AppColors.primary,
                  iconBackgroundColor: isSelected ? AppColors.primary : null,
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white38 : Colors.black26),
                    size: 22,
                  ),
                  onTap: () async {
                    final val = lang['code']!;
                    setState(() => _selectedLang = val);
                    await ref.read(appLocaleProvider.notifier).setLocale(val);
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: 'App language set to ${lang['name']}',
                        type: SnacBarType.info,
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 72),
              ],
            );
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Changing language updates all UI screens, notifications, dialogs and voice call prompts instantly.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.black45,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
