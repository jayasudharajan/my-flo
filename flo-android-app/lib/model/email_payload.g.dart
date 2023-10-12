// GENERATED CODE - DO NOT MODIFY BY HAND

part of email_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<EmailPayload> _$emailPayloadSerializer =
    new _$EmailPayloadSerializer();

class _$EmailPayloadSerializer implements StructuredSerializer<EmailPayload> {
  @override
  final Iterable<Type> types = const [EmailPayload, _$EmailPayload];
  @override
  final String wireName = 'EmailPayload';

  @override
  Iterable<Object> serialize(Serializers serializers, EmailPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'email',
      serializers.serialize(object.email,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  EmailPayload deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new EmailPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'email':
          result.email = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$EmailPayload extends EmailPayload {
  @override
  final String email;

  factory _$EmailPayload([void Function(EmailPayloadBuilder) updates]) =>
      (new EmailPayloadBuilder()..update(updates)).build();

  _$EmailPayload._({this.email}) : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('EmailPayload', 'email');
    }
  }

  @override
  EmailPayload rebuild(void Function(EmailPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EmailPayloadBuilder toBuilder() => new EmailPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EmailPayload && email == other.email;
  }

  @override
  int get hashCode {
    return $jf($jc(0, email.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EmailPayload')..add('email', email))
        .toString();
  }
}

class EmailPayloadBuilder
    implements Builder<EmailPayload, EmailPayloadBuilder> {
  _$EmailPayload _$v;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  EmailPayloadBuilder();

  EmailPayloadBuilder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EmailPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$EmailPayload;
  }

  @override
  void update(void Function(EmailPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EmailPayload build() {
    final _$result = _$v ?? new _$EmailPayload._(email: email);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
