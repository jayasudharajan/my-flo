// GENERATED CODE - DO NOT MODIFY BY HAND

part of icd;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Icd> _$icdSerializer = new _$IcdSerializer();

class _$IcdSerializer implements StructuredSerializer<Icd> {
  @override
  final Iterable<Type> types = const [Icd, _$Icd];
  @override
  final String wireName = 'Icd';

  @override
  Iterable<Object> serialize(Serializers serializers, Icd object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.deviceId != null) {
      result
        ..add('device_id')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.timeZone != null) {
      result
        ..add('time_zone')
        ..add(serializers.serialize(object.timeZone,
            specifiedType: const FullType(String)));
    }
    if (object.icdId != null) {
      result
        ..add('icd_id')
        ..add(serializers.serialize(object.icdId,
            specifiedType: const FullType(String)));
    }
    if (object.systemMode != null) {
      result
        ..add('system_mode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  Icd deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new IcdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'device_id':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'time_zone':
          result.timeZone = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'icd_id':
          result.icdId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'system_mode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Icd extends Icd {
  @override
  final String deviceId;
  @override
  final String timeZone;
  @override
  final String icdId;
  @override
  final int systemMode;

  factory _$Icd([void Function(IcdBuilder) updates]) =>
      (new IcdBuilder()..update(updates)).build();

  _$Icd._({this.deviceId, this.timeZone, this.icdId, this.systemMode})
      : super._();

  @override
  Icd rebuild(void Function(IcdBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IcdBuilder toBuilder() => new IcdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Icd &&
        deviceId == other.deviceId &&
        timeZone == other.timeZone &&
        icdId == other.icdId &&
        systemMode == other.systemMode;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, deviceId.hashCode), timeZone.hashCode), icdId.hashCode),
        systemMode.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Icd')
          ..add('deviceId', deviceId)
          ..add('timeZone', timeZone)
          ..add('icdId', icdId)
          ..add('systemMode', systemMode))
        .toString();
  }
}

class IcdBuilder implements Builder<Icd, IcdBuilder> {
  _$Icd _$v;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _timeZone;
  String get timeZone => _$this._timeZone;
  set timeZone(String timeZone) => _$this._timeZone = timeZone;

  String _icdId;
  String get icdId => _$this._icdId;
  set icdId(String icdId) => _$this._icdId = icdId;

  int _systemMode;
  int get systemMode => _$this._systemMode;
  set systemMode(int systemMode) => _$this._systemMode = systemMode;

  IcdBuilder();

  IcdBuilder get _$this {
    if (_$v != null) {
      _deviceId = _$v.deviceId;
      _timeZone = _$v.timeZone;
      _icdId = _$v.icdId;
      _systemMode = _$v.systemMode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Icd other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Icd;
  }

  @override
  void update(void Function(IcdBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Icd build() {
    final _$result = _$v ??
        new _$Icd._(
            deviceId: deviceId,
            timeZone: timeZone,
            icdId: icdId,
            systemMode: systemMode);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
