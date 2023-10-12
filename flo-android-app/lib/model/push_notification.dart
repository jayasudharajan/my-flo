library push_notification;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'pending_push_notification.dart';
import 'push_notification_data.dart';
import 'serializers.dart';

part 'push_notification.g.dart';

abstract class PushNotification
    implements Built<PushNotification, PushNotificationBuilder> {
  PushNotification._();

  factory PushNotification([updates(PushNotificationBuilder b)]) =
  _$PushNotification;

  @nullable
  @BuiltValueField(wireName: 'notification')
  PendingPushNotification get notification;
  @nullable
  @BuiltValueField(wireName: 'data')
  PushNotificationData get data;
  String toJson() {
    return json
        .encode(serializers.serializeWith(PushNotification.serializer, this));
  }

  @nullable
  static PushNotification fromJson(String jsonString) {
    return or(() => serializers.deserializeWith(PushNotification.serializer, json.decode(jsonString)));
  }

  @nullable
  static PushNotification fromMap2(Map<String, dynamic> map) {
    return or(() => serializers.deserializeWith(PushNotification.serializer, map));
  }

  static PushNotification fromBuiltMap(BuiltMap<String, dynamic> map) {
    return serializers.deserializeWith(
        PushNotification.serializer, map);
  }

  static Serializer<PushNotification> get serializer =>
      _$pushNotificationSerializer;

  /*
  {
    notification: {
      title: null,
      body: null
    },
    data: {
      id: b63957ac-f9d1-11e9-b9a2-74e182118ff6,
      ts: 1572301471354,
      icd: {
        "device_id":"74e182118ff6",
        "time_zone":"US\/Pacific",
        "icd_id":"db32ac90-96bd-43d6-b2a0-66e5acf99e5b",
        "system_mode":2
      },
      version: 1,
      notification: {
        "severity":2,
        "name":"low_water_pressure",
        "description":"",
        "alarm_id":15
      }
    }
  }
  */
}