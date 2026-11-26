import 'package:flutter/material.dart';

import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one service (title + starting price).
Future<Map<String, String>?> showServiceDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
  final fromCtrl = TextEditingController(text: existing?['from'] ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.get('addService', lang)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              isDense: true,
              labelText: AppStrings.get('serviceTitle', lang),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fromCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: AppStrings.get('serviceFrom', lang),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppStrings.get('cancel', lang)),
        ),
        FilledButton(
          onPressed: () {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.of(ctx).pop({
              'title': title,
              'from': fromCtrl.text.trim(),
            });
          },
          child: Text(AppStrings.get('save', lang)),
        ),
      ],
    ),
  );
}
