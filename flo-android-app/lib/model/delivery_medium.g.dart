// GENERATED CODE - DO NOT MODIFY BY HAND

part of delivery_medium;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DeliveryMedium> _$deliveryMediumSerializer =
    new _$DeliveryMediumSerializer();

class _$DeliveryMediumSerializer
    implements StructuredSerializer<DeliveryMedium> {
  @override
  final Iterable<Type> types = const [DeliveryMedium, _$DeliveryMedium];
  @override
  final String wireName = 'DeliveryMedium';

  @override
  Iterable<Object> serialize(Serializers serializers, DeliveryMedium object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.supported != null) {
      result
        ..add('supported')
        ..add(serializers.serialize(object.supported,
            specifiedType: const FullType(bool)));
    }
    if (object.defaultSettings != null) {
      result
        ..add('defaultSettings')
        ..add(serializers.serialize(object.defaultSettings,
            specifiedType: const FullType(
                BuiltList, const [const FullType(DeliveryMediumSettings)])));
    }
    return result;
  }

  @override
  DeliveryMedium deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeliveryMediumBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'supported':
          result.supported = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'defaultSettings':
          result.defaultSettings.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(DeliveryMediumSettings)
              ])) as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$DeliveryMedium extends DeliveryMedium {
  @override
  final bool supported;
  @override
  final BuiltList<DeliveryMediumSettings> defaultSettings;

  factory _$DeliveryMedium([void Function(DeliveryMediumBuilder) updates]) =>
      (new DeliveryMediumBuilder()..update(updates)).build();

  _$DeliveryMedium._({this.supported, this.defaultSettings}) : super._();

  @override
  DeliveryMedium rebuild(void Function(DeliveryMediumBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeliveryMediumBuilder toBuilder() =>
      new DeliveryMediumBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeliveryMedium &&
        supported == other.supported &&
        defaultSettings == other.defaultSettings;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, supported.hashCode), defaultSettings.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeliveryMedium')
          ..add('supported', supported)
          ..add('defaultSettings', defaultSettings))
        .toString();
  }
}

class DeliveryMediumBuilder
    implements Builder<DeliveryMedium, DeliveryMediumBuilder> {
  _$DeliveryMedium _$v;

  bool _supported;
  bool get supported => _$this._supported;
  set supported(bool supported) => _$this._supported = supported;

  ListBuilder<DeliveryMediumSettings> _defaultSettings;
  ListBuilder<DeliveryMediumSettings> get defaultSettings =>
      _$this._defaultSettings ??= new ListBuilder<DeliveryMediumSettings>();
  set defaultSettings(ListBuilder<DeliveryMediumSettings> defaultSettings) =>
      _$this._defaultSettings = defaultSettings;

  DeliveryMediumBuilder();

  DeliveryMediumBuilder get _$this {
    if (_$v != null) {
      _supported = _$v.supported;
      _defaultSettings = _$v.defaultSettings?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeliveryMedium other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DeliveryMedium;
  }

  @override
  void update(void Function(DeliveryMediumBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DeliveryMedium build() {
    _$DeliveryMedium _$result;
    try {
      _$result = _$v ??
          new _$DeliveryMedium._(
              supported: supported, defaultSettings: _defaultSettings?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'defaultSettings';
        _defaultSettings?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DeliveryMedium', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
