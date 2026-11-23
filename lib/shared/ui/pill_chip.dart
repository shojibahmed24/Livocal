import 'package:flutter/material.dart';
import 'package:livocal/shared/ui/livocal_buttons.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

enum ChipTone { brand, accent, success, warning, danger, neutral }

/// Compact label chip: language pairs, minutes, filters, statuses.
class PillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ChipTone tone;
  final bool filled;
  final VoidCallback? onTap;

  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = ChipTone.neutral,
    this.filled = true,
    this.onTap,
  });

  Color _color(bool isDark) => switch (tone) {
        ChipTone.brand => AppColors.primary,
        ChipTone.accent => AppColors.accent,
        ChipTone.success => AppColors.success,
        ChipTone.warning => AppColors.warning,
        ChipTone.danger => AppColors.errorLight,
        ChipTone.neutral =>
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color(isDark);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: isDark ? 0.16 : 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: CustomTextTheme.body,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: chip,
    );
  }
}

/// Empty state: soft brand bloom, icon, title, body and an optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bodyColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.lightDivider,
                  ),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CustomTextTheme.display,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: CustomTextTheme.body,
                  fontSize: 13,
                  height: 1.4,
                  color: bodyColor,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: PrimaryButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
