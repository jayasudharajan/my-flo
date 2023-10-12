library device;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart' as material;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils.dart';
import 'alert_statistics.dart';
import 'certificate2.dart';
import 'connectivity.dart';
import 'estimate_water_usage.dart';
import 'firmware_properties.dart';
import 'hardware_thresholds.dart';
import 'health_test.dart';
import 'id.dart';
import 'install_status.dart';
import 'irrigation_schedule.dart';
import 'learning.dart';
import 'pending_system_mode.dart';
import 'serializers.dart';
import 'telemetries.dart';
import 'valve.dart';

part 'device.g.dart';

/**
 * {
 *  // "prvInstalledAfter": true,
 *  "irrigationType": "none",
 *  "installationPoint": "string",
 *  "nickname": "string",
 *  "valve": {
 *    "target": "open",
 *    "lastKnown": "open"
 *  },
 *  "createdAt": "2019-06-18T21:38:04.238Z",
 *  "updatedAt": "2019-06-18T21:38:04.238Z",
 *  "id": "ffffffff-5717-4562-b3fc-ffffffffffff",
 *  "macAddress": "string",
 *  "deviceType": "string",
 *  "deviceModel": "string",
 *  "isConnected": true,
 *  "lastHeardFromTime": "2019-06-18T21:38:04.238Z",
 *  "fwVersion": "string",
 *  "fwProperties": {},
 *  "systemMode": {
 *    "target": "home",
 *    "shouldInhert": true,
 *    "revertMinutes": 0,
 *    "revertMode": "home",
 *    "revertScheduledAt": "2019-06-18T21:38:04.238Z"
 *  }
 *}
 */
abstract class Device implements Built<Device, DeviceBuilder> {
  Device._();

  factory Device([updates(DeviceBuilder b)]) = _$Device;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;

  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;

  @nullable
  @BuiltValueField(wireName: 'prvInstallation')
  String get prvInstallation;

  @nullable
  @BuiltValueField(wireName: 'irrigationType')
  String get irrigationType;

  @nullable
  @BuiltValueField(wireName: 'installationPoint') // installPoint?
  String get installationPoint;

  @nullable
  @BuiltValueField(wireName: 'nickname')
  String get nickname;

  @nullable
  @BuiltValueField(wireName: 'valve')
  Valve get valve;

  @nullable
  @BuiltValueField(wireName: 'valveState')
  Valve get valveState;

  @nullable
  @BuiltValueField(wireName: 'createdAt', serialize: false)
  String get createdAt;
  @nullable
  @BuiltValueField(wireName: 'updatedAt', serialize: false)
  String get updatedAt;
  @nullable
  @BuiltValueField(wireName: 'deviceType')
  String get deviceType;
  @nullable
  @BuiltValueField(wireName: 'deviceModel')
  String get deviceModel;
  @nullable
  @BuiltValueField(wireName: 'isConnected')
  bool get isConnected;
  @nullable
  @BuiltValueField(wireName: 'isPaired')
  bool get isPaired;
  @nullable
  @BuiltValueField(wireName: 'lastHeardFromTime')
  String get lastHeardFromTime;
  
  @nullable
  @BuiltValueField(wireName: 'location')
  Id get location;

  @nullable
  @BuiltValueField(wireName: 'fwVersion')
  String get firmwareVersion;

  @nullable
  @BuiltValueField(wireName: 'fwProperties')
  FirmwareProperties get firmwareProperties;
  //BuiltMap<String, dynamic> get firmwareProperties;

  @nullable
  @BuiltValueField(wireName: 'systemMode')
  PendingSystemMode get systemMode;

  @nullable
  @BuiltValueField(wireName: 'hardwareThresholds')
  HardwareThresholds get hardwareThresholds;

  @nullable
  @BuiltValueField(wireName: 'connectivity')
  Connectivity get connectivity;

  @nullable
  @BuiltValueField(wireName: 'notifications')
  AlertStatistics get notifications;

  @nullable
  @BuiltValueField(wireName: 'telemetry')
  Telemetries get telemetries;

  @nullable
  @BuiltValueField(wireName: 'installStatus')
  InstallStatus get installStatus;

  @nullable
  @BuiltValueField(wireName: 'healthTest') // TODO
  HealthTest get healthTest;

  @nullable
  @BuiltValueField(wireName: 'fsTimestamp', serialize: false)
  BuiltMap<String, String> get fsTimestamp;

  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;

  @nullable
  @BuiltValueField(wireName: 'irrigationSchedule')
  IrrigationSchedule get irrigationSchedule;

  @nullable
  @BuiltValueField(wireName: 'learning')
  Learning get learning;

  @nullable
  @BuiltValueField(wireName: 'pairingData')
  Certificate2 get certificate;

  @nullable
  @BuiltValueField(wireName: 'serialNumber')
  String get serialNumber;

  @nullable
  @BuiltValueField(wireName: 'waterConsumption')
  EstimateWaterUsage get estimateWaterUsage;


  /// NOTICE: Remember to remove readonly property you just added on Flo.putDevice();


  @nullable
  @BuiltValueField(wireName: 'dirty', serialize: false)
  bool get dirty;

  String toJson() {
    return json.encode(serializers.serializeWith(Device.serializer, this));
  }

  static Device fromJson(String jsonString) {
    return serializers.deserializeWith(
        Device.serializer, json.decode(jsonString));
  }

  static Serializer<Device> get serializer => _$deviceSerializer;
  static Device get empty => Device((b) => b
  ..id = ""
  );
  static Device get EMPTY => Device();

  Device mergeValve(Valve it) {
    if (it == null) return this;
    return rebuild((b) => b
      ..valve = valve?.merge(it) ?? it.toBuilder()
    );
  }

  Device mergeCertificate(Certificate2 it) {
    return rebuild((b) => b
      ..certificate = it?.toBuilder() ?? b.certificate
    );
  }

  Device merge(Device it) {
    return rebuild((b) => b
        ..systemMode = systemMode?.rebuild((b) => b
          ..lastKnown = it?.systemMode?.lastKnown ?? b.lastKnown
          ..target = it?.systemMode?.target ?? b.target)?.toBuilder() ?? b.systemMode
        ..isConnected = it.isConnected ?? b.isConnected
        ..valve = valve?.rebuild((b) => b..lastKnown = it?.valve?.lastKnown ?? b.lastKnown)?.toBuilder()
        ..valveState = valveState?.rebuild((b) => b..lastKnown = it?.valveState?.lastKnown ?? b.lastKnown)?.toBuilder()
        ..healthTest = it.healthTest?.toBuilder() ?? b.healthTest
        ..connectivity = connectivity?.rebuild((b) => b..rssi = it?.connectivity?.rssi ?? b.rssi)?.toBuilder()
        ..telemetries = it?.telemetries?.toBuilder() ?? b.telemetries
        ..installStatus = it?.installStatus?.toBuilder() ?? b.installStatus
        ..certificate = it?.certificate?.toBuilder() ?? b?.certificate
        ..notifications = it?.notifications?.pending != null ? it?.notifications?.toBuilder() : b.notifications
    );
  }

  // device_model
  static const String FLO_DEVICE_075_V2 = "flo_device_075_v2";
  static const String FLO_DEVICE_125_V2 = "flo_device_125_v2";
  static const String PUCK_V1 = "puck_v1";
  static const Set<String> MODELS = const {
    FLO_DEVICE_075_V2,
    FLO_DEVICE_125_V2,
    PUCK_V1,
  };

  static const String FLO_DEVICE_075_V2_DISPLAY = "3/4\" Smart Water Shutoff";
  static const String FLO_DEVICE_125_V2_DISPLAY = "1-1/4\" Smart Water Shutoff";
  static const String PUCK_V1_DISPLAY = "Water Sensor";

  static const String NONE = "none";
  static const String SPRINKLERS = "sprinklers";
  static const String DRIP = "drip";
  static const String BEFORE = "before";
  static const String AFTER = "after";
  static const String NO = "no";

  // device_make
  static const String FLO_DEVICE_V2 = "flo_device_v2";
  static const String PUCK_OEM = "puck_oem";
  static const Set<String> MAKES = const {
    FLO_DEVICE_V2,
    PUCK_OEM,
  };

  static const String PUCK = "puck";
  static const String PUCK_SSID_PREFIX = PUCK;
  static const String UNKNOWN = "unknown";

  String get displayName => nickname ?? DeviceUtils.modelOr(deviceModel) ?? "";

  String displayNameOf(material.BuildContext context) => nickname ?? DeviceUtils.model(deviceModel, context: context);

  String displayNameOfOr(material.BuildContext context) => nickname ?? DeviceUtils.modelOr(deviceModel, context: context);

  bool get isLearning => (systemMode?.isLearning ?? true) || !(installStatus?.isInstalled ?? true);

  bool get isSecure => (installStatus?.isInstalled ?? false) && !(isLearning ?? false) && (isConnected ?? false);


  bool isNeedsInstallProvisioned(SharedPreferences prefs) => or(() => prefs.getBool("${NEEDS_INSTALL_PROVISIONED}_${id}")) ?? false;

  Future<bool> provisionNeedsInstall({SharedPreferences prefs}) async {
    prefs ??= await SharedPreferences.getInstance();
    return await prefs.setBool("${NEEDS_INSTALL_PROVISIONED}_${id}", true);
  }

  static const String NEEDS_INSTALL_PROVISIONED = "needs_install_provisioned";

  bool isNeededShowNeedsInstall(SharedPreferences prefs) {
    return (installStatus?.isJustInstalled() ?? false) && isNeedsInstallProvisioned(prefs);
  }

  Future<bool> get isNeededShowNeedsInstallAsync async =>
      (installStatus?.isJustInstalled() ?? false) && !isNeedsInstallProvisioned(await SharedPreferences.getInstance());
}

