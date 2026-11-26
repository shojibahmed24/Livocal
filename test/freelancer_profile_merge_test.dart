import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/models/freelancer_profile.dart';

void main() {
  group('FreelancerProfile.mergeMissingFrom', () {
    FreelancerProfile profile({
      String headline = '',
      String responseTime = '',
      int projects = 0,
      List<String> skills = const [],
    }) {
      return FreelancerProfile(
        ownerUid: 'u',
        slug: 'u',
        displayName: 'Shojib',
        headline: headline,
        responseTime: responseTime,
        projectsDone: projects,
        skills: skills,
        updatedAt: DateTime(2026, 11, 27),
      );
    }

    test('fills empty fields from the cloud copy', () {
      final local = profile();
      final remote = profile(
        headline: 'Flutter developer',
        responseTime: 'within 2 hours',
        projects: 25,
        skills: ['Flutter', 'Dart'],
      );

      local.mergeMissingFrom(remote);

      expect(local.responseTime, 'within 2 hours');
      expect(local.projectsDone, 25);
      expect(local.skills, ['Flutter', 'Dart']);
      expect(local.headline, 'Flutter developer');
    });

    test('never overwrites non-empty local values', () {
      final local = profile(headline: 'Local headline', projects: 3);
      final remote = profile(headline: 'Remote headline', projects: 99);

      local.mergeMissingFrom(remote);

      expect(local.headline, 'Local headline');
      expect(local.projectsDone, 3);
    });

    test('copies new sections when local is empty', () {
      final local = profile();
      final remote = FreelancerProfile(
        ownerUid: 'u',
        slug: 'u',
        displayName: 'Shojib',
        education: ['{"school":"DU","degree":"BSc"}'],
        certifications: ['{"name":"Flutter"}'],
        faq: ['{"question":"Rate?","answer":"USD 20"}'],
        accentColor: 'violet',
        sectionOrder: ['about', 'experience'],
        updatedAt: DateTime(2026, 11, 27),
      );

      local.mergeMissingFrom(remote);

      expect(local.educationEntries.first['school'], 'DU');
      expect(local.certificationEntries.first['name'], 'Flutter');
      expect(local.faqEntries.first['question'], 'Rate?');
      expect(local.accentColor, 'violet');
      expect(local.sectionOrder, ['about', 'experience']);
    });
  });
}
