import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/theme/app_colors.dart';

/// Editable controllers for one invoice row.
class InvoiceLineDraft {
  final TextEditingController description;
  final TextEditingController qty;
  final TextEditingController rate;

  InvoiceLineDraft([InvoiceLine? line])
      : description = TextEditingController(text: line?.description ?? ''),
        qty = TextEditingController(
          text: line == null
              ? '1'
              : (line.qty % 1 == 0
                  ? line.qty.toInt().toString()
                  : line.qty.toString()),
        ),
        rate = TextEditingController(
          text: line == null || line.rate == 0
              ? ''
              : (line.rate % 1 == 0
                  ? line.rate.toInt().toString()
                  : line.rate.toString()),
        );

  InvoiceLine toLine() => InvoiceLine(
        description: description.text.trim(),
        qty: double.tryParse(qty.text.trim()) ?? 0,
        rate: double.tryParse(rate.text.trim()) ?? 0,
      );

  bool get isEmpty =>
      description.text.trim().isEmpty &&
      (double.tryParse(rate.text.trim()) ?? 0) == 0;

  void dispose() {
    description.dispose();
    qty.dispose();
    rate.dispose();
  }
}

/// One row in the invoice editor: description, qty, rate, amount, remove.
class InvoiceLineTile extends StatelessWidget {
  final InvoiceLineDraft draft;
  final String currency;
  final String Function(String key) t;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const InvoiceLineTile({
    super.key,
    required this.draft,
    required this.currency,
    required this.t,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final line = draft.toLine();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.description,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: t('itemDescription'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: t('statusVoid'),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t('qty'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: draft.rate,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t('unitRate'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 78,
                child: Text(
                  '$currency ${line.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
