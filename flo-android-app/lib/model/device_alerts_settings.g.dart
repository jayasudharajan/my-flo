// GENERATED CODE - DO NOT MODIFY BY HAND

part of device_alerts_settings;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DeviceAlertsSettings> _$deviceAlertsSettingsSerializer =
    new _$DeviceAlertsSettingsSerializer();

class _$DeviceAlertsSettingsSerializer
    implements StructuredSerializer<DeviceAlertsSettings> {
  @override
  final Iterable<Type> types = const [
    DeviceAlertsSettings,
    _$DeviceAlertsSettings
  ];
  @override
  final String wireName = 'DeviceAlertsSettings';

  @override
  Iterable<Object> serialize(
      Serializers serializers, DeviceAlertsSettings object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.settings != null) {
      result
        ..add('settings')
        ..add(serializers.serialize(object.settings,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlertSettings)])));
    }
    if (object.smallDripSensitivity != null) {
      result
        ..add('smallDripSensitivity')
        ..add(serializers.serialize(object.smallDripSensitivity,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  DeviceAlertsSettings deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeviceAlertsSettingsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'settings':
          result.settings.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlertSettings)]))
              as BuiltList<dynamic>);
          break;
        case 'smallDripSensitivity':
          result.smallDripSensitivity = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$DeviceAlertsSettings extends DeviceAlertsSettings {
  @override
  final String deviceId;
  @override
  final BuiltList<AlertSettings> settings;
  @override
  final int smallDripSensitivity;

  factory _$DeviceAlertsSettings(
          [void Function(DeviceAlertsSettingsBuilder) updates]) =>
      (new DeviceAlertsSettingsBuilder()..update(updates)).build();

  _$DeviceAlertsSettings._(
      {this.deviceId, this.settings, this.smallDripSensitivity})
      : super._();

  @override
  DeviceAlertsSettings rebuild(
          void Function(DeviceAlertsSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceAlertsSettingsBuilder toBuilder() =>
      new DeviceAlertsSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceAlertsSettings &&
        deviceId == other.deviceId &&
        settings == other.settings &&
        smallDripSensitivity == other.smallDripSensitivity;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, deviceId.hashCode), settings.hashCode),
        smallDripSensitivity.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeviceAlertsSettings')
          ..add('deviceId', deviceId)
          ..add('settings', settings)
          ..add('smallDripSensitivity', smallDripSensitivity))
        .toString();
  }
}

class DeviceAlertsSettingsBuilder
    implements Builder<DeviceAlertsSettings, DeviceAlertsSettingsBuilder> {
  _$DeviceAlertsSettings _$v;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  ListBuilder<AlertSettings> _settings;
  ListBuilder<AlertSettings> get settings =>
      _$this._settings ??= new ListBuilder<AlertSettings>();
  set settings(ListBuilder<AlertSettings> settings) =>
      _$this._settings = settings;

  int _smallDripSensitivity;
  int get smallDripSensitivity => _$this._smallDripSensitivity;
  set smallDripSensitivity(int smallDripSensitivity) =>
      _$this._smallDripSensitivity = smallDripSensitivity;

  DeviceAlertsSettingsBuilder();

  DeviceAlertsSettingsBuilder get _$this {
    if (_$v != null) {
      _deviceId = _$v.deviceId;
      _settings = _$v.settings?.toBuilder();
      _smallDripSensitivity = _$v.smallDripSensitivity;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceAlertsSettings other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DeviceAlertsSettings;
  }

  @override
  void update(void Function(DeviceAlertsSettingsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DeviceAlertsSettings build() {
    _$DeviceAlertsSettings _$result;
    try {
      _$result = _$v ??
          new _$DeviceAlertsSettings._(
              deviceId: deviceId,
              settings: _settings?.build(),
              smallDripSensitivity: smallDripSensitivity);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'settings';
        _settings?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DeviceAlertsSettings', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
