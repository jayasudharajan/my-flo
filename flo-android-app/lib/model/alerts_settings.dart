library alerts_settings;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'device_alerts_settings.dart';
import 'serializers.dart';

part 'alerts_settings.g.dart';

abstract class AlertsSettings
    implements Built<AlertsSettings, AlertsSettingsBuilder> {
  AlertsSettings._();

  factory AlertsSettings([updates(AlertsSettingsBuilder b)]) = _$AlertsSettings;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<DeviceAlertsSettings> get items;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertsSettings.serializer, this));
  }

  static AlertsSettings fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertsSettings.serializer, json.decode(jsonString));
  }

  static Serializer<AlertsSettings> get serializer => _$alertsSettingsSerializer;
}
