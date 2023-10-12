library certificate;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'certificate.g.dart';

abstract class Certificate implements Built<Certificate, CertificateBuilder> {
  Certificate._();

  factory Certificate([updates(CertificateBuilder b)]) = _$Certificate;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;

  @nullable
  @BuiltValueField(wireName: 'ap_name')
  String get apName;

  @nullable
  @BuiltValueField(wireName: 'ap_password')
  String get apPassword;
  @nullable
  @BuiltValueField(wireName: 'device_id')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'login_token')
  String get loginToken;
  @nullable
  @BuiltValueField(wireName: 'client_cert')
  String get clientCert;
  @nullable
  @BuiltValueField(wireName: 'client_key')
  String get clientKey;
  @nullable
  @BuiltValueField(wireName: 'server_cert')
  String get serverCert;
  @nullable
  @BuiltValueField(wireName: 'websocket_cert')
  String get websocketCert;
  @nullable
  @BuiltValueField(wireName: 'websocket_cert_der')
  String get websocketCertDer;
  @nullable
  @BuiltValueField(wireName: 'websocket_key')
  String get websocketKey;
  String toJson() {
    return json.encode(serializers.serializeWith(Certificate.serializer, this));
  }

  static Certificate fromJson(String jsonString) {
    return serializers.deserializeWith(
        Certificate.serializer, json.decode(jsonString));
  }

  static Serializer<Certificate> get serializer => _$certificateSerializer;

  static Certificate get random => Certificate((b) => b
  ..id = "ffffffffffffffffffffffffffffffff"
  ..apName = "Flo-ffff"
  ..deviceId = "ffffffffffff"
  ..loginToken = "ffffffffffffffffffffffffffffffffffffffff"
  ..clientCert = ""
  ..clientKey = ""
  ..serverCert = ""
  ..websocketCert = ""
  ..websocketCertDer = ""
  ..websocketKey = ""
  );

  static Certificate get empty => Certificate((b) => b
  ..id = ""
  ..apName = ""
  ..apPassword = ""
  ..deviceId = ""
  ..loginToken = ""
  ..clientCert = ""
  ..clientKey = ""
  ..serverCert = ""
  ..websocketCert = ""
  ..websocketCertDer = ""
  ..websocketKey = ""
  );
}
