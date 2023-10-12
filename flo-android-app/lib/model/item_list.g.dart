// GENERATED CODE - DO NOT MODIFY BY HAND

part of item_list;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ItemList> _$itemListSerializer = new _$ItemListSerializer();

class _$ItemListSerializer implements StructuredSerializer<ItemList> {
  @override
  final Iterable<Type> types = const [ItemList, _$ItemList];
  @override
  final String wireName = 'ItemList';

  @override
  Iterable<Object> serialize(Serializers serializers, ItemList object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Item)])));
    }
    return result;
  }

  @override
  ItemList deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ItemListBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Item)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$ItemList extends ItemList {
  @override
  final BuiltList<Item> items;

  factory _$ItemList([void Function(ItemListBuilder) updates]) =>
      (new ItemListBuilder()..update(updates)).build();

  _$ItemList._({this.items}) : super._();

  @override
  ItemList rebuild(void Function(ItemListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemListBuilder toBuilder() => new ItemListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItemList && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ItemList')..add('items', items))
        .toString();
  }
}

class ItemListBuilder implements Builder<ItemList, ItemListBuilder> {
  _$ItemList _$v;

  ListBuilder<Item> _items;
  ListBuilder<Item> get items => _$this._items ??= new ListBuilder<Item>();
  set items(ListBuilder<Item> items) => _$this._items = items;

  ItemListBuilder();

  ItemListBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItemList other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ItemList;
  }

  @override
  void update(void Function(ItemListBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ItemList build() {
    _$ItemList _$result;
    try {
      _$result = _$v ?? new _$ItemList._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ItemList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
