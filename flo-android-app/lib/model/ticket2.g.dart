// GENERATED CODE - DO NOT MODIFY BY HAND

part of ticket2;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Ticket2> _$ticket2Serializer = new _$Ticket2Serializer();

class _$Ticket2Serializer implements StructuredSerializer<Ticket2> {
  @override
  final Iterable<Type> types = const [Ticket2, _$Ticket2];
  @override
  final String wireName = 'Ticket2';

  @override
  Iterable<Object> serialize(Serializers serializers, Ticket2 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'data',
      serializers.serialize(object.data, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Ticket2 deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new Ticket2Builder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'data':
          result.data = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Ticket2 extends Ticket2 {
  @override
  final String data;

  factory _$Ticket2([void Function(Ticket2Builder) updates]) =>
      (new Ticket2Builder()..update(updates)).build();

  _$Ticket2._({this.data}) : super._() {
    if (data == null) {
      throw new BuiltValueNullFieldError('Ticket2', 'data');
    }
  }

  @override
  Ticket2 rebuild(void Function(Ticket2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Ticket2Builder toBuilder() => new Ticket2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Ticket2 && data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc(0, data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Ticket2')..add('data', data))
        .toString();
  }
}

class Ticket2Builder implements Builder<Ticket2, Ticket2Builder> {
  _$Ticket2 _$v;

  String _data;
  String get data => _$this._data;
  set data(String data) => _$this._data = data;

  Ticket2Builder();

  Ticket2Builder get _$this {
    if (_$v != null) {
      _data = _$v.data;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Ticket2 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Ticket2;
  }

  @override
  void update(void Function(Ticket2Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Ticket2 build() {
    final _$result = _$v ?? new _$Ticket2._(data: data);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
