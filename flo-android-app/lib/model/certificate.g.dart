// GENERATED CODE - DO NOT MODIFY BY HAND

part of certificate;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Certificate> _$certificateSerializer = new _$CertificateSerializer();

class _$CertificateSerializer implements StructuredSerializer<Certificate> {
  @override
  final Iterable<Type> types = const [Certificate, _$Certificate];
  @override
  final String wireName = 'Certificate';

  @override
  Iterable<Object> serialize(Serializers serializers, Certificate object,
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
        ..add('ap_name')
        ..add(serializers.serialize(object.apName,
            specifiedType: const FullType(String)));
    }
    if (object.apPassword != null) {
      result
        ..add('ap_password')
        ..add(serializers.serialize(object.apPassword,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('device_id')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.loginToken != null) {
      result
        ..add('login_token')
        ..add(serializers.serialize(object.loginToken,
            specifiedType: const FullType(String)));
    }
    if (object.clientCert != null) {
      result
        ..add('client_cert')
        ..add(serializers.serialize(object.clientCert,
            specifiedType: const FullType(String)));
    }
    if (object.clientKey != null) {
      result
        ..add('client_key')
        ..add(serializers.serialize(object.clientKey,
            specifiedType: const FullType(String)));
    }
    if (object.serverCert != null) {
      result
        ..add('server_cert')
        ..add(serializers.serialize(object.serverCert,
            specifiedType: const FullType(String)));
    }
    if (object.websocketCert != null) {
      result
        ..add('websocket_cert')
        ..add(serializers.serialize(object.websocketCert,
            specifiedType: const FullType(String)));
    }
    if (object.websocketCertDer != null) {
      result
        ..add('websocket_cert_der')
        ..add(serializers.serialize(object.websocketCertDer,
            specifiedType: const FullType(String)));
    }
    if (object.websocketKey != null) {
      result
        ..add('websocket_key')
        ..add(serializers.serialize(object.websocketKey,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Certificate deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new CertificateBuilder();

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
        case 'ap_name':
          result.apName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'ap_password':
          result.apPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'device_id':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'login_token':
          result.loginToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_cert':
          result.clientCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_key':
          result.clientKey = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'server_cert':
          result.serverCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocket_cert':
          result.websocketCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocket_cert_der':
          result.websocketCertDer = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'websocket_key':
          result.websocketKey = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Certificate extends Certificate {
  @override
  final String id;
  @override
  final String apName;
  @override
  final String apPassword;
  @override
  final String deviceId;
  @override
  final String loginToken;
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

  factory _$Certificate([void Function(CertificateBuilder) updates]) =>
      (new CertificateBuilder()..update(updates)).build();

  _$Certificate._(
      {this.id,
      this.apName,
      this.apPassword,
      this.deviceId,
      this.loginToken,
      this.clientCert,
      this.clientKey,
      this.serverCert,
      this.websocketCert,
      this.websocketCertDer,
      this.websocketKey})
      : super._();

  @override
  Certificate rebuild(void Function(CertificateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CertificateBuilder toBuilder() => new CertificateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Certificate &&
        id == other.id &&
        apName == other.apName &&
        apPassword == other.apPassword &&
        deviceId == other.deviceId &&
        loginToken == other.loginToken &&
        clientCert == other.clientCert &&
        clientKey == other.clientKey &&
        serverCert == other.serverCert &&
        websocketCert == other.websocketCert &&
        websocketCertDer == other.websocketCertDer &&
        websocketKey == other.websocketKey;
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
                                        $jc($jc(0, id.hashCode),
                                            apName.hashCode),
                                        apPassword.hashCode),
                                    deviceId.hashCode),
                                loginToken.hashCode),
                            clientCert.hashCode),
                        clientKey.hashCode),
                    serverCert.hashCode),
                websocketCert.hashCode),
            websocketCertDer.hashCode),
        websocketKey.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Certificate')
          ..add('id', id)
          ..add('apName', apName)
          ..add('apPassword', apPassword)
          ..add('deviceId', deviceId)
          ..add('loginToken', loginToken)
          ..add('clientCert', clientCert)
          ..add('clientKey', clientKey)
          ..add('serverCert', serverCert)
          ..add('websocketCert', websocketCert)
          ..add('websocketCertDer', websocketCertDer)
          ..add('websocketKey', websocketKey))
        .toString();
  }
}

class CertificateBuilder implements Builder<Certificate, CertificateBuilder> {
  _$Certificate _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _apName;
  String get apName => _$this._apName;
  set apName(String apName) => _$this._apName = apName;

  String _apPassword;
  String get apPassword => _$this._apPassword;
  set apPassword(String apPassword) => _$this._apPassword = apPassword;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _loginToken;
  String get loginToken => _$this._loginToken;
  set loginToken(String loginToken) => _$this._loginToken = loginToken;

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

  CertificateBuilder();

  CertificateBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _apName = _$v.apName;
      _apPassword = _$v.apPassword;
      _deviceId = _$v.deviceId;
      _loginToken = _$v.loginToken;
      _clientCert = _$v.clientCert;
      _clientKey = _$v.clientKey;
      _serverCert = _$v.serverCert;
      _websocketCert = _$v.websocketCert;
      _websocketCertDer = _$v.websocketCertDer;
      _websocketKey = _$v.websocketKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Certificate other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Certificate;
  }

  @override
  void update(void Function(CertificateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Certificate build() {
    final _$result = _$v ??
        new _$Certificate._(
            id: id,
            apName: apName,
            apPassword: apPassword,
            deviceId: deviceId,
            loginToken: loginToken,
            clientCert: clientCert,
            clientKey: clientKey,
            serverCert: serverCert,
            websocketCert: websocketCert,
            websocketCertDer: websocketCertDer,
            websocketKey: websocketKey);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
