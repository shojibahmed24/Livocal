import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/features/freelancer/widgets/editable_entry_tile.dart';

/// Case-study list with add/edit/remove.
class CaseStudiesSection extends StatelessWidget {
  final List<Map<String, String>> entries;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onAdd;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;

  const CaseStudiesSection({
    super.key,
    required this.entries,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
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
                t('caseStudiesLabel').toUpperCase(),
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
              tooltip: t('addCaseStudy'),
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
                  Icons.work_history_outlined,
                  size: 15,
                  color: AppColors.primary,
                ),
                title: entry.value['title'] ?? '',
                subtitle: entry.value['client'] ?? '',
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
