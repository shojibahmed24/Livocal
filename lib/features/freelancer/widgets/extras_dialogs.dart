import 'package:flutter/material.dart';

import 'package:livocal/shared/utils/app_localizations.dart';

Widget _field(
  BuildContext context,
  TextEditingController controller,
  String key, {
  int lines = 1,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        isDense: true,
        labelText: AppStrings.get(key, lang),
      ),
    ),
  );
}

Future<Map<String, String>?> showEducationDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) => AppStrings.get(key, lang);
  final school = TextEditingController(text: existing?['school'] ?? '');
  final degree = TextEditingController(text: existing?['degree'] ?? '');
  final start = TextEditingController(text: existing?['start'] ?? '');
  final end = TextEditingController(text: existing?['end'] ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('addEducation')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(context, school, 'eduSchool'),
          _field(context, degree, 'eduDegree'),
          Row(
            children: [
              Expanded(child: _field(context, start, 'expStart')),
              const SizedBox(width: 8),
              Expanded(child: _field(context, end, 'expEnd')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = school.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop({
              'school': value,
              'degree': degree.text.trim(),
              'start': start.text.trim(),
              'end': end.text.trim(),
            });
          },
          child: Text(t('save')),
        ),
      ],
    ),
  );
}

Future<Map<String, String>?> showCertificationDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) => AppStrings.get(key, lang);
  final name = TextEditingController(text: existing?['name'] ?? '');
  final issuer = TextEditingController(text: existing?['issuer'] ?? '');
  final year = TextEditingController(text: existing?['year'] ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('addCertification')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(context, name, 'certName'),
          _field(context, issuer, 'certIssuer'),
          _field(context, year, 'certYear'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = name.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop({
              'name': value,
              'issuer': issuer.text.trim(),
              'year': year.text.trim(),
            });
          },
          child: Text(t('save')),
        ),
      ],
    ),
  );
}

Future<Map<String, String>?> showFaqDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) => AppStrings.get(key, lang);
  final question = TextEditingController(text: existing?['question'] ?? '');
  final answer = TextEditingController(text: existing?['answer'] ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('addFaq')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(context, question, 'faqQuestion'),
          _field(context, answer, 'faqAnswer', lines: 3),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = question.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop({
              'question': value,
              'answer': answer.text.trim(),
            });
          },
          child: Text(t('save')),
        ),
      ],
    ),
  );
}
