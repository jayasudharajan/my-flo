// GENERATED CODE - DO NOT MODIFY BY HAND

part of oauth_token;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OauthToken> _$oauthTokenSerializer = new _$OauthTokenSerializer();

class _$OauthTokenSerializer implements StructuredSerializer<OauthToken> {
  @override
  final Iterable<Type> types = const [OauthToken, _$OauthToken];
  @override
  final String wireName = 'OauthToken';

  @override
  Iterable<Object> serialize(Serializers serializers, OauthToken object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.accessToken != null) {
      result
        ..add('access_token')
        ..add(serializers.serialize(object.accessToken,
            specifiedType: const FullType(String)));
    }
    if (object.refreshToken != null) {
      result
        ..add('refresh_token')
        ..add(serializers.serialize(object.refreshToken,
            specifiedType: const FullType(String)));
    }
    if (object.expiresIn != null) {
      result
        ..add('expires_in')
        ..add(serializers.serialize(object.expiresIn,
            specifiedType: const FullType(int)));
    }
    if (object.userId != null) {
      result
        ..add('user_id')
        ..add(serializers.serialize(object.userId,
            specifiedType: const FullType(String)));
    }
    if (object.expiresAt != null) {
      result
        ..add('expires_at')
        ..add(serializers.serialize(object.expiresAt,
            specifiedType: const FullType(String)));
    }
    if (object.issuedAt != null) {
      result
        ..add('issued_at')
        ..add(serializers.serialize(object.issuedAt,
            specifiedType: const FullType(String)));
    }
    if (object.tokenType != null) {
      result
        ..add('token_type')
        ..add(serializers.serialize(object.tokenType,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  OauthToken deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OauthTokenBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'access_token':
          result.accessToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'refresh_token':
          result.refreshToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'expires_in':
          result.expiresIn = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'user_id':
          result.userId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'expires_at':
          result.expiresAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'issued_at':
          result.issuedAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'token_type':
          result.tokenType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$OauthToken extends OauthToken {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final int expiresIn;
  @override
  final String userId;
  @override
  final String expiresAt;
  @override
  final String issuedAt;
  @override
  final String tokenType;

  factory _$OauthToken([void Function(OauthTokenBuilder) updates]) =>
      (new OauthTokenBuilder()..update(updates)).build();

  _$OauthToken._(
      {this.accessToken,
      this.refreshToken,
      this.expiresIn,
      this.userId,
      this.expiresAt,
      this.issuedAt,
      this.tokenType})
      : super._();

  @override
  OauthToken rebuild(void Function(OauthTokenBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OauthTokenBuilder toBuilder() => new OauthTokenBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OauthToken &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        expiresIn == other.expiresIn &&
        userId == other.userId &&
        expiresAt == other.expiresAt &&
        issuedAt == other.issuedAt &&
        tokenType == other.tokenType;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc(0, accessToken.hashCode),
                            refreshToken.hashCode),
                        expiresIn.hashCode),
                    userId.hashCode),
                expiresAt.hashCode),
            issuedAt.hashCode),
        tokenType.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OauthToken')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('expiresIn', expiresIn)
          ..add('userId', userId)
          ..add('expiresAt', expiresAt)
          ..add('issuedAt', issuedAt)
          ..add('tokenType', tokenType))
        .toString();
  }
}

class OauthTokenBuilder implements Builder<OauthToken, OauthTokenBuilder> {
  _$OauthToken _$v;

  String _accessToken;
  String get accessToken => _$this._accessToken;
  set accessToken(String accessToken) => _$this._accessToken = accessToken;

  String _refreshToken;
  String get refreshToken => _$this._refreshToken;
  set refreshToken(String refreshToken) => _$this._refreshToken = refreshToken;

  int _expiresIn;
  int get expiresIn => _$this._expiresIn;
  set expiresIn(int expiresIn) => _$this._expiresIn = expiresIn;

  String _userId;
  String get userId => _$this._userId;
  set userId(String userId) => _$this._userId = userId;

  String _expiresAt;
  String get expiresAt => _$this._expiresAt;
  set expiresAt(String expiresAt) => _$this._expiresAt = expiresAt;

  String _issuedAt;
  String get issuedAt => _$this._issuedAt;
  set issuedAt(String issuedAt) => _$this._issuedAt = issuedAt;

  String _tokenType;
  String get tokenType => _$this._tokenType;
  set tokenType(String tokenType) => _$this._tokenType = tokenType;

  OauthTokenBuilder();

  OauthTokenBuilder get _$this {
    if (_$v != null) {
      _accessToken = _$v.accessToken;
      _refreshToken = _$v.refreshToken;
      _expiresIn = _$v.expiresIn;
      _userId = _$v.userId;
      _expiresAt = _$v.expiresAt;
      _issuedAt = _$v.issuedAt;
      _tokenType = _$v.tokenType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OauthToken other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$OauthToken;
  }

  @override
  void update(void Function(OauthTokenBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OauthToken build() {
    final _$result = _$v ??
        new _$OauthToken._(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            userId: userId,
            expiresAt: expiresAt,
            issuedAt: issuedAt,
            tokenType: tokenType);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
