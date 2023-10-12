library oauth_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'oauth_payload.g.dart';

abstract class OauthPayload
    implements Built<OauthPayload, OauthPayloadBuilder> {
  OauthPayload._();

  factory OauthPayload([updates(OauthPayloadBuilder b)]) = _$OauthPayload;

  @nullable
  @BuiltValueField(wireName: 'client_id')
  String get clientId;
  @nullable
  @BuiltValueField(wireName: 'client_secret')
  String get clientSecret;
  @nullable
  @BuiltValueField(wireName: 'grant_type')
  String get grantType;
  @nullable
  @BuiltValueField(wireName: 'username')
  String get username;
  @nullable
  @BuiltValueField(wireName: 'password')
  String get password;
  @nullable
  @BuiltValueField(wireName: 'refresh_token')
  String get refreshToken;

  @nullable
  @BuiltValueField(wireName: 'token')
  String get token;

  String toJson() {
    return json
        .encode(serializers.serializeWith(OauthPayload.serializer, this));
  }

  static OauthPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        OauthPayload.serializer, json.decode(jsonString));
  }

  static Serializer<OauthPayload> get serializer => _$oauthPayloadSerializer;
}
