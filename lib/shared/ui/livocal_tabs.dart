import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

/// Pill-style top tabs. Replaces the WhatsApp underline tab bar: one rounded
/// track, one gradient thumb that slides between labels.
class LivocalTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final EdgeInsets margin;

  const LivocalTabs({
    super.key,
    required this.controller,
    required this.labels,
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 8),
  });

  static const double tabHeight = 38;
  static const double outerHeight = tabHeight + 8;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselected =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(4),
      height: outerHeight,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.lightDivider,
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelColor: Colors.white,
        unselectedLabelColor: unselected,
        labelStyle: const TextStyle(
          fontFamily: CustomTextTheme.display,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: CustomTextTheme.display,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: [
          for (final label in labels) Tab(height: tabHeight, text: label),
        ],
      ),
    );
  }
}
