// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage_averages;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsageAverages> _$waterUsageAveragesSerializer =
    new _$WaterUsageAveragesSerializer();

class _$WaterUsageAveragesSerializer
    implements StructuredSerializer<WaterUsageAverages> {
  @override
  final Iterable<Type> types = const [WaterUsageAverages, _$WaterUsageAverages];
  @override
  final String wireName = 'WaterUsageAverages';

  @override
  Iterable<Object> serialize(Serializers serializers, WaterUsageAverages object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.params != null) {
      result
        ..add('params')
        ..add(serializers.serialize(object.params,
            specifiedType: const FullType(WaterUsageParams)));
    }
    if (object.aggregations != null) {
      result
        ..add('aggregations')
        ..add(serializers.serialize(object.aggregations,
            specifiedType: const FullType(WaterUsageAveragesAggregations)));
    }
    return result;
  }

  @override
  WaterUsageAverages deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageAveragesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'params':
          result.params.replace(serializers.deserialize(value,
                  specifiedType: const FullType(WaterUsageParams))
              as WaterUsageParams);
          break;
        case 'aggregations':
          result.aggregations.replace(serializers.deserialize(value,
                  specifiedType: const FullType(WaterUsageAveragesAggregations))
              as WaterUsageAveragesAggregations);
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsageAverages extends WaterUsageAverages {
  @override
  final WaterUsageParams params;
  @override
  final WaterUsageAveragesAggregations aggregations;

  factory _$WaterUsageAverages(
          [void Function(WaterUsageAveragesBuilder) updates]) =>
      (new WaterUsageAveragesBuilder()..update(updates)).build();

  _$WaterUsageAverages._({this.params, this.aggregations}) : super._();

  @override
  WaterUsageAverages rebuild(
          void Function(WaterUsageAveragesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageAveragesBuilder toBuilder() =>
      new WaterUsageAveragesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsageAverages &&
        params == other.params &&
        aggregations == other.aggregations;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, params.hashCode), aggregations.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsageAverages')
          ..add('params', params)
          ..add('aggregations', aggregations))
        .toString();
  }
}

class WaterUsageAveragesBuilder
    implements Builder<WaterUsageAverages, WaterUsageAveragesBuilder> {
  _$WaterUsageAverages _$v;

  WaterUsageParamsBuilder _params;
  WaterUsageParamsBuilder get params =>
      _$this._params ??= new WaterUsageParamsBuilder();
  set params(WaterUsageParamsBuilder params) => _$this._params = params;

  WaterUsageAveragesAggregationsBuilder _aggregations;
  WaterUsageAveragesAggregationsBuilder get aggregations =>
      _$this._aggregations ??= new WaterUsageAveragesAggregationsBuilder();
  set aggregations(WaterUsageAveragesAggregationsBuilder aggregations) =>
      _$this._aggregations = aggregations;

  WaterUsageAveragesBuilder();

  WaterUsageAveragesBuilder get _$this {
    if (_$v != null) {
      _params = _$v.params?.toBuilder();
      _aggregations = _$v.aggregations?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsageAverages other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsageAverages;
  }

  @override
  void update(void Function(WaterUsageAveragesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsageAverages build() {
    _$WaterUsageAverages _$result;
    try {
      _$result = _$v ??
          new _$WaterUsageAverages._(
              params: _params?.build(), aggregations: _aggregations?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'params';
        _params?.build();
        _$failedField = 'aggregations';
        _aggregations?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'WaterUsageAverages', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
