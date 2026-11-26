import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// One client group inside the time report (name, minutes, estimated amount).
class TimeClientRow extends StatelessWidget {
  final String name;
  final String minutesLabel;
  final String amountLabel;
  final bool hasRate;
  final Color textColor;
  final Color muted;

  const TimeClientRow({
    super.key,
    required this.name,
    required this.minutesLabel,
    required this.amountLabel,
    required this.hasRate,
    required this.textColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  minutesLabel,
                  style: TextStyle(fontSize: 10.5, color: muted),
                ),
              ],
            ),
          ),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: hasRate ? AppColors.primary : muted,
            ),
          ),
        ],
      ),
    );
  }
}
