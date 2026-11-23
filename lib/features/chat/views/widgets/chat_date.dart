import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

class ChatDate extends StatelessWidget {
  const ChatDate({
    super.key,
    required this.date,
    this.shouldBeTransparent = false,
  });

  final String date;
  final bool shouldBeTransparent;

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final alpha = shouldBeTransparent ? 0.55 : 0.85;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDarkTheme
            ? Colors.white.withValues(alpha: 0.06 * alpha * 2)
            : Colors.white.withValues(alpha: alpha),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFE2E7F4),
        ),
      ),
      child: Text(
        date,
        style: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
