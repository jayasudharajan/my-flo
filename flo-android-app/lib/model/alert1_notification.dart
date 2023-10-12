library alert1_notification;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alert1_notification.g.dart';

abstract class Alert1Notification
    implements Built<Alert1Notification, Alert1NotificationBuilder> {
  Alert1Notification._();

  factory Alert1Notification([updates(Alert1NotificationBuilder b)]) =
  _$Alert1Notification;

  @nullable
  @BuiltValueField(wireName: 'severity')
  int get severity;
  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  @nullable
  @BuiltValueField(wireName: 'alarm_id')
  int get alarmId;
  String toJson() {
    return json
        .encode(serializers.serializeWith(Alert1Notification.serializer, this));
  }

  static Alert1Notification fromJson(String jsonString) {
    return serializers.deserializeWith(
        Alert1Notification.serializer, json.decode(jsonString));
  }

  static Serializer<Alert1Notification> get serializer =>
      _$alert1NotificationSerializer;
}
