// GENERATED CODE - DO NOT MODIFY BY HAND

part of hardware_thresholds;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<HardwareThresholds> _$hardwareThresholdsSerializer =
    new _$HardwareThresholdsSerializer();

class _$HardwareThresholdsSerializer
    implements StructuredSerializer<HardwareThresholds> {
  @override
  final Iterable<Type> types = const [HardwareThresholds, _$HardwareThresholds];
  @override
  final String wireName = 'HardwareThresholds';

  @override
  Iterable<Object> serialize(Serializers serializers, HardwareThresholds object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.gpm != null) {
      result
        ..add('gpm')
        ..add(serializers.serialize(object.gpm,
            specifiedType: const FullType(Threshold)));
    }
    if (object.psi != null) {
      result
        ..add('psi')
        ..add(serializers.serialize(object.psi,
            specifiedType: const FullType(Threshold)));
    }
    if (object.lpm != null) {
      result
        ..add('lpm')
        ..add(serializers.serialize(object.lpm,
            specifiedType: const FullType(Threshold)));
    }
    if (object.kPa != null) {
      result
        ..add('kPa')
        ..add(serializers.serialize(object.kPa,
            specifiedType: const FullType(Threshold)));
    }
    if (object.celsius != null) {
      result
        ..add('tempC')
        ..add(serializers.serialize(object.celsius,
            specifiedType: const FullType(Threshold)));
    }
    if (object.fahrenheit != null) {
      result
        ..add('tempF')
        ..add(serializers.serialize(object.fahrenheit,
            specifiedType: const FullType(Threshold)));
    }
    return result;
  }

  @override
  HardwareThresholds deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new HardwareThresholdsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'gpm':
          result.gpm.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
        case 'psi':
          result.psi.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
        case 'lpm':
          result.lpm.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
        case 'kPa':
          result.kPa.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
        case 'tempC':
          result.celsius.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
        case 'tempF':
          result.fahrenheit.replace(serializers.deserialize(value,
              specifiedType: const FullType(Threshold)) as Threshold);
          break;
      }
    }

    return result.build();
  }
}

class _$HardwareThresholds extends HardwareThresholds {
  @override
  final Threshold gpm;
  @override
  final Threshold psi;
  @override
  final Threshold lpm;
  @override
  final Threshold kPa;
  @override
  final Threshold celsius;
  @override
  final Threshold fahrenheit;

  factory _$HardwareThresholds(
          [void Function(HardwareThresholdsBuilder) updates]) =>
      (new HardwareThresholdsBuilder()..update(updates)).build();

  _$HardwareThresholds._(
      {this.gpm, this.psi, this.lpm, this.kPa, this.celsius, this.fahrenheit})
      : super._();

  @override
  HardwareThresholds rebuild(
          void Function(HardwareThresholdsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HardwareThresholdsBuilder toBuilder() =>
      new HardwareThresholdsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HardwareThresholds &&
        gpm == other.gpm &&
        psi == other.psi &&
        lpm == other.lpm &&
        kPa == other.kPa &&
        celsius == other.celsius &&
        fahrenheit == other.fahrenheit;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, gpm.hashCode), psi.hashCode), lpm.hashCode),
                kPa.hashCode),
            celsius.hashCode),
        fahrenheit.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('HardwareThresholds')
          ..add('gpm', gpm)
          ..add('psi', psi)
          ..add('lpm', lpm)
          ..add('kPa', kPa)
          ..add('celsius', celsius)
          ..add('fahrenheit', fahrenheit))
        .toString();
  }
}

class HardwareThresholdsBuilder
    implements Builder<HardwareThresholds, HardwareThresholdsBuilder> {
  _$HardwareThresholds _$v;

  ThresholdBuilder _gpm;
  ThresholdBuilder get gpm => _$this._gpm ??= new ThresholdBuilder();
  set gpm(ThresholdBuilder gpm) => _$this._gpm = gpm;

  ThresholdBuilder _psi;
  ThresholdBuilder get psi => _$this._psi ??= new ThresholdBuilder();
  set psi(ThresholdBuilder psi) => _$this._psi = psi;

  ThresholdBuilder _lpm;
  ThresholdBuilder get lpm => _$this._lpm ??= new ThresholdBuilder();
  set lpm(ThresholdBuilder lpm) => _$this._lpm = lpm;

  ThresholdBuilder _kPa;
  ThresholdBuilder get kPa => _$this._kPa ??= new ThresholdBuilder();
  set kPa(ThresholdBuilder kPa) => _$this._kPa = kPa;

  ThresholdBuilder _celsius;
  ThresholdBuilder get celsius => _$this._celsius ??= new ThresholdBuilder();
  set celsius(ThresholdBuilder celsius) => _$this._celsius = celsius;

  ThresholdBuilder _fahrenheit;
  ThresholdBuilder get fahrenheit =>
      _$this._fahrenheit ??= new ThresholdBuilder();
  set fahrenheit(ThresholdBuilder fahrenheit) =>
      _$this._fahrenheit = fahrenheit;

  HardwareThresholdsBuilder();

  HardwareThresholdsBuilder get _$this {
    if (_$v != null) {
      _gpm = _$v.gpm?.toBuilder();
      _psi = _$v.psi?.toBuilder();
      _lpm = _$v.lpm?.toBuilder();
      _kPa = _$v.kPa?.toBuilder();
      _celsius = _$v.celsius?.toBuilder();
      _fahrenheit = _$v.fahrenheit?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HardwareThresholds other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$HardwareThresholds;
  }

  @override
  void update(void Function(HardwareThresholdsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$HardwareThresholds build() {
    _$HardwareThresholds _$result;
    try {
      _$result = _$v ??
          new _$HardwareThresholds._(
              gpm: _gpm?.build(),
              psi: _psi?.build(),
              lpm: _lpm?.build(),
              kPa: _kPa?.build(),
              celsius: _celsius?.build(),
              fahrenheit: _fahrenheit?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'gpm';
        _gpm?.build();
        _$failedField = 'psi';
        _psi?.build();
        _$failedField = 'lpm';
        _lpm?.build();
        _$failedField = 'kPa';
        _kPa?.build();
        _$failedField = 'celsius';
        _celsius?.build();
        _$failedField = 'fahrenheit';
        _fahrenheit?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'HardwareThresholds', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
