// GENERATED CODE - DO NOT MODIFY BY HAND

part of id;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Id> _$idSerializer = new _$IdSerializer();

class _$IdSerializer implements StructuredSerializer<Id> {
  @override
  final Iterable<Type> types = const [Id, _$Id];
  @override
  final String wireName = 'Id';

  @override
  Iterable<Object> serialize(Serializers serializers, Id object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Id deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new IdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Id extends Id {
  @override
  final String id;

  factory _$Id([void Function(IdBuilder) updates]) =>
      (new IdBuilder()..update(updates)).build();

  _$Id._({this.id}) : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('Id', 'id');
    }
  }

  @override
  Id rebuild(void Function(IdBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IdBuilder toBuilder() => new IdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Id && id == other.id;
  }

  @override
  int get hashCode {
    return $jf($jc(0, id.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Id')..add('id', id)).toString();
  }
}

class IdBuilder implements Builder<Id, IdBuilder> {
  _$Id _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  IdBuilder();

  IdBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Id other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Id;
  }

  @override
  void update(void Function(IdBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Id build() {
    final _$result = _$v ?? new _$Id._(id: id);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
