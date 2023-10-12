library link_device_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'id.dart';
import 'serializers.dart';

import 'location.dart';

part 'link_device_payload.g.dart';

abstract class LinkDevicePayload
    implements Built<LinkDevicePayload, LinkDevicePayloadBuilder> {
  LinkDevicePayload._();

  factory LinkDevicePayload([updates(LinkDevicePayloadBuilder b)]) =
      _$LinkDevicePayload;

  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;

  @nullable
  @BuiltValueField(wireName: 'nickname')
  String get nickname;

  @nullable
  @BuiltValueField(wireName: 'location')
  //Location get location;
  Id get location;

  @nullable
  @BuiltValueField(wireName: 'deviceType')
  String get deviceType;

  @nullable
  @BuiltValueField(wireName: 'deviceModel')
  String get deviceModel;

  @nullable
  @BuiltValueField(wireName: 'area')
  String get area;

  String toJson() {
    return json
        .encode(serializers.serializeWith(LinkDevicePayload.serializer, this));
  }

  static LinkDevicePayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        LinkDevicePayload.serializer, json.decode(jsonString));
  }

  static Serializer<LinkDevicePayload> get serializer =>
      _$linkDevicePayloadSerializer;

  static LinkDevicePayload get empty => LinkDevicePayload((b) => b
  ..macAddress = ""
  ..nickname = ""
  ..location = Id.empty.toBuilder()
  ..deviceType = ""
  ..deviceModel = ""
  );
}