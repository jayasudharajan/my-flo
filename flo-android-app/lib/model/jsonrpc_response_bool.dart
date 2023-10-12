library jsonrpc_response_bool;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'jsonrpc_response_bool.g.dart';

abstract class JsonRpcResponseBool
    implements Built<JsonRpcResponseBool, JsonRpcResponseBoolBuilder> {
  JsonRpcResponseBool._();

  factory JsonRpcResponseBool([updates(JsonRpcResponseBoolBuilder b)]) =
      _$JsonRpcResponseBool;

  @nullable
  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @nullable
  @BuiltValueField(wireName: 'result')
  bool get result;
  @nullable
  @BuiltValueField(wireName: 'from_method')
  String get method;
  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json
        .encode(serializers.serializeWith(JsonRpcResponseBool.serializer, this));
  }

  static JsonRpcResponseBool fromJson(String jsonString) {
    return serializers.deserializeWith(
        JsonRpcResponseBool.serializer, json.decode(jsonString));
  }

  static Serializer<JsonRpcResponseBool> get serializer =>
      _$jsonRpcResponseBoolSerializer;
}