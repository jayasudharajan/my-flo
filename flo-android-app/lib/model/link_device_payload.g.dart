// GENERATED CODE - DO NOT MODIFY BY HAND

part of link_device_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<LinkDevicePayload> _$linkDevicePayloadSerializer =
    new _$LinkDevicePayloadSerializer();

class _$LinkDevicePayloadSerializer
    implements StructuredSerializer<LinkDevicePayload> {
  @override
  final Iterable<Type> types = const [LinkDevicePayload, _$LinkDevicePayload];
  @override
  final String wireName = 'LinkDevicePayload';

  @override
  Iterable<Object> serialize(Serializers serializers, LinkDevicePayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.nickname != null) {
      result
        ..add('nickname')
        ..add(serializers.serialize(object.nickname,
            specifiedType: const FullType(String)));
    }
    if (object.location != null) {
      result
        ..add('location')
        ..add(serializers.serialize(object.location,
            specifiedType: const FullType(Id)));
    }
    if (object.deviceType != null) {
      result
        ..add('deviceType')
        ..add(serializers.serialize(object.deviceType,
            specifiedType: const FullType(String)));
    }
    if (object.deviceModel != null) {
      result
        ..add('deviceModel')
        ..add(serializers.serialize(object.deviceModel,
            specifiedType: const FullType(String)));
    }
    if (object.area != null) {
      result
        ..add('area')
        ..add(serializers.serialize(object.area,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  LinkDevicePayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LinkDevicePayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'nickname':
          result.nickname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'location':
          result.location.replace(serializers.deserialize(value,
              specifiedType: const FullType(Id)) as Id);
          break;
        case 'deviceType':
          result.deviceType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceModel':
          result.deviceModel = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'area':
          result.area = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$LinkDevicePayload extends LinkDevicePayload {
  @override
  final String macAddress;
  @override
  final String nickname;
  @override
  final Id location;
  @override
  final String deviceType;
  @override
  final String deviceModel;
  @override
  final String area;

  factory _$LinkDevicePayload(
          [void Function(LinkDevicePayloadBuilder) updates]) =>
      (new LinkDevicePayloadBuilder()..update(updates)).build();

  _$LinkDevicePayload._(
      {this.macAddress,
      this.nickname,
      this.location,
      this.deviceType,
      this.deviceModel,
      this.area})
      : super._();

  @override
  LinkDevicePayload rebuild(void Function(LinkDevicePayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LinkDevicePayloadBuilder toBuilder() =>
      new LinkDevicePayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LinkDevicePayload &&
        macAddress == other.macAddress &&
        nickname == other.nickname &&
        location == other.location &&
        deviceType == other.deviceType &&
        deviceModel == other.deviceModel &&
        area == other.area;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, macAddress.hashCode), nickname.hashCode),
                    location.hashCode),
                deviceType.hashCode),
            deviceModel.hashCode),
        area.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LinkDevicePayload')
          ..add('macAddress', macAddress)
          ..add('nickname', nickname)
          ..add('location', location)
          ..add('deviceType', deviceType)
          ..add('deviceModel', deviceModel)
          ..add('area', area))
        .toString();
  }
}

class LinkDevicePayloadBuilder
    implements Builder<LinkDevicePayload, LinkDevicePayloadBuilder> {
  _$LinkDevicePayload _$v;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  IdBuilder _location;
  IdBuilder get location => _$this._location ??= new IdBuilder();
  set location(IdBuilder location) => _$this._location = location;

  String _deviceType;
  String get deviceType => _$this._deviceType;
  set deviceType(String deviceType) => _$this._deviceType = deviceType;

  String _deviceModel;
  String get deviceModel => _$this._deviceModel;
  set deviceModel(String deviceModel) => _$this._deviceModel = deviceModel;

  String _area;
  String get area => _$this._area;
  set area(String area) => _$this._area = area;

  LinkDevicePayloadBuilder();

  LinkDevicePayloadBuilder get _$this {
    if (_$v != null) {
      _macAddress = _$v.macAddress;
      _nickname = _$v.nickname;
      _location = _$v.location?.toBuilder();
      _deviceType = _$v.deviceType;
      _deviceModel = _$v.deviceModel;
      _area = _$v.area;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LinkDevicePayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LinkDevicePayload;
  }

  @override
  void update(void Function(LinkDevicePayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LinkDevicePayload build() {
    _$LinkDevicePayload _$result;
    try {
      _$result = _$v ??
          new _$LinkDevicePayload._(
              macAddress: macAddress,
              nickname: nickname,
              location: _location?.build(),
              deviceType: deviceType,
              deviceModel: deviceModel,
              area: area);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'location';
        _location?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'LinkDevicePayload', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
