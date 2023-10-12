library water_usage_params;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'water_usage_params.g.dart';

abstract class WaterUsageParams implements Built<WaterUsageParams, WaterUsageParamsBuilder> {
  WaterUsageParams._();

  factory WaterUsageParams([updates(WaterUsageParamsBuilder b)]) = _$WaterUsageParams;

  @nullable
  @BuiltValueField(wireName: 'startDate')
  String get startDate;
  @nullable
  @BuiltValueField(wireName: 'endDate')
  String get endDate;
  @nullable
  @BuiltValueField(wireName: 'interval')
  String get interval;
  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;
  @nullable
  @BuiltValueField(wireName: 'locationId')
  String get locationId;
  @nullable
  @BuiltValueField(wireName: 'tz')
  String get tz;
  String toJson() {
    return json.encode(serializers.serializeWith(WaterUsageParams.serializer, this));
  }

  static WaterUsageParams fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsageParams.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsageParams> get serializer => _$waterUsageParamsSerializer;
}
