// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_settings;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertSettings> _$alertSettingsSerializer =
    new _$AlertSettingsSerializer();

class _$AlertSettingsSerializer implements StructuredSerializer<AlertSettings> {
  @override
  final Iterable<Type> types = const [AlertSettings, _$AlertSettings];
  @override
  final String wireName = 'AlertSettings';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertSettings object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.alarmId != null) {
      result
        ..add('alarmId')
        ..add(serializers.serialize(object.alarmId,
            specifiedType: const FullType(int)));
    }
    if (object.systemMode != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(String)));
    }
    if (object.smsEnabled != null) {
      result
        ..add('smsEnabled')
        ..add(serializers.serialize(object.smsEnabled,
            specifiedType: const FullType(bool)));
    }
    if (object.emailEnabled != null) {
      result
        ..add('emailEnabled')
        ..add(serializers.serialize(object.emailEnabled,
            specifiedType: const FullType(bool)));
    }
    if (object.pushEnabled != null) {
      result
        ..add('pushEnabled')
        ..add(serializers.serialize(object.pushEnabled,
            specifiedType: const FullType(bool)));
    }
    if (object.callEnabled != null) {
      result
        ..add('callEnabled')
        ..add(serializers.serialize(object.callEnabled,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  AlertSettings deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertSettingsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'alarmId':
          result.alarmId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'systemMode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'smsEnabled':
          result.smsEnabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'emailEnabled':
          result.emailEnabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'pushEnabled':
          result.pushEnabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'callEnabled':
          result.callEnabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$AlertSettings extends AlertSettings {
  @override
  final int alarmId;
  @override
  final String systemMode;
  @override
  final bool smsEnabled;
  @override
  final bool emailEnabled;
  @override
  final bool pushEnabled;
  @override
  final bool callEnabled;

  factory _$AlertSettings([void Function(AlertSettingsBuilder) updates]) =>
      (new AlertSettingsBuilder()..update(updates)).build();

  _$AlertSettings._(
      {this.alarmId,
      this.systemMode,
      this.smsEnabled,
      this.emailEnabled,
      this.pushEnabled,
      this.callEnabled})
      : super._();

  @override
  AlertSettings rebuild(void Function(AlertSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertSettingsBuilder toBuilder() => new AlertSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertSettings &&
        alarmId == other.alarmId &&
        systemMode == other.systemMode &&
        smsEnabled == other.smsEnabled &&
        emailEnabled == other.emailEnabled &&
        pushEnabled == other.pushEnabled &&
        callEnabled == other.callEnabled;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, alarmId.hashCode), systemMode.hashCode),
                    smsEnabled.hashCode),
                emailEnabled.hashCode),
            pushEnabled.hashCode),
        callEnabled.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertSettings')
          ..add('alarmId', alarmId)
          ..add('systemMode', systemMode)
          ..add('smsEnabled', smsEnabled)
          ..add('emailEnabled', emailEnabled)
          ..add('pushEnabled', pushEnabled)
          ..add('callEnabled', callEnabled))
        .toString();
  }
}

class AlertSettingsBuilder
    implements Builder<AlertSettings, AlertSettingsBuilder> {
  _$AlertSettings _$v;

  int _alarmId;
  int get alarmId => _$this._alarmId;
  set alarmId(int alarmId) => _$this._alarmId = alarmId;

  String _systemMode;
  String get systemMode => _$this._systemMode;
  set systemMode(String systemMode) => _$this._systemMode = systemMode;

  bool _smsEnabled;
  bool get smsEnabled => _$this._smsEnabled;
  set smsEnabled(bool smsEnabled) => _$this._smsEnabled = smsEnabled;

  bool _emailEnabled;
  bool get emailEnabled => _$this._emailEnabled;
  set emailEnabled(bool emailEnabled) => _$this._emailEnabled = emailEnabled;

  bool _pushEnabled;
  bool get pushEnabled => _$this._pushEnabled;
  set pushEnabled(bool pushEnabled) => _$this._pushEnabled = pushEnabled;

  bool _callEnabled;
  bool get callEnabled => _$this._callEnabled;
  set callEnabled(bool callEnabled) => _$this._callEnabled = callEnabled;

  AlertSettingsBuilder();

  AlertSettingsBuilder get _$this {
    if (_$v != null) {
      _alarmId = _$v.alarmId;
      _systemMode = _$v.systemMode;
      _smsEnabled = _$v.smsEnabled;
      _emailEnabled = _$v.emailEnabled;
      _pushEnabled = _$v.pushEnabled;
      _callEnabled = _$v.callEnabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertSettings other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertSettings;
  }

  @override
  void update(void Function(AlertSettingsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertSettings build() {
    final _$result = _$v ??
        new _$AlertSettings._(
            alarmId: alarmId,
            systemMode: systemMode,
            smsEnabled: smsEnabled,
            emailEnabled: emailEnabled,
            pushEnabled: pushEnabled,
            callEnabled: callEnabled);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
