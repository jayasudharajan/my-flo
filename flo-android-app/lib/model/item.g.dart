// GENERATED CODE - DO NOT MODIFY BY HAND

part of item;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Item> _$itemSerializer = new _$ItemSerializer();

class _$ItemSerializer implements StructuredSerializer<Item> {
  @override
  final Iterable<Type> types = const [Item, _$Item];
  @override
  final String wireName = 'Item';

  @override
  Iterable<Object> serialize(Serializers serializers, Item object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
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
  Item deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ItemBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
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

class _$Item extends Item {
  @override
  final String key;
  @override
  final String shortDisplay;
  @override
  final String longDisplay;
  @override
  final String language;

  factory _$Item([void Function(ItemBuilder) updates]) =>
      (new ItemBuilder()..update(updates)).build();

  _$Item._({this.key, this.shortDisplay, this.longDisplay, this.language})
      : super._();

  @override
  Item rebuild(void Function(ItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemBuilder toBuilder() => new ItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Item &&
        key == other.key &&
        shortDisplay == other.shortDisplay &&
        longDisplay == other.longDisplay &&
        language == other.language;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, key.hashCode), shortDisplay.hashCode),
            longDisplay.hashCode),
        language.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Item')
          ..add('key', key)
          ..add('shortDisplay', shortDisplay)
          ..add('longDisplay', longDisplay)
          ..add('language', language))
        .toString();
  }
}

class ItemBuilder implements Builder<Item, ItemBuilder> {
  _$Item _$v;

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

  ItemBuilder();

  ItemBuilder get _$this {
    if (_$v != null) {
      _key = _$v.key;
      _shortDisplay = _$v.shortDisplay;
      _longDisplay = _$v.longDisplay;
      _language = _$v.language;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Item other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Item;
  }

  @override
  void update(void Function(ItemBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Item build() {
    final _$result = _$v ??
        new _$Item._(
            key: key,
            shortDisplay: shortDisplay,
            longDisplay: longDisplay,
            language: language);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
