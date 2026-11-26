import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a proposal to PDF with bundled Bangla + Latin fonts.
class ProposalPdfService {
  ProposalPdfService._();

  static Future<File> build({
    required String fromName,
    required String clientName,
    required String headline,
    required String scope,
    required String timeline,
    required String price,
    required String terms,
    required String title,
    required String scopeLabel,
    required String timelineLabel,
    required String priceLabel,
    required String termsLabel,
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

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$fromName  →  $clientName',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            headline,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          _section(scopeLabel, scope),
          if (timeline.isNotEmpty) _section(timelineLabel, timeline),
          if (price.isNotEmpty) _section(priceLabel, price),
          if (terms.isNotEmpty) _section(termsLabel, terms),
          pw.SizedBox(height: 26),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            'Powered by Livocal · live voice translation for freelancers',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/proposal_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  static pw.Widget _section(String label, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.teal800,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(body, style: const pw.TextStyle(fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}
