import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

/// Surface used for grouped content across the app: 18 px radius, hairline
/// border in both themes, one soft shadow in light mode only.
class LivocalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool elevated;

  const LivocalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.gradient,
    this.color,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = BoxDecoration(
      color: gradient != null
          ? null
          : (color ??
              (isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white)),
      gradient: gradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.lightDivider,
      ),
      boxShadow: elevated && !isDark
          ? [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );

    final Widget body;
    if (onTap == null) {
      body = Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    } else {
      body = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: decoration.copyWith(boxShadow: null),
            child: child,
          ),
        ),
      );
    }

    return Padding(padding: margin, child: body);
  }
}

/// Eyebrow + optional trailing action, used above grouped cards and lists.
class LivocalSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const LivocalSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
