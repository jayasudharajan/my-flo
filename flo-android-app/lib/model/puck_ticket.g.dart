// GENERATED CODE - DO NOT MODIFY BY HAND

part of puck_ticket;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PuckTicket> _$puckTicketSerializer = new _$PuckTicketSerializer();

class _$PuckTicketSerializer implements StructuredSerializer<PuckTicket> {
  @override
  final Iterable<Type> types = const [PuckTicket, _$PuckTicket];
  @override
  final String wireName = 'PuckTicket';

  @override
  Iterable<Object> serialize(Serializers serializers, PuckTicket object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.apiAccessToken != null) {
      result
        ..add('api_access_token')
        ..add(serializers.serialize(object.apiAccessToken,
            specifiedType: const FullType(String)));
    }
    if (object.cloudHostname != null) {
      result
        ..add('cloud_hostname')
        ..add(serializers.serialize(object.cloudHostname,
            specifiedType: const FullType(String)));
    }
    if (object.wifiSsid != null) {
      result
        ..add('wifi_ssid')
        ..add(serializers.serialize(object.wifiSsid,
            specifiedType: const FullType(String)));
    }
    if (object.wifiPassword != null) {
      result
        ..add('wifi_password')
        ..add(serializers.serialize(object.wifiPassword,
            specifiedType: const FullType(String)));
    }
    if (object.wifiEncryption != null) {
      result
        ..add('wifi_encryption')
        ..add(serializers.serialize(object.wifiEncryption,
            specifiedType: const FullType(String)));
    }
    if (object.locationId != null) {
      result
        ..add('location_id')
        ..add(serializers.serialize(object.locationId,
            specifiedType: const FullType(String)));
    }
    if (object.nickname != null) {
      result
        ..add('nickname')
        ..add(serializers.serialize(object.nickname,
            specifiedType: const FullType(String)));
    }
    if (object.installPoint != null) {
      result
        ..add('install_point')
        ..add(serializers.serialize(object.installPoint,
            specifiedType: const FullType(String)));
    }
    if (object.deviceType != null) {
      result
        ..add('device_type')
        ..add(serializers.serialize(object.deviceType,
            specifiedType: const FullType(String)));
    }
    if (object.deviceModel != null) {
      result
        ..add('device_model')
        ..add(serializers.serialize(object.deviceModel,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  PuckTicket deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PuckTicketBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'api_access_token':
          result.apiAccessToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'cloud_hostname':
          result.cloudHostname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_ssid':
          result.wifiSsid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_password':
          result.wifiPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_encryption':
          result.wifiEncryption = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'location_id':
          result.locationId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'nickname':
          result.nickname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'install_point':
          result.installPoint = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'device_type':
          result.deviceType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'device_model':
          result.deviceModel = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$PuckTicket extends PuckTicket {
  @override
  final String apiAccessToken;
  @override
  final String cloudHostname;
  @override
  final String wifiSsid;
  @override
  final String wifiPassword;
  @override
  final String wifiEncryption;
  @override
  final String locationId;
  @override
  final String nickname;
  @override
  final String installPoint;
  @override
  final String deviceType;
  @override
  final String deviceModel;

  factory _$PuckTicket([void Function(PuckTicketBuilder) updates]) =>
      (new PuckTicketBuilder()..update(updates)).build();

  _$PuckTicket._(
      {this.apiAccessToken,
      this.cloudHostname,
      this.wifiSsid,
      this.wifiPassword,
      this.wifiEncryption,
      this.locationId,
      this.nickname,
      this.installPoint,
      this.deviceType,
      this.deviceModel})
      : super._();

  @override
  PuckTicket rebuild(void Function(PuckTicketBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PuckTicketBuilder toBuilder() => new PuckTicketBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PuckTicket &&
        apiAccessToken == other.apiAccessToken &&
        cloudHostname == other.cloudHostname &&
        wifiSsid == other.wifiSsid &&
        wifiPassword == other.wifiPassword &&
        wifiEncryption == other.wifiEncryption &&
        locationId == other.locationId &&
        nickname == other.nickname &&
        installPoint == other.installPoint &&
        deviceType == other.deviceType &&
        deviceModel == other.deviceModel;
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
                                    $jc($jc(0, apiAccessToken.hashCode),
                                        cloudHostname.hashCode),
                                    wifiSsid.hashCode),
                                wifiPassword.hashCode),
                            wifiEncryption.hashCode),
                        locationId.hashCode),
                    nickname.hashCode),
                installPoint.hashCode),
            deviceType.hashCode),
        deviceModel.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PuckTicket')
          ..add('apiAccessToken', apiAccessToken)
          ..add('cloudHostname', cloudHostname)
          ..add('wifiSsid', wifiSsid)
          ..add('wifiPassword', wifiPassword)
          ..add('wifiEncryption', wifiEncryption)
          ..add('locationId', locationId)
          ..add('nickname', nickname)
          ..add('installPoint', installPoint)
          ..add('deviceType', deviceType)
          ..add('deviceModel', deviceModel))
        .toString();
  }
}

class PuckTicketBuilder implements Builder<PuckTicket, PuckTicketBuilder> {
  _$PuckTicket _$v;

  String _apiAccessToken;
  String get apiAccessToken => _$this._apiAccessToken;
  set apiAccessToken(String apiAccessToken) =>
      _$this._apiAccessToken = apiAccessToken;

  String _cloudHostname;
  String get cloudHostname => _$this._cloudHostname;
  set cloudHostname(String cloudHostname) =>
      _$this._cloudHostname = cloudHostname;

  String _wifiSsid;
  String get wifiSsid => _$this._wifiSsid;
  set wifiSsid(String wifiSsid) => _$this._wifiSsid = wifiSsid;

  String _wifiPassword;
  String get wifiPassword => _$this._wifiPassword;
  set wifiPassword(String wifiPassword) => _$this._wifiPassword = wifiPassword;

  String _wifiEncryption;
  String get wifiEncryption => _$this._wifiEncryption;
  set wifiEncryption(String wifiEncryption) =>
      _$this._wifiEncryption = wifiEncryption;

  String _locationId;
  String get locationId => _$this._locationId;
  set locationId(String locationId) => _$this._locationId = locationId;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  String _installPoint;
  String get installPoint => _$this._installPoint;
  set installPoint(String installPoint) => _$this._installPoint = installPoint;

  String _deviceType;
  String get deviceType => _$this._deviceType;
  set deviceType(String deviceType) => _$this._deviceType = deviceType;

  String _deviceModel;
  String get deviceModel => _$this._deviceModel;
  set deviceModel(String deviceModel) => _$this._deviceModel = deviceModel;

  PuckTicketBuilder();

  PuckTicketBuilder get _$this {
    if (_$v != null) {
      _apiAccessToken = _$v.apiAccessToken;
      _cloudHostname = _$v.cloudHostname;
      _wifiSsid = _$v.wifiSsid;
      _wifiPassword = _$v.wifiPassword;
      _wifiEncryption = _$v.wifiEncryption;
      _locationId = _$v.locationId;
      _nickname = _$v.nickname;
      _installPoint = _$v.installPoint;
      _deviceType = _$v.deviceType;
      _deviceModel = _$v.deviceModel;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PuckTicket other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PuckTicket;
  }

  @override
  void update(void Function(PuckTicketBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PuckTicket build() {
    final _$result = _$v ??
        new _$PuckTicket._(
            apiAccessToken: apiAccessToken,
            cloudHostname: cloudHostname,
            wifiSsid: wifiSsid,
            wifiPassword: wifiPassword,
            wifiEncryption: wifiEncryption,
            locationId: locationId,
            nickname: nickname,
            installPoint: installPoint,
            deviceType: deviceType,
            deviceModel: deviceModel);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
