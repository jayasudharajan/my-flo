// GENERATED CODE - DO NOT MODIFY BY HAND

part of weekday_averages;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WeekdayAverages> _$weekdayAveragesSerializer =
    new _$WeekdayAveragesSerializer();

class _$WeekdayAveragesSerializer
    implements StructuredSerializer<WeekdayAverages> {
  @override
  final Iterable<Type> types = const [WeekdayAverages, _$WeekdayAverages];
  @override
  final String wireName = 'WeekdayAverages';

  @override
  Iterable<Object> serialize(Serializers serializers, WeekdayAverages object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.value != null) {
      result
        ..add('value')
        ..add(serializers.serialize(object.value,
            specifiedType: const FullType(double)));
    }
    if (object.dayOfWeek != null) {
      result
        ..add('dayOfWeek')
        ..add(serializers.serialize(object.dayOfWeek,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  WeekdayAverages deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WeekdayAveragesBuilder();

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
        case 'dayOfWeek':
          result.dayOfWeek = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$WeekdayAverages extends WeekdayAverages {
  @override
  final double value;
  @override
  final int dayOfWeek;

  factory _$WeekdayAverages([void Function(WeekdayAveragesBuilder) updates]) =>
      (new WeekdayAveragesBuilder()..update(updates)).build();

  _$WeekdayAverages._({this.value, this.dayOfWeek}) : super._();

  @override
  WeekdayAverages rebuild(void Function(WeekdayAveragesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WeekdayAveragesBuilder toBuilder() =>
      new WeekdayAveragesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeekdayAverages &&
        value == other.value &&
        dayOfWeek == other.dayOfWeek;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, value.hashCode), dayOfWeek.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WeekdayAverages')
          ..add('value', value)
          ..add('dayOfWeek', dayOfWeek))
        .toString();
  }
}

class WeekdayAveragesBuilder
    implements Builder<WeekdayAverages, WeekdayAveragesBuilder> {
  _$WeekdayAverages _$v;

  double _value;
  double get value => _$this._value;
  set value(double value) => _$this._value = value;

  int _dayOfWeek;
  int get dayOfWeek => _$this._dayOfWeek;
  set dayOfWeek(int dayOfWeek) => _$this._dayOfWeek = dayOfWeek;

  WeekdayAveragesBuilder();

  WeekdayAveragesBuilder get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _dayOfWeek = _$v.dayOfWeek;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeekdayAverages other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WeekdayAverages;
  }

  @override
  void update(void Function(WeekdayAveragesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WeekdayAverages build() {
    final _$result =
        _$v ?? new _$WeekdayAverages._(value: value, dayOfWeek: dayOfWeek);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
