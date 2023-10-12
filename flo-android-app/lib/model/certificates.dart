library certificates;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'certificates.g.dart';

abstract class Certificates implements Built<Certificates, CertificatesBuilder> {
  Certificates._();

  factory Certificates([updates(CertificatesBuilder b)]) = _$Certificates;

  @BuiltValueField(wireName: 'encoded_ca_cert')
  String get encodedCaCert;
  @BuiltValueField(wireName: 'encoded_client_cert')
  String get encodedClientCert;
  @BuiltValueField(wireName: 'encoded_client_key')
  String get encodedClientKey;
  String toJson() {
    return json.encode(serializers.serializeWith(Certificates.serializer, this));
  }

  static Certificates fromJson(String jsonString) {
    return serializers.deserializeWith(
        Certificates.serializer, json.decode(jsonString));
  }

  static Serializer<Certificates> get serializer => _$certificatesSerializer;
}