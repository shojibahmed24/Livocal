import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Latest four CRM notes (or the empty hint).
class CrmNotesList extends StatelessWidget {
  final List<Map<String, String>> notes;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;

  const CrmNotesList({
    super.key,
    required this.notes,
    required this.t,
    required this.textColor,
    required this.muted,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          t('noNotes'),
          style: TextStyle(fontSize: 12, color: muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notes.reversed.take(4).map((note) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['text'] ?? '',
                  style: TextStyle(fontSize: 12.5, color: textColor),
                ),
                if ((note['at'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatDate(
                        DateTime.tryParse(note['at']!) ?? DateTime.now(),
                      ),
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
