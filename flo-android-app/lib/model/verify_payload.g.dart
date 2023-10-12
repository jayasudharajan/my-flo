// GENERATED CODE - DO NOT MODIFY BY HAND

part of verify_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<VerifyPayload> _$verifyPayloadSerializer =
    new _$VerifyPayloadSerializer();

class _$VerifyPayloadSerializer implements StructuredSerializer<VerifyPayload> {
  @override
  final Iterable<Type> types = const [VerifyPayload, _$VerifyPayload];
  @override
  final String wireName = 'VerifyPayload';

  @override
  Iterable<Object> serialize(Serializers serializers, VerifyPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.clientId != null) {
      result
        ..add('clientId')
        ..add(serializers.serialize(object.clientId,
            specifiedType: const FullType(String)));
    }
    if (object.clientSecret != null) {
      result
        ..add('clientSecret')
        ..add(serializers.serialize(object.clientSecret,
            specifiedType: const FullType(String)));
    }
    if (object.token != null) {
      result
        ..add('token')
        ..add(serializers.serialize(object.token,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  VerifyPayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new VerifyPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'clientId':
          result.clientId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'clientSecret':
          result.clientSecret = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'token':
          result.token = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$VerifyPayload extends VerifyPayload {
  @override
  final String clientId;
  @override
  final String clientSecret;
  @override
  final String token;

  factory _$VerifyPayload([void Function(VerifyPayloadBuilder) updates]) =>
      (new VerifyPayloadBuilder()..update(updates)).build();

  _$VerifyPayload._({this.clientId, this.clientSecret, this.token}) : super._();

  @override
  VerifyPayload rebuild(void Function(VerifyPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerifyPayloadBuilder toBuilder() => new VerifyPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerifyPayload &&
        clientId == other.clientId &&
        clientSecret == other.clientSecret &&
        token == other.token;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, clientId.hashCode), clientSecret.hashCode), token.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('VerifyPayload')
          ..add('clientId', clientId)
          ..add('clientSecret', clientSecret)
          ..add('token', token))
        .toString();
  }
}

class VerifyPayloadBuilder
    implements Builder<VerifyPayload, VerifyPayloadBuilder> {
  _$VerifyPayload _$v;

  String _clientId;
  String get clientId => _$this._clientId;
  set clientId(String clientId) => _$this._clientId = clientId;

  String _clientSecret;
  String get clientSecret => _$this._clientSecret;
  set clientSecret(String clientSecret) => _$this._clientSecret = clientSecret;

  String _token;
  String get token => _$this._token;
  set token(String token) => _$this._token = token;

  VerifyPayloadBuilder();

  VerifyPayloadBuilder get _$this {
    if (_$v != null) {
      _clientId = _$v.clientId;
      _clientSecret = _$v.clientSecret;
      _token = _$v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerifyPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$VerifyPayload;
  }

  @override
  void update(void Function(VerifyPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$VerifyPayload build() {
    final _$result = _$v ??
        new _$VerifyPayload._(
            clientId: clientId, clientSecret: clientSecret, token: token);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
