library connectivity;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'connectivity.g.dart';

abstract class Connectivity
    implements Built<Connectivity, ConnectivityBuilder> {
  Connectivity._();

  factory Connectivity([updates(ConnectivityBuilder b)]) = _$Connectivity;

  @nullable
  @BuiltValueField(wireName: 'rssi')
  double get rssi;
  @nullable
  @BuiltValueField(wireName: 'ssid')
  String get ssid;
  String toJson() {
    return json
        .encode(serializers.serializeWith(Connectivity.serializer, this));
  }

  static Connectivity fromJson(String jsonString) {
    return serializers.deserializeWith(
        Connectivity.serializer, json.decode(jsonString));
  }

  static Serializer<Connectivity> get serializer => _$connectivitySerializer;
}
