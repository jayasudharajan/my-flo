// GENERATED CODE - DO NOT MODIFY BY HAND

part of oauth_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OauthPayload> _$oauthPayloadSerializer =
    new _$OauthPayloadSerializer();

class _$OauthPayloadSerializer implements StructuredSerializer<OauthPayload> {
  @override
  final Iterable<Type> types = const [OauthPayload, _$OauthPayload];
  @override
  final String wireName = 'OauthPayload';

  @override
  Iterable<Object> serialize(Serializers serializers, OauthPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.clientId != null) {
      result
        ..add('client_id')
        ..add(serializers.serialize(object.clientId,
            specifiedType: const FullType(String)));
    }
    if (object.clientSecret != null) {
      result
        ..add('client_secret')
        ..add(serializers.serialize(object.clientSecret,
            specifiedType: const FullType(String)));
    }
    if (object.grantType != null) {
      result
        ..add('grant_type')
        ..add(serializers.serialize(object.grantType,
            specifiedType: const FullType(String)));
    }
    if (object.username != null) {
      result
        ..add('username')
        ..add(serializers.serialize(object.username,
            specifiedType: const FullType(String)));
    }
    if (object.password != null) {
      result
        ..add('password')
        ..add(serializers.serialize(object.password,
            specifiedType: const FullType(String)));
    }
    if (object.refreshToken != null) {
      result
        ..add('refresh_token')
        ..add(serializers.serialize(object.refreshToken,
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
  OauthPayload deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OauthPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'client_id':
          result.clientId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_secret':
          result.clientSecret = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'grant_type':
          result.grantType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'username':
          result.username = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'password':
          result.password = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'refresh_token':
          result.refreshToken = serializers.deserialize(value,
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

class _$OauthPayload extends OauthPayload {
  @override
  final String clientId;
  @override
  final String clientSecret;
  @override
  final String grantType;
  @override
  final String username;
  @override
  final String password;
  @override
  final String refreshToken;
  @override
  final String token;

  factory _$OauthPayload([void Function(OauthPayloadBuilder) updates]) =>
      (new OauthPayloadBuilder()..update(updates)).build();

  _$OauthPayload._(
      {this.clientId,
      this.clientSecret,
      this.grantType,
      this.username,
      this.password,
      this.refreshToken,
      this.token})
      : super._();

  @override
  OauthPayload rebuild(void Function(OauthPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OauthPayloadBuilder toBuilder() => new OauthPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OauthPayload &&
        clientId == other.clientId &&
        clientSecret == other.clientSecret &&
        grantType == other.grantType &&
        username == other.username &&
        password == other.password &&
        refreshToken == other.refreshToken &&
        token == other.token;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, clientId.hashCode), clientSecret.hashCode),
                        grantType.hashCode),
                    username.hashCode),
                password.hashCode),
            refreshToken.hashCode),
        token.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OauthPayload')
          ..add('clientId', clientId)
          ..add('clientSecret', clientSecret)
          ..add('grantType', grantType)
          ..add('username', username)
          ..add('password', password)
          ..add('refreshToken', refreshToken)
          ..add('token', token))
        .toString();
  }
}

class OauthPayloadBuilder
    implements Builder<OauthPayload, OauthPayloadBuilder> {
  _$OauthPayload _$v;

  String _clientId;
  String get clientId => _$this._clientId;
  set clientId(String clientId) => _$this._clientId = clientId;

  String _clientSecret;
  String get clientSecret => _$this._clientSecret;
  set clientSecret(String clientSecret) => _$this._clientSecret = clientSecret;

  String _grantType;
  String get grantType => _$this._grantType;
  set grantType(String grantType) => _$this._grantType = grantType;

  String _username;
  String get username => _$this._username;
  set username(String username) => _$this._username = username;

  String _password;
  String get password => _$this._password;
  set password(String password) => _$this._password = password;

  String _refreshToken;
  String get refreshToken => _$this._refreshToken;
  set refreshToken(String refreshToken) => _$this._refreshToken = refreshToken;

  String _token;
  String get token => _$this._token;
  set token(String token) => _$this._token = token;

  OauthPayloadBuilder();

  OauthPayloadBuilder get _$this {
    if (_$v != null) {
      _clientId = _$v.clientId;
      _clientSecret = _$v.clientSecret;
      _grantType = _$v.grantType;
      _username = _$v.username;
      _password = _$v.password;
      _refreshToken = _$v.refreshToken;
      _token = _$v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OauthPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$OauthPayload;
  }

  @override
  void update(void Function(OauthPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OauthPayload build() {
    final _$result = _$v ??
        new _$OauthPayload._(
            clientId: clientId,
            clientSecret: clientSecret,
            grantType: grantType,
            username: username,
            password: password,
            refreshToken: refreshToken,
            token: token);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
