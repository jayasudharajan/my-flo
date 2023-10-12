library region;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'timezone.dart';

part 'region.g.dart';

abstract class Region
    implements Built<Region, RegionBuilder> {
  Region._();

  factory Region([updates(RegionBuilder b)]) = _$Region;

  @BuiltValueField(wireName: 'name')
  String get name;
  @BuiltValueField(wireName: 'abbrev')
  String get abbrev;
  @BuiltValueField(wireName: 'timezones')
  BuiltList<TimeZone> get timezones;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(Region.serializer, this));
  }

  static Region fromJson(String jsonString) {
    return serializers.deserializeWith(
        Region.serializer, json.decode(jsonString));
  }

  static Serializer<Region> get serializer => _$regionSerializer;
}
