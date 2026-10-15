import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isDestructive;
  final bool showChevron;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor =
        isDestructive ? const Color(0xFFE53935) : AppColors.primary;
    final effectiveIconColor = iconColor ?? defaultIconColor;

    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive
            ? const Color(0xFFE53935).withValues(alpha: 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.10)));

    Widget? effectiveTrailing = trailing;
    if (effectiveTrailing == null && showChevron && onTap != null) {
      effectiveTrailing = Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? Colors.white38 : Colors.black26,
      );
    }

    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFE53935)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF8696A0) : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (effectiveTrailing != null) ...[
              const SizedBox(width: 8),
              effectiveTrailing,
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
        ),
      ),
    );
  }
}
