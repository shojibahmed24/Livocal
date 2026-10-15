import 'package:flutter/material.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

Future<CallLanguage?> showUniversalLanguagePicker(
  BuildContext context, {
  required String title,
  required String selectedCode,
}) {
  return showModalBottomSheet<CallLanguage>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UniversalLanguagePickerSheet(
      title: title,
      selectedCode: selectedCode,
    ),
  );
}

class _UniversalLanguagePickerSheet extends StatefulWidget {
  final String title;
  final String selectedCode;

  const _UniversalLanguagePickerSheet({
    required this.title,
    required this.selectedCode,
  });

  @override
  State<_UniversalLanguagePickerSheet> createState() =>
      _UniversalLanguagePickerSheetState();
}

class _UniversalLanguagePickerSheetState
    extends State<_UniversalLanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final filtered = CallLanguageRegistry.search(_query);
    final popular = CallLanguageRegistry.popularLanguages;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colorTheme.greenColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorTheme.greyColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded, color: colorTheme.greenColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${CallLanguageRegistry.allLanguages.length}+ Gemini Live Languages Supported (Any-to-Any)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colorTheme.greyColor),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Search language (e.g. Bangla, English, Spanish, Arabic...)',
                    hintStyle: TextStyle(
                      color: colorTheme.greyColor,
                      fontSize: 13.5,
                    ),
                    prefixIcon:
                        Icon(Icons.search, color: colorTheme.greenColor),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colorTheme.greyColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorTheme.appBarColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_query.isEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'POPULAR LANGUAGES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorTheme.greenColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: popular.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final lang = popular[idx];
                      final isSelected = lang.code.toLowerCase() ==
                          widget.selectedCode.toLowerCase();
                      return ActionChip(
                        backgroundColor: isSelected
                            ? colorTheme.greenColor
                            : colorTheme.appBarColor,
                        side: BorderSide(
                          color: isSelected
                              ? colorTheme.greenColor
                              : colorTheme.greyColor.withOpacity(0.25),
                        ),
                        label: Text(
                          '${lang.flagEmoji} ${lang.nativeName}',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(lang),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final lang = filtered[index];
                    final isSelected = lang.code.toLowerCase() ==
                        widget.selectedCode.toLowerCase();
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(lang),
                      leading: Text(
                        lang.flagEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      title: Text(
                        '${lang.nativeName} (${lang.englishName})',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${lang.region} • Code: ${lang.bcp47}',
                        style: TextStyle(
                          color: colorTheme.greyColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: colorTheme.greenColor)
                          : Text(
                              lang.codeUpper,
                              style: TextStyle(
                                color: colorTheme.greyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showGeminiLiveSettingsSheet(
  BuildContext context, {
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GeminiLiveSettingsSheet(onSaved: onSaved),
  );
}

class _GeminiLiveSettingsSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _GeminiLiveSettingsSheet({required this.onSaved});

  @override
  State<_GeminiLiveSettingsSheet> createState() =>
      _GeminiLiveSettingsSheetState();
}

class _GeminiLiveSettingsSheetState extends State<_GeminiLiveSettingsSheet> {
  late String _selectedVoice;

  @override
  void initState() {
    super.initState();
    _selectedVoice = GeminiLiveTranslator.getSavedVoiceName();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: colorTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colorTheme.greenColor.withOpacity(0.3)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorTheme.greyColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: colorTheme.greenColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Interpreter Voice & Preferences',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customize how translated speech sounds during calls. The AI automatically detects languages in real-time.',
                style: TextStyle(color: colorTheme.greyColor, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              // Security status card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zero-Trust Cloud AI Relay Active',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Live API keys and audio pipelines are securely managed on the backend server.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select AI Interpreter Voice',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the synthetic voice profile used when speaking translated audio to you.',
                style: TextStyle(color: colorTheme.greyColor, fontSize: 11.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GeminiLiveTranslator.availableVoices.map((voice) {
                  final selected = _selectedVoice == voice;
                  return ChoiceChip(
                    selected: selected,
                    selectedColor: colorTheme.greenColor,
                    backgroundColor: colorTheme.appBarColor,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          size: 16,
                          color: selected ? Colors.black : colorTheme.greyColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          voice,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (_) => setState(() => _selectedVoice = voice),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTheme.greenColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await GeminiLiveTranslator.saveVoiceName(_selectedVoice);
                    widget.onSaved();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Save Voice Preference',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
