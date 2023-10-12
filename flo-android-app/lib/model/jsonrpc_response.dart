library jsonrpc_response;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'jsonrpc_response.g.dart';

abstract class JsonRpcResponse
    implements Built<JsonRpcResponse, JsonRpcResponseBuilder> {
  JsonRpcResponse._();

  factory JsonRpcResponse([updates(JsonRpcResponseBuilder b)]) =
      _$JsonRpcResponse;

  @nullable
  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @nullable
  @BuiltValueField(wireName: 'result')
  String get result;
  @nullable
  @BuiltValueField(wireName: 'from_method')
  String get method;
  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json
        .encode(serializers.serializeWith(JsonRpcResponse.serializer, this));
  }

  static JsonRpcResponse fromJson(String jsonString) {
    return serializers.deserializeWith(
        JsonRpcResponse.serializer, json.decode(jsonString));
  }

  static Serializer<JsonRpcResponse> get serializer =>
      _$jsonRpcResponseSerializer;
}