import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/quick_reply.dart';
import 'package:livocal/features/freelancer/services/quick_reply_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';

/// Create-template dialog: title, message body and category.
Future<void> showAddQuickReplyDialog(
  BuildContext context,
  String ownerUid,
) async {
  final lang = Localizations.localeOf(context).languageCode;
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  String category = QuickReplyService.categoryPitch;

  final created = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(AppStrings.get('addQuickReply', lang)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                isDense: true,
                decoration: const InputDecoration(isDense: true),
                items: [
                  (QuickReplyService.categoryPitch, 'catPitch'),
                  (QuickReplyService.categoryRate, 'catRate'),
                  (QuickReplyService.categoryAvailability, 'catAvailability'),
                  (QuickReplyService.categoryClosing, 'catClosing'),
                ]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.$1,
                        child: Text(
                          AppStrings.get(item.$2, lang),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.get('save', lang)),
          ),
        ],
      ),
    ),
  );

  if (created != true) return;
  final title = titleCtrl.text.trim();
  final body = bodyCtrl.text.trim();
  if (title.isEmpty || body.isEmpty) return;
  await QuickReplyService.save(
    QuickReply(
      ownerUid: ownerUid,
      title: title,
      body: body,
      category: category,
    ),
  );
}

/// Long-press delete confirmation.
Future<void> showDeleteQuickReplyDialog(
  BuildContext context,
  QuickReply reply,
) async {
  final lang = Localizations.localeOf(context).languageCode;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppStrings.get('deleteQuickReply', lang)),
      content: Text(reply.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(AppStrings.get('cancel', lang)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(AppStrings.get('delete', lang)),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await QuickReplyService.delete(reply);
  }
}
