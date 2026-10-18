import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

/// Standard button action configuration for [showAppDialog].
class AppDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// Unified, design-system compliant modal dialog helper for Livocal.
/// Ensures consistent background, corner radius, padding, title styling,
/// and readable typography in both Light and Dark themes (resolving dark mode invisible text).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  String? title,
  Widget? content,
  String? contentText,
  List<AppDialogAction>? actions,
  List<Widget>? rawActions,
  bool barrierDismissible = true,
  IconData? icon,
  Color? iconColor,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final effectiveIconColor = iconColor ?? (isDark ? AppColors.primary : AppColors.primaryDark);

      Widget? titleWidget;
      if (title != null) {
        if (icon != null) {
          titleWidget = Row(
            children: [
              Icon(icon, color: effectiveIconColor, size: 24),
              AppSpacing.horizontalMd,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        } else {
          titleWidget = Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          );
        }
      }

      Widget? bodyWidget;
      if (content != null) {
        bodyWidget = content;
      } else if (contentText != null) {
        bodyWidget = Text(
          contentText,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        );
      }

      List<Widget>? dialogActions;
      if (actions != null) {
        dialogActions = actions.map((act) {
          Color textColor;
          if (act.isDestructive) {
            textColor = theme.colorScheme.error;
          } else if (act.isPrimary) {
            textColor = theme.colorScheme.primary;
          } else {
            textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          }

          return TextButton(
            onPressed: act.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              act.label,
              style: TextStyle(
                fontWeight: act.isPrimary ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        }).toList();
      } else if (rawActions != null) {
        dialogActions = rawActions;
      }

      return AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: titleWidget,
        content: bodyWidget != null ? (content != null ? bodyWidget : SingleChildScrollView(child: bodyWidget)) : null,
        actions: dialogActions,
      );
    },
  );
}

/// Standardized high-contrast progress dialog with custom message and theme tokens.
Future<T?> showAppProgressDialog<T>({
  required BuildContext context,
  required String message,
  bool barrierDismissible = false,
  Key? key,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return AlertDialog(
        key: key,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
