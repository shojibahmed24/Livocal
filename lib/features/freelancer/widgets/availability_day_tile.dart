import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/availability_day.dart';
import 'package:livocal/theme/app_colors.dart';

/// One weekday row: enable switch plus bookable windows.
class AvailabilityDayTile extends StatelessWidget {
  final AvailabilityDay day;
  final String label;
  final String Function(String key) t;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddSlot;
  final void Function(AvailabilitySlot slot) onRemoveSlot;

  const AvailabilityDayTile({
    super.key,
    required this.day,
    required this.label,
    required this.t,
    required this.onToggle,
    required this.onAddSlot,
    required this.onRemoveSlot,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: BoxDecoration(
        color: day.enabled
            ? AppColors.primary.withValues(alpha: 0.06)
            : (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.enabled
              ? AppColors.primary.withValues(alpha: 0.3)
              : muted.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (day.enabled)
                IconButton(
                  onPressed: onAddSlot,
                  tooltip: t('addSlot'),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                  color: AppColors.primary,
                ),
              Switch(
                value: day.enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (day.enabled)
            if (day.slots.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  t('addSlot'),
                  style: TextStyle(fontSize: 11.5, color: muted),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: day.slots.map((slot) {
                  return InputChip(
                    label: Text(
                      '${slot.start} – ${slot.end}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    onDeleted: () => onRemoveSlot(slot),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  );
                }).toList(),
              ),
        ],
      ),
    );
  }
}
