import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

/// Bubble chrome for the Livocal chat. Kept as pure styling so any bubble
/// (text, media, call log, payment) can share the same surface without
/// duplicating decoration code.
class ChatBubbleStyle {
  static const Radius _big = Radius.circular(20);
  static const Radius _small = Radius.circular(7);

  static BorderRadius radius({
    required bool isFirstOfRun,
    required bool isLastOfRun,
  }) {
    return BorderRadius.only(
      topLeft: isFirstOfRun ? _big : _small,
      topRight: isFirstOfRun ? _big : _small,
      bottomLeft: isLastOfRun ? _big : _small,
      bottomRight: isLastOfRun ? _big : _small,
    );
  }

  static BoxDecoration decoration(
    BuildContext context, {
    required bool isMe,
    required bool isFirstOfRun,
    required bool isLastOfRun,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = ChatBubbleStyle.radius(
      isFirstOfRun: isFirstOfRun,
      isLastOfRun: isLastOfRun,
    );

    if (isMe) {
      return BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF5B6CF9), Color(0xFF3B49C9)]
              : const [Color(0xFFEDEFFF), Color(0xFFDCE3FF)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return BoxDecoration(
      borderRadius: radius,
      color: isDark
          ? Colors.white.withValues(alpha: 0.065)
          : Colors.white.withValues(alpha: 0.92),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.09)
            : const Color(0xFFE2E7F4),
        width: 1,
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
    );
  }
}
