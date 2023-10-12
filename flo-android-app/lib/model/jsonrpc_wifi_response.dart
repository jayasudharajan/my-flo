library jsonrpc_wifi_response;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'wifi.dart';

part 'jsonrpc_wifi_response.g.dart';

abstract class JsonRpcWifiResponse
    implements Built<JsonRpcWifiResponse, JsonRpcWifiResponseBuilder> {
  JsonRpcWifiResponse._();

  factory JsonRpcWifiResponse([updates(JsonRpcWifiResponseBuilder b)]) =
      _$JsonRpcWifiResponse;

  @nullable
  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  @nullable
  @BuiltValueField(wireName: 'from_method')
  String get method;
  @nullable
  @BuiltValueField(wireName: 'result')
  BuiltList<Wifi> get result;
  String toJson() {
    return json.encode(
        serializers.serializeWith(JsonRpcWifiResponse.serializer, this));
  }

  static JsonRpcWifiResponse fromJson(String jsonString) {
    return serializers.deserializeWith(
        JsonRpcWifiResponse.serializer, json.decode(jsonString));
  }

  static Serializer<JsonRpcWifiResponse> get serializer =>
      _$jsonRpcWifiResponseSerializer;
}