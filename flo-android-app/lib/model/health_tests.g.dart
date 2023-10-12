// GENERATED CODE - DO NOT MODIFY BY HAND

part of health_tests;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<HealthTests> _$healthTestsSerializer = new _$HealthTestsSerializer();

class _$HealthTestsSerializer implements StructuredSerializer<HealthTests> {
  @override
  final Iterable<Type> types = const [HealthTests, _$HealthTests];
  @override
  final String wireName = 'HealthTests';

  @override
  Iterable<Object> serialize(Serializers serializers, HealthTests object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType:
                const FullType(BuiltList, const [const FullType(HealthTest)])));
    }
    return result;
  }

  @override
  HealthTests deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new HealthTestsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(HealthTest)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$HealthTests extends HealthTests {
  @override
  final BuiltList<HealthTest> items;

  factory _$HealthTests([void Function(HealthTestsBuilder) updates]) =>
      (new HealthTestsBuilder()..update(updates)).build();

  _$HealthTests._({this.items}) : super._();

  @override
  HealthTests rebuild(void Function(HealthTestsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HealthTestsBuilder toBuilder() => new HealthTestsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HealthTests && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('HealthTests')..add('items', items))
        .toString();
  }
}

class HealthTestsBuilder implements Builder<HealthTests, HealthTestsBuilder> {
  _$HealthTests _$v;

  ListBuilder<HealthTest> _items;
  ListBuilder<HealthTest> get items =>
      _$this._items ??= new ListBuilder<HealthTest>();
  set items(ListBuilder<HealthTest> items) => _$this._items = items;

  HealthTestsBuilder();

  HealthTestsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HealthTests other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$HealthTests;
  }

  @override
  void update(void Function(HealthTestsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$HealthTests build() {
    _$HealthTests _$result;
    try {
      _$result = _$v ?? new _$HealthTests._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'HealthTests', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
