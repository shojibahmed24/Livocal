import 'dart:convert';

import 'package:isar/isar.dart';

import 'package:livocal/shared/constants/app_config.dart';

part 'freelancer_profile.g.dart';

/// Public freelancer profile: one per user, mirrored to `profiles/{uid}`.
@collection
class FreelancerProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String ownerUid;

  String slug;
  String username;
  String displayName;
  String headline;
  String bio;

  List<String> skills;

  /// `code:level` pairs, e.g. `en:B2`.
  List<String> languages;

  double rateAmount;
  String rateCurrency;

  /// `hourly` | `project`
  String rateBasis;

  /// `full_time` | `part_time` | `busy`
  String availability;

  /// JSON encoded `{"label": "...", "url": "...", "imageUrl": "..."}` strings.
  List<String> portfolio;

  /// JSON encoded `{"title": "...", "from": 100}` strings.
  List<String> services;

  /// JSON encoded case studies:
  /// `{"title","client","problem","result","imageUrl","url","tags"}`.
  List<String> caseStudies;

  /// JSON encoded experience:
  /// `{"role","company","start","end","summary"}`.
  List<String> experience;

  /// JSON encoded education: `{"school","degree","start","end"}`.
  List<String> education;

  /// JSON encoded certifications: `{"name","issuer","year"}`.
  List<String> certifications;

  /// JSON encoded FAQ: `{"question","answer"}`.
  List<String> faq;

  /// Theme accent key: emerald | blue | violet | amber | rose.
  String accentColor;

  /// Public section order keys.
  List<String> sectionOrder;

  String avatarUrl;
  bool published;

  String coverUrl;
  String responseTime;
  String githubUrl;
  String linkedinUrl;
  String websiteUrl;
  String cvUrl;
  int projectsDone;
  int yearsExperience;
  int clientsCount;

  /// Server-managed review aggregates (never pushed back).
  double ratingAvg;
  int ratingCount;

  DateTime updatedAt;
  bool synced;

  FreelancerProfile({
    required this.ownerUid,
    required this.slug,
    this.username = '',
    required this.displayName,
    this.headline = '',
    this.bio = '',
    List<String> skills = const <String>[],
    List<String> languages = const <String>[],
    this.rateAmount = 0,
    this.rateCurrency = 'USD',
    this.rateBasis = 'hourly',
    this.availability = 'full_time',
    List<String> portfolio = const <String>[],
    List<String> services = const <String>[],
    List<String> caseStudies = const <String>[],
    List<String> experience = const <String>[],
    List<String> education = const <String>[],
    List<String> certifications = const <String>[],
    List<String> faq = const <String>[],
    this.accentColor = 'emerald',
    List<String> sectionOrder = const <String>[],
    this.avatarUrl = '',
    this.published = false,
    this.coverUrl = '',
    this.responseTime = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.websiteUrl = '',
    this.cvUrl = '',
    this.projectsDone = 0,
    this.yearsExperience = 0,
    this.clientsCount = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    required this.updatedAt,
    this.synced = false,
  })  : skills = List<String>.from(skills),
        languages = List<String>.from(languages),
        portfolio = List<String>.from(portfolio),
        services = List<String>.from(services),
        caseStudies = List<String>.from(caseStudies),
        experience = List<String>.from(experience),
        education = List<String>.from(education),
        certifications = List<String>.from(certifications),
        faq = List<String>.from(faq),
        sectionOrder = List<String>.from(sectionOrder);

  @ignore
  String get handle => username.isNotEmpty ? username : slug;

  @ignore
  String get publicUrl => '${AppConfig.relayHttpBaseUrl}/u/$handle';

  @ignore
  List<Map<String, String>> get languageEntries => languages.map((raw) {
        final parts = raw.split(':');
        return {
          'code': parts.first,
          'level': parts.length > 1 ? parts[1] : '',
        };
      }).toList();

  @ignore
  List<Map<String, String>> get educationEntries =>
      _decode(education, ['school', 'degree', 'start', 'end']);

  @ignore
  List<Map<String, String>> get certificationEntries =>
      _decode(certifications, ['name', 'issuer', 'year']);

  @ignore
  List<Map<String, String>> get faqEntries =>
      _decode(faq, ['question', 'answer']);

  static List<Map<String, String>> _decode(
    List<String> rawList,
    List<String> keys,
  ) {
    return rawList.map((raw) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return {for (final key in keys) key: (map[key] ?? '').toString()};
      } catch (_) {
        return {for (final key in keys) key: key == keys.first ? raw : ''};
      }
    }).toList();
  }

  static List<String> _mapList(dynamic raw, List<String> keys) {
    if (raw is! List) return const <String>[];
    return raw.map((item) {
      if (item is Map) {
        return jsonEncode(
            {for (final key in keys) key: (item[key] ?? '').toString()});
      }
      return item.toString();
    }).toList();
  }

  /// Fills empty local fields from the cloud copy so a stale cache can never
  /// erase data that already exists remotely.
  void mergeMissingFrom(FreelancerProfile remote) {
    void fillString(String current, String other, void Function(String) set) {
      if (current.trim().isEmpty && other.trim().isNotEmpty) set(other);
    }

    fillString(coverUrl, remote.coverUrl, (v) => coverUrl = v);
    fillString(responseTime, remote.responseTime, (v) => responseTime = v);
    fillString(githubUrl, remote.githubUrl, (v) => githubUrl = v);
    fillString(linkedinUrl, remote.linkedinUrl, (v) => linkedinUrl = v);
    fillString(websiteUrl, remote.websiteUrl, (v) => websiteUrl = v);
    fillString(cvUrl, remote.cvUrl, (v) => cvUrl = v);
    fillString(headline, remote.headline, (v) => headline = v);
    fillString(bio, remote.bio, (v) => bio = v);
    if (projectsDone == 0) projectsDone = remote.projectsDone;
    if (yearsExperience == 0) yearsExperience = remote.yearsExperience;
    if (clientsCount == 0) clientsCount = remote.clientsCount;
    if (skills.isEmpty) skills = List<String>.from(remote.skills);
    if (languages.isEmpty) languages = List<String>.from(remote.languages);
    if (portfolio.isEmpty) portfolio = List<String>.from(remote.portfolio);
    if (services.isEmpty) services = List<String>.from(remote.services);
    if (caseStudies.isEmpty)
      caseStudies = List<String>.from(remote.caseStudies);
    if (experience.isEmpty) experience = List<String>.from(remote.experience);
    if (education.isEmpty) education = List<String>.from(remote.education);
    if (certifications.isEmpty) {
      certifications = List<String>.from(remote.certifications);
    }
    if (faq.isEmpty) faq = List<String>.from(remote.faq);
    if (accentColor == 'emerald' && remote.accentColor != 'emerald') {
      accentColor = remote.accentColor;
    }
    if (sectionOrder.isEmpty)
      sectionOrder = List<String>.from(remote.sectionOrder);
  }

  @ignore
  List<Map<String, String>> get serviceEntries => services.map((raw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return {
            'title': (map['title'] ?? '').toString(),
            'from': (map['from'] ?? '').toString(),
          };
        } catch (_) {
          return {'title': raw, 'from': ''};
        }
      }).toList();

  @ignore
  List<Map<String, String>> get caseEntries => caseStudies.map((raw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return {
            'title': (map['title'] ?? '').toString(),
            'client': (map['client'] ?? '').toString(),
            'problem': (map['problem'] ?? '').toString(),
            'result': (map['result'] ?? '').toString(),
            'imageUrl': (map['imageUrl'] ?? '').toString(),
            'url': (map['url'] ?? '').toString(),
            'tags': (map['tags'] ?? '').toString(),
          };
        } catch (_) {
          return {
            'title': raw,
            'client': '',
            'problem': '',
            'result': '',
            'imageUrl': '',
            'url': '',
            'tags': '',
          };
        }
      }).toList();

  @ignore
  List<Map<String, String>> get experienceEntries => experience.map((raw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return {
            'role': (map['role'] ?? '').toString(),
            'company': (map['company'] ?? '').toString(),
            'start': (map['start'] ?? '').toString(),
            'end': (map['end'] ?? '').toString(),
            'summary': (map['summary'] ?? '').toString(),
          };
        } catch (_) {
          return {
            'role': raw,
            'company': '',
            'start': '',
            'end': '',
            'summary': '',
          };
        }
      }).toList();

  static List<String> _experienceFromMap(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw.map((item) {
      if (item is Map) {
        return jsonEncode({
          'role': (item['role'] ?? '').toString(),
          'company': (item['company'] ?? '').toString(),
          'start': (item['start'] ?? '').toString(),
          'end': (item['end'] ?? '').toString(),
          'summary': (item['summary'] ?? '').toString(),
        });
      }
      return item.toString();
    }).toList();
  }

  static List<String> _caseFromMap(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw.map((item) {
      if (item is Map) {
        return jsonEncode({
          'title': (item['title'] ?? '').toString(),
          'client': (item['client'] ?? '').toString(),
          'problem': (item['problem'] ?? '').toString(),
          'result': (item['result'] ?? '').toString(),
          'imageUrl': (item['imageUrl'] ?? '').toString(),
          'url': (item['url'] ?? '').toString(),
          'tags': (item['tags'] ?? '').toString(),
        });
      }
      return item.toString();
    }).toList();
  }

  @ignore
  List<Map<String, String>> get portfolioEntries => portfolio.map((raw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return {
            'label': (map['label'] ?? '').toString(),
            'url': (map['url'] ?? '').toString(),
            'imageUrl': (map['imageUrl'] ?? '').toString(),
          };
        } catch (_) {
          return {'label': raw, 'url': '', 'imageUrl': ''};
        }
      }).toList();

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'username': handle,
        'displayName': displayName,
        'headline': headline,
        'bio': bio,
        'skills': skills,
        'languages': languageEntries,
        'rate': {
          'amount': rateAmount,
          'currency': rateCurrency,
          'basis': rateBasis,
        },
        'availability': availability,
        'portfolio': portfolioEntries,
        'services': serviceEntries,
        'caseStudies': caseEntries,
        'experience': experienceEntries,
        'education': educationEntries,
        'certifications': certificationEntries,
        'faq': faqEntries,
        'accentColor': accentColor,
        'sectionOrder': sectionOrder,
        'avatarUrl': avatarUrl,
        'coverUrl': coverUrl,
        'responseTime': responseTime,
        'githubUrl': githubUrl,
        'linkedinUrl': linkedinUrl,
        'websiteUrl': websiteUrl,
        'cvUrl': cvUrl,
        'projectsDone': projectsDone,
        'yearsExperience': yearsExperience,
        'clientsCount': clientsCount,
        'published': published,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static FreelancerProfile fromMap(String ownerUid, Map<String, dynamic> map) {
    final rate = map['rate'];
    final rawSkills = map['skills'];
    final rawLanguages = map['languages'];
    final rawPortfolio = map['portfolio'];
    final rawServices = map['services'];

    return FreelancerProfile(
      ownerUid: ownerUid,
      slug: (map['slug'] as String?) ?? '',
      username:
          (map['username'] as String?) ?? ((map['slug'] as String?) ?? ''),
      displayName: (map['displayName'] as String?) ?? '',
      headline: (map['headline'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      skills: rawSkills is List
          ? rawSkills.map((e) => e.toString()).toList()
          : const <String>[],
      languages: rawLanguages is List
          ? rawLanguages.map((item) {
              if (item is Map) {
                final code = (item['code'] ?? '').toString();
                final level = (item['level'] ?? '').toString();
                return level.isEmpty ? code : '$code:$level';
              }
              return item.toString();
            }).toList()
          : const <String>[],
      rateAmount: rate is Map ? (rate['amount'] as num?)?.toDouble() ?? 0 : 0,
      rateCurrency:
          rate is Map ? (rate['currency'] as String?) ?? 'USD' : 'USD',
      rateBasis:
          rate is Map ? (rate['basis'] as String?) ?? 'hourly' : 'hourly',
      availability: (map['availability'] as String?) ?? 'full_time',
      portfolio: rawPortfolio is List
          ? rawPortfolio.map((item) {
              if (item is Map) {
                return jsonEncode({
                  'label': (item['label'] ?? '').toString(),
                  'url': (item['url'] ?? '').toString(),
                  'imageUrl': (item['imageUrl'] ?? '').toString(),
                });
              }
              return item.toString();
            }).toList()
          : const <String>[],
      caseStudies: _caseFromMap(map['caseStudies']),
      experience: _experienceFromMap(map['experience']),
      education:
          _mapList(map['education'], ['school', 'degree', 'start', 'end']),
      certifications:
          _mapList(map['certifications'], ['name', 'issuer', 'year']),
      faq: _mapList(map['faq'], ['question', 'answer']),
      accentColor: (map['accentColor'] as String?) ?? 'emerald',
      sectionOrder: map['sectionOrder'] is List
          ? (map['sectionOrder'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      services: rawServices is List
          ? rawServices.map((item) {
              if (item is Map) {
                return jsonEncode({
                  'title': (item['title'] ?? '').toString(),
                  'from': (item['from'] ?? '').toString(),
                });
              }
              return item.toString();
            }).toList()
          : const <String>[],
      avatarUrl: (map['avatarUrl'] as String?) ?? '',
      coverUrl: (map['coverUrl'] as String?) ?? '',
      responseTime: (map['responseTime'] as String?) ?? '',
      githubUrl: (map['githubUrl'] as String?) ?? '',
      linkedinUrl: (map['linkedinUrl'] as String?) ?? '',
      websiteUrl: (map['websiteUrl'] as String?) ?? '',
      cvUrl: (map['cvUrl'] as String?) ?? '',
      projectsDone: (map['projectsDone'] as num?)?.toInt() ?? 0,
      yearsExperience: (map['yearsExperience'] as num?)?.toInt() ?? 0,
      clientsCount: (map['clientsCount'] as num?)?.toInt() ?? 0,
      published: map['published'] == true,
      ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      synced: true,
    );
  }
}
