// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimeEntryCollection on Isar {
  IsarCollection<TimeEntry> get timeEntrys => this.collection();
}

const TimeEntrySchema = CollectionSchema(
  name: r'TimeEntry',
  id: -8996794355716442839,
  properties: {
    r'at': PropertySchema(
      id: 0,
      name: r'at',
      type: IsarType.dateTime,
    ),
    r'callId': PropertySchema(
      id: 1,
      name: r'callId',
      type: IsarType.string,
    ),
    r'clientName': PropertySchema(
      id: 2,
      name: r'clientName',
      type: IsarType.string,
    ),
    r'clientUid': PropertySchema(
      id: 3,
      name: r'clientUid',
      type: IsarType.string,
    ),
    r'minutes': PropertySchema(
      id: 4,
      name: r'minutes',
      type: IsarType.long,
    ),
    r'ownerUid': PropertySchema(
      id: 5,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 6,
      name: r'synced',
      type: IsarType.bool,
    )
  },
  estimateSize: _timeEntryEstimateSize,
  serialize: _timeEntrySerialize,
  deserialize: _timeEntryDeserialize,
  deserializeProp: _timeEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerUid_callId': IndexSchema(
      id: -3477165158062679150,
      name: r'ownerUid_callId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'callId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _timeEntryGetId,
  getLinks: _timeEntryGetLinks,
  attach: _timeEntryAttach,
  version: '3.1.0+1',
);

int _timeEntryEstimateSize(
  TimeEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.callId.length * 3;
  bytesCount += 3 + object.clientName.length * 3;
  bytesCount += 3 + object.clientUid.length * 3;
  bytesCount += 3 + object.ownerUid.length * 3;
  return bytesCount;
}

void _timeEntrySerialize(
  TimeEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.at);
  writer.writeString(offsets[1], object.callId);
  writer.writeString(offsets[2], object.clientName);
  writer.writeString(offsets[3], object.clientUid);
  writer.writeLong(offsets[4], object.minutes);
  writer.writeString(offsets[5], object.ownerUid);
  writer.writeBool(offsets[6], object.synced);
}

TimeEntry _timeEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeEntry(
    at: reader.readDateTime(offsets[0]),
    callId: reader.readString(offsets[1]),
    clientName: reader.readString(offsets[2]),
    clientUid: reader.readString(offsets[3]),
    minutes: reader.readLong(offsets[4]),
    ownerUid: reader.readString(offsets[5]),
    synced: reader.readBoolOrNull(offsets[6]) ?? false,
  );
  object.id = id;
  return object;
}

P _timeEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _timeEntryGetId(TimeEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timeEntryGetLinks(TimeEntry object) {
  return [];
}

void _timeEntryAttach(IsarCollection<dynamic> col, Id id, TimeEntry object) {
  object.id = id;
}

extension TimeEntryByIndex on IsarCollection<TimeEntry> {
  Future<TimeEntry?> getByOwnerUidCallId(String ownerUid, String callId) {
    return getByIndex(r'ownerUid_callId', [ownerUid, callId]);
  }

  TimeEntry? getByOwnerUidCallIdSync(String ownerUid, String callId) {
    return getByIndexSync(r'ownerUid_callId', [ownerUid, callId]);
  }

  Future<bool> deleteByOwnerUidCallId(String ownerUid, String callId) {
    return deleteByIndex(r'ownerUid_callId', [ownerUid, callId]);
  }

  bool deleteByOwnerUidCallIdSync(String ownerUid, String callId) {
    return deleteByIndexSync(r'ownerUid_callId', [ownerUid, callId]);
  }

  Future<List<TimeEntry?>> getAllByOwnerUidCallId(
      List<String> ownerUidValues, List<String> callIdValues) {
    final len = ownerUidValues.length;
    assert(callIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], callIdValues[i]]);
    }

    return getAllByIndex(r'ownerUid_callId', values);
  }

  List<TimeEntry?> getAllByOwnerUidCallIdSync(
      List<String> ownerUidValues, List<String> callIdValues) {
    final len = ownerUidValues.length;
    assert(callIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], callIdValues[i]]);
    }

    return getAllByIndexSync(r'ownerUid_callId', values);
  }

  Future<int> deleteAllByOwnerUidCallId(
      List<String> ownerUidValues, List<String> callIdValues) {
    final len = ownerUidValues.length;
    assert(callIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], callIdValues[i]]);
    }

    return deleteAllByIndex(r'ownerUid_callId', values);
  }

  int deleteAllByOwnerUidCallIdSync(
      List<String> ownerUidValues, List<String> callIdValues) {
    final len = ownerUidValues.length;
    assert(callIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], callIdValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerUid_callId', values);
  }

  Future<Id> putByOwnerUidCallId(TimeEntry object) {
    return putByIndex(r'ownerUid_callId', object);
  }

  Id putByOwnerUidCallIdSync(TimeEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'ownerUid_callId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerUidCallId(List<TimeEntry> objects) {
    return putAllByIndex(r'ownerUid_callId', objects);
  }

  List<Id> putAllByOwnerUidCallIdSync(List<TimeEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerUid_callId', objects, saveLinks: saveLinks);
  }
}

extension TimeEntryQueryWhereSort
    on QueryBuilder<TimeEntry, TimeEntry, QWhere> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TimeEntryQueryWhere
    on QueryBuilder<TimeEntry, TimeEntry, QWhereClause> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause>
      ownerUidEqualToAnyCallId(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_callId',
        value: [ownerUid],
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause>
      ownerUidNotEqualToAnyCallId(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause> ownerUidCallIdEqualTo(
      String ownerUid, String callId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_callId',
        value: [ownerUid, callId],
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterWhereClause>
      ownerUidEqualToCallIdNotEqualTo(String ownerUid, String callId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid],
              upper: [ownerUid, callId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid, callId],
              includeLower: false,
              upper: [ownerUid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid, callId],
              includeLower: false,
              upper: [ownerUid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_callId',
              lower: [ownerUid],
              upper: [ownerUid, callId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TimeEntryQueryFilter
    on QueryBuilder<TimeEntry, TimeEntry, QFilterCondition> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> atEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> atGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> atLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> atBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'at',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'callId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'callId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'callId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'callId',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> callIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'callId',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> clientUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientUid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      clientUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientUid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> minutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidEqualTo(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidGreaterThan(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidLessThan(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidBetween(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidStartsWith(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidEndsWith(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidContains(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidMatches(
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

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition>
      ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterFilterCondition> syncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }
}

extension TimeEntryQueryObject
    on QueryBuilder<TimeEntry, TimeEntry, QFilterCondition> {}

extension TimeEntryQueryLinks
    on QueryBuilder<TimeEntry, TimeEntry, QFilterCondition> {}

extension TimeEntryQuerySortBy on QueryBuilder<TimeEntry, TimeEntry, QSortBy> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByClientUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientUid', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByClientUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientUid', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutes', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutes', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }
}

extension TimeEntryQuerySortThenBy
    on QueryBuilder<TimeEntry, TimeEntry, QSortThenBy> {
  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByClientUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientUid', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByClientUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientUid', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutes', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutes', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }
}

extension TimeEntryQueryWhereDistinct
    on QueryBuilder<TimeEntry, TimeEntry, QDistinct> {
  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'at');
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByCallId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'callId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByClientName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByClientUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minutes');
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctByOwnerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeEntry, TimeEntry, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }
}

extension TimeEntryQueryProperty
    on QueryBuilder<TimeEntry, TimeEntry, QQueryProperty> {
  QueryBuilder<TimeEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimeEntry, DateTime, QQueryOperations> atProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'at');
    });
  }

  QueryBuilder<TimeEntry, String, QQueryOperations> callIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'callId');
    });
  }

  QueryBuilder<TimeEntry, String, QQueryOperations> clientNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientName');
    });
  }

  QueryBuilder<TimeEntry, String, QQueryOperations> clientUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientUid');
    });
  }

  QueryBuilder<TimeEntry, int, QQueryOperations> minutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minutes');
    });
  }

  QueryBuilder<TimeEntry, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<TimeEntry, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }
}
