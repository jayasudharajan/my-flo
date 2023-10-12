library oauth_token;

import 'dart:convert';

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

part 'oauth_token.g.dart';

abstract class OauthToken implements Built<OauthToken, OauthTokenBuilder> {
  OauthToken._();

  factory OauthToken([updates(OauthTokenBuilder b)]) = _$OauthToken;

  @nullable
  @BuiltValueField(wireName: 'access_token')
  String get accessToken;
  @nullable
  @BuiltValueField(wireName: 'refresh_token')
  String get refreshToken;
  @nullable
  @BuiltValueField(wireName: 'expires_in')
  int get expiresIn;
  @nullable
  @BuiltValueField(wireName: 'user_id')
  String get userId;
  @nullable
  @BuiltValueField(wireName: 'expires_at')
  String get expiresAt;
  DateTime get expiresAtDateTime => DateTimes.of(expiresAt, isUtc: true);
  @nullable
  @BuiltValueField(wireName: 'issued_at')
  String get issuedAt;
  @nullable
  @BuiltValueField(wireName: 'token_type')
  String get tokenType;
  String toJson() {
    return json.encode(serializers.serializeWith(OauthToken.serializer, this));
  }

  static OauthToken fromJson(String jsonString) {
    return serializers.deserializeWith(
        OauthToken.serializer, json.decode(jsonString));
  }

  static Serializer<OauthToken> get serializer => _$oauthTokenSerializer;

  static OauthToken empty = OauthToken((b) => b
    ..accessToken = ""
    ..userId = ""
    ..refreshToken = ""
    ..expiresIn = -1
    ..expiresAt = ""
    ..issuedAt = ""
    ..tokenType = ""
  );

  String get authorization => "Bearer ${accessToken}";

  bool get isExpired => DateTime.now().isAfter(expiresAtDateTime);

}