library device_alerts_settings;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'alarm.dart';
import 'alert_settings.dart';
import 'serializers.dart';

part 'device_alerts_settings.g.dart';

abstract class DeviceAlertsSettings implements Built<DeviceAlertsSettings, DeviceAlertsSettingsBuilder> {
  DeviceAlertsSettings._();

  factory DeviceAlertsSettings([updates(DeviceAlertsSettingsBuilder b)]) = _$DeviceAlertsSettings;

  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'settings')
  BuiltList<AlertSettings> get settings;
  @nullable
  @BuiltValueField(wireName: 'smallDripSensitivity')
  int get smallDripSensitivity;

  @NonNull
  AlertSettings alertSettingsByAlarm(
      @NonNull
      Alarm alarm, {String systemMode}) {
    return or(() => settings?.where((it) => it.alarmId == alarm.id)?.firstWhere((it) => it.systemMode == systemMode, orElse: () => systemMode != null ? alarm.alertSettingsBySystemMode(systemMode) : alarm.alertSettings)) ?? alarm.alertSettings;
  }

  String toJson() {
    return json.encode(serializers.serializeWith(DeviceAlertsSettings.serializer, this));
  }

  static DeviceAlertsSettings fromJson(String jsonString) {
    return serializers.deserializeWith(
        DeviceAlertsSettings.serializer, json.decode(jsonString));
  }

  static Serializer<DeviceAlertsSettings> get serializer => _$deviceAlertsSettingsSerializer;
}
