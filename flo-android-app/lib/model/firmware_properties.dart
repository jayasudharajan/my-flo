library firmware_properties;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

part 'firmware_properties.g.dart';

abstract class FirmwareProperties
    implements Built<FirmwareProperties, FirmwarePropertiesBuilder> {
  FirmwareProperties._();

  factory FirmwareProperties([updates(FirmwarePropertiesBuilder b)]) =
      _$FirmwareProperties;

  @nullable
  @BuiltValueField(wireName: 'device_data_free_mb')
  double get deviceDataFreeMb;
  @nullable
  @BuiltValueField(wireName: 'device_installed')
  bool get deviceInstalled;
  @nullable
  @BuiltValueField(wireName: 'device_mem_available_kb')
  double get deviceMemAvailableKb;
  @nullable
  @BuiltValueField(wireName: 'device_rootfs_free_kb')
  double get deviceRootfsFreeKb;
  @nullable
  @BuiltValueField(wireName: 'device_uptime_sec')
  double get deviceUptimeSec;
  @nullable
  @BuiltValueField(wireName: 'fw_ver')
  String get fwVer;
  @nullable
  @BuiltValueField(wireName: 'fw_ver_a')
  String get fwVerA;
  @nullable
  @BuiltValueField(wireName: 'fw_ver_b')
  String get fwVerB;
  @nullable
  @BuiltValueField(wireName: 'ht_attempt_doubleerval')
  double get htAttemptInterval;
  @nullable
  @BuiltValueField(wireName: 'ht_check_window_max_pressure_decay_limit')
  double get htCheckWindowMaxPressureDecayLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_check_window_width')
  double get htCheckWindowWidth;
  @nullable
  @BuiltValueField(wireName: 'ht_max_open_closed_pressure_decay_pct_limit')
  double get htMaxOpenClosedPressureDecayPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_max_pressure_growth_limit')
  double get htMaxPressureGrowthLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_max_pressure_growth_pct_limit')
  double get htMaxPressureGrowthPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_min_computable_podouble_limit')
  double get htMinComputablePointLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_min_pressure_limit')
  double get htMinPressureLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_min_r_squared_limit')
  double get htMinRSquaredLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_min_slope_limit')
  double get htMinSlopeLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_1_max_pressure_decay_limit')
  double get htPhase1MaxPressureDecayLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_1_max_pressure_decay_pct_limit')
  double get htPhase1MaxPressureDecayPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_1_time_index')
  double get htPhase1TimeIndex;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_2_max_pressure_decay_limit')
  double get htPhase2MaxPressureDecayLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_2_max_pressure_decay_pct_limit')
  double get htPhase2MaxPressureDecayPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_2_time_index')
  double get htPhase2TimeIndex;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_3_max_pressure_decay_limit')
  double get htPhase3MaxPressureDecayLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_3_max_pressure_decay_pct_limit')
  double get htPhase3MaxPressureDecayPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_3_time_index')
  double get htPhase3TimeIndex;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_4_max_pressure_decay_limit')
  double get htPhase4MaxPressureDecayLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_4_max_pressure_decay_pct_limit')
  double get htPhase4MaxPressureDecayPctLimit;
  @nullable
  @BuiltValueField(wireName: 'ht_phase_4_time_index')
  double get htPhase4TimeIndex;
  @nullable
  @BuiltValueField(wireName: 'ht_recent_flow_event_cool_down')
  double get htRecentFlowEventCoolDown;
  @nullable
  @BuiltValueField(wireName: 'ht_retry_on_fail_doubleerval')
  double get htRetryOnFailInterval;
  @nullable
  @BuiltValueField(wireName: 'ht_times_per_day')
  double get htTimesPerDay;
  @nullable
  @BuiltValueField(wireName: 'motor_delay_close')
  double get motorDelayClose;
  @nullable
  @BuiltValueField(wireName: 'motor_delay_open')
  double get motorDelayOpen;
  @nullable
  @BuiltValueField(wireName: 'pes_away_v1_high_flow_rate')
  double get pesAwayV1HighFlowRate;
  @nullable
  @BuiltValueField(wireName: 'pes_away_v1_high_flow_rate_duration')
  double get pesAwayV1HighFlowRateDuration;
  @nullable
  @BuiltValueField(wireName: 'pes_away_v2_high_flow_rate')
  double get pesAwayV2HighFlowRate;
  @nullable
  @BuiltValueField(wireName: 'pes_away_v2_high_flow_rate_duration')
  double get pesAwayV2HighFlowRateDuration;
  @nullable
  @BuiltValueField(wireName: 'pes_home_high_flow_rate')
  double get pesHomeHighFlowRate;
  @nullable
  @BuiltValueField(wireName: 'pes_home_high_flow_rate_duration')
  double get pesHomeHighFlowRateDuration;
  @nullable
  @BuiltValueField(wireName: 'pes_moderately_high_pressure')
  double get pesModeratelyHighPressure;
  @nullable
  @BuiltValueField(wireName: 'pes_moderately_high_pressure_count')
  double get pesModeratelyHighPressureCount;
  @nullable
  @BuiltValueField(wireName: 'pes_moderately_high_pressure_delay')
  double get pesModeratelyHighPressureDelay;
  @nullable
  @BuiltValueField(wireName: 'pes_moderately_high_pressure_period')
  double get pesModeratelyHighPressurePeriod;
  @nullable
  @BuiltValueField(wireName: 'reboot_count')
  double get rebootCount;
  @nullable
  @BuiltValueField(wireName: 'serial_number')
  String get serialNumber;
  @nullable
  @BuiltValueField(wireName: 'system_mode')
  double get systemMode;
  @nullable
  @BuiltValueField(wireName: 'telemetry_flow_rate')
  double get telemetryFlowRate;
  @nullable
  @BuiltValueField(wireName: 'telemetry_pressure')
  double get telemetryPressure;
  @nullable
  @BuiltValueField(wireName: 'telemetry_temperature')
  double get telemetryTemperature;
  @nullable
  @BuiltValueField(wireName: 'valve_actuation_count')
  double get valveActuationCount;
  @nullable
  @BuiltValueField(wireName: 'valve_state')
  double get valveState;
  @nullable
  @BuiltValueField(wireName: 'wifi_disconnections')
  double get wifiDisconnections;
  @nullable
  @BuiltValueField(wireName: 'wifi_rssi')
  double get wifiRssi;
  @nullable
  @BuiltValueField(wireName: 'wifi_sta_enc')
  String get wifiStaEnc;
  @nullable
  @BuiltValueField(wireName: 'wifi_sta_ssid')
  String get wifiStaSsid;
  @nullable
  @BuiltValueField(wireName: 'zit_auto_count')
  double get zitAutoCount;
  @nullable
  @BuiltValueField(wireName: 'zit_manual_count')
  double get zitManualCount;
  @nullable
  @BuiltValueField(wireName: 'player_action')
  String get playerAction;
  @nullable
  @BuiltValueField(wireName: 'player_flow')
  double get playerFlow;
  @nullable
  @BuiltValueField(wireName: 'player_min_pressure')
  double get playerMinPressure;
  @nullable
  @BuiltValueField(wireName: 'player_pressure')
  double get playerPressure;
  @nullable
  @BuiltValueField(wireName: 'player_temperature')
  double get playerTemperature;

  // Puck
  //fw_name: "0.2.0-alpha1"
  //pairing_state: "authenticating"
  //reason: "get"
  //wifi_ap_ssid: "Puck-39d4"
  //wifi_sta_enc: "wpa2-psk"
  //wifi_sta_mac: "3c71bf4739d4"
  //wifi_sta_ssid: ""
  @nullable
  @BuiltValueField(wireName: 'fw_name')
  String get firmwareName;
  @nullable
  @BuiltValueField(wireName: 'reason')
  String get reason;
  @nullable
  @BuiltValueField(wireName: 'wifi_sta_pass')
  String get wifiStaPassword;
  @nullable
  @BuiltValueField(wireName: 'wifi_ap_ssid')
  String get wifiApSsid;
  @nullable
  @BuiltValueField(wireName: 'wifi_sta_mac')
  String get wifiStaMac;
  @nullable
  @BuiltValueField(wireName: 'pairing_state')
  String get pairingState;
  /// The modal shall display if the firmware property “alarm_shut_off_time_remaining” is present and its value is >10s
  @nullable
  @BuiltValueField(wireName: 'alarm_shut_off_time_remaining')
  int get alarmShutoffTimeRemaining;

  /// If the user selects “Keep Water Running”, the APP shall set the firmware property “alarm_suppress_until_event_end” to true.
  ///
  /// When set to true:
  ///
  /// the firmware shall resolve any pending flow alarms which will in turn resolve the APP pending alarms that triggered the user alert.
  /// the firmware shall suppress all alarms and shutoff events until the flow rate goes to 0.
  ///
  /// All FloSense alarms shall also be suppressed from being reported to the cloud or triggering a shutoff regardless of their level.
  /// Once the flow rate is 0, the firmware will change the property to “false” and re-enable normal alarm functionality.
  ///
  /// The firmware shall set the property “alarm_shut_off_time_remaining” back to “-1” to indicate that the shut off is no longer active.
  ///
  /// When set to false:
  ///
  /// Whether it’s external or by the firmware, “false” means normal behavior.
  @nullable
  @BuiltValueField(wireName: 'alarm_suppress_until_event_end')
  bool get alarmSuppressUntilEventEnd;

  bool get isAlarmShutoffTimeRemaining => alarmShutoffTimeRemaining != null && alarmShutoffTimeRemaining > 10;

  static const PAIRING = "pairing";
  static const PAIRED = "paired";
  static const DHCP = "dhcp";
  static const CONNECTING = "connecting";
  static const AUTHENTICATING = "authenticating";
  static const ERROR_PASSWORD = "error_password";
  static const STATES = const {
    PAIRING,
    PAIRED,
    DHCP,
    CONNECTING,
    AUTHENTICATING,
    ERROR_PASSWORD,
  };

  // How fast descending pressure is
  static const String PLAYER_ACTION_CAT1 = "cat1"; // worst, fastest
  static const String PLAYER_ACTION_CAT2 = "cat2";
  static const String PLAYER_ACTION_CAT3 = "cat3";
  static const String PLAYER_ACTION_CAT4 = "cat4"; // slow such as small drip
  static const String PLAYER_ACTION_WATER_USAGE = PLAYER_ACTION_CAT1;
  static const String PLAYER_ACTION_SMALL_DRIP = PLAYER_ACTION_CAT4;
  static const String PLAYER_ACTION_CONSTANT = "constant";
  static const String PLAYER_ACTION_DISABLED = "disabled";

  bool get isPlayerDisabled => playerAction != null ? playerAction == PLAYER_ACTION_DISABLED : true;
  bool get isPlayerConstant => playerAction != null ? playerAction == PLAYER_ACTION_CONSTANT : false;
  bool get isPlayerPressureDescending => playerAction != null
      ? anyOf(playerAction, [
          FirmwareProperties.PLAYER_ACTION_CAT1,
          FirmwareProperties.PLAYER_ACTION_CAT2,
          FirmwareProperties.PLAYER_ACTION_CAT3,
          FirmwareProperties.PLAYER_ACTION_CAT4,
        ])
      : false;
  bool get isPlayerCat1 => playerAction != null ? playerAction == FirmwareProperties.PLAYER_ACTION_CAT1 : false;
  bool get isPlayerCat2 => playerAction != null ? playerAction == FirmwareProperties.PLAYER_ACTION_CAT2 : false;
  bool get isPlayerCat3 => playerAction != null ? playerAction == FirmwareProperties.PLAYER_ACTION_CAT3 : false;
  bool get isPlayerCat4 => playerAction != null ? playerAction == FirmwareProperties.PLAYER_ACTION_CAT4 : false;

  String toJson() {
    return json
        .encode(serializers.serializeWith(FirmwareProperties.serializer, this));
  }

  static FirmwareProperties fromJson(String jsonString) {
    return serializers.deserializeWith(
        FirmwareProperties.serializer, json.decode(jsonString));
  }

  static Serializer<FirmwareProperties> get serializer =>
      _$firmwarePropertiesSerializer;
}
