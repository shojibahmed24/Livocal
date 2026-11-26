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

  /// JSON encoded `{"label": "...", "url": "..."}` strings.
  List<String> portfolio;

  String avatarUrl;
  bool published;

  /// Server-managed review aggregates (never pushed back).
  double ratingAvg;
  int ratingCount;

  DateTime updatedAt;
  bool synced;

  FreelancerProfile({
    required this.ownerUid,
    required this.slug,
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
    this.avatarUrl = '',
    this.published = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    required this.updatedAt,
    this.synced = false,
  })  : skills = List<String>.from(skills),
        languages = List<String>.from(languages),
        portfolio = List<String>.from(portfolio);

  @ignore
  String get publicUrl => '${AppConfig.relayHttpBaseUrl}/p/$slug';

  @ignore
  List<Map<String, String>> get languageEntries => languages.map((raw) {
        final parts = raw.split(':');
        return {
          'code': parts.first,
          'level': parts.length > 1 ? parts[1] : '',
        };
      }).toList();

  @ignore
  List<Map<String, String>> get portfolioEntries => portfolio.map((raw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return {
            'label': (map['label'] ?? '').toString(),
            'url': (map['url'] ?? '').toString(),
          };
        } catch (_) {
          return {'label': raw, 'url': ''};
        }
      }).toList();

  Map<String, dynamic> toMap() => {
        'slug': slug,
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
        'avatarUrl': avatarUrl,
        'published': published,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static FreelancerProfile fromMap(String ownerUid, Map<String, dynamic> map) {
    final rate = map['rate'];
    final rawSkills = map['skills'];
    final rawLanguages = map['languages'];
    final rawPortfolio = map['portfolio'];

    return FreelancerProfile(
      ownerUid: ownerUid,
      slug: (map['slug'] as String?) ?? '',
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
                });
              }
              return item.toString();
            }).toList()
          : const <String>[],
      avatarUrl: (map['avatarUrl'] as String?) ?? '',
      published: map['published'] == true,
      ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      synced: true,
    );
  }
}
