library wifi_station_jsonrpc;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'wifi_station.dart';

part 'wifi_station_jsonrpc.g.dart';

abstract class WifiStationJsonRpc
    implements Built<WifiStationJsonRpc, WifiStationJsonRpcBuilder> {
  WifiStationJsonRpc._();

  factory WifiStationJsonRpc([updates(WifiStationJsonRpcBuilder b)]) =
      _$WifiStationJsonRpc;

  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @BuiltValueField(wireName: 'method')
  String get method;
  @BuiltValueField(wireName: 'params')
  WifiStation get params;
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json
        .encode(serializers.serializeWith(WifiStationJsonRpc.serializer, this));
  }

  static WifiStationJsonRpc fromJson(String jsonString) {
    return serializers.deserializeWith(
        WifiStationJsonRpc.serializer, json.decode(jsonString));
  }

  static Serializer<WifiStationJsonRpc> get serializer => _$wifiStationJsonRpcSerializer;
}