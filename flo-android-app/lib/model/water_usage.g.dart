// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsage> _$waterUsageSerializer = new _$WaterUsageSerializer();

class _$WaterUsageSerializer implements StructuredSerializer<WaterUsage> {
  @override
  final Iterable<Type> types = const [WaterUsage, _$WaterUsage];
  @override
  final String wireName = 'WaterUsage';

  @override
  Iterable<Object> serialize(Serializers serializers, WaterUsage object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.params != null) {
      result
        ..add('params')
        ..add(serializers.serialize(object.params,
            specifiedType: const FullType(WaterUsageParams)));
    }
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType: const FullType(
                BuiltList, const [const FullType(WaterUsageItem)])));
    }
    if (object.aggregations != null) {
      result
        ..add('aggregations')
        ..add(serializers.serialize(object.aggregations,
            specifiedType: const FullType(WaterUsageAggregations)));
    }
    return result;
  }

  @override
  WaterUsage deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageBuilder();

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
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(WaterUsageItem)]))
              as BuiltList<dynamic>);
          break;
        case 'aggregations':
          result.aggregations.replace(serializers.deserialize(value,
                  specifiedType: const FullType(WaterUsageAggregations))
              as WaterUsageAggregations);
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsage extends WaterUsage {
  @override
  final WaterUsageParams params;
  @override
  final BuiltList<WaterUsageItem> items;
  @override
  final WaterUsageAggregations aggregations;

  factory _$WaterUsage([void Function(WaterUsageBuilder) updates]) =>
      (new WaterUsageBuilder()..update(updates)).build();

  _$WaterUsage._({this.params, this.items, this.aggregations}) : super._();

  @override
  WaterUsage rebuild(void Function(WaterUsageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageBuilder toBuilder() => new WaterUsageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsage &&
        params == other.params &&
        items == other.items &&
        aggregations == other.aggregations;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, params.hashCode), items.hashCode), aggregations.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsage')
          ..add('params', params)
          ..add('items', items)
          ..add('aggregations', aggregations))
        .toString();
  }
}

class WaterUsageBuilder implements Builder<WaterUsage, WaterUsageBuilder> {
  _$WaterUsage _$v;

  WaterUsageParamsBuilder _params;
  WaterUsageParamsBuilder get params =>
      _$this._params ??= new WaterUsageParamsBuilder();
  set params(WaterUsageParamsBuilder params) => _$this._params = params;

  ListBuilder<WaterUsageItem> _items;
  ListBuilder<WaterUsageItem> get items =>
      _$this._items ??= new ListBuilder<WaterUsageItem>();
  set items(ListBuilder<WaterUsageItem> items) => _$this._items = items;

  WaterUsageAggregationsBuilder _aggregations;
  WaterUsageAggregationsBuilder get aggregations =>
      _$this._aggregations ??= new WaterUsageAggregationsBuilder();
  set aggregations(WaterUsageAggregationsBuilder aggregations) =>
      _$this._aggregations = aggregations;

  WaterUsageBuilder();

  WaterUsageBuilder get _$this {
    if (_$v != null) {
      _params = _$v.params?.toBuilder();
      _items = _$v.items?.toBuilder();
      _aggregations = _$v.aggregations?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsage other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsage;
  }

  @override
  void update(void Function(WaterUsageBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsage build() {
    _$WaterUsage _$result;
    try {
      _$result = _$v ??
          new _$WaterUsage._(
              params: _params?.build(),
              items: _items?.build(),
              aggregations: _aggregations?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'params';
        _params?.build();
        _$failedField = 'items';
        _items?.build();
        _$failedField = 'aggregations';
        _aggregations?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'WaterUsage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
