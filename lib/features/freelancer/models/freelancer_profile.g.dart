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
    r'availability': PropertySchema(
      id: 0,
      name: r'availability',
      type: IsarType.string,
    ),
    r'avatarUrl': PropertySchema(
      id: 1,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'bio': PropertySchema(
      id: 2,
      name: r'bio',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 3,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'headline': PropertySchema(
      id: 4,
      name: r'headline',
      type: IsarType.string,
    ),
    r'languages': PropertySchema(
      id: 5,
      name: r'languages',
      type: IsarType.stringList,
    ),
    r'ownerUid': PropertySchema(
      id: 6,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'portfolio': PropertySchema(
      id: 7,
      name: r'portfolio',
      type: IsarType.stringList,
    ),
    r'published': PropertySchema(
      id: 8,
      name: r'published',
      type: IsarType.bool,
    ),
    r'rateAmount': PropertySchema(
      id: 9,
      name: r'rateAmount',
      type: IsarType.double,
    ),
    r'rateBasis': PropertySchema(
      id: 10,
      name: r'rateBasis',
      type: IsarType.string,
    ),
    r'rateCurrency': PropertySchema(
      id: 11,
      name: r'rateCurrency',
      type: IsarType.string,
    ),
    r'ratingAvg': PropertySchema(
      id: 12,
      name: r'ratingAvg',
      type: IsarType.double,
    ),
    r'ratingCount': PropertySchema(
      id: 13,
      name: r'ratingCount',
      type: IsarType.long,
    ),
    r'skills': PropertySchema(
      id: 14,
      name: r'skills',
      type: IsarType.stringList,
    ),
    r'slug': PropertySchema(
      id: 15,
      name: r'slug',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 16,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 17,
      name: r'updatedAt',
      type: IsarType.dateTime,
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
  bytesCount += 3 + object.availability.length * 3;
  bytesCount += 3 + object.avatarUrl.length * 3;
  bytesCount += 3 + object.bio.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.headline.length * 3;
  bytesCount += 3 + object.languages.length * 3;
  {
    for (var i = 0; i < object.languages.length; i++) {
      final value = object.languages[i];
      bytesCount += value.length * 3;
    }
  }
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
  bytesCount += 3 + object.skills.length * 3;
  {
    for (var i = 0; i < object.skills.length; i++) {
      final value = object.skills[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.slug.length * 3;
  return bytesCount;
}

void _freelancerProfileSerialize(
  FreelancerProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.availability);
  writer.writeString(offsets[1], object.avatarUrl);
  writer.writeString(offsets[2], object.bio);
  writer.writeString(offsets[3], object.displayName);
  writer.writeString(offsets[4], object.headline);
  writer.writeStringList(offsets[5], object.languages);
  writer.writeString(offsets[6], object.ownerUid);
  writer.writeStringList(offsets[7], object.portfolio);
  writer.writeBool(offsets[8], object.published);
  writer.writeDouble(offsets[9], object.rateAmount);
  writer.writeString(offsets[10], object.rateBasis);
  writer.writeString(offsets[11], object.rateCurrency);
  writer.writeDouble(offsets[12], object.ratingAvg);
  writer.writeLong(offsets[13], object.ratingCount);
  writer.writeStringList(offsets[14], object.skills);
  writer.writeString(offsets[15], object.slug);
  writer.writeBool(offsets[16], object.synced);
  writer.writeDateTime(offsets[17], object.updatedAt);
}

FreelancerProfile _freelancerProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FreelancerProfile(
    availability: reader.readStringOrNull(offsets[0]) ?? 'full_time',
    avatarUrl: reader.readStringOrNull(offsets[1]) ?? '',
    bio: reader.readStringOrNull(offsets[2]) ?? '',
    displayName: reader.readString(offsets[3]),
    headline: reader.readStringOrNull(offsets[4]) ?? '',
    languages: reader.readStringList(offsets[5]) ?? const <String>[],
    ownerUid: reader.readString(offsets[6]),
    portfolio: reader.readStringList(offsets[7]) ?? const <String>[],
    published: reader.readBoolOrNull(offsets[8]) ?? false,
    rateAmount: reader.readDoubleOrNull(offsets[9]) ?? 0,
    rateBasis: reader.readStringOrNull(offsets[10]) ?? 'hourly',
    rateCurrency: reader.readStringOrNull(offsets[11]) ?? 'USD',
    ratingAvg: reader.readDoubleOrNull(offsets[12]) ?? 0,
    ratingCount: reader.readLongOrNull(offsets[13]) ?? 0,
    skills: reader.readStringList(offsets[14]) ?? const <String>[],
    slug: reader.readString(offsets[15]),
    synced: reader.readBoolOrNull(offsets[16]) ?? false,
    updatedAt: reader.readDateTime(offsets[17]),
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
      return (reader.readStringOrNull(offset) ?? 'full_time') as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 5:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? 'hourly') as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? 'USD') as P;
    case 12:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 13:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 14:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
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
}

extension FreelancerProfileQueryObject
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QFilterCondition> {}

extension FreelancerProfileQueryLinks
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QFilterCondition> {}

extension FreelancerProfileQuerySortBy
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QSortBy> {
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
}

extension FreelancerProfileQuerySortThenBy
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QSortThenBy> {
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
}

extension FreelancerProfileQueryWhereDistinct
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QDistinct> {
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
      distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
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
}

extension FreelancerProfileQueryProperty
    on QueryBuilder<FreelancerProfile, FreelancerProfile, QQueryProperty> {
  QueryBuilder<FreelancerProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
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

  QueryBuilder<FreelancerProfile, String, QQueryOperations>
      displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
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
}
