// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alert> _$alertSerializer = new _$AlertSerializer();

class _$AlertSerializer implements StructuredSerializer<Alert> {
  @override
  final Iterable<Type> types = const [Alert, _$Alert];
  @override
  final String wireName = 'Alert';

  @override
  Iterable<Object> serialize(Serializers serializers, Alert object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.alarm != null) {
      result
        ..add('alarm')
        ..add(serializers.serialize(object.alarm,
            specifiedType: const FullType(Alarm)));
    }
    if (object.displayTitle != null) {
      result
        ..add('displayTitle')
        ..add(serializers.serialize(object.displayTitle,
            specifiedType: const FullType(String)));
    }
    if (object.displayMessage != null) {
      result
        ..add('displayMessage')
        ..add(serializers.serialize(object.displayMessage,
            specifiedType: const FullType(String)));
    }
    if (object.icdId != null) {
      result
        ..add('icdId')
        ..add(serializers.serialize(object.icdId,
            specifiedType: const FullType(String)));
    }
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    if (object.reason != null) {
      result
        ..add('reason')
        ..add(serializers.serialize(object.reason,
            specifiedType: const FullType(String)));
    }
    if (object.snoozeTo != null) {
      result
        ..add('snoozeTo')
        ..add(serializers.serialize(object.snoozeTo,
            specifiedType: const FullType(String)));
    }
    if (object.firmwareValue != null) {
      result
        ..add('fwValues')
        ..add(serializers.serialize(object.firmwareValue,
            specifiedType: const FullType(AlertFirmwareValue)));
    }
    if (object.userFeedbacks != null) {
      result
        ..add('userFeedback')
        ..add(serializers.serialize(object.userFeedbacks,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlertFeedbacks)])));
    }
    if (object.locationId != null) {
      result
        ..add('locationId')
        ..add(serializers.serialize(object.locationId,
            specifiedType: const FullType(String)));
    }
    if (object.systemMode != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(String)));
    }
    if (object.updateAt != null) {
      result
        ..add('updateAt')
        ..add(serializers.serialize(object.updateAt,
            specifiedType: const FullType(String)));
    }
    if (object.createAt != null) {
      result
        ..add('createAt')
        ..add(serializers.serialize(object.createAt,
            specifiedType: const FullType(String)));
    }
    if (object.resolvedAt != null) {
      result
        ..add('resolvedAt')
        ..add(serializers.serialize(object.resolvedAt,
            specifiedType: const FullType(String)));
    }
    if (object.resolutionDate != null) {
      result
        ..add('resolutionDate')
        ..add(serializers.serialize(object.resolutionDate,
            specifiedType: const FullType(String)));
    }
    if (object.healthTest != null) {
      result
        ..add('healthTest')
        ..add(serializers.serialize(object.healthTest,
            specifiedType: const FullType(HealthTest)));
    }
    return result;
  }

  @override
  Alert deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertBuilder();

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
        case 'alarm':
          result.alarm.replace(serializers.deserialize(value,
              specifiedType: const FullType(Alarm)) as Alarm);
          break;
        case 'displayTitle':
          result.displayTitle = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'displayMessage':
          result.displayMessage = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'icdId':
          result.icdId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'reason':
          result.reason = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'snoozeTo':
          result.snoozeTo = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'fwValues':
          result.firmwareValue.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertFirmwareValue))
              as AlertFirmwareValue);
          break;
        case 'userFeedback':
          result.userFeedbacks.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlertFeedbacks)]))
              as BuiltList<dynamic>);
          break;
        case 'locationId':
          result.locationId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'systemMode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'updateAt':
          result.updateAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'createAt':
          result.createAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'resolvedAt':
          result.resolvedAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'resolutionDate':
          result.resolutionDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'healthTest':
          result.healthTest.replace(serializers.deserialize(value,
              specifiedType: const FullType(HealthTest)) as HealthTest);
          break;
      }
    }

    return result.build();
  }
}

class _$Alert extends Alert {
  @override
  final String id;
  @override
  final Alarm alarm;
  @override
  final String displayTitle;
  @override
  final String displayMessage;
  @override
  final String icdId;
  @override
  final String macAddress;
  @override
  final String deviceId;
  @override
  final String status;
  @override
  final String reason;
  @override
  final String snoozeTo;
  @override
  final AlertFirmwareValue firmwareValue;
  @override
  final BuiltList<AlertFeedbacks> userFeedbacks;
  @override
  final String locationId;
  @override
  final String systemMode;
  @override
  final String updateAt;
  @override
  final String createAt;
  @override
  final String resolvedAt;
  @override
  final String resolutionDate;
  @override
  final HealthTest healthTest;
  @override
  final Location location;
  @override
  final Device device;

  factory _$Alert([void Function(AlertBuilder) updates]) =>
      (new AlertBuilder()..update(updates)).build();

  _$Alert._(
      {this.id,
      this.alarm,
      this.displayTitle,
      this.displayMessage,
      this.icdId,
      this.macAddress,
      this.deviceId,
      this.status,
      this.reason,
      this.snoozeTo,
      this.firmwareValue,
      this.userFeedbacks,
      this.locationId,
      this.systemMode,
      this.updateAt,
      this.createAt,
      this.resolvedAt,
      this.resolutionDate,
      this.healthTest,
      this.location,
      this.device})
      : super._();

  @override
  Alert rebuild(void Function(AlertBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertBuilder toBuilder() => new AlertBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alert &&
        id == other.id &&
        alarm == other.alarm &&
        displayTitle == other.displayTitle &&
        displayMessage == other.displayMessage &&
        icdId == other.icdId &&
        macAddress == other.macAddress &&
        deviceId == other.deviceId &&
        status == other.status &&
        reason == other.reason &&
        snoozeTo == other.snoozeTo &&
        firmwareValue == other.firmwareValue &&
        userFeedbacks == other.userFeedbacks &&
        locationId == other.locationId &&
        systemMode == other.systemMode &&
        updateAt == other.updateAt &&
        createAt == other.createAt &&
        resolvedAt == other.resolvedAt &&
        resolutionDate == other.resolutionDate &&
        healthTest == other.healthTest &&
        location == other.location &&
        device == other.device;
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
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(
                                                                        $jc(
                                                                            $jc($jc($jc(0, id.hashCode), alarm.hashCode),
                                                                                displayTitle.hashCode),
                                                                            displayMessage.hashCode),
                                                                        icdId.hashCode),
                                                                    macAddress.hashCode),
                                                                deviceId.hashCode),
                                                            status.hashCode),
                                                        reason.hashCode),
                                                    snoozeTo.hashCode),
                                                firmwareValue.hashCode),
                                            userFeedbacks.hashCode),
                                        locationId.hashCode),
                                    systemMode.hashCode),
                                updateAt.hashCode),
                            createAt.hashCode),
                        resolvedAt.hashCode),
                    resolutionDate.hashCode),
                healthTest.hashCode),
            location.hashCode),
        device.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alert')
          ..add('id', id)
          ..add('alarm', alarm)
          ..add('displayTitle', displayTitle)
          ..add('displayMessage', displayMessage)
          ..add('icdId', icdId)
          ..add('macAddress', macAddress)
          ..add('deviceId', deviceId)
          ..add('status', status)
          ..add('reason', reason)
          ..add('snoozeTo', snoozeTo)
          ..add('firmwareValue', firmwareValue)
          ..add('userFeedbacks', userFeedbacks)
          ..add('locationId', locationId)
          ..add('systemMode', systemMode)
          ..add('updateAt', updateAt)
          ..add('createAt', createAt)
          ..add('resolvedAt', resolvedAt)
          ..add('resolutionDate', resolutionDate)
          ..add('healthTest', healthTest)
          ..add('location', location)
          ..add('device', device))
        .toString();
  }
}

class AlertBuilder implements Builder<Alert, AlertBuilder> {
  _$Alert _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  AlarmBuilder _alarm;
  AlarmBuilder get alarm => _$this._alarm ??= new AlarmBuilder();
  set alarm(AlarmBuilder alarm) => _$this._alarm = alarm;

  String _displayTitle;
  String get displayTitle => _$this._displayTitle;
  set displayTitle(String displayTitle) => _$this._displayTitle = displayTitle;

  String _displayMessage;
  String get displayMessage => _$this._displayMessage;
  set displayMessage(String displayMessage) =>
      _$this._displayMessage = displayMessage;

  String _icdId;
  String get icdId => _$this._icdId;
  set icdId(String icdId) => _$this._icdId = icdId;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  String _reason;
  String get reason => _$this._reason;
  set reason(String reason) => _$this._reason = reason;

  String _snoozeTo;
  String get snoozeTo => _$this._snoozeTo;
  set snoozeTo(String snoozeTo) => _$this._snoozeTo = snoozeTo;

  AlertFirmwareValueBuilder _firmwareValue;
  AlertFirmwareValueBuilder get firmwareValue =>
      _$this._firmwareValue ??= new AlertFirmwareValueBuilder();
  set firmwareValue(AlertFirmwareValueBuilder firmwareValue) =>
      _$this._firmwareValue = firmwareValue;

  ListBuilder<AlertFeedbacks> _userFeedbacks;
  ListBuilder<AlertFeedbacks> get userFeedbacks =>
      _$this._userFeedbacks ??= new ListBuilder<AlertFeedbacks>();
  set userFeedbacks(ListBuilder<AlertFeedbacks> userFeedbacks) =>
      _$this._userFeedbacks = userFeedbacks;

  String _locationId;
  String get locationId => _$this._locationId;
  set locationId(String locationId) => _$this._locationId = locationId;

  String _systemMode;
  String get systemMode => _$this._systemMode;
  set systemMode(String systemMode) => _$this._systemMode = systemMode;

  String _updateAt;
  String get updateAt => _$this._updateAt;
  set updateAt(String updateAt) => _$this._updateAt = updateAt;

  String _createAt;
  String get createAt => _$this._createAt;
  set createAt(String createAt) => _$this._createAt = createAt;

  String _resolvedAt;
  String get resolvedAt => _$this._resolvedAt;
  set resolvedAt(String resolvedAt) => _$this._resolvedAt = resolvedAt;

  String _resolutionDate;
  String get resolutionDate => _$this._resolutionDate;
  set resolutionDate(String resolutionDate) =>
      _$this._resolutionDate = resolutionDate;

  HealthTestBuilder _healthTest;
  HealthTestBuilder get healthTest =>
      _$this._healthTest ??= new HealthTestBuilder();
  set healthTest(HealthTestBuilder healthTest) =>
      _$this._healthTest = healthTest;

  LocationBuilder _location;
  LocationBuilder get location => _$this._location ??= new LocationBuilder();
  set location(LocationBuilder location) => _$this._location = location;

  DeviceBuilder _device;
  DeviceBuilder get device => _$this._device ??= new DeviceBuilder();
  set device(DeviceBuilder device) => _$this._device = device;

  AlertBuilder();

  AlertBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _alarm = _$v.alarm?.toBuilder();
      _displayTitle = _$v.displayTitle;
      _displayMessage = _$v.displayMessage;
      _icdId = _$v.icdId;
      _macAddress = _$v.macAddress;
      _deviceId = _$v.deviceId;
      _status = _$v.status;
      _reason = _$v.reason;
      _snoozeTo = _$v.snoozeTo;
      _firmwareValue = _$v.firmwareValue?.toBuilder();
      _userFeedbacks = _$v.userFeedbacks?.toBuilder();
      _locationId = _$v.locationId;
      _systemMode = _$v.systemMode;
      _updateAt = _$v.updateAt;
      _createAt = _$v.createAt;
      _resolvedAt = _$v.resolvedAt;
      _resolutionDate = _$v.resolutionDate;
      _healthTest = _$v.healthTest?.toBuilder();
      _location = _$v.location?.toBuilder();
      _device = _$v.device?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alert other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alert;
  }

  @override
  void update(void Function(AlertBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alert build() {
    _$Alert _$result;
    try {
      _$result = _$v ??
          new _$Alert._(
              id: id,
              alarm: _alarm?.build(),
              displayTitle: displayTitle,
              displayMessage: displayMessage,
              icdId: icdId,
              macAddress: macAddress,
              deviceId: deviceId,
              status: status,
              reason: reason,
              snoozeTo: snoozeTo,
              firmwareValue: _firmwareValue?.build(),
              userFeedbacks: _userFeedbacks?.build(),
              locationId: locationId,
              systemMode: systemMode,
              updateAt: updateAt,
              createAt: createAt,
              resolvedAt: resolvedAt,
              resolutionDate: resolutionDate,
              healthTest: _healthTest?.build(),
              location: _location?.build(),
              device: _device?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'alarm';
        _alarm?.build();

        _$failedField = 'firmwareValue';
        _firmwareValue?.build();
        _$failedField = 'userFeedbacks';
        _userFeedbacks?.build();

        _$failedField = 'healthTest';
        _healthTest?.build();
        _$failedField = 'location';
        _location?.build();
        _$failedField = 'device';
        _device?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Alert', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
