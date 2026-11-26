// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freelancer_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFreelancerProfileCollection on Isar {
  IsarCollection<FreelancerProfile> get freelancerProfiles => this.collection();
}

const FreelancerProfileSchema = CollectionSchema(
  name: r'FreelancerProfile',
  id: 8390889716158811100,
  properties: {
    r'accentColor': PropertySchema(
      id: 0,
      name: r'accentColor',
      type: IsarType.string,
    ),
    r'availability': PropertySchema(
      id: 1,
      name: r'availability',
      type: IsarType.string,
    ),
    r'avatarUrl': PropertySchema(
      id: 2,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'bio': PropertySchema(
      id: 3,
      name: r'bio',
      type: IsarType.string,
    ),
    r'caseStudies': PropertySchema(
      id: 4,
      name: r'caseStudies',
      type: IsarType.stringList,
    ),
    r'certifications': PropertySchema(
      id: 5,
      name: r'certifications',
      type: IsarType.stringList,
    ),
    r'clientsCount': PropertySchema(
      id: 6,
      name: r'clientsCount',
      type: IsarType.long,
    ),
    r'coverUrl': PropertySchema(
      id: 7,
      name: r'coverUrl',
      type: IsarType.string,
    ),
    r'cvUrl': PropertySchema(
      id: 8,
      name: r'cvUrl',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 9,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'education': PropertySchema(
      id: 10,
      name: r'education',
      type: IsarType.stringList,
    ),
    r'experience': PropertySchema(
      id: 11,
      name: r'experience',
      type: IsarType.stringList,
    ),
    r'faq': PropertySchema(
      id: 12,
      name: r'faq',
      type: IsarType.stringList,
    ),
    r'githubUrl': PropertySchema(
      id: 13,
      name: r'githubUrl',
      type: IsarType.string,
    ),
    r'headline': PropertySchema(
      id: 14,
      name: r'headline',
      type: IsarType.string,
    ),
    r'languages': PropertySchema(
      id: 15,
      name: r'languages',
      type: IsarType.stringList,
    ),
    r'linkedinUrl': PropertySchema(
      id: 16,
      name: r'linkedinUrl',
      type: IsarType.string,
    ),
    r'ownerUid': PropertySchema(
      id: 17,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'portfolio': PropertySchema(
      id: 18,
      name: r'portfolio',
      type: IsarType.stringList,
    ),
    r'projectsDone': PropertySchema(
      id: 19,
      name: r'projectsDone',
      type: IsarType.long,
    ),
    r'published': PropertySchema(
      id: 20,
      name: r'published',
      type: IsarType.bool,
    ),
    r'rateAmount': PropertySchema(
      id: 21,
      name: r'rateAmount',
      type: IsarType.double,
    ),
    r'rateBasis': PropertySchema(
      id: 22,
      name: r'rateBasis',
      type: IsarType.string,
    ),
    r'rateCurrency': PropertySchema(
      id: 23,
      name: r'rateCurrency',
      type: IsarType.string,
    ),
    r'ratingAvg': PropertySchema(
      id: 24,
      name: r'ratingAvg',
      type: IsarType.double,
    ),
    r'ratingCount': PropertySchema(
      id: 25,
      name: r'ratingCount',
      type: IsarType.long,
    ),
    r'responseTime': PropertySchema(
      id: 26,
      name: r'responseTime',
      type: IsarType.string,
    ),
    r'sectionOrder': PropertySchema(
      id: 27,
      name: r'sectionOrder',
      type: IsarType.stringList,
    ),
    r'services': PropertySchema(
      id: 28,
      name: r'services',
      type: IsarType.stringList,
    ),
    r'skills': PropertySchema(
      id: 29,
      name: r'skills',
      type: IsarType.stringList,
    ),
    r'slug': PropertySchema(
      id: 30,
      name: r'slug',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 31,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 32,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'username': PropertySchema(
      id: 33,
      name: r'username',
      type: IsarType.string,
    ),
    r'websiteUrl': PropertySchema(
      id: 34,
      name: r'websiteUrl',
      type: IsarType.string,
    ),
    r'yearsExperience': PropertySchema(
      id: 35,
      name: r'yearsExperience',
      type: IsarType.long,
    )
  },
  estimateSize: _freelancerProfileEstimateSize,
  serialize: _freelancerProfileSerialize,
  deserialize: _freelancerProfileDeserialize,
  deserializeProp: _freelancerProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerUid': IndexSchema(
      id: -8016718989707307851,
      name: r'ownerUid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _freelancerProfileGetId,
  getLinks: _freelancerProfileGetLinks,
  attach: _freelancerProfileAttach,
  version: '3.1.0+1',
);

int _freelancerProfileEstimateSize(
  FreelancerProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accentColor.length * 3;
  bytesCount += 3 + object.availability.length * 3;
  bytesCount += 3 + object.avatarUrl.length * 3;
  bytesCount += 3 + object.bio.length * 3;
  bytesCount += 3 + object.caseStudies.length * 3;
  {
    for (var i = 0; i < object.caseStudies.length; i++) {
      final value = object.caseStudies[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.certifications.length * 3;
  {
    for (var i = 0; i < object.certifications.length; i++) {
      final value = object.certifications[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.coverUrl.length * 3;
  bytesCount += 3 + object.cvUrl.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.education.length * 3;
  {
    for (var i = 0; i < object.education.length; i++) {
      final value = object.education[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.experience.length * 3;
  {
    for (var i = 0; i < object.experience.length; i++) {
      final value = object.experience[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.faq.length * 3;
  {
    for (var i = 0; i < object.faq.length; i++) {
      final value = object.faq[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.githubUrl.length * 3;
  bytesCount += 3 + object.headline.length * 3;
  bytesCount += 3 + object.languages.length * 3;
  {
    for (var i = 0; i < object.languages.length; i++) {
      final value = object.languages[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.linkedinUrl.length * 3;
  bytesCount += 3 + object.ownerUid.length * 3;
  bytesCount += 3 + object.portfolio.length * 3;
  {
    for (var i = 0; i < object.portfolio.length; i++) {
      final value = object.portfolio[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.rateBasis.length * 3;
  bytesCount += 3 + object.rateCurrency.length * 3;
  bytesCount += 3 + object.responseTime.length * 3;
  bytesCount += 3 + object.sectionOrder.length * 3;
  {
    for (var i = 0; i < object.sectionOrder.length; i++) {
      final value = object.sectionOrder[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.services.length * 3;
  {
    for (var i = 0; i < object.services.length; i++) {
      final value = object.services[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.skills.length * 3;
  {
    for (var i = 0; i < object.skills.length; i++) {
      final value = object.skills[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.slug.length * 3;
  bytesCount += 3 + object.username.length * 3;
  bytesCount += 3 + object.websiteUrl.length * 3;
  return bytesCount;
}

void _freelancerProfileSerialize(
  FreelancerProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accentColor);
  writer.writeString(offsets[1], object.availability);
  writer.writeString(offsets[2], object.avatarUrl);
  writer.writeString(offsets[3], object.bio);
  writer.writeStringList(offsets[4], object.caseStudies);
  writer.writeStringList(offsets[5], object.certifications);
  writer.writeLong(offsets[6], object.clientsCount);
  writer.writeString(offsets[7], object.coverUrl);
  writer.writeString(offsets[8], object.cvUrl);
  writer.writeString(offsets[9], object.displayName);
  writer.writeStringList(offsets[10], object.education);
  writer.writeStringList(offsets[11], object.experience);
  writer.writeStringList(offsets[12], object.faq);
  writer.writeString(offsets[13], object.githubUrl);
  writer.writeString(offsets[14], object.headline);
  writer.writeStringList(offsets[15], object.languages);
  writer.writeString(offsets[16], object.linkedinUrl);
  writer.writeString(offsets[17], object.ownerUid);
  writer.writeStringList(offsets[18], object.portfolio);
  writer.writeLong(offsets[19], object.projectsDone);
  writer.writeBool(offsets[20], object.published);
  writer.writeDouble(offsets[21], object.rateAmount);
  writer.writeString(offsets[22], object.rateBasis);
  writer.writeString(offsets[23], object.rateCurrency);
  writer.writeDouble(offsets[24], object.ratingAvg);
  writer.writeLong(offsets[25], object.ratingCount);
  writer.writeString(offsets[26], object.responseTime);
  writer.writeStringList(offsets[27], object.sectionOrder);
  writer.writeStringList(offsets[28], object.services);
  writer.writeStringList(offsets[29], object.skills);
  writer.writeString(offsets[30], object.slug);
  writer.writeBool(offsets[31], object.synced);
  writer.writeDateTime(offsets[32], object.updatedAt);
  writer.writeString(offsets[33], object.username);
  writer.writeString(offsets[34], object.websiteUrl);
  writer.writeLong(offsets[35], object.yearsExperience);
}

FreelancerProfile _freelancerProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FreelancerProfile(
    accentColor: reader.readStringOrNull(offsets[0]) ?? 'emerald',
    availability: reader.readStringOrNull(offsets[1]) ?? 'full_time',
    avatarUrl: reader.readStringOrNull(offsets[2]) ?? '',
    bio: reader.readStringOrNull(offsets[3]) ?? '',
    caseStudies: reader.readStringList(offsets[4]) ?? const <String>[],
    certifications: reader.readStringList(offsets[5]) ?? const <String>[],
    clientsCount: reader.readLongOrNull(offsets[6]) ?? 0,
    coverUrl: reader.readStringOrNull(offsets[7]) ?? '',
    cvUrl: reader.readStringOrNull(offsets[8]) ?? '',
    displayName: reader.readString(offsets[9]),
    education: reader.readStringList(offsets[10]) ?? const <String>[],
    experience: reader.readStringList(offsets[11]) ?? const <String>[],
    faq: reader.readStringList(offsets[12]) ?? const <String>[],
    githubUrl: reader.readStringOrNull(offsets[13]) ?? '',
    headline: reader.readStringOrNull(offsets[14]) ?? '',
    languages: reader.readStringList(offsets[15]) ?? const <String>[],
    linkedinUrl: reader.readStringOrNull(offsets[16]) ?? '',
    ownerUid: reader.readString(offsets[17]),
    portfolio: reader.readStringList(offsets[18]) ?? const <String>[],
    projectsDone: reader.readLongOrNull(offsets[19]) ?? 0,
    published: reader.readBoolOrNull(offsets[20]) ?? false,
    rateAmount: reader.readDoubleOrNull(offsets[21]) ?? 0,
    rateBasis: reader.readStringOrNull(offsets[22]) ?? 'hourly',
    rateCurrency: reader.readStringOrNull(offsets[23]) ?? 'USD',
    ratingAvg: reader.readDoubleOrNull(offsets[24]) ?? 0,
    ratingCount: reader.readLongOrNull(offsets[25]) ?? 0,
    responseTime: reader.readStringOrNull(offsets[26]) ?? '',
    sectionOrder: reader.readStringList(offsets[27]) ?? const <String>[],
    services: reader.readStringList(offsets[28]) ?? const <String>[],
    skills: reader.readStringList(offsets[29]) ?? const <String>[],
    slug: reader.readString(offsets[30]),
    synced: reader.readBoolOrNull(offsets[31]) ?? false,
    updatedAt: reader.readDateTime(offsets[32]),
    username: reader.readStringOrNull(offsets[33]) ?? '',
    websiteUrl: reader.readStringOrNull(offsets[34]) ?? '',
    yearsExperience: reader.readLongOrNull(offsets[35]) ?? 0,
  );
  object.id = id;
  return object;
}

P _freelancerProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? 'emerald') as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? 'full_time') as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 5:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 11:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 12:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 13:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 14:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 15:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 16:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 19:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 20:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 21:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 22:
      return (reader.readStringOrNull(offset) ?? 'hourly') as P;
    case 23:
      return (reader.readStringOrNull(offset) ?? 'USD') as P;
    case 24:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 25:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 26:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 27:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 28:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 29:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 30:
      return (reader.readString(offset)) as P;
    case 31:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 32:
      return (reader.readDateTime(offset)) as P;
    case 33:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 34:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 35:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _freelancerProfileGetId(FreelancerProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _freelancerProfileGetLinks(
    FreelancerProfile object) {
  return [];
}

void _freelancerProfileAttach(
    IsarCollection<dynamic> col, Id id, FreelancerProfile object) {
  object.id = id;
}

extension FreelancerProfileByIndex on IsarCollection<FreelancerProfile> {
  Future<FreelancerProfile?> getByOwnerUid(String ownerUid) {
    return getByIndex(r'ownerUid', [ownerUid]);
  }

  FreelancerProfile? getByOwnerUidSync(String ownerUid) {
    return getByIndexSync(r'ownerUid', [ownerUid]);
  }

  Future<bool> deleteByOwnerUid(String ownerUid) {
    return deleteByIndex(r'ownerUid', [ownerUid]);
  }

  bool deleteByOwnerUidSync(String ownerUid) {
    return deleteByIndexSync(r'ownerUid', [ownerUid]);
  }

  Future<List<FreelancerProfile?>> getAllByOwnerUid(
      List<String> ownerUidValues) {
    final values = ownerUidValues.map((e) => [e]).toList();
    return getAllByIndex(r'ownerUid', values);
  }

  List<FreelancerProfile?> getAllByOwnerUidSync(List<String> ownerUidValues) {
    final values = ownerUidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ownerUid', values);
  }

  Future<int> deleteAllByOwnerUid(List<String> ownerUidValues) {
    final values = ownerUidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ownerUid', values);
  }

  int deleteAllByOwnerUidSync(List<String> ownerUidValues) {
    final values = ownerUidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ownerUid', values);
  }

  Future<Id> putByOwnerUid(FreelancerProfile object) {
    return putByIndex(r'ownerUid', object);
  }

  Id putByOwnerUidSync(FreelancerProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'ownerUid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerUid(List<FreelancerProfile> objects) {
    return putAllByIndex(r'ownerUid', objects);
  }

  List<Id> putAllByOwnerUidSync(List<FreelancerProfile> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerUid', objects, saveLinks: saveLinks);
  }
}

extension FreelancerProfileQueryWhereSort
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QWhere> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FreelancerProfileQueryWhere
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QWhereClause> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      ownerUidEqualTo(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid',
        value: [ownerUid],
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterWhereClause>
      ownerUidNotEqualTo(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FreelancerProfileQueryFilter
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QFilterCondition> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accentColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accentColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accentColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accentColor',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      accentColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accentColor',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'availability',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'availability',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'availability',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availability',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      availabilityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'availability',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bio',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bio',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      bioIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bio',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caseStudies',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'caseStudies',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'caseStudies',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caseStudies',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'caseStudies',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      caseStudiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'caseStudies',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'certifications',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'certifications',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'certifications',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'certifications',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'certifications',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      certificationsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'certifications',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      clientsCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      clientsCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      clientsCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      clientsCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coverUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coverUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coverUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      coverUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coverUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cvUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cvUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cvUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cvUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      cvUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cvUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'education',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'education',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'education',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'education',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'education',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      educationLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'education',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'experience',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'experience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'experience',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experience',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'experience',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      experienceLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'experience',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'faq',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'faq',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'faq',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'faq',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'faq',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      faqLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'faq',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'githubUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'githubUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'githubUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'githubUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      githubUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'githubUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headline',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headline',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headline',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headline',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      headlineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headline',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'languages',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'languages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'languages',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'languages',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'languages',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      languagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'languages',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkedinUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'linkedinUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'linkedinUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedinUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      linkedinUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'linkedinUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'portfolio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'portfolio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'portfolio',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'portfolio',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'portfolio',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      portfolioLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'portfolio',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      projectsDoneEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectsDone',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      projectsDoneGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectsDone',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      projectsDoneLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectsDone',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      projectsDoneBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectsDone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      publishedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'published',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateBasis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateBasis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateBasisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      rateCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingAvgEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ratingAvg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingAvgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ratingAvg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingAvgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ratingAvg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingAvgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ratingAvg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ratingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ratingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ratingCount',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      ratingCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ratingCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'responseTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'responseTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'responseTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'responseTime',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      responseTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'responseTime',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sectionOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sectionOrder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sectionOrder',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sectionOrder',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sectionOrder',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      sectionOrderLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sectionOrder',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'services',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'services',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'services',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'services',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'services',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      servicesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'services',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skills',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skills',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skills',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skills',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skills',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      skillsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'skills',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      slugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'websiteUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'websiteUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'websiteUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'websiteUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      websiteUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'websiteUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      yearsExperienceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'yearsExperience',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      yearsExperienceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'yearsExperience',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      yearsExperienceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'yearsExperience',
        value: value,
      ));
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterFilterCondition>
      yearsExperienceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'yearsExperience',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FreelancerProfileQueryObject
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QFilterCondition> {}

extension FreelancerProfileQueryLinks
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QFilterCondition> {}

extension FreelancerProfileQuerySortBy
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QSortBy> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAccentColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAccentColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy> sortByBio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByBioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByClientsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientsCount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByClientsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientsCount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByCoverUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByCoverUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByCvUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByCvUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByGithubUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'githubUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByGithubUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'githubUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByHeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headline', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByHeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headline', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByLinkedinUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedinUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByLinkedinUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedinUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByProjectsDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectsDone', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByProjectsDoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectsDone', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByPublishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRateCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRatingAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingAvg', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRatingAvgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingAvg', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRatingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingCount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByRatingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingCount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByResponseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseTime', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByResponseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseTime', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByWebsiteUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'websiteUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByWebsiteUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'websiteUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      sortByYearsExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.desc);
    });
  }
}

extension FreelancerProfileQuerySortThenBy
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QSortThenBy> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAccentColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAccentColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColor', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAvailability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAvailabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availability', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy> thenByBio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByBioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bio', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByClientsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientsCount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByClientsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientsCount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByCoverUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByCoverUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByCvUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByCvUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByGithubUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'githubUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByGithubUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'githubUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByHeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headline', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByHeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headline', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByLinkedinUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedinUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByLinkedinUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedinUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByProjectsDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectsDone', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByProjectsDoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectsDone', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByPublishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRateCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRatingAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingAvg', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRatingAvgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingAvg', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRatingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingCount', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByRatingCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingCount', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByResponseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseTime', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByResponseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseTime', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByWebsiteUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'websiteUrl', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByWebsiteUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'websiteUrl', Sort.desc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.asc);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QAfterSortBy>
      thenByYearsExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.desc);
    });
  }
}

extension FreelancerProfileQueryWhereDistinct
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct> {
  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByAccentColor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accentColor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByAvailability({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availability', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByAvatarUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct> distinctByBio(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bio', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByCaseStudies() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caseStudies');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByCertifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'certifications');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByClientsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientsCount');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByCoverUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct> distinctByCvUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cvUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByEducation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'education');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'experience');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByFaq() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'faq');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByGithubUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'githubUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByHeadline({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headline', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByLanguages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'languages');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByLinkedinUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedinUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByOwnerUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByPortfolio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portfolio');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByProjectsDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectsDone');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'published');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateAmount');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByRateBasis({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateBasis', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByRateCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByRatingAvg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ratingAvg');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByRatingCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ratingCount');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByResponseTime({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'responseTime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctBySectionOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sectionOrder');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByServices() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'services');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctBySkills() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skills');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct> distinctBySlug(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByUsername({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByWebsiteUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'websiteUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct>
      distinctByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'yearsExperience');
    });
  }
}

extension FreelancerProfileQueryProperty
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QQueryProperty> {
  QueryBuilder<FreelancerProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      accentColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accentColor');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      availabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availability');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarUrl');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> bioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bio');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      caseStudiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caseStudies');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      certificationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'certifications');
    });
  }

  QueryBuilder<FreelancerProfile, int, QQueryOperations>
      clientsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientsCount');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> coverUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverUrl');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> cvUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cvUrl');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      educationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'education');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      experienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'experience');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      faqProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'faq');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      githubUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'githubUrl');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> headlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headline');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      languagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'languages');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      linkedinUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedinUrl');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      portfolioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portfolio');
    });
  }

  QueryBuilder<FreelancerProfile, int, QQueryOperations>
      projectsDoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectsDone');
    });
  }

  QueryBuilder<FreelancerProfile, bool, QQueryOperations> publishedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'published');
    });
  }

  QueryBuilder<FreelancerProfile, double, QQueryOperations>
      rateAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateAmount');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      rateBasisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateBasis');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      rateCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateCurrency');
    });
  }

  QueryBuilder<FreelancerProfile, double, QQueryOperations>
      ratingAvgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ratingAvg');
    });
  }

  QueryBuilder<FreelancerProfile, int, QQueryOperations> ratingCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ratingCount');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      responseTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'responseTime');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      sectionOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sectionOrder');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      servicesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'services');
    });
  }

  QueryBuilder<FreelancerProfile, List<String>, QQueryOperations>
      skillsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skills');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> slugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slug');
    });
  }

  QueryBuilder<FreelancerProfile, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<FreelancerProfile, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      websiteUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'websiteUrl');
    });
  }

  QueryBuilder<FreelancerProfile, int, QQueryOperations>
      yearsExperienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'yearsExperience');
    });
  }
}
