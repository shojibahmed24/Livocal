import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/theme/app_colors.dart';

/// Follow-up date row plus the last-contacted hint.
class FollowUpField extends StatelessWidget {
  final CrmEntry entry;
  final String Function(String key) t;
  final VoidCallback onPick;
  final void Function(void Function(CrmEntry)) mutate;

  const FollowUpField({
    super.key,
    required this.entry,
    required this.t,
    required this.onPick,
    required this.mutate,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t('followUpLabel').toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onPick,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        entry.followUpAt == null
                            ? t('noFollowUp')
                            : _formatDate(entry.followUpAt!),
                        style: TextStyle(fontSize: 12.5, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (entry.followUpAt != null)
              IconButton(
                onPressed: () => mutate((e) => e.followUpAt = null),
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: t('noFollowUp'),
              ),
          ],
        ),
        if (entry.lastContactedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            '${t('lastContacted')}: ${_formatDate(entry.lastContactedAt!)}',
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
