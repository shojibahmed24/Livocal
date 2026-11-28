import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';

/// Builds the premium one-page CV PDF from the public profile.
class CvPdfService {
  CvPdfService._();

  static final PdfColor _accent = PdfColor.fromHex('#0F9D76');
  static final PdfColor _ink = PdfColor.fromHex('#0B1220');
  static final PdfColor _body = PdfColor.fromHex('#334155');
  static final PdfColor _muted = PdfColor.fromHex('#64748B');
  static final PdfColor _rule = PdfColor.fromHex('#E2E8F0');
  static final PdfColor _chip = PdfColor.fromHex('#ECFDF5');

  static Future<File> build(FreelancerProfile profile) async {
    final theme = pw.ThemeData.withFont(
      base: await _font('assets/fonts/NotoSans-Regular.ttf'),
      bold: await _font('assets/fonts/NotoSans-Bold.ttf'),
      fontFallback: [
        await _font('assets/fonts/NotoSansBengali-Regular.ttf'),
        await _font('assets/fonts/NotoSansBengali-Bold.ttf'),
      ],
    );
    final photo = await _photo(profile.avatarUrl);
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 36, 38, 30),
        build: (context) => [
          _header(profile, photo),
          if (profile.bio.isNotEmpty)
            _section('Summary', [pw.Text(profile.bio, style: _bodyStyle())]),
          if (profile.skills.isNotEmpty)
            _section('Core skills', [_skills(profile.skills)]),
          if (profile.experienceEntries.isNotEmpty)
            _section('Experience', [
              ...profile.experienceEntries.map(_experienceRow),
            ]),
          if (profile.educationEntries.isNotEmpty)
            _section('Education', [
              ...profile.educationEntries.map(_educationRow),
            ]),
          if (profile.certificationEntries.isNotEmpty)
            _section('Certifications', [
              ...profile.certificationEntries.map(_certificationRow),
            ]),
          if (profile.caseEntries.isNotEmpty)
            _section('Selected work', [...profile.caseEntries.map(_caseRow)]),
          if (profile.languages.isNotEmpty)
            _section('Languages', [_plain(_languageLine(profile))]),
          if (_links(profile).isNotEmpty)
            _section('Links', [..._links(profile).map(_plain)]),
          pw.SizedBox(height: 14),
          pw.Container(height: 0.8, color: _rule),
          pw.SizedBox(height: 5),
          pw.Text(
            'livocal.app/u/${profile.handle} · Generated with Livocal',
            style: pw.TextStyle(fontSize: 7.5, color: _muted),
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

  static Future<pw.Font> _font(String asset) async =>
      pw.Font.ttf(await rootBundle.load(asset));

  static Future<pw.MemoryImage?> _photo(String url) async {
    if (!url.startsWith('http')) return null;
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      if (res.bodyBytes.length > 4 * 1024 * 1024) return null;
      return pw.MemoryImage(res.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(FreelancerProfile profile, pw.MemoryImage? photo) {
    final facts = <String>[
      'livocal.app/u/${profile.handle}',
      if (profile.rateAmount > 0)
        '${profile.rateCurrency} ${profile.rateAmount.toStringAsFixed(0)} / '
            '${profile.rateBasis == 'project' ? 'project' : 'hour'}',
      if (profile.responseTime.isNotEmpty)
        'Replies ${profile.responseTime.toLowerCase()}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.displayName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (profile.headline.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      profile.headline,
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Wrap(
                    spacing: 9,
                    runSpacing: 2,
                    children: [
                      for (var i = 0; i < facts.length; i++) ...[
                        if (i > 0)
                          pw.Text('·',
                              style: pw.TextStyle(fontSize: 8, color: _muted)),
                        pw.Text(
                          facts[i],
                          style: pw.TextStyle(fontSize: 8.2, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (photo != null) ...[
              pw.SizedBox(width: 16),
              pw.Container(
                width: 74,
                height: 74,
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  image: pw.DecorationImage(
                    image: photo,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.6, color: _accent),
      ],
    );
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 13),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 0.7, color: _rule),
        pw.SizedBox(height: 6),
        ...children,
      ],
    );
  }

  static pw.Widget _skills(List<String> skills) {
    final shown = skills.take(18).toList();
    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final skill in shown)
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: pw.BoxDecoration(
              color: _chip,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              skill,
              style: pw.TextStyle(fontSize: 8.2, color: _ink),
            ),
          ),
      ],
    );
  }

  static pw.Widget _experienceRow(Map<String, String> item) {
    final role = item['role'] ?? '';
    final company = item['company'] ?? '';
    final dates = _dates(item['start'] ?? '', item['end'] ?? '');
    final summary = item['summary'] ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: role,
                        style: pw.TextStyle(
                          fontSize: 9.6,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      if (company.isNotEmpty)
                        pw.TextSpan(
                          text: '  ·  $company',
                          style: pw.TextStyle(fontSize: 9, color: _muted),
                        ),
                    ],
                  ),
                ),
              ),
              if (dates.isNotEmpty)
                pw.Text(
                  dates,
                  style: pw.TextStyle(fontSize: 8.2, color: _muted),
                ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              '•  $summary',
              style: _bodyStyle(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _educationRow(Map<String, String> item) {
    final school = item['school'] ?? '';
    final degree = item['degree'] ?? '';
    final dates = _dates(item['start'] ?? '', item['end'] ?? '');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: school,
                    style: pw.TextStyle(
                      fontSize: 9.4,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (degree.isNotEmpty)
                    pw.TextSpan(
                      text: '  ·  $degree',
                      style: pw.TextStyle(fontSize: 9, color: _body),
                    ),
                ],
              ),
            ),
          ),
          if (dates.isNotEmpty)
            pw.Text(dates, style: pw.TextStyle(fontSize: 8.2, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _certificationRow(Map<String, String> item) {
    final name = item['name'] ?? '';
    final issuer = item['issuer'] ?? '';
    final year = item['year'] ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: name,
                    style: pw.TextStyle(
                      fontSize: 9.2,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (issuer.isNotEmpty)
                    pw.TextSpan(
                      text: '  ·  $issuer',
                      style: pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                ],
              ),
            ),
          ),
          if (year.isNotEmpty)
            pw.Text(year, style: pw.TextStyle(fontSize: 8.2, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _caseRow(Map<String, String> item) {
    final title = item['title'] ?? '';
    final client = item['client'] ?? '';
    final result = item['result'] ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: title,
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (client.isNotEmpty)
                  pw.TextSpan(
                    text: '  ·  $client',
                    style: pw.TextStyle(fontSize: 9, color: _muted),
                  ),
              ],
            ),
          ),
          if (result.isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            pw.Text(result, style: _bodyStyle(fontSize: 8.8)),
          ],
        ],
      ),
    );
  }

  static List<String> _links(FreelancerProfile p) => [
        if (p.githubUrl.isNotEmpty) 'GitHub — ${p.githubUrl}',
        if (p.linkedinUrl.isNotEmpty) 'LinkedIn — ${p.linkedinUrl}',
        if (p.websiteUrl.isNotEmpty) 'Website — ${p.websiteUrl}',
        for (final item in p.portfolioEntries)
          if ((item['label'] ?? '').isNotEmpty)
            '${item['label']} — ${item['url'] ?? ''}',
      ];

  static String _languageLine(FreelancerProfile p) => p.languageEntries
      .map((item) => '${item['code']} ${item['level']}'.trim())
      .join('  ·  ');

  static String _dates(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    final to = end.isEmpty ? 'Present' : end;
    if (start.isEmpty) return to;
    return '$start – $to';
  }

  static pw.Widget _plain(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text, style: _bodyStyle(fontSize: 8.8)),
      );

  static pw.TextStyle _bodyStyle({double fontSize = 9.4}) => pw.TextStyle(
        fontSize: fontSize,
        color: _body,
        height: 1.3,
      );
}
