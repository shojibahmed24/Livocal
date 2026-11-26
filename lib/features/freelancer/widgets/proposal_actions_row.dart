import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Copy / share / save row under a generated proposal.
class ProposalActionsRow extends StatelessWidget {
  final String copyLabel;
  final String shareLabel;
  final String saveLabel;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback? onSave;

  const ProposalActionsRow({
    super.key,
    required this.copyLabel,
    required this.shareLabel,
    required this.saveLabel,
    required this.onCopy,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _action(Icons.copy_rounded, copyLabel, onCopy),
        const SizedBox(width: 8),
        _action(Icons.ios_share_rounded, shareLabel, onShare),
        const Spacer(),
        _action(
          Icons.save_alt_rounded,
          saveLabel,
          onSave,
          highlight: true,
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
