// GENERATED CODE - DO NOT MODIFY BY HAND

part of estimate_water_usage;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<EstimateWaterUsage> _$estimateWaterUsageSerializer =
    new _$EstimateWaterUsageSerializer();

class _$EstimateWaterUsageSerializer
    implements StructuredSerializer<EstimateWaterUsage> {
  @override
  final Iterable<Type> types = const [EstimateWaterUsage, _$EstimateWaterUsage];
  @override
  final String wireName = 'EstimateWaterUsage';

  @override
  Iterable<Object> serialize(Serializers serializers, EstimateWaterUsage object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.estimateLastUpdated != null) {
      result
        ..add('estimateLastUpdated')
        ..add(serializers.serialize(object.estimateLastUpdated,
            specifiedType: const FullType(String)));
    }
    if (object.estimateToday != null) {
      result
        ..add('estimateToday')
        ..add(serializers.serialize(object.estimateToday,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  EstimateWaterUsage deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new EstimateWaterUsageBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'estimateLastUpdated':
          result.estimateLastUpdated = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'estimateToday':
          result.estimateToday = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$EstimateWaterUsage extends EstimateWaterUsage {
  @override
  final String estimateLastUpdated;
  @override
  final double estimateToday;

  factory _$EstimateWaterUsage(
          [void Function(EstimateWaterUsageBuilder) updates]) =>
      (new EstimateWaterUsageBuilder()..update(updates)).build();

  _$EstimateWaterUsage._({this.estimateLastUpdated, this.estimateToday})
      : super._();

  @override
  EstimateWaterUsage rebuild(
          void Function(EstimateWaterUsageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EstimateWaterUsageBuilder toBuilder() =>
      new EstimateWaterUsageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EstimateWaterUsage &&
        estimateLastUpdated == other.estimateLastUpdated &&
        estimateToday == other.estimateToday;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc(0, estimateLastUpdated.hashCode), estimateToday.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EstimateWaterUsage')
          ..add('estimateLastUpdated', estimateLastUpdated)
          ..add('estimateToday', estimateToday))
        .toString();
  }
}

class EstimateWaterUsageBuilder
    implements Builder<EstimateWaterUsage, EstimateWaterUsageBuilder> {
  _$EstimateWaterUsage _$v;

  String _estimateLastUpdated;
  String get estimateLastUpdated => _$this._estimateLastUpdated;
  set estimateLastUpdated(String estimateLastUpdated) =>
      _$this._estimateLastUpdated = estimateLastUpdated;

  double _estimateToday;
  double get estimateToday => _$this._estimateToday;
  set estimateToday(double estimateToday) =>
      _$this._estimateToday = estimateToday;

  EstimateWaterUsageBuilder();

  EstimateWaterUsageBuilder get _$this {
    if (_$v != null) {
      _estimateLastUpdated = _$v.estimateLastUpdated;
      _estimateToday = _$v.estimateToday;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EstimateWaterUsage other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$EstimateWaterUsage;
  }

  @override
  void update(void Function(EstimateWaterUsageBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EstimateWaterUsage build() {
    final _$result = _$v ??
        new _$EstimateWaterUsage._(
            estimateLastUpdated: estimateLastUpdated,
            estimateToday: estimateToday);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
