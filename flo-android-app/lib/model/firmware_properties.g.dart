// GENERATED CODE - DO NOT MODIFY BY HAND

part of firmware_properties;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FirmwareProperties> _$firmwarePropertiesSerializer =
    new _$FirmwarePropertiesSerializer();

class _$FirmwarePropertiesSerializer
    implements StructuredSerializer<FirmwareProperties> {
  @override
  final Iterable<Type> types = const [FirmwareProperties, _$FirmwareProperties];
  @override
  final String wireName = 'FirmwareProperties';

  @override
  Iterable<Object> serialize(Serializers serializers, FirmwareProperties object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.deviceDataFreeMb != null) {
      result
        ..add('device_data_free_mb')
        ..add(serializers.serialize(object.deviceDataFreeMb,
            specifiedType: const FullType(double)));
    }
    if (object.deviceInstalled != null) {
      result
        ..add('device_installed')
        ..add(serializers.serialize(object.deviceInstalled,
            specifiedType: const FullType(bool)));
    }
    if (object.deviceMemAvailableKb != null) {
      result
        ..add('device_mem_available_kb')
        ..add(serializers.serialize(object.deviceMemAvailableKb,
            specifiedType: const FullType(double)));
    }
    if (object.deviceRootfsFreeKb != null) {
      result
        ..add('device_rootfs_free_kb')
        ..add(serializers.serialize(object.deviceRootfsFreeKb,
            specifiedType: const FullType(double)));
    }
    if (object.deviceUptimeSec != null) {
      result
        ..add('device_uptime_sec')
        ..add(serializers.serialize(object.deviceUptimeSec,
            specifiedType: const FullType(double)));
    }
    if (object.fwVer != null) {
      result
        ..add('fw_ver')
        ..add(serializers.serialize(object.fwVer,
            specifiedType: const FullType(String)));
    }
    if (object.fwVerA != null) {
      result
        ..add('fw_ver_a')
        ..add(serializers.serialize(object.fwVerA,
            specifiedType: const FullType(String)));
    }
    if (object.fwVerB != null) {
      result
        ..add('fw_ver_b')
        ..add(serializers.serialize(object.fwVerB,
            specifiedType: const FullType(String)));
    }
    if (object.htAttemptInterval != null) {
      result
        ..add('ht_attempt_doubleerval')
        ..add(serializers.serialize(object.htAttemptInterval,
            specifiedType: const FullType(double)));
    }
    if (object.htCheckWindowMaxPressureDecayLimit != null) {
      result
        ..add('ht_check_window_max_pressure_decay_limit')
        ..add(serializers.serialize(object.htCheckWindowMaxPressureDecayLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htCheckWindowWidth != null) {
      result
        ..add('ht_check_window_width')
        ..add(serializers.serialize(object.htCheckWindowWidth,
            specifiedType: const FullType(double)));
    }
    if (object.htMaxOpenClosedPressureDecayPctLimit != null) {
      result
        ..add('ht_max_open_closed_pressure_decay_pct_limit')
        ..add(serializers.serialize(object.htMaxOpenClosedPressureDecayPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMaxPressureGrowthLimit != null) {
      result
        ..add('ht_max_pressure_growth_limit')
        ..add(serializers.serialize(object.htMaxPressureGrowthLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMaxPressureGrowthPctLimit != null) {
      result
        ..add('ht_max_pressure_growth_pct_limit')
        ..add(serializers.serialize(object.htMaxPressureGrowthPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMinComputablePointLimit != null) {
      result
        ..add('ht_min_computable_podouble_limit')
        ..add(serializers.serialize(object.htMinComputablePointLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMinPressureLimit != null) {
      result
        ..add('ht_min_pressure_limit')
        ..add(serializers.serialize(object.htMinPressureLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMinRSquaredLimit != null) {
      result
        ..add('ht_min_r_squared_limit')
        ..add(serializers.serialize(object.htMinRSquaredLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htMinSlopeLimit != null) {
      result
        ..add('ht_min_slope_limit')
        ..add(serializers.serialize(object.htMinSlopeLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase1MaxPressureDecayLimit != null) {
      result
        ..add('ht_phase_1_max_pressure_decay_limit')
        ..add(serializers.serialize(object.htPhase1MaxPressureDecayLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase1MaxPressureDecayPctLimit != null) {
      result
        ..add('ht_phase_1_max_pressure_decay_pct_limit')
        ..add(serializers.serialize(object.htPhase1MaxPressureDecayPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase1TimeIndex != null) {
      result
        ..add('ht_phase_1_time_index')
        ..add(serializers.serialize(object.htPhase1TimeIndex,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase2MaxPressureDecayLimit != null) {
      result
        ..add('ht_phase_2_max_pressure_decay_limit')
        ..add(serializers.serialize(object.htPhase2MaxPressureDecayLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase2MaxPressureDecayPctLimit != null) {
      result
        ..add('ht_phase_2_max_pressure_decay_pct_limit')
        ..add(serializers.serialize(object.htPhase2MaxPressureDecayPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase2TimeIndex != null) {
      result
        ..add('ht_phase_2_time_index')
        ..add(serializers.serialize(object.htPhase2TimeIndex,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase3MaxPressureDecayLimit != null) {
      result
        ..add('ht_phase_3_max_pressure_decay_limit')
        ..add(serializers.serialize(object.htPhase3MaxPressureDecayLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase3MaxPressureDecayPctLimit != null) {
      result
        ..add('ht_phase_3_max_pressure_decay_pct_limit')
        ..add(serializers.serialize(object.htPhase3MaxPressureDecayPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase3TimeIndex != null) {
      result
        ..add('ht_phase_3_time_index')
        ..add(serializers.serialize(object.htPhase3TimeIndex,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase4MaxPressureDecayLimit != null) {
      result
        ..add('ht_phase_4_max_pressure_decay_limit')
        ..add(serializers.serialize(object.htPhase4MaxPressureDecayLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase4MaxPressureDecayPctLimit != null) {
      result
        ..add('ht_phase_4_max_pressure_decay_pct_limit')
        ..add(serializers.serialize(object.htPhase4MaxPressureDecayPctLimit,
            specifiedType: const FullType(double)));
    }
    if (object.htPhase4TimeIndex != null) {
      result
        ..add('ht_phase_4_time_index')
        ..add(serializers.serialize(object.htPhase4TimeIndex,
            specifiedType: const FullType(double)));
    }
    if (object.htRecentFlowEventCoolDown != null) {
      result
        ..add('ht_recent_flow_event_cool_down')
        ..add(serializers.serialize(object.htRecentFlowEventCoolDown,
            specifiedType: const FullType(double)));
    }
    if (object.htRetryOnFailInterval != null) {
      result
        ..add('ht_retry_on_fail_doubleerval')
        ..add(serializers.serialize(object.htRetryOnFailInterval,
            specifiedType: const FullType(double)));
    }
    if (object.htTimesPerDay != null) {
      result
        ..add('ht_times_per_day')
        ..add(serializers.serialize(object.htTimesPerDay,
            specifiedType: const FullType(double)));
    }
    if (object.motorDelayClose != null) {
      result
        ..add('motor_delay_close')
        ..add(serializers.serialize(object.motorDelayClose,
            specifiedType: const FullType(double)));
    }
    if (object.motorDelayOpen != null) {
      result
        ..add('motor_delay_open')
        ..add(serializers.serialize(object.motorDelayOpen,
            specifiedType: const FullType(double)));
    }
    if (object.pesAwayV1HighFlowRate != null) {
      result
        ..add('pes_away_v1_high_flow_rate')
        ..add(serializers.serialize(object.pesAwayV1HighFlowRate,
            specifiedType: const FullType(double)));
    }
    if (object.pesAwayV1HighFlowRateDuration != null) {
      result
        ..add('pes_away_v1_high_flow_rate_duration')
        ..add(serializers.serialize(object.pesAwayV1HighFlowRateDuration,
            specifiedType: const FullType(double)));
    }
    if (object.pesAwayV2HighFlowRate != null) {
      result
        ..add('pes_away_v2_high_flow_rate')
        ..add(serializers.serialize(object.pesAwayV2HighFlowRate,
            specifiedType: const FullType(double)));
    }
    if (object.pesAwayV2HighFlowRateDuration != null) {
      result
        ..add('pes_away_v2_high_flow_rate_duration')
        ..add(serializers.serialize(object.pesAwayV2HighFlowRateDuration,
            specifiedType: const FullType(double)));
    }
    if (object.pesHomeHighFlowRate != null) {
      result
        ..add('pes_home_high_flow_rate')
        ..add(serializers.serialize(object.pesHomeHighFlowRate,
            specifiedType: const FullType(double)));
    }
    if (object.pesHomeHighFlowRateDuration != null) {
      result
        ..add('pes_home_high_flow_rate_duration')
        ..add(serializers.serialize(object.pesHomeHighFlowRateDuration,
            specifiedType: const FullType(double)));
    }
    if (object.pesModeratelyHighPressure != null) {
      result
        ..add('pes_moderately_high_pressure')
        ..add(serializers.serialize(object.pesModeratelyHighPressure,
            specifiedType: const FullType(double)));
    }
    if (object.pesModeratelyHighPressureCount != null) {
      result
        ..add('pes_moderately_high_pressure_count')
        ..add(serializers.serialize(object.pesModeratelyHighPressureCount,
            specifiedType: const FullType(double)));
    }
    if (object.pesModeratelyHighPressureDelay != null) {
      result
        ..add('pes_moderately_high_pressure_delay')
        ..add(serializers.serialize(object.pesModeratelyHighPressureDelay,
            specifiedType: const FullType(double)));
    }
    if (object.pesModeratelyHighPressurePeriod != null) {
      result
        ..add('pes_moderately_high_pressure_period')
        ..add(serializers.serialize(object.pesModeratelyHighPressurePeriod,
            specifiedType: const FullType(double)));
    }
    if (object.rebootCount != null) {
      result
        ..add('reboot_count')
        ..add(serializers.serialize(object.rebootCount,
            specifiedType: const FullType(double)));
    }
    if (object.serialNumber != null) {
      result
        ..add('serial_number')
        ..add(serializers.serialize(object.serialNumber,
            specifiedType: const FullType(String)));
    }
    if (object.systemMode != null) {
      result
        ..add('system_mode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(double)));
    }
    if (object.telemetryFlowRate != null) {
      result
        ..add('telemetry_flow_rate')
        ..add(serializers.serialize(object.telemetryFlowRate,
            specifiedType: const FullType(double)));
    }
    if (object.telemetryPressure != null) {
      result
        ..add('telemetry_pressure')
        ..add(serializers.serialize(object.telemetryPressure,
            specifiedType: const FullType(double)));
    }
    if (object.telemetryTemperature != null) {
      result
        ..add('telemetry_temperature')
        ..add(serializers.serialize(object.telemetryTemperature,
            specifiedType: const FullType(double)));
    }
    if (object.valveActuationCount != null) {
      result
        ..add('valve_actuation_count')
        ..add(serializers.serialize(object.valveActuationCount,
            specifiedType: const FullType(double)));
    }
    if (object.valveState != null) {
      result
        ..add('valve_state')
        ..add(serializers.serialize(object.valveState,
            specifiedType: const FullType(double)));
    }
    if (object.wifiDisconnections != null) {
      result
        ..add('wifi_disconnections')
        ..add(serializers.serialize(object.wifiDisconnections,
            specifiedType: const FullType(double)));
    }
    if (object.wifiRssi != null) {
      result
        ..add('wifi_rssi')
        ..add(serializers.serialize(object.wifiRssi,
            specifiedType: const FullType(double)));
    }
    if (object.wifiStaEnc != null) {
      result
        ..add('wifi_sta_enc')
        ..add(serializers.serialize(object.wifiStaEnc,
            specifiedType: const FullType(String)));
    }
    if (object.wifiStaSsid != null) {
      result
        ..add('wifi_sta_ssid')
        ..add(serializers.serialize(object.wifiStaSsid,
            specifiedType: const FullType(String)));
    }
    if (object.zitAutoCount != null) {
      result
        ..add('zit_auto_count')
        ..add(serializers.serialize(object.zitAutoCount,
            specifiedType: const FullType(double)));
    }
    if (object.zitManualCount != null) {
      result
        ..add('zit_manual_count')
        ..add(serializers.serialize(object.zitManualCount,
            specifiedType: const FullType(double)));
    }
    if (object.playerAction != null) {
      result
        ..add('player_action')
        ..add(serializers.serialize(object.playerAction,
            specifiedType: const FullType(String)));
    }
    if (object.playerFlow != null) {
      result
        ..add('player_flow')
        ..add(serializers.serialize(object.playerFlow,
            specifiedType: const FullType(double)));
    }
    if (object.playerMinPressure != null) {
      result
        ..add('player_min_pressure')
        ..add(serializers.serialize(object.playerMinPressure,
            specifiedType: const FullType(double)));
    }
    if (object.playerPressure != null) {
      result
        ..add('player_pressure')
        ..add(serializers.serialize(object.playerPressure,
            specifiedType: const FullType(double)));
    }
    if (object.playerTemperature != null) {
      result
        ..add('player_temperature')
        ..add(serializers.serialize(object.playerTemperature,
            specifiedType: const FullType(double)));
    }
    if (object.firmwareName != null) {
      result
        ..add('fw_name')
        ..add(serializers.serialize(object.firmwareName,
            specifiedType: const FullType(String)));
    }
    if (object.reason != null) {
      result
        ..add('reason')
        ..add(serializers.serialize(object.reason,
            specifiedType: const FullType(String)));
    }
    if (object.wifiStaPassword != null) {
      result
        ..add('wifi_sta_pass')
        ..add(serializers.serialize(object.wifiStaPassword,
            specifiedType: const FullType(String)));
    }
    if (object.wifiApSsid != null) {
      result
        ..add('wifi_ap_ssid')
        ..add(serializers.serialize(object.wifiApSsid,
            specifiedType: const FullType(String)));
    }
    if (object.wifiStaMac != null) {
      result
        ..add('wifi_sta_mac')
        ..add(serializers.serialize(object.wifiStaMac,
            specifiedType: const FullType(String)));
    }
    if (object.pairingState != null) {
      result
        ..add('pairing_state')
        ..add(serializers.serialize(object.pairingState,
            specifiedType: const FullType(String)));
    }
    if (object.alarmShutoffTimeRemaining != null) {
      result
        ..add('alarm_shut_off_time_remaining')
        ..add(serializers.serialize(object.alarmShutoffTimeRemaining,
            specifiedType: const FullType(int)));
    }
    if (object.alarmSuppressUntilEventEnd != null) {
      result
        ..add('alarm_suppress_until_event_end')
        ..add(serializers.serialize(object.alarmSuppressUntilEventEnd,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  FirmwareProperties deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FirmwarePropertiesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'device_data_free_mb':
          result.deviceDataFreeMb = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'device_installed':
          result.deviceInstalled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'device_mem_available_kb':
          result.deviceMemAvailableKb = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'device_rootfs_free_kb':
          result.deviceRootfsFreeKb = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'device_uptime_sec':
          result.deviceUptimeSec = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'fw_ver':
          result.fwVer = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'fw_ver_a':
          result.fwVerA = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'fw_ver_b':
          result.fwVerB = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'ht_attempt_doubleerval':
          result.htAttemptInterval = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_check_window_max_pressure_decay_limit':
          result.htCheckWindowMaxPressureDecayLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_check_window_width':
          result.htCheckWindowWidth = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_max_open_closed_pressure_decay_pct_limit':
          result.htMaxOpenClosedPressureDecayPctLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_max_pressure_growth_limit':
          result.htMaxPressureGrowthLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_max_pressure_growth_pct_limit':
          result.htMaxPressureGrowthPctLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_min_computable_podouble_limit':
          result.htMinComputablePointLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_min_pressure_limit':
          result.htMinPressureLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_min_r_squared_limit':
          result.htMinRSquaredLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_min_slope_limit':
          result.htMinSlopeLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_1_max_pressure_decay_limit':
          result.htPhase1MaxPressureDecayLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_1_max_pressure_decay_pct_limit':
          result.htPhase1MaxPressureDecayPctLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_1_time_index':
          result.htPhase1TimeIndex = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_2_max_pressure_decay_limit':
          result.htPhase2MaxPressureDecayLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_2_max_pressure_decay_pct_limit':
          result.htPhase2MaxPressureDecayPctLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_2_time_index':
          result.htPhase2TimeIndex = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_3_max_pressure_decay_limit':
          result.htPhase3MaxPressureDecayLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_3_max_pressure_decay_pct_limit':
          result.htPhase3MaxPressureDecayPctLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_3_time_index':
          result.htPhase3TimeIndex = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_4_max_pressure_decay_limit':
          result.htPhase4MaxPressureDecayLimit = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_4_max_pressure_decay_pct_limit':
          result.htPhase4MaxPressureDecayPctLimit = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_phase_4_time_index':
          result.htPhase4TimeIndex = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_recent_flow_event_cool_down':
          result.htRecentFlowEventCoolDown = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_retry_on_fail_doubleerval':
          result.htRetryOnFailInterval = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ht_times_per_day':
          result.htTimesPerDay = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'motor_delay_close':
          result.motorDelayClose = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'motor_delay_open':
          result.motorDelayOpen = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_away_v1_high_flow_rate':
          result.pesAwayV1HighFlowRate = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_away_v1_high_flow_rate_duration':
          result.pesAwayV1HighFlowRateDuration = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_away_v2_high_flow_rate':
          result.pesAwayV2HighFlowRate = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_away_v2_high_flow_rate_duration':
          result.pesAwayV2HighFlowRateDuration = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_home_high_flow_rate':
          result.pesHomeHighFlowRate = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_home_high_flow_rate_duration':
          result.pesHomeHighFlowRateDuration = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_moderately_high_pressure':
          result.pesModeratelyHighPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_moderately_high_pressure_count':
          result.pesModeratelyHighPressureCount = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_moderately_high_pressure_delay':
          result.pesModeratelyHighPressureDelay = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'pes_moderately_high_pressure_period':
          result.pesModeratelyHighPressurePeriod = serializers.deserialize(
              value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'reboot_count':
          result.rebootCount = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'serial_number':
          result.serialNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'system_mode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'telemetry_flow_rate':
          result.telemetryFlowRate = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'telemetry_pressure':
          result.telemetryPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'telemetry_temperature':
          result.telemetryTemperature = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'valve_actuation_count':
          result.valveActuationCount = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'valve_state':
          result.valveState = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'wifi_disconnections':
          result.wifiDisconnections = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'wifi_rssi':
          result.wifiRssi = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'wifi_sta_enc':
          result.wifiStaEnc = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_sta_ssid':
          result.wifiStaSsid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'zit_auto_count':
          result.zitAutoCount = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'zit_manual_count':
          result.zitManualCount = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'player_action':
          result.playerAction = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'player_flow':
          result.playerFlow = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'player_min_pressure':
          result.playerMinPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'player_pressure':
          result.playerPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'player_temperature':
          result.playerTemperature = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'fw_name':
          result.firmwareName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'reason':
          result.reason = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_sta_pass':
          result.wifiStaPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_ap_ssid':
          result.wifiApSsid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wifi_sta_mac':
          result.wifiStaMac = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'pairing_state':
          result.pairingState = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'alarm_shut_off_time_remaining':
          result.alarmShutoffTimeRemaining = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'alarm_suppress_until_event_end':
          result.alarmSuppressUntilEventEnd = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$FirmwareProperties extends FirmwareProperties {
  @override
  final double deviceDataFreeMb;
  @override
  final bool deviceInstalled;
  @override
  final double deviceMemAvailableKb;
  @override
  final double deviceRootfsFreeKb;
  @override
  final double deviceUptimeSec;
  @override
  final String fwVer;
  @override
  final String fwVerA;
  @override
  final String fwVerB;
  @override
  final double htAttemptInterval;
  @override
  final double htCheckWindowMaxPressureDecayLimit;
  @override
  final double htCheckWindowWidth;
  @override
  final double htMaxOpenClosedPressureDecayPctLimit;
  @override
  final double htMaxPressureGrowthLimit;
  @override
  final double htMaxPressureGrowthPctLimit;
  @override
  final double htMinComputablePointLimit;
  @override
  final double htMinPressureLimit;
  @override
  final double htMinRSquaredLimit;
  @override
  final double htMinSlopeLimit;
  @override
  final double htPhase1MaxPressureDecayLimit;
  @override
  final double htPhase1MaxPressureDecayPctLimit;
  @override
  final double htPhase1TimeIndex;
  @override
  final double htPhase2MaxPressureDecayLimit;
  @override
  final double htPhase2MaxPressureDecayPctLimit;
  @override
  final double htPhase2TimeIndex;
  @override
  final double htPhase3MaxPressureDecayLimit;
  @override
  final double htPhase3MaxPressureDecayPctLimit;
  @override
  final double htPhase3TimeIndex;
  @override
  final double htPhase4MaxPressureDecayLimit;
  @override
  final double htPhase4MaxPressureDecayPctLimit;
  @override
  final double htPhase4TimeIndex;
  @override
  final double htRecentFlowEventCoolDown;
  @override
  final double htRetryOnFailInterval;
  @override
  final double htTimesPerDay;
  @override
  final double motorDelayClose;
  @override
  final double motorDelayOpen;
  @override
  final double pesAwayV1HighFlowRate;
  @override
  final double pesAwayV1HighFlowRateDuration;
  @override
  final double pesAwayV2HighFlowRate;
  @override
  final double pesAwayV2HighFlowRateDuration;
  @override
  final double pesHomeHighFlowRate;
  @override
  final double pesHomeHighFlowRateDuration;
  @override
  final double pesModeratelyHighPressure;
  @override
  final double pesModeratelyHighPressureCount;
  @override
  final double pesModeratelyHighPressureDelay;
  @override
  final double pesModeratelyHighPressurePeriod;
  @override
  final double rebootCount;
  @override
  final String serialNumber;
  @override
  final double systemMode;
  @override
  final double telemetryFlowRate;
  @override
  final double telemetryPressure;
  @override
  final double telemetryTemperature;
  @override
  final double valveActuationCount;
  @override
  final double valveState;
  @override
  final double wifiDisconnections;
  @override
  final double wifiRssi;
  @override
  final String wifiStaEnc;
  @override
  final String wifiStaSsid;
  @override
  final double zitAutoCount;
  @override
  final double zitManualCount;
  @override
  final String playerAction;
  @override
  final double playerFlow;
  @override
  final double playerMinPressure;
  @override
  final double playerPressure;
  @override
  final double playerTemperature;
  @override
  final String firmwareName;
  @override
  final String reason;
  @override
  final String wifiStaPassword;
  @override
  final String wifiApSsid;
  @override
  final String wifiStaMac;
  @override
  final String pairingState;
  @override
  final int alarmShutoffTimeRemaining;
  @override
  final bool alarmSuppressUntilEventEnd;

  factory _$FirmwareProperties(
          [void Function(FirmwarePropertiesBuilder) updates]) =>
      (new FirmwarePropertiesBuilder()..update(updates)).build();

  _$FirmwareProperties._(
      {this.deviceDataFreeMb,
      this.deviceInstalled,
      this.deviceMemAvailableKb,
      this.deviceRootfsFreeKb,
      this.deviceUptimeSec,
      this.fwVer,
      this.fwVerA,
      this.fwVerB,
      this.htAttemptInterval,
      this.htCheckWindowMaxPressureDecayLimit,
      this.htCheckWindowWidth,
      this.htMaxOpenClosedPressureDecayPctLimit,
      this.htMaxPressureGrowthLimit,
      this.htMaxPressureGrowthPctLimit,
      this.htMinComputablePointLimit,
      this.htMinPressureLimit,
      this.htMinRSquaredLimit,
      this.htMinSlopeLimit,
      this.htPhase1MaxPressureDecayLimit,
      this.htPhase1MaxPressureDecayPctLimit,
      this.htPhase1TimeIndex,
      this.htPhase2MaxPressureDecayLimit,
      this.htPhase2MaxPressureDecayPctLimit,
      this.htPhase2TimeIndex,
      this.htPhase3MaxPressureDecayLimit,
      this.htPhase3MaxPressureDecayPctLimit,
      this.htPhase3TimeIndex,
      this.htPhase4MaxPressureDecayLimit,
      this.htPhase4MaxPressureDecayPctLimit,
      this.htPhase4TimeIndex,
      this.htRecentFlowEventCoolDown,
      this.htRetryOnFailInterval,
      this.htTimesPerDay,
      this.motorDelayClose,
      this.motorDelayOpen,
      this.pesAwayV1HighFlowRate,
      this.pesAwayV1HighFlowRateDuration,
      this.pesAwayV2HighFlowRate,
      this.pesAwayV2HighFlowRateDuration,
      this.pesHomeHighFlowRate,
      this.pesHomeHighFlowRateDuration,
      this.pesModeratelyHighPressure,
      this.pesModeratelyHighPressureCount,
      this.pesModeratelyHighPressureDelay,
      this.pesModeratelyHighPressurePeriod,
      this.rebootCount,
      this.serialNumber,
      this.systemMode,
      this.telemetryFlowRate,
      this.telemetryPressure,
      this.telemetryTemperature,
      this.valveActuationCount,
      this.valveState,
      this.wifiDisconnections,
      this.wifiRssi,
      this.wifiStaEnc,
      this.wifiStaSsid,
      this.zitAutoCount,
      this.zitManualCount,
      this.playerAction,
      this.playerFlow,
      this.playerMinPressure,
      this.playerPressure,
      this.playerTemperature,
      this.firmwareName,
      this.reason,
      this.wifiStaPassword,
      this.wifiApSsid,
      this.wifiStaMac,
      this.pairingState,
      this.alarmShutoffTimeRemaining,
      this.alarmSuppressUntilEventEnd})
      : super._();

  @override
  FirmwareProperties rebuild(
          void Function(FirmwarePropertiesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FirmwarePropertiesBuilder toBuilder() =>
      new FirmwarePropertiesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FirmwareProperties &&
        deviceDataFreeMb == other.deviceDataFreeMb &&
        deviceInstalled == other.deviceInstalled &&
        deviceMemAvailableKb == other.deviceMemAvailableKb &&
        deviceRootfsFreeKb == other.deviceRootfsFreeKb &&
        deviceUptimeSec == other.deviceUptimeSec &&
        fwVer == other.fwVer &&
        fwVerA == other.fwVerA &&
        fwVerB == other.fwVerB &&
        htAttemptInterval == other.htAttemptInterval &&
        htCheckWindowMaxPressureDecayLimit ==
            other.htCheckWindowMaxPressureDecayLimit &&
        htCheckWindowWidth == other.htCheckWindowWidth &&
        htMaxOpenClosedPressureDecayPctLimit ==
            other.htMaxOpenClosedPressureDecayPctLimit &&
        htMaxPressureGrowthLimit == other.htMaxPressureGrowthLimit &&
        htMaxPressureGrowthPctLimit == other.htMaxPressureGrowthPctLimit &&
        htMinComputablePointLimit == other.htMinComputablePointLimit &&
        htMinPressureLimit == other.htMinPressureLimit &&
        htMinRSquaredLimit == other.htMinRSquaredLimit &&
        htMinSlopeLimit == other.htMinSlopeLimit &&
        htPhase1MaxPressureDecayLimit == other.htPhase1MaxPressureDecayLimit &&
        htPhase1MaxPressureDecayPctLimit ==
            other.htPhase1MaxPressureDecayPctLimit &&
        htPhase1TimeIndex == other.htPhase1TimeIndex &&
        htPhase2MaxPressureDecayLimit == other.htPhase2MaxPressureDecayLimit &&
        htPhase2MaxPressureDecayPctLimit ==
            other.htPhase2MaxPressureDecayPctLimit &&
        htPhase2TimeIndex == other.htPhase2TimeIndex &&
        htPhase3MaxPressureDecayLimit == other.htPhase3MaxPressureDecayLimit &&
        htPhase3MaxPressureDecayPctLimit ==
            other.htPhase3MaxPressureDecayPctLimit &&
        htPhase3TimeIndex == other.htPhase3TimeIndex &&
        htPhase4MaxPressureDecayLimit == other.htPhase4MaxPressureDecayLimit &&
        htPhase4MaxPressureDecayPctLimit ==
            other.htPhase4MaxPressureDecayPctLimit &&
        htPhase4TimeIndex == other.htPhase4TimeIndex &&
        htRecentFlowEventCoolDown == other.htRecentFlowEventCoolDown &&
        htRetryOnFailInterval == other.htRetryOnFailInterval &&
        htTimesPerDay == other.htTimesPerDay &&
        motorDelayClose == other.motorDelayClose &&
        motorDelayOpen == other.motorDelayOpen &&
        pesAwayV1HighFlowRate == other.pesAwayV1HighFlowRate &&
        pesAwayV1HighFlowRateDuration == other.pesAwayV1HighFlowRateDuration &&
        pesAwayV2HighFlowRate == other.pesAwayV2HighFlowRate &&
        pesAwayV2HighFlowRateDuration == other.pesAwayV2HighFlowRateDuration &&
        pesHomeHighFlowRate == other.pesHomeHighFlowRate &&
        pesHomeHighFlowRateDuration == other.pesHomeHighFlowRateDuration &&
        pesModeratelyHighPressure == other.pesModeratelyHighPressure &&
        pesModeratelyHighPressureCount ==
            other.pesModeratelyHighPressureCount &&
        pesModeratelyHighPressureDelay ==
            other.pesModeratelyHighPressureDelay &&
        pesModeratelyHighPressurePeriod ==
            other.pesModeratelyHighPressurePeriod &&
        rebootCount == other.rebootCount &&
        serialNumber == other.serialNumber &&
        systemMode == other.systemMode &&
        telemetryFlowRate == other.telemetryFlowRate &&
        telemetryPressure == other.telemetryPressure &&
        telemetryTemperature == other.telemetryTemperature &&
        valveActuationCount == other.valveActuationCount &&
        valveState == other.valveState &&
        wifiDisconnections == other.wifiDisconnections &&
        wifiRssi == other.wifiRssi &&
        wifiStaEnc == other.wifiStaEnc &&
        wifiStaSsid == other.wifiStaSsid &&
        zitAutoCount == other.zitAutoCount &&
        zitManualCount == other.zitManualCount &&
        playerAction == other.playerAction &&
        playerFlow == other.playerFlow &&
        playerMinPressure == other.playerMinPressure &&
        playerPressure == other.playerPressure &&
        playerTemperature == other.playerTemperature &&
        firmwareName == other.firmwareName &&
        reason == other.reason &&
        wifiStaPassword == other.wifiStaPassword &&
        wifiApSsid == other.wifiApSsid &&
        wifiStaMac == other.wifiStaMac &&
        pairingState == other.pairingState &&
        alarmShutoffTimeRemaining == other.alarmShutoffTimeRemaining &&
        alarmSuppressUntilEventEnd == other.alarmSuppressUntilEventEnd;
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
                                                                            $jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc(0, deviceDataFreeMb.hashCode), deviceInstalled.hashCode), deviceMemAvailableKb.hashCode), deviceRootfsFreeKb.hashCode), deviceUptimeSec.hashCode), fwVer.hashCode), fwVerA.hashCode), fwVerB.hashCode), htAttemptInterval.hashCode), htCheckWindowMaxPressureDecayLimit.hashCode), htCheckWindowWidth.hashCode), htMaxOpenClosedPressureDecayPctLimit.hashCode), htMaxPressureGrowthLimit.hashCode), htMaxPressureGrowthPctLimit.hashCode), htMinComputablePointLimit.hashCode), htMinPressureLimit.hashCode), htMinRSquaredLimit.hashCode), htMinSlopeLimit.hashCode), htPhase1MaxPressureDecayLimit.hashCode), htPhase1MaxPressureDecayPctLimit.hashCode), htPhase1TimeIndex.hashCode), htPhase2MaxPressureDecayLimit.hashCode), htPhase2MaxPressureDecayPctLimit.hashCode), htPhase2TimeIndex.hashCode), htPhase3MaxPressureDecayLimit.hashCode), htPhase3MaxPressureDecayPctLimit.hashCode), htPhase3TimeIndex.hashCode), htPhase4MaxPressureDecayLimit.hashCode), htPhase4MaxPressureDecayPctLimit.hashCode), htPhase4TimeIndex.hashCode), htRecentFlowEventCoolDown.hashCode), htRetryOnFailInterval.hashCode), htTimesPerDay.hashCode), motorDelayClose.hashCode), motorDelayOpen.hashCode), pesAwayV1HighFlowRate.hashCode), pesAwayV1HighFlowRateDuration.hashCode), pesAwayV2HighFlowRate.hashCode), pesAwayV2HighFlowRateDuration.hashCode), pesHomeHighFlowRate.hashCode), pesHomeHighFlowRateDuration.hashCode), pesModeratelyHighPressure.hashCode), pesModeratelyHighPressureCount.hashCode), pesModeratelyHighPressureDelay.hashCode), pesModeratelyHighPressurePeriod.hashCode), rebootCount.hashCode), serialNumber.hashCode), systemMode.hashCode), telemetryFlowRate.hashCode), telemetryPressure.hashCode), telemetryTemperature.hashCode), valveActuationCount.hashCode), valveState.hashCode),
                                                                                wifiDisconnections.hashCode),
                                                                            wifiRssi.hashCode),
                                                                        wifiStaEnc.hashCode),
                                                                    wifiStaSsid.hashCode),
                                                                zitAutoCount.hashCode),
                                                            zitManualCount.hashCode),
                                                        playerAction.hashCode),
                                                    playerFlow.hashCode),
                                                playerMinPressure.hashCode),
                                            playerPressure.hashCode),
                                        playerTemperature.hashCode),
                                    firmwareName.hashCode),
                                reason.hashCode),
                            wifiStaPassword.hashCode),
                        wifiApSsid.hashCode),
                    wifiStaMac.hashCode),
                pairingState.hashCode),
            alarmShutoffTimeRemaining.hashCode),
        alarmSuppressUntilEventEnd.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FirmwareProperties')
          ..add('deviceDataFreeMb', deviceDataFreeMb)
          ..add('deviceInstalled', deviceInstalled)
          ..add('deviceMemAvailableKb', deviceMemAvailableKb)
          ..add('deviceRootfsFreeKb', deviceRootfsFreeKb)
          ..add('deviceUptimeSec', deviceUptimeSec)
          ..add('fwVer', fwVer)
          ..add('fwVerA', fwVerA)
          ..add('fwVerB', fwVerB)
          ..add('htAttemptInterval', htAttemptInterval)
          ..add('htCheckWindowMaxPressureDecayLimit',
              htCheckWindowMaxPressureDecayLimit)
          ..add('htCheckWindowWidth', htCheckWindowWidth)
          ..add('htMaxOpenClosedPressureDecayPctLimit',
              htMaxOpenClosedPressureDecayPctLimit)
          ..add('htMaxPressureGrowthLimit', htMaxPressureGrowthLimit)
          ..add('htMaxPressureGrowthPctLimit', htMaxPressureGrowthPctLimit)
          ..add('htMinComputablePointLimit', htMinComputablePointLimit)
          ..add('htMinPressureLimit', htMinPressureLimit)
          ..add('htMinRSquaredLimit', htMinRSquaredLimit)
          ..add('htMinSlopeLimit', htMinSlopeLimit)
          ..add('htPhase1MaxPressureDecayLimit', htPhase1MaxPressureDecayLimit)
          ..add('htPhase1MaxPressureDecayPctLimit',
              htPhase1MaxPressureDecayPctLimit)
          ..add('htPhase1TimeIndex', htPhase1TimeIndex)
          ..add('htPhase2MaxPressureDecayLimit', htPhase2MaxPressureDecayLimit)
          ..add('htPhase2MaxPressureDecayPctLimit',
              htPhase2MaxPressureDecayPctLimit)
          ..add('htPhase2TimeIndex', htPhase2TimeIndex)
          ..add('htPhase3MaxPressureDecayLimit', htPhase3MaxPressureDecayLimit)
          ..add('htPhase3MaxPressureDecayPctLimit',
              htPhase3MaxPressureDecayPctLimit)
          ..add('htPhase3TimeIndex', htPhase3TimeIndex)
          ..add('htPhase4MaxPressureDecayLimit', htPhase4MaxPressureDecayLimit)
          ..add('htPhase4MaxPressureDecayPctLimit',
              htPhase4MaxPressureDecayPctLimit)
          ..add('htPhase4TimeIndex', htPhase4TimeIndex)
          ..add('htRecentFlowEventCoolDown', htRecentFlowEventCoolDown)
          ..add('htRetryOnFailInterval', htRetryOnFailInterval)
          ..add('htTimesPerDay', htTimesPerDay)
          ..add('motorDelayClose', motorDelayClose)
          ..add('motorDelayOpen', motorDelayOpen)
          ..add('pesAwayV1HighFlowRate', pesAwayV1HighFlowRate)
          ..add('pesAwayV1HighFlowRateDuration', pesAwayV1HighFlowRateDuration)
          ..add('pesAwayV2HighFlowRate', pesAwayV2HighFlowRate)
          ..add('pesAwayV2HighFlowRateDuration', pesAwayV2HighFlowRateDuration)
          ..add('pesHomeHighFlowRate', pesHomeHighFlowRate)
          ..add('pesHomeHighFlowRateDuration', pesHomeHighFlowRateDuration)
          ..add('pesModeratelyHighPressure', pesModeratelyHighPressure)
          ..add(
              'pesModeratelyHighPressureCount', pesModeratelyHighPressureCount)
          ..add(
              'pesModeratelyHighPressureDelay', pesModeratelyHighPressureDelay)
          ..add('pesModeratelyHighPressurePeriod',
              pesModeratelyHighPressurePeriod)
          ..add('rebootCount', rebootCount)
          ..add('serialNumber', serialNumber)
          ..add('systemMode', systemMode)
          ..add('telemetryFlowRate', telemetryFlowRate)
          ..add('telemetryPressure', telemetryPressure)
          ..add('telemetryTemperature', telemetryTemperature)
          ..add('valveActuationCount', valveActuationCount)
          ..add('valveState', valveState)
          ..add('wifiDisconnections', wifiDisconnections)
          ..add('wifiRssi', wifiRssi)
          ..add('wifiStaEnc', wifiStaEnc)
          ..add('wifiStaSsid', wifiStaSsid)
          ..add('zitAutoCount', zitAutoCount)
          ..add('zitManualCount', zitManualCount)
          ..add('playerAction', playerAction)
          ..add('playerFlow', playerFlow)
          ..add('playerMinPressure', playerMinPressure)
          ..add('playerPressure', playerPressure)
          ..add('playerTemperature', playerTemperature)
          ..add('firmwareName', firmwareName)
          ..add('reason', reason)
          ..add('wifiStaPassword', wifiStaPassword)
          ..add('wifiApSsid', wifiApSsid)
          ..add('wifiStaMac', wifiStaMac)
          ..add('pairingState', pairingState)
          ..add('alarmShutoffTimeRemaining', alarmShutoffTimeRemaining)
          ..add('alarmSuppressUntilEventEnd', alarmSuppressUntilEventEnd))
        .toString();
  }
}

class FirmwarePropertiesBuilder
    implements Builder<FirmwareProperties, FirmwarePropertiesBuilder> {
  _$FirmwareProperties _$v;

  double _deviceDataFreeMb;
  double get deviceDataFreeMb => _$this._deviceDataFreeMb;
  set deviceDataFreeMb(double deviceDataFreeMb) =>
      _$this._deviceDataFreeMb = deviceDataFreeMb;

  bool _deviceInstalled;
  bool get deviceInstalled => _$this._deviceInstalled;
  set deviceInstalled(bool deviceInstalled) =>
      _$this._deviceInstalled = deviceInstalled;

  double _deviceMemAvailableKb;
  double get deviceMemAvailableKb => _$this._deviceMemAvailableKb;
  set deviceMemAvailableKb(double deviceMemAvailableKb) =>
      _$this._deviceMemAvailableKb = deviceMemAvailableKb;

  double _deviceRootfsFreeKb;
  double get deviceRootfsFreeKb => _$this._deviceRootfsFreeKb;
  set deviceRootfsFreeKb(double deviceRootfsFreeKb) =>
      _$this._deviceRootfsFreeKb = deviceRootfsFreeKb;

  double _deviceUptimeSec;
  double get deviceUptimeSec => _$this._deviceUptimeSec;
  set deviceUptimeSec(double deviceUptimeSec) =>
      _$this._deviceUptimeSec = deviceUptimeSec;

  String _fwVer;
  String get fwVer => _$this._fwVer;
  set fwVer(String fwVer) => _$this._fwVer = fwVer;

  String _fwVerA;
  String get fwVerA => _$this._fwVerA;
  set fwVerA(String fwVerA) => _$this._fwVerA = fwVerA;

  String _fwVerB;
  String get fwVerB => _$this._fwVerB;
  set fwVerB(String fwVerB) => _$this._fwVerB = fwVerB;

  double _htAttemptInterval;
  double get htAttemptInterval => _$this._htAttemptInterval;
  set htAttemptInterval(double htAttemptInterval) =>
      _$this._htAttemptInterval = htAttemptInterval;

  double _htCheckWindowMaxPressureDecayLimit;
  double get htCheckWindowMaxPressureDecayLimit =>
      _$this._htCheckWindowMaxPressureDecayLimit;
  set htCheckWindowMaxPressureDecayLimit(
          double htCheckWindowMaxPressureDecayLimit) =>
      _$this._htCheckWindowMaxPressureDecayLimit =
          htCheckWindowMaxPressureDecayLimit;

  double _htCheckWindowWidth;
  double get htCheckWindowWidth => _$this._htCheckWindowWidth;
  set htCheckWindowWidth(double htCheckWindowWidth) =>
      _$this._htCheckWindowWidth = htCheckWindowWidth;

  double _htMaxOpenClosedPressureDecayPctLimit;
  double get htMaxOpenClosedPressureDecayPctLimit =>
      _$this._htMaxOpenClosedPressureDecayPctLimit;
  set htMaxOpenClosedPressureDecayPctLimit(
          double htMaxOpenClosedPressureDecayPctLimit) =>
      _$this._htMaxOpenClosedPressureDecayPctLimit =
          htMaxOpenClosedPressureDecayPctLimit;

  double _htMaxPressureGrowthLimit;
  double get htMaxPressureGrowthLimit => _$this._htMaxPressureGrowthLimit;
  set htMaxPressureGrowthLimit(double htMaxPressureGrowthLimit) =>
      _$this._htMaxPressureGrowthLimit = htMaxPressureGrowthLimit;

  double _htMaxPressureGrowthPctLimit;
  double get htMaxPressureGrowthPctLimit => _$this._htMaxPressureGrowthPctLimit;
  set htMaxPressureGrowthPctLimit(double htMaxPressureGrowthPctLimit) =>
      _$this._htMaxPressureGrowthPctLimit = htMaxPressureGrowthPctLimit;

  double _htMinComputablePointLimit;
  double get htMinComputablePointLimit => _$this._htMinComputablePointLimit;
  set htMinComputablePointLimit(double htMinComputablePointLimit) =>
      _$this._htMinComputablePointLimit = htMinComputablePointLimit;

  double _htMinPressureLimit;
  double get htMinPressureLimit => _$this._htMinPressureLimit;
  set htMinPressureLimit(double htMinPressureLimit) =>
      _$this._htMinPressureLimit = htMinPressureLimit;

  double _htMinRSquaredLimit;
  double get htMinRSquaredLimit => _$this._htMinRSquaredLimit;
  set htMinRSquaredLimit(double htMinRSquaredLimit) =>
      _$this._htMinRSquaredLimit = htMinRSquaredLimit;

  double _htMinSlopeLimit;
  double get htMinSlopeLimit => _$this._htMinSlopeLimit;
  set htMinSlopeLimit(double htMinSlopeLimit) =>
      _$this._htMinSlopeLimit = htMinSlopeLimit;

  double _htPhase1MaxPressureDecayLimit;
  double get htPhase1MaxPressureDecayLimit =>
      _$this._htPhase1MaxPressureDecayLimit;
  set htPhase1MaxPressureDecayLimit(double htPhase1MaxPressureDecayLimit) =>
      _$this._htPhase1MaxPressureDecayLimit = htPhase1MaxPressureDecayLimit;

  double _htPhase1MaxPressureDecayPctLimit;
  double get htPhase1MaxPressureDecayPctLimit =>
      _$this._htPhase1MaxPressureDecayPctLimit;
  set htPhase1MaxPressureDecayPctLimit(
          double htPhase1MaxPressureDecayPctLimit) =>
      _$this._htPhase1MaxPressureDecayPctLimit =
          htPhase1MaxPressureDecayPctLimit;

  double _htPhase1TimeIndex;
  double get htPhase1TimeIndex => _$this._htPhase1TimeIndex;
  set htPhase1TimeIndex(double htPhase1TimeIndex) =>
      _$this._htPhase1TimeIndex = htPhase1TimeIndex;

  double _htPhase2MaxPressureDecayLimit;
  double get htPhase2MaxPressureDecayLimit =>
      _$this._htPhase2MaxPressureDecayLimit;
  set htPhase2MaxPressureDecayLimit(double htPhase2MaxPressureDecayLimit) =>
      _$this._htPhase2MaxPressureDecayLimit = htPhase2MaxPressureDecayLimit;

  double _htPhase2MaxPressureDecayPctLimit;
  double get htPhase2MaxPressureDecayPctLimit =>
      _$this._htPhase2MaxPressureDecayPctLimit;
  set htPhase2MaxPressureDecayPctLimit(
          double htPhase2MaxPressureDecayPctLimit) =>
      _$this._htPhase2MaxPressureDecayPctLimit =
          htPhase2MaxPressureDecayPctLimit;

  double _htPhase2TimeIndex;
  double get htPhase2TimeIndex => _$this._htPhase2TimeIndex;
  set htPhase2TimeIndex(double htPhase2TimeIndex) =>
      _$this._htPhase2TimeIndex = htPhase2TimeIndex;

  double _htPhase3MaxPressureDecayLimit;
  double get htPhase3MaxPressureDecayLimit =>
      _$this._htPhase3MaxPressureDecayLimit;
  set htPhase3MaxPressureDecayLimit(double htPhase3MaxPressureDecayLimit) =>
      _$this._htPhase3MaxPressureDecayLimit = htPhase3MaxPressureDecayLimit;

  double _htPhase3MaxPressureDecayPctLimit;
  double get htPhase3MaxPressureDecayPctLimit =>
      _$this._htPhase3MaxPressureDecayPctLimit;
  set htPhase3MaxPressureDecayPctLimit(
          double htPhase3MaxPressureDecayPctLimit) =>
      _$this._htPhase3MaxPressureDecayPctLimit =
          htPhase3MaxPressureDecayPctLimit;

  double _htPhase3TimeIndex;
  double get htPhase3TimeIndex => _$this._htPhase3TimeIndex;
  set htPhase3TimeIndex(double htPhase3TimeIndex) =>
      _$this._htPhase3TimeIndex = htPhase3TimeIndex;

  double _htPhase4MaxPressureDecayLimit;
  double get htPhase4MaxPressureDecayLimit =>
      _$this._htPhase4MaxPressureDecayLimit;
  set htPhase4MaxPressureDecayLimit(double htPhase4MaxPressureDecayLimit) =>
      _$this._htPhase4MaxPressureDecayLimit = htPhase4MaxPressureDecayLimit;

  double _htPhase4MaxPressureDecayPctLimit;
  double get htPhase4MaxPressureDecayPctLimit =>
      _$this._htPhase4MaxPressureDecayPctLimit;
  set htPhase4MaxPressureDecayPctLimit(
          double htPhase4MaxPressureDecayPctLimit) =>
      _$this._htPhase4MaxPressureDecayPctLimit =
          htPhase4MaxPressureDecayPctLimit;

  double _htPhase4TimeIndex;
  double get htPhase4TimeIndex => _$this._htPhase4TimeIndex;
  set htPhase4TimeIndex(double htPhase4TimeIndex) =>
      _$this._htPhase4TimeIndex = htPhase4TimeIndex;

  double _htRecentFlowEventCoolDown;
  double get htRecentFlowEventCoolDown => _$this._htRecentFlowEventCoolDown;
  set htRecentFlowEventCoolDown(double htRecentFlowEventCoolDown) =>
      _$this._htRecentFlowEventCoolDown = htRecentFlowEventCoolDown;

  double _htRetryOnFailInterval;
  double get htRetryOnFailInterval => _$this._htRetryOnFailInterval;
  set htRetryOnFailInterval(double htRetryOnFailInterval) =>
      _$this._htRetryOnFailInterval = htRetryOnFailInterval;

  double _htTimesPerDay;
  double get htTimesPerDay => _$this._htTimesPerDay;
  set htTimesPerDay(double htTimesPerDay) =>
      _$this._htTimesPerDay = htTimesPerDay;

  double _motorDelayClose;
  double get motorDelayClose => _$this._motorDelayClose;
  set motorDelayClose(double motorDelayClose) =>
      _$this._motorDelayClose = motorDelayClose;

  double _motorDelayOpen;
  double get motorDelayOpen => _$this._motorDelayOpen;
  set motorDelayOpen(double motorDelayOpen) =>
      _$this._motorDelayOpen = motorDelayOpen;

  double _pesAwayV1HighFlowRate;
  double get pesAwayV1HighFlowRate => _$this._pesAwayV1HighFlowRate;
  set pesAwayV1HighFlowRate(double pesAwayV1HighFlowRate) =>
      _$this._pesAwayV1HighFlowRate = pesAwayV1HighFlowRate;

  double _pesAwayV1HighFlowRateDuration;
  double get pesAwayV1HighFlowRateDuration =>
      _$this._pesAwayV1HighFlowRateDuration;
  set pesAwayV1HighFlowRateDuration(double pesAwayV1HighFlowRateDuration) =>
      _$this._pesAwayV1HighFlowRateDuration = pesAwayV1HighFlowRateDuration;

  double _pesAwayV2HighFlowRate;
  double get pesAwayV2HighFlowRate => _$this._pesAwayV2HighFlowRate;
  set pesAwayV2HighFlowRate(double pesAwayV2HighFlowRate) =>
      _$this._pesAwayV2HighFlowRate = pesAwayV2HighFlowRate;

  double _pesAwayV2HighFlowRateDuration;
  double get pesAwayV2HighFlowRateDuration =>
      _$this._pesAwayV2HighFlowRateDuration;
  set pesAwayV2HighFlowRateDuration(double pesAwayV2HighFlowRateDuration) =>
      _$this._pesAwayV2HighFlowRateDuration = pesAwayV2HighFlowRateDuration;

  double _pesHomeHighFlowRate;
  double get pesHomeHighFlowRate => _$this._pesHomeHighFlowRate;
  set pesHomeHighFlowRate(double pesHomeHighFlowRate) =>
      _$this._pesHomeHighFlowRate = pesHomeHighFlowRate;

  double _pesHomeHighFlowRateDuration;
  double get pesHomeHighFlowRateDuration => _$this._pesHomeHighFlowRateDuration;
  set pesHomeHighFlowRateDuration(double pesHomeHighFlowRateDuration) =>
      _$this._pesHomeHighFlowRateDuration = pesHomeHighFlowRateDuration;

  double _pesModeratelyHighPressure;
  double get pesModeratelyHighPressure => _$this._pesModeratelyHighPressure;
  set pesModeratelyHighPressure(double pesModeratelyHighPressure) =>
      _$this._pesModeratelyHighPressure = pesModeratelyHighPressure;

  double _pesModeratelyHighPressureCount;
  double get pesModeratelyHighPressureCount =>
      _$this._pesModeratelyHighPressureCount;
  set pesModeratelyHighPressureCount(double pesModeratelyHighPressureCount) =>
      _$this._pesModeratelyHighPressureCount = pesModeratelyHighPressureCount;

  double _pesModeratelyHighPressureDelay;
  double get pesModeratelyHighPressureDelay =>
      _$this._pesModeratelyHighPressureDelay;
  set pesModeratelyHighPressureDelay(double pesModeratelyHighPressureDelay) =>
      _$this._pesModeratelyHighPressureDelay = pesModeratelyHighPressureDelay;

  double _pesModeratelyHighPressurePeriod;
  double get pesModeratelyHighPressurePeriod =>
      _$this._pesModeratelyHighPressurePeriod;
  set pesModeratelyHighPressurePeriod(double pesModeratelyHighPressurePeriod) =>
      _$this._pesModeratelyHighPressurePeriod = pesModeratelyHighPressurePeriod;

  double _rebootCount;
  double get rebootCount => _$this._rebootCount;
  set rebootCount(double rebootCount) => _$this._rebootCount = rebootCount;

  String _serialNumber;
  String get serialNumber => _$this._serialNumber;
  set serialNumber(String serialNumber) => _$this._serialNumber = serialNumber;

  double _systemMode;
  double get systemMode => _$this._systemMode;
  set systemMode(double systemMode) => _$this._systemMode = systemMode;

  double _telemetryFlowRate;
  double get telemetryFlowRate => _$this._telemetryFlowRate;
  set telemetryFlowRate(double telemetryFlowRate) =>
      _$this._telemetryFlowRate = telemetryFlowRate;

  double _telemetryPressure;
  double get telemetryPressure => _$this._telemetryPressure;
  set telemetryPressure(double telemetryPressure) =>
      _$this._telemetryPressure = telemetryPressure;

  double _telemetryTemperature;
  double get telemetryTemperature => _$this._telemetryTemperature;
  set telemetryTemperature(double telemetryTemperature) =>
      _$this._telemetryTemperature = telemetryTemperature;

  double _valveActuationCount;
  double get valveActuationCount => _$this._valveActuationCount;
  set valveActuationCount(double valveActuationCount) =>
      _$this._valveActuationCount = valveActuationCount;

  double _valveState;
  double get valveState => _$this._valveState;
  set valveState(double valveState) => _$this._valveState = valveState;

  double _wifiDisconnections;
  double get wifiDisconnections => _$this._wifiDisconnections;
  set wifiDisconnections(double wifiDisconnections) =>
      _$this._wifiDisconnections = wifiDisconnections;

  double _wifiRssi;
  double get wifiRssi => _$this._wifiRssi;
  set wifiRssi(double wifiRssi) => _$this._wifiRssi = wifiRssi;

  String _wifiStaEnc;
  String get wifiStaEnc => _$this._wifiStaEnc;
  set wifiStaEnc(String wifiStaEnc) => _$this._wifiStaEnc = wifiStaEnc;

  String _wifiStaSsid;
  String get wifiStaSsid => _$this._wifiStaSsid;
  set wifiStaSsid(String wifiStaSsid) => _$this._wifiStaSsid = wifiStaSsid;

  double _zitAutoCount;
  double get zitAutoCount => _$this._zitAutoCount;
  set zitAutoCount(double zitAutoCount) => _$this._zitAutoCount = zitAutoCount;

  double _zitManualCount;
  double get zitManualCount => _$this._zitManualCount;
  set zitManualCount(double zitManualCount) =>
      _$this._zitManualCount = zitManualCount;

  String _playerAction;
  String get playerAction => _$this._playerAction;
  set playerAction(String playerAction) => _$this._playerAction = playerAction;

  double _playerFlow;
  double get playerFlow => _$this._playerFlow;
  set playerFlow(double playerFlow) => _$this._playerFlow = playerFlow;

  double _playerMinPressure;
  double get playerMinPressure => _$this._playerMinPressure;
  set playerMinPressure(double playerMinPressure) =>
      _$this._playerMinPressure = playerMinPressure;

  double _playerPressure;
  double get playerPressure => _$this._playerPressure;
  set playerPressure(double playerPressure) =>
      _$this._playerPressure = playerPressure;

  double _playerTemperature;
  double get playerTemperature => _$this._playerTemperature;
  set playerTemperature(double playerTemperature) =>
      _$this._playerTemperature = playerTemperature;

  String _firmwareName;
  String get firmwareName => _$this._firmwareName;
  set firmwareName(String firmwareName) => _$this._firmwareName = firmwareName;

  String _reason;
  String get reason => _$this._reason;
  set reason(String reason) => _$this._reason = reason;

  String _wifiStaPassword;
  String get wifiStaPassword => _$this._wifiStaPassword;
  set wifiStaPassword(String wifiStaPassword) =>
      _$this._wifiStaPassword = wifiStaPassword;

  String _wifiApSsid;
  String get wifiApSsid => _$this._wifiApSsid;
  set wifiApSsid(String wifiApSsid) => _$this._wifiApSsid = wifiApSsid;

  String _wifiStaMac;
  String get wifiStaMac => _$this._wifiStaMac;
  set wifiStaMac(String wifiStaMac) => _$this._wifiStaMac = wifiStaMac;

  String _pairingState;
  String get pairingState => _$this._pairingState;
  set pairingState(String pairingState) => _$this._pairingState = pairingState;

  int _alarmShutoffTimeRemaining;
  int get alarmShutoffTimeRemaining => _$this._alarmShutoffTimeRemaining;
  set alarmShutoffTimeRemaining(int alarmShutoffTimeRemaining) =>
      _$this._alarmShutoffTimeRemaining = alarmShutoffTimeRemaining;

  bool _alarmSuppressUntilEventEnd;
  bool get alarmSuppressUntilEventEnd => _$this._alarmSuppressUntilEventEnd;
  set alarmSuppressUntilEventEnd(bool alarmSuppressUntilEventEnd) =>
      _$this._alarmSuppressUntilEventEnd = alarmSuppressUntilEventEnd;

  FirmwarePropertiesBuilder();

  FirmwarePropertiesBuilder get _$this {
    if (_$v != null) {
      _deviceDataFreeMb = _$v.deviceDataFreeMb;
      _deviceInstalled = _$v.deviceInstalled;
      _deviceMemAvailableKb = _$v.deviceMemAvailableKb;
      _deviceRootfsFreeKb = _$v.deviceRootfsFreeKb;
      _deviceUptimeSec = _$v.deviceUptimeSec;
      _fwVer = _$v.fwVer;
      _fwVerA = _$v.fwVerA;
      _fwVerB = _$v.fwVerB;
      _htAttemptInterval = _$v.htAttemptInterval;
      _htCheckWindowMaxPressureDecayLimit =
          _$v.htCheckWindowMaxPressureDecayLimit;
      _htCheckWindowWidth = _$v.htCheckWindowWidth;
      _htMaxOpenClosedPressureDecayPctLimit =
          _$v.htMaxOpenClosedPressureDecayPctLimit;
      _htMaxPressureGrowthLimit = _$v.htMaxPressureGrowthLimit;
      _htMaxPressureGrowthPctLimit = _$v.htMaxPressureGrowthPctLimit;
      _htMinComputablePointLimit = _$v.htMinComputablePointLimit;
      _htMinPressureLimit = _$v.htMinPressureLimit;
      _htMinRSquaredLimit = _$v.htMinRSquaredLimit;
      _htMinSlopeLimit = _$v.htMinSlopeLimit;
      _htPhase1MaxPressureDecayLimit = _$v.htPhase1MaxPressureDecayLimit;
      _htPhase1MaxPressureDecayPctLimit = _$v.htPhase1MaxPressureDecayPctLimit;
      _htPhase1TimeIndex = _$v.htPhase1TimeIndex;
      _htPhase2MaxPressureDecayLimit = _$v.htPhase2MaxPressureDecayLimit;
      _htPhase2MaxPressureDecayPctLimit = _$v.htPhase2MaxPressureDecayPctLimit;
      _htPhase2TimeIndex = _$v.htPhase2TimeIndex;
      _htPhase3MaxPressureDecayLimit = _$v.htPhase3MaxPressureDecayLimit;
      _htPhase3MaxPressureDecayPctLimit = _$v.htPhase3MaxPressureDecayPctLimit;
      _htPhase3TimeIndex = _$v.htPhase3TimeIndex;
      _htPhase4MaxPressureDecayLimit = _$v.htPhase4MaxPressureDecayLimit;
      _htPhase4MaxPressureDecayPctLimit = _$v.htPhase4MaxPressureDecayPctLimit;
      _htPhase4TimeIndex = _$v.htPhase4TimeIndex;
      _htRecentFlowEventCoolDown = _$v.htRecentFlowEventCoolDown;
      _htRetryOnFailInterval = _$v.htRetryOnFailInterval;
      _htTimesPerDay = _$v.htTimesPerDay;
      _motorDelayClose = _$v.motorDelayClose;
      _motorDelayOpen = _$v.motorDelayOpen;
      _pesAwayV1HighFlowRate = _$v.pesAwayV1HighFlowRate;
      _pesAwayV1HighFlowRateDuration = _$v.pesAwayV1HighFlowRateDuration;
      _pesAwayV2HighFlowRate = _$v.pesAwayV2HighFlowRate;
      _pesAwayV2HighFlowRateDuration = _$v.pesAwayV2HighFlowRateDuration;
      _pesHomeHighFlowRate = _$v.pesHomeHighFlowRate;
      _pesHomeHighFlowRateDuration = _$v.pesHomeHighFlowRateDuration;
      _pesModeratelyHighPressure = _$v.pesModeratelyHighPressure;
      _pesModeratelyHighPressureCount = _$v.pesModeratelyHighPressureCount;
      _pesModeratelyHighPressureDelay = _$v.pesModeratelyHighPressureDelay;
      _pesModeratelyHighPressurePeriod = _$v.pesModeratelyHighPressurePeriod;
      _rebootCount = _$v.rebootCount;
      _serialNumber = _$v.serialNumber;
      _systemMode = _$v.systemMode;
      _telemetryFlowRate = _$v.telemetryFlowRate;
      _telemetryPressure = _$v.telemetryPressure;
      _telemetryTemperature = _$v.telemetryTemperature;
      _valveActuationCount = _$v.valveActuationCount;
      _valveState = _$v.valveState;
      _wifiDisconnections = _$v.wifiDisconnections;
      _wifiRssi = _$v.wifiRssi;
      _wifiStaEnc = _$v.wifiStaEnc;
      _wifiStaSsid = _$v.wifiStaSsid;
      _zitAutoCount = _$v.zitAutoCount;
      _zitManualCount = _$v.zitManualCount;
      _playerAction = _$v.playerAction;
      _playerFlow = _$v.playerFlow;
      _playerMinPressure = _$v.playerMinPressure;
      _playerPressure = _$v.playerPressure;
      _playerTemperature = _$v.playerTemperature;
      _firmwareName = _$v.firmwareName;
      _reason = _$v.reason;
      _wifiStaPassword = _$v.wifiStaPassword;
      _wifiApSsid = _$v.wifiApSsid;
      _wifiStaMac = _$v.wifiStaMac;
      _pairingState = _$v.pairingState;
      _alarmShutoffTimeRemaining = _$v.alarmShutoffTimeRemaining;
      _alarmSuppressUntilEventEnd = _$v.alarmSuppressUntilEventEnd;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FirmwareProperties other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FirmwareProperties;
  }

  @override
  void update(void Function(FirmwarePropertiesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FirmwareProperties build() {
    final _$result = _$v ??
        new _$FirmwareProperties._(
            deviceDataFreeMb: deviceDataFreeMb,
            deviceInstalled: deviceInstalled,
            deviceMemAvailableKb: deviceMemAvailableKb,
            deviceRootfsFreeKb: deviceRootfsFreeKb,
            deviceUptimeSec: deviceUptimeSec,
            fwVer: fwVer,
            fwVerA: fwVerA,
            fwVerB: fwVerB,
            htAttemptInterval: htAttemptInterval,
            htCheckWindowMaxPressureDecayLimit:
                htCheckWindowMaxPressureDecayLimit,
            htCheckWindowWidth: htCheckWindowWidth,
            htMaxOpenClosedPressureDecayPctLimit:
                htMaxOpenClosedPressureDecayPctLimit,
            htMaxPressureGrowthLimit: htMaxPressureGrowthLimit,
            htMaxPressureGrowthPctLimit: htMaxPressureGrowthPctLimit,
            htMinComputablePointLimit: htMinComputablePointLimit,
            htMinPressureLimit: htMinPressureLimit,
            htMinRSquaredLimit: htMinRSquaredLimit,
            htMinSlopeLimit: htMinSlopeLimit,
            htPhase1MaxPressureDecayLimit: htPhase1MaxPressureDecayLimit,
            htPhase1MaxPressureDecayPctLimit: htPhase1MaxPressureDecayPctLimit,
            htPhase1TimeIndex: htPhase1TimeIndex,
            htPhase2MaxPressureDecayLimit: htPhase2MaxPressureDecayLimit,
            htPhase2MaxPressureDecayPctLimit: htPhase2MaxPressureDecayPctLimit,
            htPhase2TimeIndex: htPhase2TimeIndex,
            htPhase3MaxPressureDecayLimit: htPhase3MaxPressureDecayLimit,
            htPhase3MaxPressureDecayPctLimit: htPhase3MaxPressureDecayPctLimit,
            htPhase3TimeIndex: htPhase3TimeIndex,
            htPhase4MaxPressureDecayLimit: htPhase4MaxPressureDecayLimit,
            htPhase4MaxPressureDecayPctLimit: htPhase4MaxPressureDecayPctLimit,
            htPhase4TimeIndex: htPhase4TimeIndex,
            htRecentFlowEventCoolDown: htRecentFlowEventCoolDown,
            htRetryOnFailInterval: htRetryOnFailInterval,
            htTimesPerDay: htTimesPerDay,
            motorDelayClose: motorDelayClose,
            motorDelayOpen: motorDelayOpen,
            pesAwayV1HighFlowRate: pesAwayV1HighFlowRate,
            pesAwayV1HighFlowRateDuration: pesAwayV1HighFlowRateDuration,
            pesAwayV2HighFlowRate: pesAwayV2HighFlowRate,
            pesAwayV2HighFlowRateDuration: pesAwayV2HighFlowRateDuration,
            pesHomeHighFlowRate: pesHomeHighFlowRate,
            pesHomeHighFlowRateDuration: pesHomeHighFlowRateDuration,
            pesModeratelyHighPressure: pesModeratelyHighPressure,
            pesModeratelyHighPressureCount: pesModeratelyHighPressureCount,
            pesModeratelyHighPressureDelay: pesModeratelyHighPressureDelay,
            pesModeratelyHighPressurePeriod: pesModeratelyHighPressurePeriod,
            rebootCount: rebootCount,
            serialNumber: serialNumber,
            systemMode: systemMode,
            telemetryFlowRate: telemetryFlowRate,
            telemetryPressure: telemetryPressure,
            telemetryTemperature: telemetryTemperature,
            valveActuationCount: valveActuationCount,
            valveState: valveState,
            wifiDisconnections: wifiDisconnections,
            wifiRssi: wifiRssi,
            wifiStaEnc: wifiStaEnc,
            wifiStaSsid: wifiStaSsid,
            zitAutoCount: zitAutoCount,
            zitManualCount: zitManualCount,
            playerAction: playerAction,
            playerFlow: playerFlow,
            playerMinPressure: playerMinPressure,
            playerPressure: playerPressure,
            playerTemperature: playerTemperature,
            firmwareName: firmwareName,
            reason: reason,
            wifiStaPassword: wifiStaPassword,
            wifiApSsid: wifiApSsid,
            wifiStaMac: wifiStaMac,
            pairingState: pairingState,
            alarmShutoffTimeRemaining: alarmShutoffTimeRemaining,
            alarmSuppressUntilEventEnd: alarmSuppressUntilEventEnd);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
