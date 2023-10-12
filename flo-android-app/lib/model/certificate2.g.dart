// GENERATED CODE - DO NOT MODIFY BY HAND

part of certificate2;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Certificate2> _$certificate2Serializer =
    new _$Certificate2Serializer();

class _$Certificate2Serializer implements StructuredSerializer<Certificate2> {
  @override
  final Iterable<Type> types = const [Certificate2, _$Certificate2];
  @override
  final String wireName = 'Certificate2';

  @override
  Iterable<Object> serialize(Serializers serializers, Certificate2 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.apName != null) {
      result
        ..add('apName')
        ..add(serializers.serialize(object.apName,
            specifiedType: const FullType(String)));
    }
    if (object.apPassword != null) {
      result
        ..add('apPassword')
        ..add(serializers.serialize(object.apPassword,
            specifiedType: const FullType(String)));
    }
    if (object.loginToken != null) {
      result
        ..add('loginToken')
        ..add(serializers.serialize(object.loginToken,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.clientCert != null) {
      result
        ..add('clientCert')
        ..add(serializers.serialize(object.clientCert,
            specifiedType: const FullType(String)));
    }
    if (object.clientKey != null) {
      result
        ..add('clientKey')
        ..add(serializers.serialize(object.clientKey,
            specifiedType: const FullType(String)));
    }
    if (object.serverCert != null) {
      result
        ..add('serverCert')
        ..add(serializers.serialize(object.serverCert,
            specifiedType: const FullType(String)));
    }
    if (object.websocketCert != null) {
      result
        ..add('websocketCert')
        ..add(serializers.serialize(object.websocketCert,
            specifiedType: const FullType(String)));
    }
    if (object.websocketCertDer != null) {
      result
        ..add('websocketCertDer')
        ..add(serializers.serialize(object.websocketCertDer,
            specifiedType: const FullType(String)));
    }
    if (object.websocketKey != null) {
      result
        ..add('websocketKey')
        ..add(serializers.serialize(object.websocketKey,
            specifiedType: const FullType(String)));
    }
    if (object.firestoreToken != null) {
      result
        ..add('firestore')
        ..add(serializers.serialize(object.firestoreToken,
            specifiedType: const FullType(Token)));
    }
    return result;
  }

  @override
  Certificate2 deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new Certificate2Builder();

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
        case 'apName':
          result.apName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'apPassword':
          result.apPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'loginToken':
          result.loginToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'clientCert':
          result.clientCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'clientKey':
          result.clientKey = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'serverCert':
          result.serverCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocketCert':
          result.websocketCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocketCertDer':
          result.websocketCertDer = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocketKey':
          result.websocketKey = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'firestore':
          result.firestoreToken.replace(serializers.deserialize(value,
              specifiedType: const FullType(Token)) as Token);
          break;
      }
    }

    return result.build();
  }
}

class _$Certificate2 extends Certificate2 {
  @override
  final String id;
  @override
  final String apName;
  @override
  final String apPassword;
  @override
  final String loginToken;
  @override
  final String deviceId;
  @override
  final String clientCert;
  @override
  final String clientKey;
  @override
  final String serverCert;
  @override
  final String websocketCert;
  @override
  final String websocketCertDer;
  @override
  final String websocketKey;
  @override
  final Token firestoreToken;

  factory _$Certificate2([void Function(Certificate2Builder) updates]) =>
      (new Certificate2Builder()..update(updates)).build();

  _$Certificate2._(
      {this.id,
      this.apName,
      this.apPassword,
      this.loginToken,
      this.deviceId,
      this.clientCert,
      this.clientKey,
      this.serverCert,
      this.websocketCert,
      this.websocketCertDer,
      this.websocketKey,
      this.firestoreToken})
      : super._();

  @override
  Certificate2 rebuild(void Function(Certificate2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Certificate2Builder toBuilder() => new Certificate2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Certificate2 &&
        id == other.id &&
        apName == other.apName &&
        apPassword == other.apPassword &&
        loginToken == other.loginToken &&
        deviceId == other.deviceId &&
        clientCert == other.clientCert &&
        clientKey == other.clientKey &&
        serverCert == other.serverCert &&
        websocketCert == other.websocketCert &&
        websocketCertDer == other.websocketCertDer &&
        websocketKey == other.websocketKey &&
        firestoreToken == other.firestoreToken;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc($jc(0, id.hashCode),
                                                apName.hashCode),
                                            apPassword.hashCode),
                                        loginToken.hashCode),
                                    deviceId.hashCode),
                                clientCert.hashCode),
                            clientKey.hashCode),
                        serverCert.hashCode),
                    websocketCert.hashCode),
                websocketCertDer.hashCode),
            websocketKey.hashCode),
        firestoreToken.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Certificate2')
          ..add('id', id)
          ..add('apName', apName)
          ..add('apPassword', apPassword)
          ..add('loginToken', loginToken)
          ..add('deviceId', deviceId)
          ..add('clientCert', clientCert)
          ..add('clientKey', clientKey)
          ..add('serverCert', serverCert)
          ..add('websocketCert', websocketCert)
          ..add('websocketCertDer', websocketCertDer)
          ..add('websocketKey', websocketKey)
          ..add('firestoreToken', firestoreToken))
        .toString();
  }
}

class Certificate2Builder
    implements Builder<Certificate2, Certificate2Builder> {
  _$Certificate2 _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _apName;
  String get apName => _$this._apName;
  set apName(String apName) => _$this._apName = apName;

  String _apPassword;
  String get apPassword => _$this._apPassword;
  set apPassword(String apPassword) => _$this._apPassword = apPassword;

  String _loginToken;
  String get loginToken => _$this._loginToken;
  set loginToken(String loginToken) => _$this._loginToken = loginToken;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _clientCert;
  String get clientCert => _$this._clientCert;
  set clientCert(String clientCert) => _$this._clientCert = clientCert;

  String _clientKey;
  String get clientKey => _$this._clientKey;
  set clientKey(String clientKey) => _$this._clientKey = clientKey;

  String _serverCert;
  String get serverCert => _$this._serverCert;
  set serverCert(String serverCert) => _$this._serverCert = serverCert;

  String _websocketCert;
  String get websocketCert => _$this._websocketCert;
  set websocketCert(String websocketCert) =>
      _$this._websocketCert = websocketCert;

  String _websocketCertDer;
  String get websocketCertDer => _$this._websocketCertDer;
  set websocketCertDer(String websocketCertDer) =>
      _$this._websocketCertDer = websocketCertDer;

  String _websocketKey;
  String get websocketKey => _$this._websocketKey;
  set websocketKey(String websocketKey) => _$this._websocketKey = websocketKey;

  TokenBuilder _firestoreToken;
  TokenBuilder get firestoreToken =>
      _$this._firestoreToken ??= new TokenBuilder();
  set firestoreToken(TokenBuilder firestoreToken) =>
      _$this._firestoreToken = firestoreToken;

  Certificate2Builder();

  Certificate2Builder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _apName = _$v.apName;
      _apPassword = _$v.apPassword;
      _loginToken = _$v.loginToken;
      _deviceId = _$v.deviceId;
      _clientCert = _$v.clientCert;
      _clientKey = _$v.clientKey;
      _serverCert = _$v.serverCert;
      _websocketCert = _$v.websocketCert;
      _websocketCertDer = _$v.websocketCertDer;
      _websocketKey = _$v.websocketKey;
      _firestoreToken = _$v.firestoreToken?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Certificate2 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Certificate2;
  }

  @override
  void update(void Function(Certificate2Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Certificate2 build() {
    _$Certificate2 _$result;
    try {
      _$result = _$v ??
          new _$Certificate2._(
              id: id,
              apName: apName,
              apPassword: apPassword,
              loginToken: loginToken,
              deviceId: deviceId,
              clientCert: clientCert,
              clientKey: clientKey,
              serverCert: serverCert,
              websocketCert: websocketCert,
              websocketCertDer: websocketCertDer,
              websocketKey: websocketKey,
              firestoreToken: _firestoreToken?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'firestoreToken';
        _firestoreToken?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Certificate2', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
