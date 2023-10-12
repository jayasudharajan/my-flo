// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_firmware_value;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFirmwareValue> _$alertFirmwareValueSerializer =
    new _$AlertFirmwareValueSerializer();

class _$AlertFirmwareValueSerializer
    implements StructuredSerializer<AlertFirmwareValue> {
  @override
  final Iterable<Type> types = const [AlertFirmwareValue, _$AlertFirmwareValue];
  @override
  final String wireName = 'AlertFirmwareValue';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertFirmwareValue object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.gpm != null) {
      result
        ..add('gpm')
        ..add(serializers.serialize(object.gpm,
            specifiedType: const FullType(double)));
    }
    if (object.galUsed != null) {
      result
        ..add('galUsed')
        ..add(serializers.serialize(object.galUsed,
            specifiedType: const FullType(double)));
    }
    if (object.psiDelta != null) {
      result
        ..add('psiDelta')
        ..add(serializers.serialize(object.psiDelta,
            specifiedType: const FullType(double)));
    }
    if (object.leakLossMinGal != null) {
      result
        ..add('leakLossMinGal')
        ..add(serializers.serialize(object.leakLossMinGal,
            specifiedType: const FullType(double)));
    }
    if (object.leakLossMaxGal != null) {
      result
        ..add('leakLossMaxGal')
        ..add(serializers.serialize(object.leakLossMaxGal,
            specifiedType: const FullType(double)));
    }
    if (object.flowEventDurationInSeconds != null) {
      result
        ..add('flowEventDuration')
        ..add(serializers.serialize(object.flowEventDurationInSeconds,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  AlertFirmwareValue deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFirmwareValueBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'gpm':
          result.gpm = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'galUsed':
          result.galUsed = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'psiDelta':
          result.psiDelta = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'leakLossMinGal':
          result.leakLossMinGal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'leakLossMaxGal':
          result.leakLossMaxGal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'flowEventDuration':
          result.flowEventDurationInSeconds = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFirmwareValue extends AlertFirmwareValue {
  @override
  final double gpm;
  @override
  final double galUsed;
  @override
  final double psiDelta;
  @override
  final double leakLossMinGal;
  @override
  final double leakLossMaxGal;
  @override
  final double flowEventDurationInSeconds;

  factory _$AlertFirmwareValue(
          [void Function(AlertFirmwareValueBuilder) updates]) =>
      (new AlertFirmwareValueBuilder()..update(updates)).build();

  _$AlertFirmwareValue._(
      {this.gpm,
      this.galUsed,
      this.psiDelta,
      this.leakLossMinGal,
      this.leakLossMaxGal,
      this.flowEventDurationInSeconds})
      : super._();

  @override
  AlertFirmwareValue rebuild(
          void Function(AlertFirmwareValueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFirmwareValueBuilder toBuilder() =>
      new AlertFirmwareValueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFirmwareValue &&
        gpm == other.gpm &&
        galUsed == other.galUsed &&
        psiDelta == other.psiDelta &&
        leakLossMinGal == other.leakLossMinGal &&
        leakLossMaxGal == other.leakLossMaxGal &&
        flowEventDurationInSeconds == other.flowEventDurationInSeconds;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, gpm.hashCode), galUsed.hashCode),
                    psiDelta.hashCode),
                leakLossMinGal.hashCode),
            leakLossMaxGal.hashCode),
        flowEventDurationInSeconds.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFirmwareValue')
          ..add('gpm', gpm)
          ..add('galUsed', galUsed)
          ..add('psiDelta', psiDelta)
          ..add('leakLossMinGal', leakLossMinGal)
          ..add('leakLossMaxGal', leakLossMaxGal)
          ..add('flowEventDurationInSeconds', flowEventDurationInSeconds))
        .toString();
  }
}

class AlertFirmwareValueBuilder
    implements Builder<AlertFirmwareValue, AlertFirmwareValueBuilder> {
  _$AlertFirmwareValue _$v;

  double _gpm;
  double get gpm => _$this._gpm;
  set gpm(double gpm) => _$this._gpm = gpm;

  double _galUsed;
  double get galUsed => _$this._galUsed;
  set galUsed(double galUsed) => _$this._galUsed = galUsed;

  double _psiDelta;
  double get psiDelta => _$this._psiDelta;
  set psiDelta(double psiDelta) => _$this._psiDelta = psiDelta;

  double _leakLossMinGal;
  double get leakLossMinGal => _$this._leakLossMinGal;
  set leakLossMinGal(double leakLossMinGal) =>
      _$this._leakLossMinGal = leakLossMinGal;

  double _leakLossMaxGal;
  double get leakLossMaxGal => _$this._leakLossMaxGal;
  set leakLossMaxGal(double leakLossMaxGal) =>
      _$this._leakLossMaxGal = leakLossMaxGal;

  double _flowEventDurationInSeconds;
  double get flowEventDurationInSeconds => _$this._flowEventDurationInSeconds;
  set flowEventDurationInSeconds(double flowEventDurationInSeconds) =>
      _$this._flowEventDurationInSeconds = flowEventDurationInSeconds;

  AlertFirmwareValueBuilder();

  AlertFirmwareValueBuilder get _$this {
    if (_$v != null) {
      _gpm = _$v.gpm;
      _galUsed = _$v.galUsed;
      _psiDelta = _$v.psiDelta;
      _leakLossMinGal = _$v.leakLossMinGal;
      _leakLossMaxGal = _$v.leakLossMaxGal;
      _flowEventDurationInSeconds = _$v.flowEventDurationInSeconds;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFirmwareValue other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFirmwareValue;
  }

  @override
  void update(void Function(AlertFirmwareValueBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFirmwareValue build() {
    final _$result = _$v ??
        new _$AlertFirmwareValue._(
            gpm: gpm,
            galUsed: galUsed,
            psiDelta: psiDelta,
            leakLossMinGal: leakLossMinGal,
            leakLossMaxGal: leakLossMaxGal,
            flowEventDurationInSeconds: flowEventDurationInSeconds);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
