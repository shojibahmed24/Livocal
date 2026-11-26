// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crm_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCrmEntryCollection on Isar {
  IsarCollection<CrmEntry> get crmEntrys => this.collection();
}

const CrmEntrySchema = CollectionSchema(
  name: r'CrmEntry',
  id: -3485472243301205762,
  properties: {
    r'followUpAt': PropertySchema(
      id: 0,
      name: r'followUpAt',
      type: IsarType.dateTime,
    ),
    r'isArchived': PropertySchema(
      id: 1,
      name: r'isArchived',
      type: IsarType.bool,
    ),
    r'isClient': PropertySchema(
      id: 2,
      name: r'isClient',
      type: IsarType.bool,
    ),
    r'isProspect': PropertySchema(
      id: 3,
      name: r'isProspect',
      type: IsarType.bool,
    ),
    r'lastContactedAt': PropertySchema(
      id: 4,
      name: r'lastContactedAt',
      type: IsarType.dateTime,
    ),
    r'notes': PropertySchema(
      id: 5,
      name: r'notes',
      type: IsarType.stringList,
    ),
    r'ownerUid': PropertySchema(
      id: 6,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'peerUid': PropertySchema(
      id: 7,
      name: r'peerUid',
      type: IsarType.string,
    ),
    r'rateAmount': PropertySchema(
      id: 8,
      name: r'rateAmount',
      type: IsarType.double,
    ),
    r'rateBasis': PropertySchema(
      id: 9,
      name: r'rateBasis',
      type: IsarType.string,
    ),
    r'rateCurrency': PropertySchema(
      id: 10,
      name: r'rateCurrency',
      type: IsarType.string,
    ),
    r'stage': PropertySchema(
      id: 11,
      name: r'stage',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 12,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'tag': PropertySchema(
      id: 13,
      name: r'tag',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _crmEntryEstimateSize,
  serialize: _crmEntrySerialize,
  deserialize: _crmEntryDeserialize,
  deserializeProp: _crmEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerUid_peerUid': IndexSchema(
      id: 3642542771407332124,
      name: r'ownerUid_peerUid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'peerUid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _crmEntryGetId,
  getLinks: _crmEntryGetLinks,
  attach: _crmEntryAttach,
  version: '3.1.0+1',
);

int _crmEntryEstimateSize(
  CrmEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.notes.length * 3;
  {
    for (var i = 0; i < object.notes.length; i++) {
      final value = object.notes[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerUid.length * 3;
  bytesCount += 3 + object.peerUid.length * 3;
  bytesCount += 3 + object.rateBasis.length * 3;
  bytesCount += 3 + object.rateCurrency.length * 3;
  bytesCount += 3 + object.stage.length * 3;
  bytesCount += 3 + object.tag.length * 3;
  return bytesCount;
}

void _crmEntrySerialize(
  CrmEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.followUpAt);
  writer.writeBool(offsets[1], object.isArchived);
  writer.writeBool(offsets[2], object.isClient);
  writer.writeBool(offsets[3], object.isProspect);
  writer.writeDateTime(offsets[4], object.lastContactedAt);
  writer.writeStringList(offsets[5], object.notes);
  writer.writeString(offsets[6], object.ownerUid);
  writer.writeString(offsets[7], object.peerUid);
  writer.writeDouble(offsets[8], object.rateAmount);
  writer.writeString(offsets[9], object.rateBasis);
  writer.writeString(offsets[10], object.rateCurrency);
  writer.writeString(offsets[11], object.stage);
  writer.writeBool(offsets[12], object.synced);
  writer.writeString(offsets[13], object.tag);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

CrmEntry _crmEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CrmEntry(
    followUpAt: reader.readDateTimeOrNull(offsets[0]),
    lastContactedAt: reader.readDateTimeOrNull(offsets[4]),
    notes: reader.readStringList(offsets[5]) ?? const <String>[],
    ownerUid: reader.readString(offsets[6]),
    peerUid: reader.readString(offsets[7]),
    rateAmount: reader.readDoubleOrNull(offsets[8]) ?? 0,
    rateBasis: reader.readStringOrNull(offsets[9]) ?? 'hourly',
    rateCurrency: reader.readStringOrNull(offsets[10]) ?? 'USD',
    stage: reader.readStringOrNull(offsets[11]) ?? 'new',
    synced: reader.readBoolOrNull(offsets[12]) ?? false,
    tag: reader.readStringOrNull(offsets[13]) ?? 'prospect',
    updatedAt: reader.readDateTime(offsets[14]),
  );
  object.id = id;
  return object;
}

P _crmEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? const <String>[]) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 9:
      return (reader.readStringOrNull(offset) ?? 'hourly') as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? 'USD') as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? 'new') as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readStringOrNull(offset) ?? 'prospect') as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _crmEntryGetId(CrmEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _crmEntryGetLinks(CrmEntry object) {
  return [];
}

void _crmEntryAttach(IsarCollection<dynamic> col, Id id, CrmEntry object) {
  object.id = id;
}

extension CrmEntryByIndex on IsarCollection<CrmEntry> {
  Future<CrmEntry?> getByOwnerUidPeerUid(String ownerUid, String peerUid) {
    return getByIndex(r'ownerUid_peerUid', [ownerUid, peerUid]);
  }

  CrmEntry? getByOwnerUidPeerUidSync(String ownerUid, String peerUid) {
    return getByIndexSync(r'ownerUid_peerUid', [ownerUid, peerUid]);
  }

  Future<bool> deleteByOwnerUidPeerUid(String ownerUid, String peerUid) {
    return deleteByIndex(r'ownerUid_peerUid', [ownerUid, peerUid]);
  }

  bool deleteByOwnerUidPeerUidSync(String ownerUid, String peerUid) {
    return deleteByIndexSync(r'ownerUid_peerUid', [ownerUid, peerUid]);
  }

  Future<List<CrmEntry?>> getAllByOwnerUidPeerUid(
      List<String> ownerUidValues, List<String> peerUidValues) {
    final len = ownerUidValues.length;
    assert(peerUidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], peerUidValues[i]]);
    }

    return getAllByIndex(r'ownerUid_peerUid', values);
  }

  List<CrmEntry?> getAllByOwnerUidPeerUidSync(
      List<String> ownerUidValues, List<String> peerUidValues) {
    final len = ownerUidValues.length;
    assert(peerUidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], peerUidValues[i]]);
    }

    return getAllByIndexSync(r'ownerUid_peerUid', values);
  }

  Future<int> deleteAllByOwnerUidPeerUid(
      List<String> ownerUidValues, List<String> peerUidValues) {
    final len = ownerUidValues.length;
    assert(peerUidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], peerUidValues[i]]);
    }

    return deleteAllByIndex(r'ownerUid_peerUid', values);
  }

  int deleteAllByOwnerUidPeerUidSync(
      List<String> ownerUidValues, List<String> peerUidValues) {
    final len = ownerUidValues.length;
    assert(peerUidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], peerUidValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerUid_peerUid', values);
  }

  Future<Id> putByOwnerUidPeerUid(CrmEntry object) {
    return putByIndex(r'ownerUid_peerUid', object);
  }

  Id putByOwnerUidPeerUidSync(CrmEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'ownerUid_peerUid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerUidPeerUid(List<CrmEntry> objects) {
    return putAllByIndex(r'ownerUid_peerUid', objects);
  }

  List<Id> putAllByOwnerUidPeerUidSync(List<CrmEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerUid_peerUid', objects,
        saveLinks: saveLinks);
  }
}

extension CrmEntryQueryWhereSort on QueryBuilder<CrmEntry, CrmEntry, QWhere> {
  QueryBuilder<CrmEntry, CrmEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CrmEntryQueryWhere on QueryBuilder<CrmEntry, CrmEntry, QWhereClause> {
  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> ownerUidEqualToAnyPeerUid(
      String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_peerUid',
        value: [ownerUid],
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause>
      ownerUidNotEqualToAnyPeerUid(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause> ownerUidPeerUidEqualTo(
      String ownerUid, String peerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_peerUid',
        value: [ownerUid, peerUid],
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterWhereClause>
      ownerUidEqualToPeerUidNotEqualTo(String ownerUid, String peerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid],
              upper: [ownerUid, peerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid, peerUid],
              includeLower: false,
              upper: [ownerUid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid, peerUid],
              includeLower: false,
              upper: [ownerUid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_peerUid',
              lower: [ownerUid],
              upper: [ownerUid, peerUid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CrmEntryQueryFilter
    on QueryBuilder<CrmEntry, CrmEntry, QFilterCondition> {
  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> followUpAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'followUpAt',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      followUpAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'followUpAt',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> followUpAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> followUpAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> followUpAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> followUpAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followUpAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> isArchivedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isArchived',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> isClientEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isClient',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> isProspectEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isProspect',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastContactedAt',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastContactedAt',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastContactedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastContactedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastContactedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      lastContactedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastContactedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      notesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      notesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      notesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      notesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      notesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> notesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'notes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidEqualTo(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidGreaterThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidStartsWith(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidEndsWith(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peerUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'peerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'peerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> peerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'peerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateAmountEqualTo(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateAmountGreaterThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateAmountLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateAmountBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisEqualTo(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisGreaterThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisStartsWith(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisEndsWith(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateBasis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateBasis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateBasisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      rateBasisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateBasis',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyEqualTo(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyBetween(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyEndsWith(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> rateCurrencyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      rateCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition>
      rateCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stage',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> stageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stage',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> syncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tag',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tag',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> tagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tag',
        value: '',
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<CrmEntry, CrmEntry, QAfterFilterCondition> updatedAtBetween(
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

extension CrmEntryQueryObject
    on QueryBuilder<CrmEntry, CrmEntry, QFilterCondition> {}

extension CrmEntryQueryLinks
    on QueryBuilder<CrmEntry, CrmEntry, QFilterCondition> {}

extension CrmEntryQuerySortBy on QueryBuilder<CrmEntry, CrmEntry, QSortBy> {
  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByFollowUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsClient() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClient', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsClientDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClient', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsProspect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProspect', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByIsProspectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProspect', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByLastContactedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastContactedAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByLastContactedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastContactedAt', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByPeerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerUid', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByPeerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerUid', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByRateCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByStage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByStageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CrmEntryQuerySortThenBy
    on QueryBuilder<CrmEntry, CrmEntry, QSortThenBy> {
  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByFollowUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsClient() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClient', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsClientDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClient', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsProspect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProspect', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByIsProspectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProspect', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByLastContactedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastContactedAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByLastContactedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastContactedAt', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByPeerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerUid', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByPeerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerUid', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateAmount', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateBasis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateBasisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateBasis', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByRateCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateCurrency', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByStage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByStageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CrmEntryQueryWhereDistinct
    on QueryBuilder<CrmEntry, CrmEntry, QDistinct> {
  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followUpAt');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isArchived');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByIsClient() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isClient');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByIsProspect() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isProspect');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByLastContactedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastContactedAt');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByOwnerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByPeerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByRateAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateAmount');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByRateBasis(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateBasis', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByRateCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateCurrency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByStage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByTag(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tag', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CrmEntry, CrmEntry, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CrmEntryQueryProperty
    on QueryBuilder<CrmEntry, CrmEntry, QQueryProperty> {
  QueryBuilder<CrmEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CrmEntry, DateTime?, QQueryOperations> followUpAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followUpAt');
    });
  }

  QueryBuilder<CrmEntry, bool, QQueryOperations> isArchivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isArchived');
    });
  }

  QueryBuilder<CrmEntry, bool, QQueryOperations> isClientProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isClient');
    });
  }

  QueryBuilder<CrmEntry, bool, QQueryOperations> isProspectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isProspect');
    });
  }

  QueryBuilder<CrmEntry, DateTime?, QQueryOperations>
      lastContactedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastContactedAt');
    });
  }

  QueryBuilder<CrmEntry, List<String>, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> peerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerUid');
    });
  }

  QueryBuilder<CrmEntry, double, QQueryOperations> rateAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateAmount');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> rateBasisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateBasis');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> rateCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateCurrency');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> stageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stage');
    });
  }

  QueryBuilder<CrmEntry, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<CrmEntry, String, QQueryOperations> tagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tag');
    });
  }

  QueryBuilder<CrmEntry, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
