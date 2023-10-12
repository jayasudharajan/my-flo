library wifi;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'wifi.g.dart';

abstract class Wifi implements Built<Wifi, WifiBuilder> {
  Wifi._();

  factory Wifi([updates(WifiBuilder b)]) = _$Wifi;

  @BuiltValueField(wireName: 'ssid')
  String get ssid;
  @nullable
  @BuiltValueField(wireName: 'encryption')
  String get encryption;
  @nullable
  @BuiltValueField(wireName: 'signal')
  double get signal;
  String toJson() {
    return json.encode(serializers.serializeWith(Wifi.serializer, this));
  }

  static Wifi fromJson(String jsonString) {
    return serializers.deserializeWith(
        Wifi.serializer, json.decode(jsonString));
  }

  //static Serializer<Wifi> get serializer => _$wifiSerializer;
  static Serializer<Wifi> get serializer => _$wifiSerializer;
  static const PSK2 = "psk2";
}