library verify_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'verify_payload.g.dart';

abstract class VerifyPayload
    implements Built<VerifyPayload, VerifyPayloadBuilder> {
  VerifyPayload._();

  factory VerifyPayload([updates(VerifyPayloadBuilder b)]) = _$VerifyPayload;

  @nullable
  @BuiltValueField(wireName: 'clientId')
  String get clientId;
  @nullable
  @BuiltValueField(wireName: 'clientSecret')
  String get clientSecret;
  @nullable
  @BuiltValueField(wireName: 'token')
  String get token;
  String toJson() {
    return json
        .encode(serializers.serializeWith(VerifyPayload.serializer, this));
  }

  static VerifyPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        VerifyPayload.serializer, json.decode(jsonString));
  }

  static Serializer<VerifyPayload> get serializer => _$verifyPayloadSerializer;
}