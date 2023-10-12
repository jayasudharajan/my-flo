// GENERATED CODE - DO NOT MODIFY BY HAND

part of alerts_settings;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertsSettings> _$alertsSettingsSerializer =
    new _$AlertsSettingsSerializer();

class _$AlertsSettingsSerializer
    implements StructuredSerializer<AlertsSettings> {
  @override
  final Iterable<Type> types = const [AlertsSettings, _$AlertsSettings];
  @override
  final String wireName = 'AlertsSettings';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertsSettings object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType: const FullType(
                BuiltList, const [const FullType(DeviceAlertsSettings)])));
    }
    return result;
  }

  @override
  AlertsSettings deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertsSettingsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(DeviceAlertsSettings)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertsSettings extends AlertsSettings {
  @override
  final BuiltList<DeviceAlertsSettings> items;

  factory _$AlertsSettings([void Function(AlertsSettingsBuilder) updates]) =>
      (new AlertsSettingsBuilder()..update(updates)).build();

  _$AlertsSettings._({this.items}) : super._();

  @override
  AlertsSettings rebuild(void Function(AlertsSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertsSettingsBuilder toBuilder() =>
      new AlertsSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertsSettings && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertsSettings')..add('items', items))
        .toString();
  }
}

class AlertsSettingsBuilder
    implements Builder<AlertsSettings, AlertsSettingsBuilder> {
  _$AlertsSettings _$v;

  ListBuilder<DeviceAlertsSettings> _items;
  ListBuilder<DeviceAlertsSettings> get items =>
      _$this._items ??= new ListBuilder<DeviceAlertsSettings>();
  set items(ListBuilder<DeviceAlertsSettings> items) => _$this._items = items;

  AlertsSettingsBuilder();

  AlertsSettingsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertsSettings other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertsSettings;
  }

  @override
  void update(void Function(AlertsSettingsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertsSettings build() {
    _$AlertsSettings _$result;
    try {
      _$result = _$v ?? new _$AlertsSettings._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertsSettings', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
