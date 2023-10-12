// GENERATED CODE - DO NOT MODIFY BY HAND

part of device;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Device> _$deviceSerializer = new _$DeviceSerializer();

class _$DeviceSerializer implements StructuredSerializer<Device> {
  @override
  final Iterable<Type> types = const [Device, _$Device];
  @override
  final String wireName = 'Device';

  @override
  Iterable<Object> serialize(Serializers serializers, Device object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.prvInstallation != null) {
      result
        ..add('prvInstallation')
        ..add(serializers.serialize(object.prvInstallation,
            specifiedType: const FullType(String)));
    }
    if (object.irrigationType != null) {
      result
        ..add('irrigationType')
        ..add(serializers.serialize(object.irrigationType,
            specifiedType: const FullType(String)));
    }
    if (object.installationPoint != null) {
      result
        ..add('installationPoint')
        ..add(serializers.serialize(object.installationPoint,
            specifiedType: const FullType(String)));
    }
    if (object.nickname != null) {
      result
        ..add('nickname')
        ..add(serializers.serialize(object.nickname,
            specifiedType: const FullType(String)));
    }
    if (object.valve != null) {
      result
        ..add('valve')
        ..add(serializers.serialize(object.valve,
            specifiedType: const FullType(Valve)));
    }
    if (object.valveState != null) {
      result
        ..add('valveState')
        ..add(serializers.serialize(object.valveState,
            specifiedType: const FullType(Valve)));
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
    if (object.isConnected != null) {
      result
        ..add('isConnected')
        ..add(serializers.serialize(object.isConnected,
            specifiedType: const FullType(bool)));
    }
    if (object.isPaired != null) {
      result
        ..add('isPaired')
        ..add(serializers.serialize(object.isPaired,
            specifiedType: const FullType(bool)));
    }
    if (object.lastHeardFromTime != null) {
      result
        ..add('lastHeardFromTime')
        ..add(serializers.serialize(object.lastHeardFromTime,
            specifiedType: const FullType(String)));
    }
    if (object.location != null) {
      result
        ..add('location')
        ..add(serializers.serialize(object.location,
            specifiedType: const FullType(Id)));
    }
    if (object.firmwareVersion != null) {
      result
        ..add('fwVersion')
        ..add(serializers.serialize(object.firmwareVersion,
            specifiedType: const FullType(String)));
    }
    if (object.firmwareProperties != null) {
      result
        ..add('fwProperties')
        ..add(serializers.serialize(object.firmwareProperties,
            specifiedType: const FullType(FirmwareProperties)));
    }
    if (object.systemMode != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(PendingSystemMode)));
    }
    if (object.hardwareThresholds != null) {
      result
        ..add('hardwareThresholds')
        ..add(serializers.serialize(object.hardwareThresholds,
            specifiedType: const FullType(HardwareThresholds)));
    }
    if (object.connectivity != null) {
      result
        ..add('connectivity')
        ..add(serializers.serialize(object.connectivity,
            specifiedType: const FullType(Connectivity)));
    }
    if (object.notifications != null) {
      result
        ..add('notifications')
        ..add(serializers.serialize(object.notifications,
            specifiedType: const FullType(AlertStatistics)));
    }
    if (object.telemetries != null) {
      result
        ..add('telemetry')
        ..add(serializers.serialize(object.telemetries,
            specifiedType: const FullType(Telemetries)));
    }
    if (object.installStatus != null) {
      result
        ..add('installStatus')
        ..add(serializers.serialize(object.installStatus,
            specifiedType: const FullType(InstallStatus)));
    }
    if (object.healthTest != null) {
      result
        ..add('healthTest')
        ..add(serializers.serialize(object.healthTest,
            specifiedType: const FullType(HealthTest)));
    }
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.irrigationSchedule != null) {
      result
        ..add('irrigationSchedule')
        ..add(serializers.serialize(object.irrigationSchedule,
            specifiedType: const FullType(IrrigationSchedule)));
    }
    if (object.learning != null) {
      result
        ..add('learning')
        ..add(serializers.serialize(object.learning,
            specifiedType: const FullType(Learning)));
    }
    if (object.certificate != null) {
      result
        ..add('pairingData')
        ..add(serializers.serialize(object.certificate,
            specifiedType: const FullType(Certificate2)));
    }
    if (object.serialNumber != null) {
      result
        ..add('serialNumber')
        ..add(serializers.serialize(object.serialNumber,
            specifiedType: const FullType(String)));
    }
    if (object.estimateWaterUsage != null) {
      result
        ..add('waterConsumption')
        ..add(serializers.serialize(object.estimateWaterUsage,
            specifiedType: const FullType(EstimateWaterUsage)));
    }
    return result;
  }

  @override
  Device deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeviceBuilder();

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
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'prvInstallation':
          result.prvInstallation = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'irrigationType':
          result.irrigationType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'installationPoint':
          result.installationPoint = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'nickname':
          result.nickname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'valve':
          result.valve.replace(serializers.deserialize(value,
              specifiedType: const FullType(Valve)) as Valve);
          break;
        case 'valveState':
          result.valveState.replace(serializers.deserialize(value,
              specifiedType: const FullType(Valve)) as Valve);
          break;
        case 'deviceType':
          result.deviceType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceModel':
          result.deviceModel = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isConnected':
          result.isConnected = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'isPaired':
          result.isPaired = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'lastHeardFromTime':
          result.lastHeardFromTime = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'location':
          result.location.replace(serializers.deserialize(value,
              specifiedType: const FullType(Id)) as Id);
          break;
        case 'fwVersion':
          result.firmwareVersion = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'fwProperties':
          result.firmwareProperties.replace(serializers.deserialize(value,
                  specifiedType: const FullType(FirmwareProperties))
              as FirmwareProperties);
          break;
        case 'systemMode':
          result.systemMode.replace(serializers.deserialize(value,
                  specifiedType: const FullType(PendingSystemMode))
              as PendingSystemMode);
          break;
        case 'hardwareThresholds':
          result.hardwareThresholds.replace(serializers.deserialize(value,
                  specifiedType: const FullType(HardwareThresholds))
              as HardwareThresholds);
          break;
        case 'connectivity':
          result.connectivity.replace(serializers.deserialize(value,
              specifiedType: const FullType(Connectivity)) as Connectivity);
          break;
        case 'notifications':
          result.notifications.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertStatistics))
              as AlertStatistics);
          break;
        case 'telemetry':
          result.telemetries.replace(serializers.deserialize(value,
              specifiedType: const FullType(Telemetries)) as Telemetries);
          break;
        case 'installStatus':
          result.installStatus.replace(serializers.deserialize(value,
              specifiedType: const FullType(InstallStatus)) as InstallStatus);
          break;
        case 'healthTest':
          result.healthTest.replace(serializers.deserialize(value,
              specifiedType: const FullType(HealthTest)) as HealthTest);
          break;
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'irrigationSchedule':
          result.irrigationSchedule.replace(serializers.deserialize(value,
                  specifiedType: const FullType(IrrigationSchedule))
              as IrrigationSchedule);
          break;
        case 'learning':
          result.learning.replace(serializers.deserialize(value,
              specifiedType: const FullType(Learning)) as Learning);
          break;
        case 'pairingData':
          result.certificate.replace(serializers.deserialize(value,
              specifiedType: const FullType(Certificate2)) as Certificate2);
          break;
        case 'serialNumber':
          result.serialNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'waterConsumption':
          result.estimateWaterUsage.replace(serializers.deserialize(value,
                  specifiedType: const FullType(EstimateWaterUsage))
              as EstimateWaterUsage);
          break;
      }
    }

    return result.build();
  }
}

class _$Device extends Device {
  @override
  final String id;
  @override
  final String macAddress;
  @override
  final String prvInstallation;
  @override
  final String irrigationType;
  @override
  final String installationPoint;
  @override
  final String nickname;
  @override
  final Valve valve;
  @override
  final Valve valveState;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final String deviceType;
  @override
  final String deviceModel;
  @override
  final bool isConnected;
  @override
  final bool isPaired;
  @override
  final String lastHeardFromTime;
  @override
  final Id location;
  @override
  final String firmwareVersion;
  @override
  final FirmwareProperties firmwareProperties;
  @override
  final PendingSystemMode systemMode;
  @override
  final HardwareThresholds hardwareThresholds;
  @override
  final Connectivity connectivity;
  @override
  final AlertStatistics notifications;
  @override
  final Telemetries telemetries;
  @override
  final InstallStatus installStatus;
  @override
  final HealthTest healthTest;
  @override
  final BuiltMap<String, String> fsTimestamp;
  @override
  final String deviceId;
  @override
  final IrrigationSchedule irrigationSchedule;
  @override
  final Learning learning;
  @override
  final Certificate2 certificate;
  @override
  final String serialNumber;
  @override
  final EstimateWaterUsage estimateWaterUsage;
  @override
  final bool dirty;

  factory _$Device([void Function(DeviceBuilder) updates]) =>
      (new DeviceBuilder()..update(updates)).build();

  _$Device._(
      {this.id,
      this.macAddress,
      this.prvInstallation,
      this.irrigationType,
      this.installationPoint,
      this.nickname,
      this.valve,
      this.valveState,
      this.createdAt,
      this.updatedAt,
      this.deviceType,
      this.deviceModel,
      this.isConnected,
      this.isPaired,
      this.lastHeardFromTime,
      this.location,
      this.firmwareVersion,
      this.firmwareProperties,
      this.systemMode,
      this.hardwareThresholds,
      this.connectivity,
      this.notifications,
      this.telemetries,
      this.installStatus,
      this.healthTest,
      this.fsTimestamp,
      this.deviceId,
      this.irrigationSchedule,
      this.learning,
      this.certificate,
      this.serialNumber,
      this.estimateWaterUsage,
      this.dirty})
      : super._();

  @override
  Device rebuild(void Function(DeviceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceBuilder toBuilder() => new DeviceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Device &&
        id == other.id &&
        macAddress == other.macAddress &&
        prvInstallation == other.prvInstallation &&
        irrigationType == other.irrigationType &&
        installationPoint == other.installationPoint &&
        nickname == other.nickname &&
        valve == other.valve &&
        valveState == other.valveState &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        deviceType == other.deviceType &&
        deviceModel == other.deviceModel &&
        isConnected == other.isConnected &&
        isPaired == other.isPaired &&
        lastHeardFromTime == other.lastHeardFromTime &&
        location == other.location &&
        firmwareVersion == other.firmwareVersion &&
        firmwareProperties == other.firmwareProperties &&
        systemMode == other.systemMode &&
        hardwareThresholds == other.hardwareThresholds &&
        connectivity == other.connectivity &&
        notifications == other.notifications &&
        telemetries == other.telemetries &&
        installStatus == other.installStatus &&
        healthTest == other.healthTest &&
        fsTimestamp == other.fsTimestamp &&
        deviceId == other.deviceId &&
        irrigationSchedule == other.irrigationSchedule &&
        learning == other.learning &&
        certificate == other.certificate &&
        serialNumber == other.serialNumber &&
        estimateWaterUsage == other.estimateWaterUsage &&
        dirty == other.dirty;
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
                                                                            $jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc(0, id.hashCode), macAddress.hashCode), prvInstallation.hashCode), irrigationType.hashCode), installationPoint.hashCode), nickname.hashCode), valve.hashCode), valveState.hashCode), createdAt.hashCode), updatedAt.hashCode), deviceType.hashCode), deviceModel.hashCode), isConnected.hashCode), isPaired.hashCode),
                                                                                lastHeardFromTime.hashCode),
                                                                            location.hashCode),
                                                                        firmwareVersion.hashCode),
                                                                    firmwareProperties.hashCode),
                                                                systemMode.hashCode),
                                                            hardwareThresholds.hashCode),
                                                        connectivity.hashCode),
                                                    notifications.hashCode),
                                                telemetries.hashCode),
                                            installStatus.hashCode),
                                        healthTest.hashCode),
                                    fsTimestamp.hashCode),
                                deviceId.hashCode),
                            irrigationSchedule.hashCode),
                        learning.hashCode),
                    certificate.hashCode),
                serialNumber.hashCode),
            estimateWaterUsage.hashCode),
        dirty.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Device')
          ..add('id', id)
          ..add('macAddress', macAddress)
          ..add('prvInstallation', prvInstallation)
          ..add('irrigationType', irrigationType)
          ..add('installationPoint', installationPoint)
          ..add('nickname', nickname)
          ..add('valve', valve)
          ..add('valveState', valveState)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('deviceType', deviceType)
          ..add('deviceModel', deviceModel)
          ..add('isConnected', isConnected)
          ..add('isPaired', isPaired)
          ..add('lastHeardFromTime', lastHeardFromTime)
          ..add('location', location)
          ..add('firmwareVersion', firmwareVersion)
          ..add('firmwareProperties', firmwareProperties)
          ..add('systemMode', systemMode)
          ..add('hardwareThresholds', hardwareThresholds)
          ..add('connectivity', connectivity)
          ..add('notifications', notifications)
          ..add('telemetries', telemetries)
          ..add('installStatus', installStatus)
          ..add('healthTest', healthTest)
          ..add('fsTimestamp', fsTimestamp)
          ..add('deviceId', deviceId)
          ..add('irrigationSchedule', irrigationSchedule)
          ..add('learning', learning)
          ..add('certificate', certificate)
          ..add('serialNumber', serialNumber)
          ..add('estimateWaterUsage', estimateWaterUsage)
          ..add('dirty', dirty))
        .toString();
  }
}

class DeviceBuilder implements Builder<Device, DeviceBuilder> {
  _$Device _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  String _prvInstallation;
  String get prvInstallation => _$this._prvInstallation;
  set prvInstallation(String prvInstallation) =>
      _$this._prvInstallation = prvInstallation;

  String _irrigationType;
  String get irrigationType => _$this._irrigationType;
  set irrigationType(String irrigationType) =>
      _$this._irrigationType = irrigationType;

  String _installationPoint;
  String get installationPoint => _$this._installationPoint;
  set installationPoint(String installationPoint) =>
      _$this._installationPoint = installationPoint;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  ValveBuilder _valve;
  ValveBuilder get valve => _$this._valve ??= new ValveBuilder();
  set valve(ValveBuilder valve) => _$this._valve = valve;

  ValveBuilder _valveState;
  ValveBuilder get valveState => _$this._valveState ??= new ValveBuilder();
  set valveState(ValveBuilder valveState) => _$this._valveState = valveState;

  String _createdAt;
  String get createdAt => _$this._createdAt;
  set createdAt(String createdAt) => _$this._createdAt = createdAt;

  String _updatedAt;
  String get updatedAt => _$this._updatedAt;
  set updatedAt(String updatedAt) => _$this._updatedAt = updatedAt;

  String _deviceType;
  String get deviceType => _$this._deviceType;
  set deviceType(String deviceType) => _$this._deviceType = deviceType;

  String _deviceModel;
  String get deviceModel => _$this._deviceModel;
  set deviceModel(String deviceModel) => _$this._deviceModel = deviceModel;

  bool _isConnected;
  bool get isConnected => _$this._isConnected;
  set isConnected(bool isConnected) => _$this._isConnected = isConnected;

  bool _isPaired;
  bool get isPaired => _$this._isPaired;
  set isPaired(bool isPaired) => _$this._isPaired = isPaired;

  String _lastHeardFromTime;
  String get lastHeardFromTime => _$this._lastHeardFromTime;
  set lastHeardFromTime(String lastHeardFromTime) =>
      _$this._lastHeardFromTime = lastHeardFromTime;

  IdBuilder _location;
  IdBuilder get location => _$this._location ??= new IdBuilder();
  set location(IdBuilder location) => _$this._location = location;

  String _firmwareVersion;
  String get firmwareVersion => _$this._firmwareVersion;
  set firmwareVersion(String firmwareVersion) =>
      _$this._firmwareVersion = firmwareVersion;

  FirmwarePropertiesBuilder _firmwareProperties;
  FirmwarePropertiesBuilder get firmwareProperties =>
      _$this._firmwareProperties ??= new FirmwarePropertiesBuilder();
  set firmwareProperties(FirmwarePropertiesBuilder firmwareProperties) =>
      _$this._firmwareProperties = firmwareProperties;

  PendingSystemModeBuilder _systemMode;
  PendingSystemModeBuilder get systemMode =>
      _$this._systemMode ??= new PendingSystemModeBuilder();
  set systemMode(PendingSystemModeBuilder systemMode) =>
      _$this._systemMode = systemMode;

  HardwareThresholdsBuilder _hardwareThresholds;
  HardwareThresholdsBuilder get hardwareThresholds =>
      _$this._hardwareThresholds ??= new HardwareThresholdsBuilder();
  set hardwareThresholds(HardwareThresholdsBuilder hardwareThresholds) =>
      _$this._hardwareThresholds = hardwareThresholds;

  ConnectivityBuilder _connectivity;
  ConnectivityBuilder get connectivity =>
      _$this._connectivity ??= new ConnectivityBuilder();
  set connectivity(ConnectivityBuilder connectivity) =>
      _$this._connectivity = connectivity;

  AlertStatisticsBuilder _notifications;
  AlertStatisticsBuilder get notifications =>
      _$this._notifications ??= new AlertStatisticsBuilder();
  set notifications(AlertStatisticsBuilder notifications) =>
      _$this._notifications = notifications;

  TelemetriesBuilder _telemetries;
  TelemetriesBuilder get telemetries =>
      _$this._telemetries ??= new TelemetriesBuilder();
  set telemetries(TelemetriesBuilder telemetries) =>
      _$this._telemetries = telemetries;

  InstallStatusBuilder _installStatus;
  InstallStatusBuilder get installStatus =>
      _$this._installStatus ??= new InstallStatusBuilder();
  set installStatus(InstallStatusBuilder installStatus) =>
      _$this._installStatus = installStatus;

  HealthTestBuilder _healthTest;
  HealthTestBuilder get healthTest =>
      _$this._healthTest ??= new HealthTestBuilder();
  set healthTest(HealthTestBuilder healthTest) =>
      _$this._healthTest = healthTest;

  MapBuilder<String, String> _fsTimestamp;
  MapBuilder<String, String> get fsTimestamp =>
      _$this._fsTimestamp ??= new MapBuilder<String, String>();
  set fsTimestamp(MapBuilder<String, String> fsTimestamp) =>
      _$this._fsTimestamp = fsTimestamp;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  IrrigationScheduleBuilder _irrigationSchedule;
  IrrigationScheduleBuilder get irrigationSchedule =>
      _$this._irrigationSchedule ??= new IrrigationScheduleBuilder();
  set irrigationSchedule(IrrigationScheduleBuilder irrigationSchedule) =>
      _$this._irrigationSchedule = irrigationSchedule;

  LearningBuilder _learning;
  LearningBuilder get learning => _$this._learning ??= new LearningBuilder();
  set learning(LearningBuilder learning) => _$this._learning = learning;

  Certificate2Builder _certificate;
  Certificate2Builder get certificate =>
      _$this._certificate ??= new Certificate2Builder();
  set certificate(Certificate2Builder certificate) =>
      _$this._certificate = certificate;

  String _serialNumber;
  String get serialNumber => _$this._serialNumber;
  set serialNumber(String serialNumber) => _$this._serialNumber = serialNumber;

  EstimateWaterUsageBuilder _estimateWaterUsage;
  EstimateWaterUsageBuilder get estimateWaterUsage =>
      _$this._estimateWaterUsage ??= new EstimateWaterUsageBuilder();
  set estimateWaterUsage(EstimateWaterUsageBuilder estimateWaterUsage) =>
      _$this._estimateWaterUsage = estimateWaterUsage;

  bool _dirty;
  bool get dirty => _$this._dirty;
  set dirty(bool dirty) => _$this._dirty = dirty;

  DeviceBuilder();

  DeviceBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _macAddress = _$v.macAddress;
      _prvInstallation = _$v.prvInstallation;
      _irrigationType = _$v.irrigationType;
      _installationPoint = _$v.installationPoint;
      _nickname = _$v.nickname;
      _valve = _$v.valve?.toBuilder();
      _valveState = _$v.valveState?.toBuilder();
      _createdAt = _$v.createdAt;
      _updatedAt = _$v.updatedAt;
      _deviceType = _$v.deviceType;
      _deviceModel = _$v.deviceModel;
      _isConnected = _$v.isConnected;
      _isPaired = _$v.isPaired;
      _lastHeardFromTime = _$v.lastHeardFromTime;
      _location = _$v.location?.toBuilder();
      _firmwareVersion = _$v.firmwareVersion;
      _firmwareProperties = _$v.firmwareProperties?.toBuilder();
      _systemMode = _$v.systemMode?.toBuilder();
      _hardwareThresholds = _$v.hardwareThresholds?.toBuilder();
      _connectivity = _$v.connectivity?.toBuilder();
      _notifications = _$v.notifications?.toBuilder();
      _telemetries = _$v.telemetries?.toBuilder();
      _installStatus = _$v.installStatus?.toBuilder();
      _healthTest = _$v.healthTest?.toBuilder();
      _fsTimestamp = _$v.fsTimestamp?.toBuilder();
      _deviceId = _$v.deviceId;
      _irrigationSchedule = _$v.irrigationSchedule?.toBuilder();
      _learning = _$v.learning?.toBuilder();
      _certificate = _$v.certificate?.toBuilder();
      _serialNumber = _$v.serialNumber;
      _estimateWaterUsage = _$v.estimateWaterUsage?.toBuilder();
      _dirty = _$v.dirty;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Device other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Device;
  }

  @override
  void update(void Function(DeviceBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Device build() {
    _$Device _$result;
    try {
      _$result = _$v ??
          new _$Device._(
              id: id,
              macAddress: macAddress,
              prvInstallation: prvInstallation,
              irrigationType: irrigationType,
              installationPoint: installationPoint,
              nickname: nickname,
              valve: _valve?.build(),
              valveState: _valveState?.build(),
              createdAt: createdAt,
              updatedAt: updatedAt,
              deviceType: deviceType,
              deviceModel: deviceModel,
              isConnected: isConnected,
              isPaired: isPaired,
              lastHeardFromTime: lastHeardFromTime,
              location: _location?.build(),
              firmwareVersion: firmwareVersion,
              firmwareProperties: _firmwareProperties?.build(),
              systemMode: _systemMode?.build(),
              hardwareThresholds: _hardwareThresholds?.build(),
              connectivity: _connectivity?.build(),
              notifications: _notifications?.build(),
              telemetries: _telemetries?.build(),
              installStatus: _installStatus?.build(),
              healthTest: _healthTest?.build(),
              fsTimestamp: _fsTimestamp?.build(),
              deviceId: deviceId,
              irrigationSchedule: _irrigationSchedule?.build(),
              learning: _learning?.build(),
              certificate: _certificate?.build(),
              serialNumber: serialNumber,
              estimateWaterUsage: _estimateWaterUsage?.build(),
              dirty: dirty);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'valve';
        _valve?.build();
        _$failedField = 'valveState';
        _valveState?.build();

        _$failedField = 'location';
        _location?.build();

        _$failedField = 'firmwareProperties';
        _firmwareProperties?.build();
        _$failedField = 'systemMode';
        _systemMode?.build();
        _$failedField = 'hardwareThresholds';
        _hardwareThresholds?.build();
        _$failedField = 'connectivity';
        _connectivity?.build();
        _$failedField = 'notifications';
        _notifications?.build();
        _$failedField = 'telemetries';
        _telemetries?.build();
        _$failedField = 'installStatus';
        _installStatus?.build();
        _$failedField = 'healthTest';
        _healthTest?.build();
        _$failedField = 'fsTimestamp';
        _fsTimestamp?.build();

        _$failedField = 'irrigationSchedule';
        _irrigationSchedule?.build();
        _$failedField = 'learning';
        _learning?.build();
        _$failedField = 'certificate';
        _certificate?.build();

        _$failedField = 'estimateWaterUsage';
        _estimateWaterUsage?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Device', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
