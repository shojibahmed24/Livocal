import 'package:flutter/material.dart';

/// Confirms generating a new link (old links keep working).
Future<bool> confirmRegenerateLink(
  BuildContext context,
  String Function(String key) t,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('regenerateLinkTitle')),
      content: Text(t('regenerateLinkBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(t('generateProposal')),
        ),
      ],
    ),
  );
  return result == true;
}
