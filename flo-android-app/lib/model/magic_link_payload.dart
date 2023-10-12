library magic_link_payload;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'magic_link_payload.g.dart';

abstract class MagicLinkPayload
    implements Built<MagicLinkPayload, MagicLinkPayloadBuilder> {
  MagicLinkPayload._();

  factory MagicLinkPayload([updates(MagicLinkPayloadBuilder b)]) = _$MagicLinkPayload;

  @BuiltValueField(wireName: 'email')
  String get email;
  @BuiltValueField(wireName: 'client_id')
  String get clientId;
  @BuiltValueField(wireName: 'client_secret')
  String get clientSecret;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(MagicLinkPayload.serializer, this));
  }

  static MagicLinkPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        MagicLinkPayload.serializer, json.decode(jsonString));
  }

  static Serializer<MagicLinkPayload> get serializer => _$magicLinkPayloadSerializer;
}