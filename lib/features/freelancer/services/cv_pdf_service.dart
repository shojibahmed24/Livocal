import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';

/// Builds a CV PDF from the public profile.
class CvPdfService {
  CvPdfService._();

  static Future<File> build(FreelancerProfile profile) async {
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

    final rate = profile.rateAmount > 0
        ? '${profile.rateCurrency} ${profile.rateAmount.toStringAsFixed(0)} / '
            '${profile.rateBasis == 'project' ? 'project' : 'hour'}'
        : '';
    final contact = 'livocal.app/u/${profile.handle}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            profile.displayName,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(profile.headline, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 2),
          pw.Text(
            contact,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          if (rate.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(rate, style: const pw.TextStyle(fontSize: 9)),
          ],
          pw.SizedBox(height: 14),
          if (profile.bio.isNotEmpty) _section('Summary', profile.bio),
          if (profile.skills.isNotEmpty)
            _section('Skills', profile.skills.join(' · ')),
          if (profile.experienceEntries.isNotEmpty) ...[
            pw.Text(
              'EXPERIENCE',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            ...profile.experienceEntries.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${item['role'] ?? ''}${item['company'] != null && item['company']!.isNotEmpty ? ' — ${item['company']}' : ''}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((item['start'] ?? '').isNotEmpty ||
                        (item['end'] ?? '').isNotEmpty)
                      pw.Text(
                        '${item['start'] ?? ''} – ${(item['end'] ?? '').isEmpty ? 'Present' : item['end']}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if ((item['summary'] ?? '').isNotEmpty)
                      pw.Text(
                        item['summary']!,
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (profile.educationEntries.isNotEmpty)
            _section(
              'Education',
              profile.educationEntries
                  .map(
                    (item) =>
                        '${item['school'] ?? ''} — ${item['degree'] ?? ''} '
                        '(${item['start'] ?? ''}–${item['end'] ?? ''})',
                  )
                  .join('\n'),
            ),
          if (profile.certificationEntries.isNotEmpty)
            _section(
              'Certifications',
              profile.certificationEntries
                  .map(
                    (item) => '${item['name'] ?? ''} — ${item['issuer'] ?? ''} '
                        '${item['year'] ?? ''}',
                  )
                  .join('\n'),
            ),
          if (profile.caseEntries.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'SELECTED WORK',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            ...profile.caseEntries.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item['title'] ?? '',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((item['result'] ?? '').isNotEmpty)
                      pw.Text(
                        item['result']!,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (profile.portfolioEntries.isNotEmpty)
            _section(
              'Links',
              profile.portfolioEntries
                  .map((item) => '${item['label']} — ${item['url']}')
                  .join('\n'),
            ),
          if (profile.languages.isNotEmpty)
            _section(
              'Languages',
              profile.languageEntries
                  .map((item) => '${item['code']} ${item['level']}')
                  .join(' · '),
            ),
          pw.SizedBox(height: 18),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            'Generated by Livocal · livocal.app',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeName =
        profile.displayName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final file = File('${dir.path}/CV_$safeName.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  static pw.Widget _section(String title, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(body, style: const pw.TextStyle(fontSize: 10, height: 1.4)),
        ],
      ),
    );
  }
}
