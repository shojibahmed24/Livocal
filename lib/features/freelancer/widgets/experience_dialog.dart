import 'package:flutter/material.dart';

import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one experience row.
Future<Map<String, String>?> showExperienceDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) => AppStrings.get(key, lang);
  final role = TextEditingController(text: existing?['role'] ?? '');
  final company = TextEditingController(text: existing?['company'] ?? '');
  final start = TextEditingController(text: existing?['start'] ?? '');
  final end = TextEditingController(text: existing?['end'] ?? '');
  final summary = TextEditingController(text: existing?['summary'] ?? '');

  Widget field(TextEditingController c, String key, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(isDense: true, labelText: t(key)),
      ),
    );
  }

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('addExperience')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(role, 'expRole'),
            field(company, 'expCompany'),
            Row(
              children: [
                Expanded(child: field(start, 'expStart')),
                const SizedBox(width: 8),
                Expanded(child: field(end, 'expEnd')),
              ],
            ),
            field(summary, 'expSummary', lines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = role.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop({
              'role': value,
              'company': company.text.trim(),
              'start': start.text.trim(),
              'end': end.text.trim(),
              'summary': summary.text.trim(),
            });
          },
          child: Text(t('save')),
        ),
      ],
    ),
  );
}
