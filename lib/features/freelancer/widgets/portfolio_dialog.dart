import 'package:flutter/material.dart';

import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one portfolio link (label + URL).
Future<Map<String, String>?> showPortfolioDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final titleCtrl = TextEditingController(text: existing?['label'] ?? '');
  final urlCtrl = TextEditingController(text: existing?['url'] ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.get('addPortfolio', lang)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              isDense: true,
              labelText: AppStrings.get('portfolioName', lang),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: urlCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              isDense: true,
              labelText: AppStrings.get('portfolioUrl', lang),
              hintText: 'https://',
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
            final label = titleCtrl.text.trim();
            final url = urlCtrl.text.trim();
            if (label.isEmpty || url.isEmpty) return;
            final normalized = url.startsWith('http') ? url : 'https://$url';
            Navigator.of(ctx).pop({'label': label, 'url': normalized});
          },
          child: Text(AppStrings.get('save', lang)),
        ),
      ],
    ),
  );
}
