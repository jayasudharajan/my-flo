// GENERATED CODE - DO NOT MODIFY BY HAND

part of threshold;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Threshold> _$thresholdSerializer = new _$ThresholdSerializer();

class _$ThresholdSerializer implements StructuredSerializer<Threshold> {
  @override
  final Iterable<Type> types = const [Threshold, _$Threshold];
  @override
  final String wireName = 'Threshold';

  @override
  Iterable<Object> serialize(Serializers serializers, Threshold object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'okMin',
      serializers.serialize(object.okMin, specifiedType: const FullType(int)),
      'okMax',
      serializers.serialize(object.okMax, specifiedType: const FullType(int)),
      'maxValue',
      serializers.serialize(object.maxValue,
          specifiedType: const FullType(int)),
      'minValue',
      serializers.serialize(object.minValue,
          specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  Threshold deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ThresholdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'okMin':
          result.okMin = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'okMax':
          result.okMax = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'maxValue':
          result.maxValue = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'minValue':
          result.minValue = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Threshold extends Threshold {
  @override
  final int okMin;
  @override
  final int okMax;
  @override
  final int maxValue;
  @override
  final int minValue;

  factory _$Threshold([void Function(ThresholdBuilder) updates]) =>
      (new ThresholdBuilder()..update(updates)).build();

  _$Threshold._({this.okMin, this.okMax, this.maxValue, this.minValue})
      : super._() {
    if (okMin == null) {
      throw new BuiltValueNullFieldError('Threshold', 'okMin');
    }
    if (okMax == null) {
      throw new BuiltValueNullFieldError('Threshold', 'okMax');
    }
    if (maxValue == null) {
      throw new BuiltValueNullFieldError('Threshold', 'maxValue');
    }
    if (minValue == null) {
      throw new BuiltValueNullFieldError('Threshold', 'minValue');
    }
  }

  @override
  Threshold rebuild(void Function(ThresholdBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ThresholdBuilder toBuilder() => new ThresholdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Threshold &&
        okMin == other.okMin &&
        okMax == other.okMax &&
        maxValue == other.maxValue &&
        minValue == other.minValue;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, okMin.hashCode), okMax.hashCode), maxValue.hashCode),
        minValue.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Threshold')
          ..add('okMin', okMin)
          ..add('okMax', okMax)
          ..add('maxValue', maxValue)
          ..add('minValue', minValue))
        .toString();
  }
}

class ThresholdBuilder implements Builder<Threshold, ThresholdBuilder> {
  _$Threshold _$v;

  int _okMin;
  int get okMin => _$this._okMin;
  set okMin(int okMin) => _$this._okMin = okMin;

  int _okMax;
  int get okMax => _$this._okMax;
  set okMax(int okMax) => _$this._okMax = okMax;

  int _maxValue;
  int get maxValue => _$this._maxValue;
  set maxValue(int maxValue) => _$this._maxValue = maxValue;

  int _minValue;
  int get minValue => _$this._minValue;
  set minValue(int minValue) => _$this._minValue = minValue;

  ThresholdBuilder();

  ThresholdBuilder get _$this {
    if (_$v != null) {
      _okMin = _$v.okMin;
      _okMax = _$v.okMax;
      _maxValue = _$v.maxValue;
      _minValue = _$v.minValue;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Threshold other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Threshold;
  }

  @override
  void update(void Function(ThresholdBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Threshold build() {
    final _$result = _$v ??
        new _$Threshold._(
            okMin: okMin, okMax: okMax, maxValue: maxValue, minValue: minValue);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
