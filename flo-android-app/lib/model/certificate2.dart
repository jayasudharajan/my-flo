library certificate2;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'token.dart';

part 'certificate2.g.dart';

abstract class Certificate2
    implements Built<Certificate2, Certificate2Builder> {
  Certificate2._();

  factory Certificate2([updates(Certificate2Builder b)]) = _$Certificate2;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;

  @nullable
  @BuiltValueField(wireName: 'apName')
  String get apName;

  @nullable
  @BuiltValueField(wireName: 'apPassword')
  String get apPassword;

  @nullable
  @BuiltValueField(wireName: 'loginToken')
  String get loginToken;

  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;

  @nullable
  @BuiltValueField(wireName: 'clientCert')
  String get clientCert;

  @nullable
  @BuiltValueField(wireName: 'clientKey')
  String get clientKey;
  @nullable
  @BuiltValueField(wireName: 'serverCert')
  String get serverCert;
  @nullable
  @BuiltValueField(wireName: 'websocketCert')
  String get websocketCert;
  @nullable
  @BuiltValueField(wireName: 'websocketCertDer')
  String get websocketCertDer;
  @nullable
  @BuiltValueField(wireName: 'websocketKey')
  String get websocketKey;
  @nullable
  @BuiltValueField(wireName: 'firestore')
  Token get firestoreToken;
  String toJson() {
    return json
        .encode(serializers.serializeWith(Certificate2.serializer, this));
  }

  static Certificate2 fromJson(String jsonString) {
    return serializers.deserializeWith(
        Certificate2.serializer, json.decode(jsonString));
  }

  static Serializer<Certificate2> get serializer => _$certificate2Serializer;
}