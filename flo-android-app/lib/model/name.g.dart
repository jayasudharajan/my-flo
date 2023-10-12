// GENERATED CODE - DO NOT MODIFY BY HAND

part of name;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Name> _$nameSerializer = new _$NameSerializer();

class _$NameSerializer implements StructuredSerializer<Name> {
  @override
  final Iterable<Type> types = const [Name, _$Name];
  @override
  final String wireName = 'Name';

  @override
  Iterable<Object> serialize(Serializers serializers, Name object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.name != null) {
      result
        ..add('name')
        ..add(serializers.serialize(object.name,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Name deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NameBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Name extends Name {
  @override
  final String name;

  factory _$Name([void Function(NameBuilder) updates]) =>
      (new NameBuilder()..update(updates)).build();

  _$Name._({this.name}) : super._();

  @override
  Name rebuild(void Function(NameBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NameBuilder toBuilder() => new NameBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Name && name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc(0, name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Name')..add('name', name)).toString();
  }
}

class NameBuilder implements Builder<Name, NameBuilder> {
  _$Name _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  NameBuilder();

  NameBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Name other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Name;
  }

  @override
  void update(void Function(NameBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Name build() {
    final _$result = _$v ?? new _$Name._(name: name);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
