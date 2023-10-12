// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage_aggregations;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsageAggregations> _$waterUsageAggregationsSerializer =
    new _$WaterUsageAggregationsSerializer();

class _$WaterUsageAggregationsSerializer
    implements StructuredSerializer<WaterUsageAggregations> {
  @override
  final Iterable<Type> types = const [
    WaterUsageAggregations,
    _$WaterUsageAggregations
  ];
  @override
  final String wireName = 'WaterUsageAggregations';

  @override
  Iterable<Object> serialize(
      Serializers serializers, WaterUsageAggregations object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.sumTotalGallonsConsumed != null) {
      result
        ..add('sumTotalGallonsConsumed')
        ..add(serializers.serialize(object.sumTotalGallonsConsumed,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  WaterUsageAggregations deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageAggregationsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'sumTotalGallonsConsumed':
          result.sumTotalGallonsConsumed = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsageAggregations extends WaterUsageAggregations {
  @override
  final double sumTotalGallonsConsumed;

  factory _$WaterUsageAggregations(
          [void Function(WaterUsageAggregationsBuilder) updates]) =>
      (new WaterUsageAggregationsBuilder()..update(updates)).build();

  _$WaterUsageAggregations._({this.sumTotalGallonsConsumed}) : super._();

  @override
  WaterUsageAggregations rebuild(
          void Function(WaterUsageAggregationsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageAggregationsBuilder toBuilder() =>
      new WaterUsageAggregationsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsageAggregations &&
        sumTotalGallonsConsumed == other.sumTotalGallonsConsumed;
  }

  @override
  int get hashCode {
    return $jf($jc(0, sumTotalGallonsConsumed.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsageAggregations')
          ..add('sumTotalGallonsConsumed', sumTotalGallonsConsumed))
        .toString();
  }
}

class WaterUsageAggregationsBuilder
    implements Builder<WaterUsageAggregations, WaterUsageAggregationsBuilder> {
  _$WaterUsageAggregations _$v;

  double _sumTotalGallonsConsumed;
  double get sumTotalGallonsConsumed => _$this._sumTotalGallonsConsumed;
  set sumTotalGallonsConsumed(double sumTotalGallonsConsumed) =>
      _$this._sumTotalGallonsConsumed = sumTotalGallonsConsumed;

  WaterUsageAggregationsBuilder();

  WaterUsageAggregationsBuilder get _$this {
    if (_$v != null) {
      _sumTotalGallonsConsumed = _$v.sumTotalGallonsConsumed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsageAggregations other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsageAggregations;
  }

  @override
  void update(void Function(WaterUsageAggregationsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsageAggregations build() {
    final _$result = _$v ??
        new _$WaterUsageAggregations._(
            sumTotalGallonsConsumed: sumTotalGallonsConsumed);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
