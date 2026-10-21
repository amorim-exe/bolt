// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_history_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRequestHistoryEntityCollection on Isar {
  IsarCollection<RequestHistoryEntity> get requestHistoryEntitys =>
      this.collection();
}

const RequestHistoryEntitySchema = CollectionSchema(
  name: r'RequestHistoryEntity',
  id: -4185294501923481626,
  properties: {
    r'body': PropertySchema(
      id: 0,
      name: r'body',
      type: IsarType.string,
    ),
    r'headersJson': PropertySchema(
      id: 1,
      name: r'headersJson',
      type: IsarType.string,
    ),
    r'method': PropertySchema(
      id: 2,
      name: r'method',
      type: IsarType.string,
    ),
    r'queryParamsJson': PropertySchema(
      id: 3,
      name: r'queryParamsJson',
      type: IsarType.string,
    ),
    r'statusCode': PropertySchema(
      id: 4,
      name: r'statusCode',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 5,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'url': PropertySchema(
      id: 6,
      name: r'url',
      type: IsarType.string,
    )
  },
  estimateSize: _requestHistoryEntityEstimateSize,
  serialize: _requestHistoryEntitySerialize,
  deserialize: _requestHistoryEntityDeserialize,
  deserializeProp: _requestHistoryEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _requestHistoryEntityGetId,
  getLinks: _requestHistoryEntityGetLinks,
  attach: _requestHistoryEntityAttach,
  version: '3.1.0+1',
);

int _requestHistoryEntityEstimateSize(
  RequestHistoryEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.body;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.headersJson.length * 3;
  bytesCount += 3 + object.method.length * 3;
  bytesCount += 3 + object.queryParamsJson.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _requestHistoryEntitySerialize(
  RequestHistoryEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.body);
  writer.writeString(offsets[1], object.headersJson);
  writer.writeString(offsets[2], object.method);
  writer.writeString(offsets[3], object.queryParamsJson);
  writer.writeLong(offsets[4], object.statusCode);
  writer.writeDateTime(offsets[5], object.timestamp);
  writer.writeString(offsets[6], object.url);
}

RequestHistoryEntity _requestHistoryEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RequestHistoryEntity();
  object.body = reader.readStringOrNull(offsets[0]);
  object.headersJson = reader.readString(offsets[1]);
  object.id = id;
  object.method = reader.readString(offsets[2]);
  object.queryParamsJson = reader.readString(offsets[3]);
  object.statusCode = reader.readLongOrNull(offsets[4]);
  object.timestamp = reader.readDateTime(offsets[5]);
  object.url = reader.readString(offsets[6]);
  return object;
}

P _requestHistoryEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _requestHistoryEntityGetId(RequestHistoryEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _requestHistoryEntityGetLinks(
    RequestHistoryEntity object) {
  return [];
}

void _requestHistoryEntityAttach(
    IsarCollection<dynamic> col, Id id, RequestHistoryEntity object) {
  object.id = id;
}

extension RequestHistoryEntityQueryWhereSort
    on QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QWhere> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RequestHistoryEntityQueryWhere
    on QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QWhereClause> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhereClause>
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

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterWhereClause>
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
}

extension RequestHistoryEntityQueryFilter on QueryBuilder<RequestHistoryEntity,
    RequestHistoryEntity, QFilterCondition> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'body',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'body',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'body',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      bodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      bodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'body',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      headersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      headersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> headersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      methodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      methodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'method',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> methodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queryParamsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      queryParamsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'queryParamsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      queryParamsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'queryParamsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryParamsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> queryParamsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'queryParamsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'statusCode',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'statusCode',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> statusCodeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
          QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity,
      QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }
}

extension RequestHistoryEntityQueryObject on QueryBuilder<RequestHistoryEntity,
    RequestHistoryEntity, QFilterCondition> {}

extension RequestHistoryEntityQueryLinks on QueryBuilder<RequestHistoryEntity,
    RequestHistoryEntity, QFilterCondition> {}

extension RequestHistoryEntityQuerySortBy
    on QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QSortBy> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByHeadersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headersJson', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByHeadersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headersJson', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByQueryParamsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryParamsJson', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByQueryParamsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryParamsJson', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByStatusCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusCode', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByStatusCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusCode', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension RequestHistoryEntityQuerySortThenBy
    on QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QSortThenBy> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByHeadersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headersJson', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByHeadersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headersJson', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByQueryParamsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryParamsJson', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByQueryParamsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryParamsJson', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByStatusCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusCode', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByStatusCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusCode', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QAfterSortBy>
      thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension RequestHistoryEntityQueryWhereDistinct
    on QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct> {
  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByBody({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByHeadersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headersJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByQueryParamsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queryParamsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByStatusCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusCode');
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<RequestHistoryEntity, RequestHistoryEntity, QDistinct>
      distinctByUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension RequestHistoryEntityQueryProperty on QueryBuilder<
    RequestHistoryEntity, RequestHistoryEntity, QQueryProperty> {
  QueryBuilder<RequestHistoryEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RequestHistoryEntity, String?, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<RequestHistoryEntity, String, QQueryOperations>
      headersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headersJson');
    });
  }

  QueryBuilder<RequestHistoryEntity, String, QQueryOperations>
      methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<RequestHistoryEntity, String, QQueryOperations>
      queryParamsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queryParamsJson');
    });
  }

  QueryBuilder<RequestHistoryEntity, int?, QQueryOperations>
      statusCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusCode');
    });
  }

  QueryBuilder<RequestHistoryEntity, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<RequestHistoryEntity, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
