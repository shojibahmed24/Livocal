import 'package:flutter/material.dart';

import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one case study.
Future<Map<String, String>?> showCaseStudyDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final title = TextEditingController(text: existing?['title'] ?? '');
  final client = TextEditingController(text: existing?['client'] ?? '');
  final problem = TextEditingController(text: existing?['problem'] ?? '');
  final result = TextEditingController(text: existing?['result'] ?? '');
  final image = TextEditingController(text: existing?['imageUrl'] ?? '');
  final url = TextEditingController(text: existing?['url'] ?? '');
  final tags = TextEditingController(text: existing?['tags'] ?? '');

  Widget field(TextEditingController c, String key, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(
          isDense: true,
          labelText: AppStrings.get(key, lang),
        ),
      ),
    );
  }

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.get('addCaseStudy', lang)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(title, 'caseTitle'),
            field(client, 'caseClient'),
            field(problem, 'caseProblem', lines: 2),
            field(result, 'caseResult', lines: 2),
            field(image, 'caseImage'),
            field(url, 'caseLink'),
            field(tags, 'caseTags'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppStrings.get('cancel', lang)),
        ),
        FilledButton(
          onPressed: () {
            final value = title.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop({
              'title': value,
              'client': client.text.trim(),
              'problem': problem.text.trim(),
              'result': result.text.trim(),
              'imageUrl': image.text.trim(),
              'url': url.text.trim(),
              'tags': tags.text.trim(),
            });
          },
          child: Text(AppStrings.get('save', lang)),
        ),
      ],
    ),
  );
}
