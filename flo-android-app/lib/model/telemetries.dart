library telemetries;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'telemetry2.dart';

part 'telemetries.g.dart';

abstract class Telemetries implements Built<Telemetries, TelemetriesBuilder> {
  Telemetries._();

  factory Telemetries([updates(TelemetriesBuilder b)]) = _$Telemetries;

  @nullable
  @BuiltValueField(wireName: 'current')
  Telemetry2 get current;
  @nullable
  @BuiltValueField(wireName: 'updated')
  String get updated;
  String toJson() {
    return json.encode(serializers.serializeWith(Telemetries.serializer, this));
  }

  static Telemetries fromJson(String jsonString) {
    return serializers.deserializeWith(
        Telemetries.serializer, json.decode(jsonString));
  }

  static Serializer<Telemetries> get serializer => _$telemetriesSerializer;
}

