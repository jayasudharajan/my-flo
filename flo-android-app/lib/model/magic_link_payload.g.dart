// GENERATED CODE - DO NOT MODIFY BY HAND

part of magic_link_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MagicLinkPayload> _$magicLinkPayloadSerializer =
    new _$MagicLinkPayloadSerializer();

class _$MagicLinkPayloadSerializer
    implements StructuredSerializer<MagicLinkPayload> {
  @override
  final Iterable<Type> types = const [MagicLinkPayload, _$MagicLinkPayload];
  @override
  final String wireName = 'MagicLinkPayload';

  @override
  Iterable<Object> serialize(Serializers serializers, MagicLinkPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'email',
      serializers.serialize(object.email,
          specifiedType: const FullType(String)),
      'client_id',
      serializers.serialize(object.clientId,
          specifiedType: const FullType(String)),
      'client_secret',
      serializers.serialize(object.clientSecret,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  MagicLinkPayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MagicLinkPayloadBuilder();

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
        case 'client_id':
          result.clientId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_secret':
          result.clientSecret = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$MagicLinkPayload extends MagicLinkPayload {
  @override
  final String email;
  @override
  final String clientId;
  @override
  final String clientSecret;

  factory _$MagicLinkPayload(
          [void Function(MagicLinkPayloadBuilder) updates]) =>
      (new MagicLinkPayloadBuilder()..update(updates)).build();

  _$MagicLinkPayload._({this.email, this.clientId, this.clientSecret})
      : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('MagicLinkPayload', 'email');
    }
    if (clientId == null) {
      throw new BuiltValueNullFieldError('MagicLinkPayload', 'clientId');
    }
    if (clientSecret == null) {
      throw new BuiltValueNullFieldError('MagicLinkPayload', 'clientSecret');
    }
  }

  @override
  MagicLinkPayload rebuild(void Function(MagicLinkPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MagicLinkPayloadBuilder toBuilder() =>
      new MagicLinkPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MagicLinkPayload &&
        email == other.email &&
        clientId == other.clientId &&
        clientSecret == other.clientSecret;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, email.hashCode), clientId.hashCode), clientSecret.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MagicLinkPayload')
          ..add('email', email)
          ..add('clientId', clientId)
          ..add('clientSecret', clientSecret))
        .toString();
  }
}

class MagicLinkPayloadBuilder
    implements Builder<MagicLinkPayload, MagicLinkPayloadBuilder> {
  _$MagicLinkPayload _$v;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  String _clientId;
  String get clientId => _$this._clientId;
  set clientId(String clientId) => _$this._clientId = clientId;

  String _clientSecret;
  String get clientSecret => _$this._clientSecret;
  set clientSecret(String clientSecret) => _$this._clientSecret = clientSecret;

  MagicLinkPayloadBuilder();

  MagicLinkPayloadBuilder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _clientId = _$v.clientId;
      _clientSecret = _$v.clientSecret;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MagicLinkPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$MagicLinkPayload;
  }

  @override
  void update(void Function(MagicLinkPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$MagicLinkPayload build() {
    final _$result = _$v ??
        new _$MagicLinkPayload._(
            email: email, clientId: clientId, clientSecret: clientSecret);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
