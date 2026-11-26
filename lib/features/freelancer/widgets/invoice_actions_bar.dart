import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';

/// Bottom action bar: preview plus send / mark paid.
class InvoiceActionsBar extends StatelessWidget {
  final Invoice invoice;
  final bool busy;
  final String Function(String key) t;
  final VoidCallback onPreview;
  final VoidCallback onSend;
  final VoidCallback onMarkPaid;

  const InvoiceActionsBar({
    super.key,
    required this.invoice,
    required this.busy,
    required this.t,
    required this.onPreview,
    required this.onSend,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = invoice.status == 'sent';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(t('previewInvoice')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy || invoice.isPaid
                    ? null
                    : (isSent ? onMarkPaid : onSend),
                icon: Icon(
                  isSent
                      ? Icons.check_circle_outline_rounded
                      : Icons.send_rounded,
                  size: 18,
                ),
                label: Text(isSent ? t('markPaid') : t('sendInvoice')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
