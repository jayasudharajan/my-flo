library estimate_water_usage;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'estimate_water_usage.g.dart';

abstract class EstimateWaterUsage
    implements Built<EstimateWaterUsage, EstimateWaterUsageBuilder> {
  EstimateWaterUsage._();

  factory EstimateWaterUsage([updates(EstimateWaterUsageBuilder b)]) =
  _$EstimateWaterUsage;

  @nullable
  @BuiltValueField(wireName: 'estimateLastUpdated')
  String get estimateLastUpdated;
  @nullable
  @BuiltValueField(wireName: 'estimateToday')
  double get estimateToday;
  String toJson() {
    return json
        .encode(serializers.serializeWith(EstimateWaterUsage.serializer, this));
  }

  static EstimateWaterUsage fromJson(String jsonString) {
    return serializers.deserializeWith(
        EstimateWaterUsage.serializer, json.decode(jsonString));
  }

  static Serializer<EstimateWaterUsage> get serializer =>
      _$estimateWaterUsageSerializer;
}

