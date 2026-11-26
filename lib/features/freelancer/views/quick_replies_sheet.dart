import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/quick_reply.dart';
import 'package:livocal/features/freelancer/services/quick_reply_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Bottom sheet listing saved templates. Pops with the chosen body text.
Future<String?> showQuickRepliesSheet(
  BuildContext context, {
  required String ownerUid,
  required String langCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuickRepliesSheet(ownerUid: ownerUid, langCode: langCode),
  );
}

class _QuickRepliesSheet extends StatelessWidget {
  final String ownerUid;
  final String langCode;

  const _QuickRepliesSheet({required this.ownerUid, required this.langCode});

  String _t(BuildContext context, String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case QuickReplyService.categoryRate:
        return _t(context, 'catRate');
      case QuickReplyService.categoryAvailability:
        return _t(context, 'catAvailability');
      case QuickReplyService.categoryClosing:
        return _t(context, 'catClosing');
      default:
        return _t(context, 'catPitch');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t(context, 'quickReplies'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _t(context, 'addQuickReply'),
                  onPressed: () => _addReply(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: StreamBuilder<List<QuickReply>>(
                stream: QuickReplyService.watch(ownerUid),
                builder: (context, snapshot) {
                  final replies = snapshot.data ?? const <QuickReply>[];
                  if (replies.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _t(context, 'noNotes'),
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: replies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(reply.body),
                        onLongPress: () => _confirmDelete(context, reply),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reply.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _categoryLabel(context, reply.category),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReply(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = QuickReplyService.categoryPitch;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(_t(context, 'addQuickReply')),
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
                          child: Text(_t(context, item.$2),
                              style: const TextStyle(fontSize: 12.5)),
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
              child: Text(AppStrings.get(
                  'cancel', Localizations.localeOf(context).languageCode)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.get(
                  'save', Localizations.localeOf(context).languageCode)),
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

  Future<void> _confirmDelete(BuildContext context, QuickReply reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(context, 'deleteQuickReply')),
        content: Text(reply.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.get(
                'cancel', Localizations.localeOf(context).languageCode)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.get(
                'delete', Localizations.localeOf(context).languageCode)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await QuickReplyService.delete(reply);
    }
  }
}
