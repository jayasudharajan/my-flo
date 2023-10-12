library map_result;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'map_result.g.dart';

abstract class MapResult implements Built<MapResult, MapResultBuilder> {
  MapResult._();

  factory MapResult([updates(MapResultBuilder b)]) = _$MapResult;

  @nullable
  @BuiltValueField(wireName: 'result')
  BuiltMap<String, String> get result;

  String toJson() {
    return json.encode(serializers.serializeWith(MapResult.serializer, this));
  }

  static MapResult fromJson(String jsonString) {
    return serializers.deserializeWith(
        MapResult.serializer, json.decode(jsonString));
  }

  static Serializer<MapResult> get serializer => _$mapResultSerializer;
}
