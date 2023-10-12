library push_notification_data;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'push_notification_data.g.dart';

abstract class PushNotificationData implements Built<PushNotificationData, PushNotificationDataBuilder> {
  PushNotificationData._();

  factory PushNotificationData([updates(PushNotificationDataBuilder b)]) = _$PushNotificationData;

  @nullable
  @BuiltValueField(wireName: 'url')
  String get url;

  @nullable
  @BuiltValueField(wireName: 'data')
  JsonObject get data;

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
    return json.encode(serializers.serializeWith(PushNotificationData.serializer, this));
  }

  static PushNotificationData fromJson(String jsonString) {
    return serializers.deserializeWith(
        PushNotificationData.serializer, json.decode(jsonString));
  }

  static Serializer<PushNotificationData> get serializer => _$pushNotificationDataSerializer;
}