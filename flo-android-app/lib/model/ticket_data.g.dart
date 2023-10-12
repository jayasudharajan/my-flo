// GENERATED CODE - DO NOT MODIFY BY HAND

part of ticket_data;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<TicketData> _$ticketDataSerializer = new _$TicketDataSerializer();

class _$TicketDataSerializer implements StructuredSerializer<TicketData> {
  @override
  final Iterable<Type> types = const [TicketData, _$TicketData];
  @override
  final String wireName = 'TicketData';

  @override
  Iterable<Object> serialize(Serializers serializers, TicketData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'i',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
      'e',
      serializers.serialize(object.encryptCode,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  TicketData deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TicketDataBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'i':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'e':
          result.encryptCode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$TicketData extends TicketData {
  @override
  final String id;
  @override
  final String encryptCode;

  factory _$TicketData([void Function(TicketDataBuilder) updates]) =>
      (new TicketDataBuilder()..update(updates)).build();

  _$TicketData._({this.id, this.encryptCode}) : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('TicketData', 'id');
    }
    if (encryptCode == null) {
      throw new BuiltValueNullFieldError('TicketData', 'encryptCode');
    }
  }

  @override
  TicketData rebuild(void Function(TicketDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TicketDataBuilder toBuilder() => new TicketDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TicketData &&
        id == other.id &&
        encryptCode == other.encryptCode;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, id.hashCode), encryptCode.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TicketData')
          ..add('id', id)
          ..add('encryptCode', encryptCode))
        .toString();
  }
}

class TicketDataBuilder implements Builder<TicketData, TicketDataBuilder> {
  _$TicketData _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _encryptCode;
  String get encryptCode => _$this._encryptCode;
  set encryptCode(String encryptCode) => _$this._encryptCode = encryptCode;

  TicketDataBuilder();

  TicketDataBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _encryptCode = _$v.encryptCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TicketData other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TicketData;
  }

  @override
  void update(void Function(TicketDataBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TicketData build() {
    final _$result =
        _$v ?? new _$TicketData._(id: id, encryptCode: encryptCode);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
