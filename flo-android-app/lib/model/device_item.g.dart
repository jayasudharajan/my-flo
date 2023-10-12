// GENERATED CODE - DO NOT MODIFY BY HAND

part of device_item;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DeviceItem> _$deviceItemSerializer = new _$DeviceItemSerializer();

class _$DeviceItemSerializer implements StructuredSerializer<DeviceItem> {
  @override
  final Iterable<Type> types = const [DeviceItem, _$DeviceItem];
  @override
  final String wireName = 'DeviceItem';

  @override
  Iterable<Object> serialize(Serializers serializers, DeviceItem object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.type != null) {
      result
        ..add('type')
        ..add(serializers.serialize(object.type,
            specifiedType: const FullType(Item)));
    }
    if (object.key != null) {
      result
        ..add('key')
        ..add(serializers.serialize(object.key,
            specifiedType: const FullType(String)));
    }
    if (object.shortDisplay != null) {
      result
        ..add('shortDisplay')
        ..add(serializers.serialize(object.shortDisplay,
            specifiedType: const FullType(String)));
    }
    if (object.longDisplay != null) {
      result
        ..add('longDisplay')
        ..add(serializers.serialize(object.longDisplay,
            specifiedType: const FullType(String)));
    }
    if (object.language != null) {
      result
        ..add('lang')
        ..add(serializers.serialize(object.language,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  DeviceItem deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeviceItemBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'type':
          result.type.replace(serializers.deserialize(value,
              specifiedType: const FullType(Item)) as Item);
          break;
        case 'key':
          result.key = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'shortDisplay':
          result.shortDisplay = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'longDisplay':
          result.longDisplay = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'lang':
          result.language = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$DeviceItem extends DeviceItem {
  @override
  final Item type;
  @override
  final String key;
  @override
  final String shortDisplay;
  @override
  final String longDisplay;
  @override
  final String language;

  factory _$DeviceItem([void Function(DeviceItemBuilder) updates]) =>
      (new DeviceItemBuilder()..update(updates)).build();

  _$DeviceItem._(
      {this.type, this.key, this.shortDisplay, this.longDisplay, this.language})
      : super._();

  @override
  DeviceItem rebuild(void Function(DeviceItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceItemBuilder toBuilder() => new DeviceItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceItem &&
        type == other.type &&
        key == other.key &&
        shortDisplay == other.shortDisplay &&
        longDisplay == other.longDisplay &&
        language == other.language;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, type.hashCode), key.hashCode),
                shortDisplay.hashCode),
            longDisplay.hashCode),
        language.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeviceItem')
          ..add('type', type)
          ..add('key', key)
          ..add('shortDisplay', shortDisplay)
          ..add('longDisplay', longDisplay)
          ..add('language', language))
        .toString();
  }
}

class DeviceItemBuilder implements Builder<DeviceItem, DeviceItemBuilder> {
  _$DeviceItem _$v;

  ItemBuilder _type;
  ItemBuilder get type => _$this._type ??= new ItemBuilder();
  set type(ItemBuilder type) => _$this._type = type;

  String _key;
  String get key => _$this._key;
  set key(String key) => _$this._key = key;

  String _shortDisplay;
  String get shortDisplay => _$this._shortDisplay;
  set shortDisplay(String shortDisplay) => _$this._shortDisplay = shortDisplay;

  String _longDisplay;
  String get longDisplay => _$this._longDisplay;
  set longDisplay(String longDisplay) => _$this._longDisplay = longDisplay;

  String _language;
  String get language => _$this._language;
  set language(String language) => _$this._language = language;

  DeviceItemBuilder();

  DeviceItemBuilder get _$this {
    if (_$v != null) {
      _type = _$v.type?.toBuilder();
      _key = _$v.key;
      _shortDisplay = _$v.shortDisplay;
      _longDisplay = _$v.longDisplay;
      _language = _$v.language;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceItem other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DeviceItem;
  }

  @override
  void update(void Function(DeviceItemBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DeviceItem build() {
    _$DeviceItem _$result;
    try {
      _$result = _$v ??
          new _$DeviceItem._(
              type: _type?.build(),
              key: key,
              shortDisplay: shortDisplay,
              longDisplay: longDisplay,
              language: language);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'type';
        _type?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DeviceItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
