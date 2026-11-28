import 'package:flutter/material.dart';

/// One editable row inside a profile section (experience, education, ...).
///
/// Tapping the row opens the same dialog in edit mode; the trailing icons make
/// edit and delete discoverable without a long-press.
class EditableEntryTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String trailing;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditableEntryTile({
    super.key,
    required this.leading,
    required this.title,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onEdit,
    required this.onDelete,
    this.subtitle = '',
    this.trailing = '',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: textColor),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                ],
              ),
            ),
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: TextStyle(fontSize: 10.5, color: muted),
              ),
            IconButton(
              onPressed: onEdit,
              tooltip: t('edit'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.edit_outlined, size: 15, color: muted),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: t('delete'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.close_rounded, size: 16, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
