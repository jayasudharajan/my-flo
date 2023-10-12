library water_usage_aggregations;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'water_usage_aggregations.g.dart';

abstract class WaterUsageAggregations
    implements Built<WaterUsageAggregations, WaterUsageAggregationsBuilder> {
  WaterUsageAggregations._();

  factory WaterUsageAggregations([updates(WaterUsageAggregationsBuilder b)]) = _$WaterUsageAggregations;

  @nullable
  @BuiltValueField(wireName: 'sumTotalGallonsConsumed')
  double get sumTotalGallonsConsumed;

  String toJson() {
    return json
        .encode(serializers.serializeWith(WaterUsageAggregations.serializer, this));
  }

  static WaterUsageAggregations fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsageAggregations.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsageAggregations> get serializer => _$waterUsageAggregationsSerializer;

  WaterUsageAggregations merge(WaterUsageAggregations it) {
    if (it == null) return this;
    return rebuild((b) => b..sumTotalGallonsConsumed = (sumTotalGallonsConsumed ?? 0) + (it.sumTotalGallonsConsumed ?? 0));
  }

  WaterUsageAggregations operator +(WaterUsageAggregations it) => merge(it);
}