import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/theme/app_colors.dart';

/// Small status chip for invoices (draft / sent / paid / void / overdue).
class InvoiceStatusPill extends StatelessWidget {
  final Invoice invoice;
  final String Function(String key) t;

  const InvoiceStatusPill({
    super.key,
    required this.invoice,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final String label;
    late final Color color;

    if (invoice.isVoid) {
      label = t('statusVoid');
      color = isDark ? Colors.white54 : Colors.grey;
    } else if (invoice.isPaid) {
      label = t('statusPaid');
      color = AppColors.primary;
    } else if (invoice.isOverdue) {
      label = t('filterOverdue');
      color = Colors.redAccent;
    } else if (invoice.status == 'sent') {
      label = t('statusSent');
      color = Colors.orangeAccent.shade700;
    } else {
      label = t('statusDraft');
      color = isDark ? Colors.blueGrey.shade200 : Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
