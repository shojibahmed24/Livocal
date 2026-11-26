import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/features/freelancer/services/invoice_service.dart';
import 'package:livocal/features/freelancer/views/invoice_editor_screen.dart';
import 'package:livocal/features/freelancer/widgets/invoice_status_pill.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// All invoices of the signed-in freelancer, filterable by status.
class InvoicesScreen extends ConsumerStatefulWidget {
  final User user;

  const InvoicesScreen({super.key, required this.user});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    InvoiceService.pull(widget.user.id);
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  bool _matches(Invoice invoice) {
    switch (_filter) {
      case 'draft':
        return invoice.status == 'draft';
      case 'sent':
        return invoice.status == 'sent' && !invoice.isOverdue;
      case 'paid':
        return invoice.isPaid;
      case 'overdue':
        return invoice.isOverdue;
      default:
        return !invoice.isVoid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(_t('invoices'))),
      body: StreamBuilder<List<Invoice>>(
        stream: InvoiceService.watch(widget.user.id),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Invoice>[];
          final visible = all.where(_matches).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    _chip('all', 'invoices', muted),
                    _chip('draft', 'statusDraft', muted),
                    _chip('sent', 'statusSent', muted),
                    _chip('paid', 'statusPaid', muted),
                    _chip('overdue', 'filterOverdue', muted),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          _t('emptyInvoices'),
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final invoice = visible[index];
                          return _InvoiceTile(
                            invoice: invoice,
                            t: _t,
                            textColor: textColor,
                            muted: muted,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InvoiceEditorScreen(
                                    user: widget.user,
                                    clientUid: invoice.clientUid,
                                    clientName: invoice.clientName,
                                    invoice: invoice,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String value, String labelKey, Color muted) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_t(labelKey), style: const TextStyle(fontSize: 11.5)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected ? AppColors.primary : muted.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onTap;

  const _InvoiceTile({
    required this.invoice,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final due = invoice.dueDate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: invoice.isOverdue
                  ? Colors.redAccent.withValues(alpha: 0.45)
                  : muted.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.number,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  InvoiceStatusPill(invoice: invoice, t: t),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                invoice.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    invoice.totalLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (due != null)
                    Text(
                      '${t('dueDate')} ${due.day.toString().padLeft(2, '0')}/'
                      '${due.month.toString().padLeft(2, '0')}/${due.year}',
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
