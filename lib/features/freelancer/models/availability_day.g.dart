// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_day.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAvailabilityDayCollection on Isar {
  IsarCollection<AvailabilityDay> get availabilityDays => this.collection();
}

const AvailabilityDaySchema = CollectionSchema(
  name: r'AvailabilityDay',
  id: 6774757733665523915,
  properties: {
    r'dayOfWeek': PropertySchema(
      id: 0,
      name: r'dayOfWeek',
      type: IsarType.long,
    ),
    r'enabled': PropertySchema(
      id: 1,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'ownerUid': PropertySchema(
      id: 2,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'slots': PropertySchema(
      id: 3,
      name: r'slots',
      type: IsarType.objectList,
      target: r'AvailabilitySlot',
    ),
    r'synced': PropertySchema(
      id: 4,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _availabilityDayEstimateSize,
  serialize: _availabilityDaySerialize,
  deserialize: _availabilityDayDeserialize,
  deserializeProp: _availabilityDayDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerUid_dayOfWeek': IndexSchema(
      id: 2063096170065266941,
      name: r'ownerUid_dayOfWeek',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'dayOfWeek',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'AvailabilitySlot': AvailabilitySlotSchema},
  getId: _availabilityDayGetId,
  getLinks: _availabilityDayGetLinks,
  attach: _availabilityDayAttach,
  version: '3.1.0+1',
);

int _availabilityDayEstimateSize(
  AvailabilityDay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ownerUid.length * 3;
  bytesCount += 3 + object.slots.length * 3;
  {
    final offsets = allOffsets[AvailabilitySlot]!;
    for (var i = 0; i < object.slots.length; i++) {
      final value = object.slots[i];
      bytesCount +=
          AvailabilitySlotSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _availabilityDaySerialize(
  AvailabilityDay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dayOfWeek);
  writer.writeBool(offsets[1], object.enabled);
  writer.writeString(offsets[2], object.ownerUid);
  writer.writeObjectList<AvailabilitySlot>(
    offsets[3],
    allOffsets,
    AvailabilitySlotSchema.serialize,
    object.slots,
  );
  writer.writeBool(offsets[4], object.synced);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

AvailabilityDay _availabilityDayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AvailabilityDay(
    dayOfWeek: reader.readLong(offsets[0]),
    enabled: reader.readBoolOrNull(offsets[1]) ?? false,
    ownerUid: reader.readString(offsets[2]),
    slots: reader.readObjectList<AvailabilitySlot>(
          offsets[3],
          AvailabilitySlotSchema.deserialize,
          allOffsets,
          AvailabilitySlot(),
        ) ??
        const <AvailabilitySlot>[],
    synced: reader.readBoolOrNull(offsets[4]) ?? false,
    updatedAt: reader.readDateTime(offsets[5]),
  );
  object.id = id;
  return object;
}

P _availabilityDayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readObjectList<AvailabilitySlot>(
            offset,
            AvailabilitySlotSchema.deserialize,
            allOffsets,
            AvailabilitySlot(),
          ) ??
          const <AvailabilitySlot>[]) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _availabilityDayGetId(AvailabilityDay object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _availabilityDayGetLinks(AvailabilityDay object) {
  return [];
}

void _availabilityDayAttach(
    IsarCollection<dynamic> col, Id id, AvailabilityDay object) {
  object.id = id;
}

extension AvailabilityDayByIndex on IsarCollection<AvailabilityDay> {
  Future<AvailabilityDay?> getByOwnerUidDayOfWeek(
      String ownerUid, int dayOfWeek) {
    return getByIndex(r'ownerUid_dayOfWeek', [ownerUid, dayOfWeek]);
  }

  AvailabilityDay? getByOwnerUidDayOfWeekSync(String ownerUid, int dayOfWeek) {
    return getByIndexSync(r'ownerUid_dayOfWeek', [ownerUid, dayOfWeek]);
  }

  Future<bool> deleteByOwnerUidDayOfWeek(String ownerUid, int dayOfWeek) {
    return deleteByIndex(r'ownerUid_dayOfWeek', [ownerUid, dayOfWeek]);
  }

  bool deleteByOwnerUidDayOfWeekSync(String ownerUid, int dayOfWeek) {
    return deleteByIndexSync(r'ownerUid_dayOfWeek', [ownerUid, dayOfWeek]);
  }

  Future<List<AvailabilityDay?>> getAllByOwnerUidDayOfWeek(
      List<String> ownerUidValues, List<int> dayOfWeekValues) {
    final len = ownerUidValues.length;
    assert(dayOfWeekValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], dayOfWeekValues[i]]);
    }

    return getAllByIndex(r'ownerUid_dayOfWeek', values);
  }

  List<AvailabilityDay?> getAllByOwnerUidDayOfWeekSync(
      List<String> ownerUidValues, List<int> dayOfWeekValues) {
    final len = ownerUidValues.length;
    assert(dayOfWeekValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], dayOfWeekValues[i]]);
    }

    return getAllByIndexSync(r'ownerUid_dayOfWeek', values);
  }

  Future<int> deleteAllByOwnerUidDayOfWeek(
      List<String> ownerUidValues, List<int> dayOfWeekValues) {
    final len = ownerUidValues.length;
    assert(dayOfWeekValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], dayOfWeekValues[i]]);
    }

    return deleteAllByIndex(r'ownerUid_dayOfWeek', values);
  }

  int deleteAllByOwnerUidDayOfWeekSync(
      List<String> ownerUidValues, List<int> dayOfWeekValues) {
    final len = ownerUidValues.length;
    assert(dayOfWeekValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerUidValues[i], dayOfWeekValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerUid_dayOfWeek', values);
  }

  Future<Id> putByOwnerUidDayOfWeek(AvailabilityDay object) {
    return putByIndex(r'ownerUid_dayOfWeek', object);
  }

  Id putByOwnerUidDayOfWeekSync(AvailabilityDay object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'ownerUid_dayOfWeek', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerUidDayOfWeek(List<AvailabilityDay> objects) {
    return putAllByIndex(r'ownerUid_dayOfWeek', objects);
  }

  List<Id> putAllByOwnerUidDayOfWeekSync(List<AvailabilityDay> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerUid_dayOfWeek', objects,
        saveLinks: saveLinks);
  }
}

extension AvailabilityDayQueryWhereSort
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QWhere> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AvailabilityDayQueryWhere
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QWhereClause> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause> idBetween(
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidEqualToAnyDayOfWeek(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_dayOfWeek',
        value: [ownerUid],
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidNotEqualToAnyDayOfWeek(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidDayOfWeekEqualTo(String ownerUid, int dayOfWeek) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid_dayOfWeek',
        value: [ownerUid, dayOfWeek],
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidEqualToDayOfWeekNotEqualTo(String ownerUid, int dayOfWeek) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid],
              upper: [ownerUid, dayOfWeek],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid, dayOfWeek],
              includeLower: false,
              upper: [ownerUid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid, dayOfWeek],
              includeLower: false,
              upper: [ownerUid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid_dayOfWeek',
              lower: [ownerUid],
              upper: [ownerUid, dayOfWeek],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidEqualToDayOfWeekGreaterThan(
    String ownerUid,
    int dayOfWeek, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerUid_dayOfWeek',
        lower: [ownerUid, dayOfWeek],
        includeLower: include,
        upper: [ownerUid],
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidEqualToDayOfWeekLessThan(
    String ownerUid,
    int dayOfWeek, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerUid_dayOfWeek',
        lower: [ownerUid],
        upper: [ownerUid, dayOfWeek],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterWhereClause>
      ownerUidEqualToDayOfWeekBetween(
    String ownerUid,
    int lowerDayOfWeek,
    int upperDayOfWeek, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerUid_dayOfWeek',
        lower: [ownerUid, lowerDayOfWeek],
        includeLower: includeLower,
        upper: [ownerUid, upperDayOfWeek],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AvailabilityDayQueryFilter
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QFilterCondition> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      dayOfWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      dayOfWeekGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      dayOfWeekLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      dayOfWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      ownerUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      ownerUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'slots',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
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

extension AvailabilityDayQueryObject
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QFilterCondition> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterFilterCondition>
      slotsElement(FilterQuery<AvailabilitySlot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'slots');
    });
  }
}

extension AvailabilityDayQueryLinks
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QFilterCondition> {}

extension AvailabilityDayQuerySortBy
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QSortBy> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AvailabilityDayQuerySortThenBy
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QSortThenBy> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AvailabilityDayQueryWhereDistinct
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct> {
  QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct>
      distinctByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeek');
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct>
      distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct> distinctByOwnerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<AvailabilityDay, AvailabilityDay, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension AvailabilityDayQueryProperty
    on QueryBuilder<AvailabilityDay, AvailabilityDay, QQueryProperty> {
  QueryBuilder<AvailabilityDay, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AvailabilityDay, int, QQueryOperations> dayOfWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeek');
    });
  }

  QueryBuilder<AvailabilityDay, bool, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<AvailabilityDay, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<AvailabilityDay, List<AvailabilitySlot>, QQueryOperations>
      slotsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slots');
    });
  }

  QueryBuilder<AvailabilityDay, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<AvailabilityDay, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const AvailabilitySlotSchema = Schema(
  name: r'AvailabilitySlot',
  id: 6173918632615147827,
  properties: {
    r'end': PropertySchema(
      id: 0,
      name: r'end',
      type: IsarType.string,
    ),
    r'endMinutes': PropertySchema(
      id: 1,
      name: r'endMinutes',
      type: IsarType.long,
    ),
    r'isValid': PropertySchema(
      id: 2,
      name: r'isValid',
      type: IsarType.bool,
    ),
    r'start': PropertySchema(
      id: 3,
      name: r'start',
      type: IsarType.string,
    ),
    r'startMinutes': PropertySchema(
      id: 4,
      name: r'startMinutes',
      type: IsarType.long,
    )
  },
  estimateSize: _availabilitySlotEstimateSize,
  serialize: _availabilitySlotSerialize,
  deserialize: _availabilitySlotDeserialize,
  deserializeProp: _availabilitySlotDeserializeProp,
);

int _availabilitySlotEstimateSize(
  AvailabilitySlot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.end.length * 3;
  bytesCount += 3 + object.start.length * 3;
  return bytesCount;
}

void _availabilitySlotSerialize(
  AvailabilitySlot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.end);
  writer.writeLong(offsets[1], object.endMinutes);
  writer.writeBool(offsets[2], object.isValid);
  writer.writeString(offsets[3], object.start);
  writer.writeLong(offsets[4], object.startMinutes);
}

AvailabilitySlot _availabilitySlotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AvailabilitySlot(
    end: reader.readStringOrNull(offsets[0]) ?? '17:00',
    start: reader.readStringOrNull(offsets[3]) ?? '09:00',
  );
  return object;
}

P _availabilitySlotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '17:00') as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '09:00') as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension AvailabilitySlotQueryFilter
    on QueryBuilder<AvailabilitySlot, AvailabilitySlot, QFilterCondition> {
  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'end',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'end',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'end',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      endMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      isValidEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isValid',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'start',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'start',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'start',
        value: '',
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<AvailabilitySlot, AvailabilitySlot, QAfterFilterCondition>
      startMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AvailabilitySlotQueryObject
    on QueryBuilder<AvailabilitySlot, AvailabilitySlot, QFilterCondition> {}
