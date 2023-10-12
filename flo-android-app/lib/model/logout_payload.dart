library logout_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'logout_payload.g.dart';

abstract class LogoutPayload implements Built<LogoutPayload, LogoutPayloadBuilder> {
  LogoutPayload._();

  factory LogoutPayload([updates(LogoutPayloadBuilder b)]) = _$LogoutPayload;

  @BuiltValueField(wireName: 'mobile_device_id')
  String get deviceId;
  String toJson() {
    return json.encode(serializers.serializeWith(LogoutPayload.serializer, this));
  }

  static LogoutPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        LogoutPayload.serializer, json.decode(jsonString));
  }

  static Serializer<LogoutPayload> get serializer => _$logoutPayloadSerializer;
}
