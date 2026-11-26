import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/theme/app_colors.dart';

/// Subtotal / tax / discount / total block of the invoice editor.
class InvoiceTotalsCard extends StatelessWidget {
  final Invoice invoice;
  final String Function(String key) t;
  final Color muted;
  final Color textColor;

  const InvoiceTotalsCard({
    super.key,
    required this.invoice,
    required this.t,
    required this.muted,
    required this.textColor,
  });

  String get _currency => invoice.currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row(
            t('subtotal'),
            '$_currency ${invoice.subtotal.toStringAsFixed(2)}',
            muted,
            textColor,
          ),
          _row(
            t('taxPct'),
            '$_currency ${invoice.taxAmount.toStringAsFixed(2)}',
            muted,
            textColor,
          ),
          _row(
            t('discount'),
            '- $_currency ${invoice.discount.toStringAsFixed(2)}',
            muted,
            textColor,
          ),
          const Divider(height: 16),
          _row(
            t('totalLabel'),
            '$_currency ${invoice.total.toStringAsFixed(2)}',
            AppColors.primary,
            AppColors.primary,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
