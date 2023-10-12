// GENERATED CODE - DO NOT MODIFY BY HAND

part of telemetry;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Telemetry> _$telemetrySerializer = new _$TelemetrySerializer();

class _$TelemetrySerializer implements StructuredSerializer<Telemetry> {
  @override
  final Iterable<Type> types = const [Telemetry, _$Telemetry];
  @override
  final String wireName = 'Telemetry';

  @override
  Iterable<Object> serialize(Serializers serializers, Telemetry object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'did',
      serializers.serialize(object.deviceId,
          specifiedType: const FullType(String)),
      'wf',
      serializers.serialize(object.waterFlow,
          specifiedType: const FullType(double)),
      'f',
      serializers.serialize(object.flow, specifiedType: const FullType(double)),
      't',
      serializers.serialize(object.temperature,
          specifiedType: const FullType(double)),
      'p',
      serializers.serialize(object.pressure,
          specifiedType: const FullType(double)),
      'ts',
      serializers.serialize(object.timestamp,
          specifiedType: const FullType(int)),
      'sm',
      serializers.serialize(object.systemMode,
          specifiedType: const FullType(int)),
      'sw1',
      serializers.serialize(object.switch1, specifiedType: const FullType(int)),
      'sw2',
      serializers.serialize(object.switch2, specifiedType: const FullType(int)),
      'v',
      serializers.serialize(object.valve, specifiedType: const FullType(int)),
      'freq',
      serializers.serialize(object.wifiFrequency,
          specifiedType: const FullType(double)),
      'rssi',
      serializers.serialize(object.rssi, specifiedType: const FullType(double)),
      'mbps',
      serializers.serialize(object.mbps, specifiedType: const FullType(double)),
    ];

    return result;
  }

  @override
  Telemetry deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TelemetryBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'did':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wf':
          result.waterFlow = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'f':
          result.flow = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 't':
          result.temperature = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'p':
          result.pressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ts':
          result.timestamp = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'sm':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'sw1':
          result.switch1 = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'sw2':
          result.switch2 = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'v':
          result.valve = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'freq':
          result.wifiFrequency = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'rssi':
          result.rssi = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'mbps':
          result.mbps = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$Telemetry extends Telemetry {
  @override
  final String deviceId;
  @override
  final double waterFlow;
  @override
  final double flow;
  @override
  final double temperature;
  @override
  final double pressure;
  @override
  final int timestamp;
  @override
  final int systemMode;
  @override
  final int switch1;
  @override
  final int switch2;
  @override
  final int valve;
  @override
  final double wifiFrequency;
  @override
  final double rssi;
  @override
  final double mbps;

  factory _$Telemetry([void Function(TelemetryBuilder) updates]) =>
      (new TelemetryBuilder()..update(updates)).build();

  _$Telemetry._(
      {this.deviceId,
      this.waterFlow,
      this.flow,
      this.temperature,
      this.pressure,
      this.timestamp,
      this.systemMode,
      this.switch1,
      this.switch2,
      this.valve,
      this.wifiFrequency,
      this.rssi,
      this.mbps})
      : super._() {
    if (deviceId == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'deviceId');
    }
    if (waterFlow == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'waterFlow');
    }
    if (flow == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'flow');
    }
    if (temperature == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'temperature');
    }
    if (pressure == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'pressure');
    }
    if (timestamp == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'timestamp');
    }
    if (systemMode == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'systemMode');
    }
    if (switch1 == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'switch1');
    }
    if (switch2 == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'switch2');
    }
    if (valve == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'valve');
    }
    if (wifiFrequency == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'wifiFrequency');
    }
    if (rssi == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'rssi');
    }
    if (mbps == null) {
      throw new BuiltValueNullFieldError('Telemetry', 'mbps');
    }
  }

  @override
  Telemetry rebuild(void Function(TelemetryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TelemetryBuilder toBuilder() => new TelemetryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Telemetry &&
        deviceId == other.deviceId &&
        waterFlow == other.waterFlow &&
        flow == other.flow &&
        temperature == other.temperature &&
        pressure == other.pressure &&
        timestamp == other.timestamp &&
        systemMode == other.systemMode &&
        switch1 == other.switch1 &&
        switch2 == other.switch2 &&
        valve == other.valve &&
        wifiFrequency == other.wifiFrequency &&
        rssi == other.rssi &&
        mbps == other.mbps;
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
                                                $jc($jc(0, deviceId.hashCode),
                                                    waterFlow.hashCode),
                                                flow.hashCode),
                                            temperature.hashCode),
                                        pressure.hashCode),
                                    timestamp.hashCode),
                                systemMode.hashCode),
                            switch1.hashCode),
                        switch2.hashCode),
                    valve.hashCode),
                wifiFrequency.hashCode),
            rssi.hashCode),
        mbps.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Telemetry')
          ..add('deviceId', deviceId)
          ..add('waterFlow', waterFlow)
          ..add('flow', flow)
          ..add('temperature', temperature)
          ..add('pressure', pressure)
          ..add('timestamp', timestamp)
          ..add('systemMode', systemMode)
          ..add('switch1', switch1)
          ..add('switch2', switch2)
          ..add('valve', valve)
          ..add('wifiFrequency', wifiFrequency)
          ..add('rssi', rssi)
          ..add('mbps', mbps))
        .toString();
  }
}

class TelemetryBuilder implements Builder<Telemetry, TelemetryBuilder> {
  _$Telemetry _$v;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  double _waterFlow;
  double get waterFlow => _$this._waterFlow;
  set waterFlow(double waterFlow) => _$this._waterFlow = waterFlow;

  double _flow;
  double get flow => _$this._flow;
  set flow(double flow) => _$this._flow = flow;

  double _temperature;
  double get temperature => _$this._temperature;
  set temperature(double temperature) => _$this._temperature = temperature;

  double _pressure;
  double get pressure => _$this._pressure;
  set pressure(double pressure) => _$this._pressure = pressure;

  int _timestamp;
  int get timestamp => _$this._timestamp;
  set timestamp(int timestamp) => _$this._timestamp = timestamp;

  int _systemMode;
  int get systemMode => _$this._systemMode;
  set systemMode(int systemMode) => _$this._systemMode = systemMode;

  int _switch1;
  int get switch1 => _$this._switch1;
  set switch1(int switch1) => _$this._switch1 = switch1;

  int _switch2;
  int get switch2 => _$this._switch2;
  set switch2(int switch2) => _$this._switch2 = switch2;

  int _valve;
  int get valve => _$this._valve;
  set valve(int valve) => _$this._valve = valve;

  double _wifiFrequency;
  double get wifiFrequency => _$this._wifiFrequency;
  set wifiFrequency(double wifiFrequency) =>
      _$this._wifiFrequency = wifiFrequency;

  double _rssi;
  double get rssi => _$this._rssi;
  set rssi(double rssi) => _$this._rssi = rssi;

  double _mbps;
  double get mbps => _$this._mbps;
  set mbps(double mbps) => _$this._mbps = mbps;

  TelemetryBuilder();

  TelemetryBuilder get _$this {
    if (_$v != null) {
      _deviceId = _$v.deviceId;
      _waterFlow = _$v.waterFlow;
      _flow = _$v.flow;
      _temperature = _$v.temperature;
      _pressure = _$v.pressure;
      _timestamp = _$v.timestamp;
      _systemMode = _$v.systemMode;
      _switch1 = _$v.switch1;
      _switch2 = _$v.switch2;
      _valve = _$v.valve;
      _wifiFrequency = _$v.wifiFrequency;
      _rssi = _$v.rssi;
      _mbps = _$v.mbps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Telemetry other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Telemetry;
  }

  @override
  void update(void Function(TelemetryBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Telemetry build() {
    final _$result = _$v ??
        new _$Telemetry._(
            deviceId: deviceId,
            waterFlow: waterFlow,
            flow: flow,
            temperature: temperature,
            pressure: pressure,
            timestamp: timestamp,
            systemMode: systemMode,
            switch1: switch1,
            switch2: switch2,
            valve: valve,
            wifiFrequency: wifiFrequency,
            rssi: rssi,
            mbps: mbps);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
