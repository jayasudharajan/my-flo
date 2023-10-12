// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage_averages_aggregations;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsageAveragesAggregations>
    _$waterUsageAveragesAggregationsSerializer =
    new _$WaterUsageAveragesAggregationsSerializer();

class _$WaterUsageAveragesAggregationsSerializer
    implements StructuredSerializer<WaterUsageAveragesAggregations> {
  @override
  final Iterable<Type> types = const [
    WaterUsageAveragesAggregations,
    _$WaterUsageAveragesAggregations
  ];
  @override
  final String wireName = 'WaterUsageAveragesAggregations';

  @override
  Iterable<Object> serialize(
      Serializers serializers, WaterUsageAveragesAggregations object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.weekdayAverages != null) {
      result
        ..add('dayOfWeekAvg')
        ..add(serializers.serialize(object.weekdayAverages,
            specifiedType: const FullType(WeekdayAverages)));
    }
    if (object.weekdailyAverages != null) {
      result
        ..add('prevCalendarWeekDailyAvg')
        ..add(serializers.serialize(object.weekdailyAverages,
            specifiedType: const FullType(DurationValue)));
    }
    if (object.monthlyAverages != null) {
      result
        ..add('monthlyAvg')
        ..add(serializers.serialize(object.monthlyAverages,
            specifiedType: const FullType(DurationValue)));
    }
    return result;
  }

  @override
  WaterUsageAveragesAggregations deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageAveragesAggregationsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'dayOfWeekAvg':
          result.weekdayAverages.replace(serializers.deserialize(value,
                  specifiedType: const FullType(WeekdayAverages))
              as WeekdayAverages);
          break;
        case 'prevCalendarWeekDailyAvg':
          result.weekdailyAverages.replace(serializers.deserialize(value,
              specifiedType: const FullType(DurationValue)) as DurationValue);
          break;
        case 'monthlyAvg':
          result.monthlyAverages.replace(serializers.deserialize(value,
              specifiedType: const FullType(DurationValue)) as DurationValue);
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsageAveragesAggregations extends WaterUsageAveragesAggregations {
  @override
  final WeekdayAverages weekdayAverages;
  @override
  final DurationValue weekdailyAverages;
  @override
  final DurationValue monthlyAverages;

  factory _$WaterUsageAveragesAggregations(
          [void Function(WaterUsageAveragesAggregationsBuilder) updates]) =>
      (new WaterUsageAveragesAggregationsBuilder()..update(updates)).build();

  _$WaterUsageAveragesAggregations._(
      {this.weekdayAverages, this.weekdailyAverages, this.monthlyAverages})
      : super._();

  @override
  WaterUsageAveragesAggregations rebuild(
          void Function(WaterUsageAveragesAggregationsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageAveragesAggregationsBuilder toBuilder() =>
      new WaterUsageAveragesAggregationsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsageAveragesAggregations &&
        weekdayAverages == other.weekdayAverages &&
        weekdailyAverages == other.weekdailyAverages &&
        monthlyAverages == other.monthlyAverages;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, weekdayAverages.hashCode), weekdailyAverages.hashCode),
        monthlyAverages.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsageAveragesAggregations')
          ..add('weekdayAverages', weekdayAverages)
          ..add('weekdailyAverages', weekdailyAverages)
          ..add('monthlyAverages', monthlyAverages))
        .toString();
  }
}

class WaterUsageAveragesAggregationsBuilder
    implements
        Builder<WaterUsageAveragesAggregations,
            WaterUsageAveragesAggregationsBuilder> {
  _$WaterUsageAveragesAggregations _$v;

  WeekdayAveragesBuilder _weekdayAverages;
  WeekdayAveragesBuilder get weekdayAverages =>
      _$this._weekdayAverages ??= new WeekdayAveragesBuilder();
  set weekdayAverages(WeekdayAveragesBuilder weekdayAverages) =>
      _$this._weekdayAverages = weekdayAverages;

  DurationValueBuilder _weekdailyAverages;
  DurationValueBuilder get weekdailyAverages =>
      _$this._weekdailyAverages ??= new DurationValueBuilder();
  set weekdailyAverages(DurationValueBuilder weekdailyAverages) =>
      _$this._weekdailyAverages = weekdailyAverages;

  DurationValueBuilder _monthlyAverages;
  DurationValueBuilder get monthlyAverages =>
      _$this._monthlyAverages ??= new DurationValueBuilder();
  set monthlyAverages(DurationValueBuilder monthlyAverages) =>
      _$this._monthlyAverages = monthlyAverages;

  WaterUsageAveragesAggregationsBuilder();

  WaterUsageAveragesAggregationsBuilder get _$this {
    if (_$v != null) {
      _weekdayAverages = _$v.weekdayAverages?.toBuilder();
      _weekdailyAverages = _$v.weekdailyAverages?.toBuilder();
      _monthlyAverages = _$v.monthlyAverages?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsageAveragesAggregations other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsageAveragesAggregations;
  }

  @override
  void update(void Function(WaterUsageAveragesAggregationsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsageAveragesAggregations build() {
    _$WaterUsageAveragesAggregations _$result;
    try {
      _$result = _$v ??
          new _$WaterUsageAveragesAggregations._(
              weekdayAverages: _weekdayAverages?.build(),
              weekdailyAverages: _weekdailyAverages?.build(),
              monthlyAverages: _monthlyAverages?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'weekdayAverages';
        _weekdayAverages?.build();
        _$failedField = 'weekdailyAverages';
        _weekdailyAverages?.build();
        _$failedField = 'monthlyAverages';
        _monthlyAverages?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'WaterUsageAveragesAggregations', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
