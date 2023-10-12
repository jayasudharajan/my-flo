// GENERATED CODE - DO NOT MODIFY BY HAND

part of string_items;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<StringItems> _$stringItemsSerializer = new _$StringItemsSerializer();

class _$StringItemsSerializer implements StructuredSerializer<StringItems> {
  @override
  final Iterable<Type> types = const [StringItems, _$StringItems];
  @override
  final String wireName = 'StringItems';

  @override
  Iterable<Object> serialize(Serializers serializers, StringItems object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    return result;
  }

  @override
  StringItems deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new StringItemsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$StringItems extends StringItems {
  @override
  final BuiltList<String> items;

  factory _$StringItems([void Function(StringItemsBuilder) updates]) =>
      (new StringItemsBuilder()..update(updates)).build();

  _$StringItems._({this.items}) : super._();

  @override
  StringItems rebuild(void Function(StringItemsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StringItemsBuilder toBuilder() => new StringItemsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StringItems && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StringItems')..add('items', items))
        .toString();
  }
}

class StringItemsBuilder implements Builder<StringItems, StringItemsBuilder> {
  _$StringItems _$v;

  ListBuilder<String> _items;
  ListBuilder<String> get items => _$this._items ??= new ListBuilder<String>();
  set items(ListBuilder<String> items) => _$this._items = items;

  StringItemsBuilder();

  StringItemsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StringItems other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$StringItems;
  }

  @override
  void update(void Function(StringItemsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StringItems build() {
    _$StringItems _$result;
    try {
      _$result = _$v ?? new _$StringItems._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'StringItems', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
