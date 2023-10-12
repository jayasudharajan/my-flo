// GENERATED CODE - DO NOT MODIFY BY HAND

part of telemetry2;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Telemetry2> _$telemetry2Serializer = new _$Telemetry2Serializer();

class _$Telemetry2Serializer implements StructuredSerializer<Telemetry2> {
  @override
  final Iterable<Type> types = const [Telemetry2, _$Telemetry2];
  @override
  final String wireName = 'Telemetry2';

  @override
  Iterable<Object> serialize(Serializers serializers, Telemetry2 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.flow != null) {
      result
        ..add('gpm')
        ..add(serializers.serialize(object.flow,
            specifiedType: const FullType(double)));
    }
    if (object.pressure != null) {
      result
        ..add('psi')
        ..add(serializers.serialize(object.pressure,
            specifiedType: const FullType(double)));
    }
    if (object.fahrenheit != null) {
      result
        ..add('tempF')
        ..add(serializers.serialize(object.fahrenheit,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  Telemetry2 deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new Telemetry2Builder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'gpm':
          result.flow = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'psi':
          result.pressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'tempF':
          result.fahrenheit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$Telemetry2 extends Telemetry2 {
  @override
  final double flow;
  @override
  final double pressure;
  @override
  final double fahrenheit;
  @override
  final String updated;

  factory _$Telemetry2([void Function(Telemetry2Builder) updates]) =>
      (new Telemetry2Builder()..update(updates)).build();

  _$Telemetry2._({this.flow, this.pressure, this.fahrenheit, this.updated})
      : super._();

  @override
  Telemetry2 rebuild(void Function(Telemetry2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Telemetry2Builder toBuilder() => new Telemetry2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Telemetry2 &&
        flow == other.flow &&
        pressure == other.pressure &&
        fahrenheit == other.fahrenheit &&
        updated == other.updated;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, flow.hashCode), pressure.hashCode), fahrenheit.hashCode),
        updated.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Telemetry2')
          ..add('flow', flow)
          ..add('pressure', pressure)
          ..add('fahrenheit', fahrenheit)
          ..add('updated', updated))
        .toString();
  }
}

class Telemetry2Builder implements Builder<Telemetry2, Telemetry2Builder> {
  _$Telemetry2 _$v;

  double _flow;
  double get flow => _$this._flow;
  set flow(double flow) => _$this._flow = flow;

  double _pressure;
  double get pressure => _$this._pressure;
  set pressure(double pressure) => _$this._pressure = pressure;

  double _fahrenheit;
  double get fahrenheit => _$this._fahrenheit;
  set fahrenheit(double fahrenheit) => _$this._fahrenheit = fahrenheit;

  String _updated;
  String get updated => _$this._updated;
  set updated(String updated) => _$this._updated = updated;

  Telemetry2Builder();

  Telemetry2Builder get _$this {
    if (_$v != null) {
      _flow = _$v.flow;
      _pressure = _$v.pressure;
      _fahrenheit = _$v.fahrenheit;
      _updated = _$v.updated;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Telemetry2 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Telemetry2;
  }

  @override
  void update(void Function(Telemetry2Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Telemetry2 build() {
    final _$result = _$v ??
        new _$Telemetry2._(
            flow: flow,
            pressure: pressure,
            fahrenheit: fahrenheit,
            updated: updated);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
