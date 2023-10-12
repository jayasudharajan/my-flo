library wifi_station;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'wifi_station.g.dart';

abstract class WifiStation implements Built<WifiStation, WifiStationBuilder> {
  WifiStation._();

  factory WifiStation([updates(WifiStationBuilder b)]) = _$WifiStation;

  @nullable
  @BuiltValueField(wireName: 'wifi_sta_enabled', serialize: false)
  String get wifiStaEnabled;
  @BuiltValueField(wireName: 'wifi_sta_ssid')
  String get wifiStaSsid;
  @BuiltValueField(wireName: 'wifi_sta_encryption')
  String get wifiStaEncryption;
  @BuiltValueField(wireName: 'wifi_sta_password')
  String get wifiStaPassword;
  String toJson() {
    return json.encode(serializers.serializeWith(WifiStation.serializer, this));
  }

  static WifiStation fromJson(String jsonString) {
    return serializers.deserializeWith(
        WifiStation.serializer, json.decode(jsonString));
  }

  static Serializer<WifiStation> get serializer => _$wifiStationSerializer;
}
