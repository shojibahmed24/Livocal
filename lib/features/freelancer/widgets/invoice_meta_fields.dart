import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Currency, tax, discount and due-date controls of the invoice editor.
class InvoiceMetaFields extends StatelessWidget {
  final String currency;
  final List<String> currencies;
  final TextEditingController taxController;
  final TextEditingController discountController;
  final DateTime? dueDate;
  final String Function(String key) t;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onChanged;
  final VoidCallback onPickDueDate;

  const InvoiceMetaFields({
    super.key,
    required this.currency,
    required this.currencies,
    required this.taxController,
    required this.discountController,
    required this.dueDate,
    required this.t,
    required this.onCurrencyChanged,
    required this.onChanged,
    required this.onPickDueDate,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: currency,
                isDense: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: currencies
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child:
                              Text(code, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onCurrencyChanged(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: t('taxPct'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: t('discount'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPickDueDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${t('dueDate')}: '
                  '${dueDate == null ? t('noDueDate') : _formatDate(dueDate!)}',
                  style: TextStyle(fontSize: 12.5, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
