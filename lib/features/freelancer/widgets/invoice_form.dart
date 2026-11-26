import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/features/freelancer/widgets/invoice_line_tile.dart';
import 'package:livocal/features/freelancer/widgets/invoice_meta_fields.dart';
import 'package:livocal/features/freelancer/widgets/invoice_status_pill.dart';
import 'package:livocal/features/freelancer/widgets/invoice_totals_card.dart';

/// Scrollable form body of the invoice editor.
class InvoiceForm extends StatelessWidget {
  final String clientName;
  final Invoice invoice;
  final List<InvoiceLineDraft> drafts;
  final String currency;
  final List<String> currencies;
  final TextEditingController tax;
  final TextEditingController discount;
  final TextEditingController notes;
  final DateTime? dueDate;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onChanged;
  final VoidCallback onAddItem;
  final void Function(InvoiceLineDraft draft) onRemoveItem;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onPickDueDate;

  const InvoiceForm({
    super.key,
    required this.clientName,
    required this.invoice,
    required this.drafts,
    required this.currency,
    required this.currencies,
    required this.tax,
    required this.discount,
    required this.notes,
    required this.dueDate,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onChanged,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onCurrencyChanged,
    required this.onPickDueDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                clientName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            InvoiceStatusPill(invoice: invoice, t: t),
          ],
        ),
        const SizedBox(height: 14),
        ...drafts.map(
          (draft) => InvoiceLineTile(
            draft: draft,
            currency: currency,
            t: t,
            onChanged: onChanged,
            onRemove: () => onRemoveItem(draft),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(t('addItem')),
        ),
        const SizedBox(height: 16),
        InvoiceMetaFields(
          currency: currency,
          currencies: currencies,
          taxController: tax,
          discountController: discount,
          dueDate: dueDate,
          t: t,
          onCurrencyChanged: onCurrencyChanged,
          onChanged: onChanged,
          onPickDueDate: onPickDueDate,
        ),
        const SizedBox(height: 12),
        InvoiceTotalsCard(
          invoice: invoice,
          t: t,
          muted: muted,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: InputDecoration(
            isDense: true,
            labelText: t('invoiceNotes'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
