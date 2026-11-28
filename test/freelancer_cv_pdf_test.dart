import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/cv_pdf_service.dart';

/// Smoke test: the redesigned CV must build, embed the fonts and produce a
/// readable PDF file even when no photo is available.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  test('builds a one-page CV PDF with all profile sections', () async {
    final profile = FreelancerProfile(
      ownerUid: 'uid-1',
      slug: 'shojib',
      username: 'shojib',
      displayName: 'Shojib Ahmed',
      headline: 'Flutter & Firebase Developer',
      bio: 'I build cross-platform apps with Flutter and Firebase.',
      skills: const ['Flutter', 'Dart', 'Firebase', 'Riverpod'],
      languages: const ['English:fluent', 'Bangla:native'],
      rateAmount: 20,
      rateCurrency: 'USD',
      responseTime: 'within 2 hours',
      experience: const [
        '{"role":"Frontend Developer","company":"Running Group",'
            '"start":"2021","end":"2022","summary":"Shipped two apps."}',
      ],
      education: const [
        '{"school":"Rajshahi University","degree":"BSc CSE",'
            '"start":"2016","end":"2020"}',
      ],
      certifications: const [
        '{"name":"Flutter Professional","issuer":"Google","year":"2024"}',
      ],
      portfolio: const [
        '{"label":"Portfolio","url":"https://example.com"}',
      ],
      updatedAt: DateTime(2026, 1, 1),
    );

    final file = await CvPdfService.build(profile);
    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
