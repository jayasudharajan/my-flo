// GENERATED CODE - DO NOT MODIFY BY HAND

part of wifi_station;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WifiStation> _$wifiStationSerializer = new _$WifiStationSerializer();

class _$WifiStationSerializer implements StructuredSerializer<WifiStation> {
  @override
  final Iterable<Type> types = const [WifiStation, _$WifiStation];
  @override
  final String wireName = 'WifiStation';

  @override
  Iterable<Object> serialize(Serializers serializers, WifiStation object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'wifi_sta_ssid',
      serializers.serialize(object.wifiStaSsid,
          specifiedType: const FullType(String)),
      'wifi_sta_encryption',
      serializers.serialize(object.wifiStaEncryption,
          specifiedType: const FullType(String)),
      'wifi_sta_password',
      serializers.serialize(object.wifiStaPassword,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  WifiStation deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WifiStationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'wifi_sta_ssid':
          result.wifiStaSsid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_sta_encryption':
          result.wifiStaEncryption = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_sta_password':
          result.wifiStaPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$WifiStation extends WifiStation {
  @override
  final String wifiStaEnabled;
  @override
  final String wifiStaSsid;
  @override
  final String wifiStaEncryption;
  @override
  final String wifiStaPassword;

  factory _$WifiStation([void Function(WifiStationBuilder) updates]) =>
      (new WifiStationBuilder()..update(updates)).build();

  _$WifiStation._(
      {this.wifiStaEnabled,
      this.wifiStaSsid,
      this.wifiStaEncryption,
      this.wifiStaPassword})
      : super._() {
    if (wifiStaSsid == null) {
      throw new BuiltValueNullFieldError('WifiStation', 'wifiStaSsid');
    }
    if (wifiStaEncryption == null) {
      throw new BuiltValueNullFieldError('WifiStation', 'wifiStaEncryption');
    }
    if (wifiStaPassword == null) {
      throw new BuiltValueNullFieldError('WifiStation', 'wifiStaPassword');
    }
  }

  @override
  WifiStation rebuild(void Function(WifiStationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WifiStationBuilder toBuilder() => new WifiStationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WifiStation &&
        wifiStaEnabled == other.wifiStaEnabled &&
        wifiStaSsid == other.wifiStaSsid &&
        wifiStaEncryption == other.wifiStaEncryption &&
        wifiStaPassword == other.wifiStaPassword;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, wifiStaEnabled.hashCode), wifiStaSsid.hashCode),
            wifiStaEncryption.hashCode),
        wifiStaPassword.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WifiStation')
          ..add('wifiStaEnabled', wifiStaEnabled)
          ..add('wifiStaSsid', wifiStaSsid)
          ..add('wifiStaEncryption', wifiStaEncryption)
          ..add('wifiStaPassword', wifiStaPassword))
        .toString();
  }
}

class WifiStationBuilder implements Builder<WifiStation, WifiStationBuilder> {
  _$WifiStation _$v;

  String _wifiStaEnabled;
  String get wifiStaEnabled => _$this._wifiStaEnabled;
  set wifiStaEnabled(String wifiStaEnabled) =>
      _$this._wifiStaEnabled = wifiStaEnabled;

  String _wifiStaSsid;
  String get wifiStaSsid => _$this._wifiStaSsid;
  set wifiStaSsid(String wifiStaSsid) => _$this._wifiStaSsid = wifiStaSsid;

  String _wifiStaEncryption;
  String get wifiStaEncryption => _$this._wifiStaEncryption;
  set wifiStaEncryption(String wifiStaEncryption) =>
      _$this._wifiStaEncryption = wifiStaEncryption;

  String _wifiStaPassword;
  String get wifiStaPassword => _$this._wifiStaPassword;
  set wifiStaPassword(String wifiStaPassword) =>
      _$this._wifiStaPassword = wifiStaPassword;

  WifiStationBuilder();

  WifiStationBuilder get _$this {
    if (_$v != null) {
      _wifiStaEnabled = _$v.wifiStaEnabled;
      _wifiStaSsid = _$v.wifiStaSsid;
      _wifiStaEncryption = _$v.wifiStaEncryption;
      _wifiStaPassword = _$v.wifiStaPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WifiStation other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WifiStation;
  }

  @override
  void update(void Function(WifiStationBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WifiStation build() {
    final _$result = _$v ??
        new _$WifiStation._(
            wifiStaEnabled: wifiStaEnabled,
            wifiStaSsid: wifiStaSsid,
            wifiStaEncryption: wifiStaEncryption,
            wifiStaPassword: wifiStaPassword);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
