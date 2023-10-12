// GENERATED CODE - DO NOT MODIFY BY HAND

part of delivery_medium_settings;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DeliveryMediumSettings> _$deliveryMediumSettingsSerializer =
    new _$DeliveryMediumSettingsSerializer();

class _$DeliveryMediumSettingsSerializer
    implements StructuredSerializer<DeliveryMediumSettings> {
  @override
  final Iterable<Type> types = const [
    DeliveryMediumSettings,
    _$DeliveryMediumSettings
  ];
  @override
  final String wireName = 'DeliveryMediumSettings';

  @override
  Iterable<Object> serialize(
      Serializers serializers, DeliveryMediumSettings object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.systemMode != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(String)));
    }
    if (object.enabled != null) {
      result
        ..add('enabled')
        ..add(serializers.serialize(object.enabled,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  DeliveryMediumSettings deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeliveryMediumSettingsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'systemMode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'enabled':
          result.enabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$DeliveryMediumSettings extends DeliveryMediumSettings {
  @override
  final String systemMode;
  @override
  final bool enabled;

  factory _$DeliveryMediumSettings(
          [void Function(DeliveryMediumSettingsBuilder) updates]) =>
      (new DeliveryMediumSettingsBuilder()..update(updates)).build();

  _$DeliveryMediumSettings._({this.systemMode, this.enabled}) : super._();

  @override
  DeliveryMediumSettings rebuild(
          void Function(DeliveryMediumSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeliveryMediumSettingsBuilder toBuilder() =>
      new DeliveryMediumSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeliveryMediumSettings &&
        systemMode == other.systemMode &&
        enabled == other.enabled;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, systemMode.hashCode), enabled.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeliveryMediumSettings')
          ..add('systemMode', systemMode)
          ..add('enabled', enabled))
        .toString();
  }
}

class DeliveryMediumSettingsBuilder
    implements Builder<DeliveryMediumSettings, DeliveryMediumSettingsBuilder> {
  _$DeliveryMediumSettings _$v;

  String _systemMode;
  String get systemMode => _$this._systemMode;
  set systemMode(String systemMode) => _$this._systemMode = systemMode;

  bool _enabled;
  bool get enabled => _$this._enabled;
  set enabled(bool enabled) => _$this._enabled = enabled;

  DeliveryMediumSettingsBuilder();

  DeliveryMediumSettingsBuilder get _$this {
    if (_$v != null) {
      _systemMode = _$v.systemMode;
      _enabled = _$v.enabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeliveryMediumSettings other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DeliveryMediumSettings;
  }

  @override
  void update(void Function(DeliveryMediumSettingsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DeliveryMediumSettings build() {
    final _$result = _$v ??
        new _$DeliveryMediumSettings._(
            systemMode: systemMode, enabled: enabled);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
