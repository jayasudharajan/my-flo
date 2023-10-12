library pending_push_notification;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'pending_push_notification.g.dart';

abstract class PendingPushNotification
    implements Built<PendingPushNotification, PendingPushNotificationBuilder> {
  PendingPushNotification._();

  factory PendingPushNotification([updates(PendingPushNotificationBuilder b)]) = _$PendingPushNotification;

  @nullable
  @BuiltValueField(wireName: 'title')
  String get title;
  @nullable
  @BuiltValueField(wireName: 'body')
  String get body;

  @nullable
  @BuiltValueField(wireName: 'tag')
  String get tag;
  @nullable
  @BuiltValueField(wireName: 'color')
  String get color;
  @nullable
  @BuiltValueField(wireName: 'click_action')
  String get clickAction;
  String toJson() {
    return json
        .encode(serializers.serializeWith(PendingPushNotification.serializer, this));
  }

  static PendingPushNotification fromJson(String jsonString) {
    return serializers.deserializeWith(
        PendingPushNotification.serializer, json.decode(jsonString));
  }

  static Serializer<PendingPushNotification> get serializer => _$pendingPushNotificationSerializer;
}