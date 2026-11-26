import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/call_summary.dart';
import 'package:livocal/theme/app_colors.dart';

/// Read-only rendering of a generated call summary.
class CallSummaryView extends StatelessWidget {
  final CallSummary summary;
  final String Function(String key) t;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final bool saved;
  final bool saving;

  const CallSummaryView({
    super.key,
    required this.summary,
    required this.t,
    required this.onCopy,
    required this.onShare,
    required this.onSave,
    required this.saved,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                t('callSummary'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.summary,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: textColor,
            ),
          ),
          if (summary.decisions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _heading(t('decisions'), muted),
            ...summary.decisions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (summary.actionItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            _heading(t('actionItems'), muted),
            ...summary.actionItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: (item.isMine ? AppColors.primary : muted)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isMine
                            ? t('summaryOwnerMe')
                            : t('summaryOwnerClient'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: item.isMine ? AppColors.primary : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (summary.clientHints.isNotEmpty) ...[
            const SizedBox(height: 10),
            _heading(t('clientHints'), muted),
            Text(
              summary.clientHints,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _action(Icons.copy_rounded, t('copySummary'), onCopy),
              const SizedBox(width: 8),
              _action(Icons.ios_share_rounded, t('shareSummary'), onShare),
              const Spacer(),
              _action(
                saved ? Icons.check_circle_rounded : Icons.save_alt_rounded,
                saved ? t('summarySaved') : t('saveToCrm'),
                saving ? null : onSave,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heading(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool highlight = false,
  }) {
    final color = highlight ? AppColors.primary : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
