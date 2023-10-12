library certificates_jsonrpc;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'certificates.dart';

part 'certificates_jsonrpc.g.dart';

abstract class CertificatesJsonRpc
    implements Built<CertificatesJsonRpc, CertificatesJsonRpcBuilder> {
  CertificatesJsonRpc._();

  factory CertificatesJsonRpc([updates(CertificatesJsonRpcBuilder b)]) =
      _$CertificatesJsonRpc;

  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @BuiltValueField(wireName: 'method')
  String get method;
  @BuiltValueField(wireName: 'params')
  Certificates get params;
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json.encode(
        serializers.serializeWith(CertificatesJsonRpc.serializer, this));
  }

  static CertificatesJsonRpc fromJson(String jsonString) {
    return serializers.deserializeWith(
        CertificatesJsonRpc.serializer, json.decode(jsonString));
  }

  static Serializer<CertificatesJsonRpc> get serializer =>
      _$certificatesJsonRpcSerializer;
}