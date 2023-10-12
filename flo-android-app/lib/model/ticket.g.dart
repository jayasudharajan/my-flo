// GENERATED CODE - DO NOT MODIFY BY HAND

part of ticket;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Ticket> _$ticketSerializer = new _$TicketSerializer();

class _$TicketSerializer implements StructuredSerializer<Ticket> {
  @override
  final Iterable<Type> types = const [Ticket, _$Ticket];
  @override
  final String wireName = 'Ticket';

  @override
  Iterable<Object> serialize(Serializers serializers, Ticket object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'data',
      serializers.serialize(object.data,
          specifiedType: const FullType(TicketData)),
    ];

    return result;
  }

  @override
  Ticket deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TicketBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'data':
          result.data.replace(serializers.deserialize(value,
              specifiedType: const FullType(TicketData)) as TicketData);
          break;
      }
    }

    return result.build();
  }
}

class _$Ticket extends Ticket {
  @override
  final TicketData data;

  factory _$Ticket([void Function(TicketBuilder) updates]) =>
      (new TicketBuilder()..update(updates)).build();

  _$Ticket._({this.data}) : super._() {
    if (data == null) {
      throw new BuiltValueNullFieldError('Ticket', 'data');
    }
  }

  @override
  Ticket rebuild(void Function(TicketBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TicketBuilder toBuilder() => new TicketBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Ticket && data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc(0, data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Ticket')..add('data', data))
        .toString();
  }
}

class TicketBuilder implements Builder<Ticket, TicketBuilder> {
  _$Ticket _$v;

  TicketDataBuilder _data;
  TicketDataBuilder get data => _$this._data ??= new TicketDataBuilder();
  set data(TicketDataBuilder data) => _$this._data = data;

  TicketBuilder();

  TicketBuilder get _$this {
    if (_$v != null) {
      _data = _$v.data?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Ticket other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Ticket;
  }

  @override
  void update(void Function(TicketBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Ticket build() {
    _$Ticket _$result;
    try {
      _$result = _$v ?? new _$Ticket._(data: data.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Ticket', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
