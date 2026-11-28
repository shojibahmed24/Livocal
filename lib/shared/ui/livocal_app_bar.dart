import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

/// The single app bar used by every Livocal screen.
///
/// Returns a plain [AppBar] so screens that wrap it (e.g. `ScaffoldWithSearch`)
/// and screens that pass it straight to `Scaffold.appBar` share one look:
/// translucent surface, hairline bottom border, dark-on-light / light-on-dark
/// foreground. No solid indigo bar.
AppBar livocalAppBar(
  BuildContext context, {
  Widget? title,
  bool showWordmark = false,
  Widget? leading,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  double titleSpacing = 16,
  bool centerTitle = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark
      ? AppColors.darkSurface.withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.95);
  final foreground =
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  return AppBar(
    backgroundColor: surface,
    foregroundColor: foreground,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: foreground),
    actionsIconTheme: IconThemeData(color: foreground),
    titleSpacing: titleSpacing,
    centerTitle: centerTitle,
    leading: leading,
    actions: actions,
    bottom: bottom,
    title: showWordmark ? const LivocalWordmark() : title,
    systemOverlayStyle:
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    shape: Border(
      bottom: BorderSide(
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        width: 1,
      ),
    ),
  );
}

/// "Livocal" wordmark: Li (foreground) + vocal (accent), plus the AI pill.
class LivocalWordmark extends StatelessWidget {
  final double fontSize;
  final bool showAiPill;

  const LivocalWordmark({
    super.key,
    this.fontSize = 21,
    this.showAiPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: fontSize * 1.35,
          height: fontSize * 1.35,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(fontSize * 0.45),
          ),
          alignment: Alignment.center,
          child: Text(
            'L',
            style: TextStyle(
              fontFamily: CustomTextTheme.display,
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: CustomTextTheme.display,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'Li', style: TextStyle(color: foreground)),
              const TextSpan(
                text: 'vocal',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
        if (showAiPill) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'AI',
              style: TextStyle(
                fontFamily: CustomTextTheme.display,
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
