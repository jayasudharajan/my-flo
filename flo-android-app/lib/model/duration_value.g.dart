// GENERATED CODE - DO NOT MODIFY BY HAND

part of duration_value;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DurationValue> _$durationValueSerializer =
    new _$DurationValueSerializer();

class _$DurationValueSerializer implements StructuredSerializer<DurationValue> {
  @override
  final Iterable<Type> types = const [DurationValue, _$DurationValue];
  @override
  final String wireName = 'DurationValue';

  @override
  Iterable<Object> serialize(Serializers serializers, DurationValue object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.value != null) {
      result
        ..add('value')
        ..add(serializers.serialize(object.value,
            specifiedType: const FullType(double)));
    }
    if (object.startDate != null) {
      result
        ..add('startDate')
        ..add(serializers.serialize(object.startDate,
            specifiedType: const FullType(String)));
    }
    if (object.endDate != null) {
      result
        ..add('endDate')
        ..add(serializers.serialize(object.endDate,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  DurationValue deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DurationValueBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'value':
          result.value = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'startDate':
          result.startDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'endDate':
          result.endDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$DurationValue extends DurationValue {
  @override
  final double value;
  @override
  final String startDate;
  @override
  final String endDate;

  factory _$DurationValue([void Function(DurationValueBuilder) updates]) =>
      (new DurationValueBuilder()..update(updates)).build();

  _$DurationValue._({this.value, this.startDate, this.endDate}) : super._();

  @override
  DurationValue rebuild(void Function(DurationValueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DurationValueBuilder toBuilder() => new DurationValueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DurationValue &&
        value == other.value &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, value.hashCode), startDate.hashCode), endDate.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DurationValue')
          ..add('value', value)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class DurationValueBuilder
    implements Builder<DurationValue, DurationValueBuilder> {
  _$DurationValue _$v;

  double _value;
  double get value => _$this._value;
  set value(double value) => _$this._value = value;

  String _startDate;
  String get startDate => _$this._startDate;
  set startDate(String startDate) => _$this._startDate = startDate;

  String _endDate;
  String get endDate => _$this._endDate;
  set endDate(String endDate) => _$this._endDate = endDate;

  DurationValueBuilder();

  DurationValueBuilder get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _startDate = _$v.startDate;
      _endDate = _$v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DurationValue other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DurationValue;
  }

  @override
  void update(void Function(DurationValueBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DurationValue build() {
    final _$result = _$v ??
        new _$DurationValue._(
            value: value, startDate: startDate, endDate: endDate);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
