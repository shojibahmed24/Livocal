import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:livocal/features/chat/controllers/chat_controller.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/features/freelancer/services/invoice_pdf_actions.dart';
import 'package:livocal/features/freelancer/services/invoice_pdf_service.dart';
import 'package:livocal/features/freelancer/services/invoice_service.dart';
import 'package:livocal/features/freelancer/services/invoice_share_service.dart';
import 'package:livocal/features/freelancer/widgets/invoice_actions_bar.dart';
import 'package:livocal/features/freelancer/widgets/invoice_form.dart';
import 'package:livocal/features/freelancer/widgets/invoice_line_tile.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Create or edit a quote/invoice for one client.
class InvoiceEditorScreen extends ConsumerStatefulWidget {
  final User user;
  final String clientUid;
  final String clientName;
  final Invoice? invoice;

  const InvoiceEditorScreen({
    super.key,
    required this.user,
    required this.clientUid,
    required this.clientName,
    this.invoice,
  });

  @override
  ConsumerState<InvoiceEditorScreen> createState() =>
      _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends ConsumerState<InvoiceEditorScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _tax = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final List<InvoiceLineDraft> _drafts = [];

  Invoice? _invoice;
  String _currency = 'USD';
  DateTime? _dueDate;
  bool _busy = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'BDT', 'INR', 'AED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    _tax.dispose();
    _discount.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _load() async {
    final existing = widget.invoice;
    final invoice = existing ??
        await InvoiceService.create(
          ownerUid: widget.user.id,
          clientUid: widget.clientUid,
          clientName: widget.clientName,
        );
    if (!mounted) return;
    setState(() {
      _invoice = invoice;
      _currency = invoice.currency;
      _tax.text = invoice.taxPct == 0 ? '' : invoice.taxPct.toString();
      _discount.text = invoice.discount == 0 ? '' : invoice.discount.toString();
      _notes.text = invoice.notes;
      _dueDate = invoice.dueDate;
      _drafts
        ..clear()
        ..addAll(
          invoice.items.isEmpty
              ? [InvoiceLineDraft()]
              : invoice.items.map(InvoiceLineDraft.new),
        );
    });
  }

  Invoice _current() {
    final invoice = _invoice!;
    invoice.items = _drafts
        .map((draft) => draft.toLine())
        .where((line) => line.description.isNotEmpty || line.amount > 0)
        .toList();
    invoice.currency = _currency;
    invoice.taxPct = double.tryParse(_tax.text.trim()) ?? 0;
    invoice.discount = double.tryParse(_discount.text.trim()) ?? 0;
    invoice.notes = _notes.text.trim();
    invoice.dueDate = _dueDate;
    return invoice;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<Invoice?> _save() async {
    final invoice = _current();
    if (invoice.items.isEmpty) {
      _snack(_t('addItem'));
      return null;
    }
    await InvoiceService.save(invoice);
    return invoice;
  }

  Future<void> _pdfAction({required bool share}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (share) {
        await InvoicePdfActions.share(
          save: _save,
          fromName: widget.user.name,
          t: _t,
        );
      } else {
        await InvoicePdfActions.preview(
          save: _save,
          fromName: widget.user.name,
          t: _t,
        );
      }
    } catch (e) {
      debugPrint('[InvoiceEditor] pdf action failed: $e');
      if (mounted) _snack(_t('summaryFailed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Builds and uploads the invoice PDF. Returns null when Storage is not
  /// available, in which case the chat message falls back to the web link.
  Future<Attachment?> _pdfAttachment(Invoice invoice) async {
    try {
      final file = await InvoicePdfService.build(
        invoice: invoice,
        fromName: widget.user.name,
        t: _t,
      );
      final fileName = '${invoice.number}.pdf';
      final url = await InvoiceShareService.uploadPdf(
        senderUid: widget.user.id,
        receiverUid: widget.clientUid,
        fileName: fileName,
        file: file,
      );
      if (url == null) return null;
      return Attachment(
        type: AttachmentType.document,
        url: url,
        fileName: fileName,
        fileSize: await file.length(),
        fileExtension: 'pdf',
        file: file,
        uploadStatus: UploadStatus.uploaded,
        autoDownload: true,
      );
    } catch (e) {
      debugPrint('[InvoiceEditor] PDF attachment skipped: $e');
      return null;
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final invoice = await _save();
      if (invoice == null || !mounted) return;
      await InvoiceService.markSent(invoice);
      final token =
          await InvoiceService.ensureShareToken(invoice, widget.user.name);
      final due = invoice.dueDate == null
          ? _t('noDueDate')
          : Invoice.formatDate(invoice.dueDate!);
      final link = '${AppConfig.relayHttpBaseUrl}/i/$token';
      final summary = '📄 ${_t('invoice')} ${invoice.number}\n'
          '${_t('totalLabel')}: ${invoice.totalLabel}\n'
          '${_t('dueDate')}: $due';
      final content = '$summary\n${_t('previewInvoice')}: $link';

      final attachment = await _pdfAttachment(invoice);
      if (!mounted) return;

      ref.read(chatControllerProvider.notifier).sendMessageNoAttachments(
            Message(
              id: const Uuid().v4(),
              content: content,
              status: MessageStatus.pending,
              senderId: widget.user.id,
              receiverId: widget.clientUid,
              timestamp: Timestamp.now(),
              attachment: attachment,
              invoiceId: invoice.id.toString(),
            ),
          );
      _snack(_t('invoiceSentMsg'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReminder() async {
    final invoice = _invoice;
    if (invoice == null) return;
    final token =
        await InvoiceService.ensureShareToken(invoice, widget.user.name);
    if (!mounted) return;
    final link = '${AppConfig.relayHttpBaseUrl}/i/$token';
    final due =
        invoice.dueDate == null ? '-' : Invoice.formatDate(invoice.dueDate!);
    final content =
        '🔔 ${_t('sendReminder')}: ${_t('invoice')} ${invoice.number}\n'
        '${_t('totalLabel')}: ${invoice.totalLabel}\n'
        '${_t('dueDate')}: $due\n'
        '${_t('previewInvoice')}: $link';
    ref.read(chatControllerProvider.notifier).sendMessageNoAttachments(
          Message(
            id: const Uuid().v4(),
            content: content,
            status: MessageStatus.pending,
            senderId: widget.user.id,
            receiverId: widget.clientUid,
            timestamp: Timestamp.now(),
          ),
        );
    _snack(_t('reminderSent'));
  }

  Future<void> _markPaid() async {
    final invoice = await _save();
    if (invoice == null) return;
    await InvoiceService.markPaid(invoice);
    if (!mounted) return;
    setState(() {});
    _snack(_t('invoicePaidMsg'));
  }

  void _removeDraft(InvoiceLineDraft draft) {
    if (_drafts.length == 1) {
      draft.description.clear();
      draft.rate.clear();
      setState(() {});
      return;
    }
    setState(() => _drafts.remove(draft));
    draft.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final invoice = _invoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          invoice == null
              ? _t('invoice')
              : '${_t('invoice')} · ${invoice.number}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_invoice?.status == 'sent' && _invoice?.isPaid == false)
            IconButton(
              onPressed: _sendReminder,
              tooltip: _t('sendReminder'),
              icon: const Icon(Icons.notifications_active_outlined),
            ),
          IconButton(
            onPressed: () => _pdfAction(share: true),
            tooltip: _t('sharePdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: invoice == null
          ? const Center(child: CircularProgressIndicator())
          : InvoiceForm(
              clientName: widget.clientName,
              invoice: _current(),
              drafts: _drafts,
              currency: _currency,
              currencies: _currencies,
              tax: _tax,
              discount: _discount,
              notes: _notes,
              dueDate: _dueDate,
              t: _t,
              textColor: textColor,
              muted: muted,
              onChanged: () => setState(() {}),
              onAddItem: () => setState(() => _drafts.add(InvoiceLineDraft())),
              onRemoveItem: _removeDraft,
              onCurrencyChanged: (value) => setState(() => _currency = value),
              onPickDueDate: _pickDueDate,
            ),
      bottomNavigationBar: invoice == null
          ? null
          : InvoiceActionsBar(
              invoice: invoice,
              busy: _busy,
              t: _t,
              onPreview: () => _pdfAction(share: false),
              onSend: _send,
              onMarkPaid: _markPaid,
            ),
    );
  }
}
