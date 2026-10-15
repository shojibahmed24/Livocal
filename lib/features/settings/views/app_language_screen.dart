import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App language'),
      ),
      body: ListView.separated(
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLang == lang['code'];

          return RadioListTile<String>(
            title: Text(
              lang['native']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(lang['name']!),
            value: lang['code']!,
            groupValue: _selectedLang,
            activeColor: primaryColor,
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
          );
        },
      ),
    );
  }
}
