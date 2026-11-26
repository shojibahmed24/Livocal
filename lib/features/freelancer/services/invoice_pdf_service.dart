import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:livocal/features/freelancer/models/invoice.dart';

/// Renders an invoice to a PDF file on this device.
///
/// Bangla and Latin glyphs come from bundled Noto fonts, so the document looks
/// the same offline on every phone.
class InvoicePdfService {
  InvoicePdfService._();

  static Future<File> build({
    required Invoice invoice,
    required String fromName,
    required String Function(String key) t,
  }) async {
    final bengali = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'),
    );
    final latin = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: bengali,
        bold: bengali,
        fontFallback: [latin],
      ),
    );

    final statusLabel = _statusLabel(invoice, t);
    final due = invoice.dueDate == null
        ? t('noDueDate')
        : _formatDate(invoice.dueDate!);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    t('invoice').toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.number,
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(statusLabel,
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(fromName,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Livocal',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(t('invoiceClient'),
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(invoice.clientName,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('${t('dueDate')}: $due',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _itemsTable(invoice, t),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _totalRow(t('subtotal'),
                        _money(invoice.currency, invoice.subtotal)),
                    if (invoice.taxPct > 0)
                      _totalRow(
                          '${t('taxPct')} ${invoice.taxPct.toStringAsFixed(1)}',
                          _money(invoice.currency, invoice.taxAmount)),
                    if (invoice.discount > 0)
                      _totalRow(t('discount'),
                          '- ${_money(invoice.currency, invoice.discount)}'),
                    pw.Divider(),
                    _totalRow(t('totalLabel'),
                        _money(invoice.currency, invoice.total),
                        bold: true),
                  ],
                ),
              ),
            ],
          ),
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(t('invoiceNotes'),
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 11)),
          ],
          pw.SizedBox(height: 28),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            'Powered by Livocal · live voice translation for freelancers',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.number}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  static pw.Widget _itemsTable(Invoice invoice, String Function(String) t) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _cell(t('itemDescription'), bold: true),
            _cell(t('qty'), bold: true),
            _cell(t('unitRate'), bold: true),
            _cell(t('totalLabel'), bold: true),
          ],
        ),
        ...invoice.items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item.description),
              _cell(_plain(item.qty)),
              _cell(_money(invoice.currency, item.rate)),
              _cell(_money(invoice.currency, item.amount)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  static String _plain(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  static String _money(String currency, double value) {
    return '$currency ${value.toStringAsFixed(2)}';
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String _statusLabel(Invoice invoice, String Function(String) t) {
    if (invoice.isVoid) return t('statusVoid');
    if (invoice.isPaid) return t('statusPaid');
    if (invoice.status == 'sent') {
      return invoice.isOverdue ? t('filterOverdue') : t('statusSent');
    }
    return t('statusDraft');
  }
}
