library alert_settings;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'delivery_mediums.dart';
import 'serializers.dart';

part 'alert_settings.g.dart';

abstract class AlertSettings
    implements Built<AlertSettings, AlertSettingsBuilder> {
  AlertSettings._();

  factory AlertSettings([updates(AlertSettingsBuilder b)]) = _$AlertSettings;

  @nullable
  @BuiltValueField(wireName: 'alarmId')
  int get alarmId;
  @nullable
  @BuiltValueField(wireName: 'systemMode')
  String get systemMode;
  @nullable
  @BuiltValueField(wireName: 'smsEnabled')
  bool get smsEnabled;
  @nullable
  @BuiltValueField(wireName: 'emailEnabled')
  bool get emailEnabled;
  @nullable
  @BuiltValueField(wireName: 'pushEnabled')
  bool get pushEnabled;
  @nullable
  @BuiltValueField(wireName: 'callEnabled')
  bool get callEnabled;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertSettings.serializer, this));
  }

  static AlertSettings fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertSettings.serializer, json.decode(jsonString));
  }

  static Serializer<AlertSettings> get serializer => _$alertSettingsSerializer;

  static AlertSettings disabled = AlertSettings((b) => b
    ..smsEnabled = false
    ..emailEnabled = false
    ..pushEnabled = false
    ..callEnabled = false
  );

  bool get isNotEmpty => [smsEnabled, emailEnabled, pushEnabled, callEnabled].any((it) => it != null);
  //bool get isEmpty => [smsEnabled, emailEnabled, pushEnabled, callEnabled].every((it) => it == null);
  bool get isEmpty => !isNotEmpty;

  AlertSettings ofMedium(DeliveryMediums deliveryMedium) =>
    rebuild((b) => b
      ..smsEnabled = (deliveryMedium?.sms?.supported ?? false) ? (b?.smsEnabled ?? deliveryMedium?.sms?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode)?.enabled ?? false) : null
      ..emailEnabled = (deliveryMedium?.email?.supported ?? false) ? (b?.emailEnabled ?? deliveryMedium?.email?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode)?.enabled ?? false) : null
      ..pushEnabled = (deliveryMedium?.push?.supported ?? false) ? (b?.pushEnabled ?? deliveryMedium?.push?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode)?.enabled ?? false) : null
      ..callEnabled = (deliveryMedium?.call?.supported ?? false) ? (b?.callEnabled ?? deliveryMedium?.call?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode)?.enabled) : null
    );
}
