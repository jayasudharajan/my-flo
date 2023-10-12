// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage_item;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsageItem> _$waterUsageItemSerializer =
    new _$WaterUsageItemSerializer();

class _$WaterUsageItemSerializer
    implements StructuredSerializer<WaterUsageItem> {
  @override
  final Iterable<Type> types = const [WaterUsageItem, _$WaterUsageItem];
  @override
  final String wireName = 'WaterUsageItem';

  @override
  Iterable<Object> serialize(Serializers serializers, WaterUsageItem object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.time != null) {
      result
        ..add('time')
        ..add(serializers.serialize(object.time,
            specifiedType: const FullType(String)));
    }
    if (object.gallonsConsumed != null) {
      result
        ..add('gallonsConsumed')
        ..add(serializers.serialize(object.gallonsConsumed,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  WaterUsageItem deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageItemBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'time':
          result.time = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'gallonsConsumed':
          result.gallonsConsumed = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsageItem extends WaterUsageItem {
  @override
  final String time;
  @override
  final double gallonsConsumed;

  factory _$WaterUsageItem([void Function(WaterUsageItemBuilder) updates]) =>
      (new WaterUsageItemBuilder()..update(updates)).build();

  _$WaterUsageItem._({this.time, this.gallonsConsumed}) : super._();

  @override
  WaterUsageItem rebuild(void Function(WaterUsageItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageItemBuilder toBuilder() =>
      new WaterUsageItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsageItem &&
        time == other.time &&
        gallonsConsumed == other.gallonsConsumed;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, time.hashCode), gallonsConsumed.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsageItem')
          ..add('time', time)
          ..add('gallonsConsumed', gallonsConsumed))
        .toString();
  }
}

class WaterUsageItemBuilder
    implements Builder<WaterUsageItem, WaterUsageItemBuilder> {
  _$WaterUsageItem _$v;

  String _time;
  String get time => _$this._time;
  set time(String time) => _$this._time = time;

  double _gallonsConsumed;
  double get gallonsConsumed => _$this._gallonsConsumed;
  set gallonsConsumed(double gallonsConsumed) =>
      _$this._gallonsConsumed = gallonsConsumed;

  WaterUsageItemBuilder();

  WaterUsageItemBuilder get _$this {
    if (_$v != null) {
      _time = _$v.time;
      _gallonsConsumed = _$v.gallonsConsumed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsageItem other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsageItem;
  }

  @override
  void update(void Function(WaterUsageItemBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsageItem build() {
    final _$result = _$v ??
        new _$WaterUsageItem._(time: time, gallonsConsumed: gallonsConsumed);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
