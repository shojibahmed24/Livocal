import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/features/freelancer/widgets/editable_entry_tile.dart';

/// Generic editor list (education, certifications, FAQ).
class ExtrasSection extends StatelessWidget {
  final String labelKey;
  final String addKey;
  final String primaryKey;
  final String secondaryKey;
  final String trailingKey;
  final List<Map<String, String>> entries;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onAdd;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;

  const ExtrasSection({
    super.key,
    required this.labelKey,
    required this.addKey,
    required this.primaryKey,
    required this.secondaryKey,
    required this.entries,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    this.trailingKey = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t(labelKey).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: muted,
                ),
              ),
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: t(addKey),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              color: AppColors.primary,
            ),
          ],
        ),
        if (entries.isEmpty)
          Text(
            t('sectionEmpty'),
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
        ...entries.asMap().entries.map(
              (entry) => EditableEntryTile(
                leading: const Icon(
                  Icons.circle,
                  size: 7,
                  color: AppColors.primary,
                ),
                title: entry.value[primaryKey] ?? '',
                subtitle: entry.value[secondaryKey] ?? '',
                trailing:
                    trailingKey.isEmpty ? '' : entry.value[trailingKey] ?? '',
                t: t,
                textColor: textColor,
                muted: muted,
                onEdit: () => onEdit(entry.key),
                onDelete: () => onRemove(entry.key),
              ),
            ),
        const SizedBox(height: 10),
      ],
    );
  }
}
