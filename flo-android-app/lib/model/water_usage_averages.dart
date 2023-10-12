library water_usage_averages;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

import 'water_usage_averages_aggregations.dart';
import 'water_usage_params.dart';

part 'water_usage_averages.g.dart';

abstract class WaterUsageAverages
    implements Built<WaterUsageAverages, WaterUsageAveragesBuilder> {
  WaterUsageAverages._();

  factory WaterUsageAverages([updates(WaterUsageAveragesBuilder b)]) =
  _$WaterUsageAverages;

  @nullable
  @BuiltValueField(wireName: 'params')
  WaterUsageParams get params;
  @nullable
  @BuiltValueField(wireName: 'aggregations')
  WaterUsageAveragesAggregations get aggregations;
  String toJson() {
    return json
        .encode(serializers.serializeWith(WaterUsageAverages.serializer, this));
  }

  static WaterUsageAverages fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsageAverages.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsageAverages> get serializer =>
      _$waterUsageAveragesSerializer;

  static WaterUsageAverages get empty => WaterUsageAverages((b) => b
      ..aggregations = WaterUsageAveragesAggregations.empty.toBuilder()
  );

  WaterUsageAverages operator +(WaterUsageAverages it) =>
    rebuild((b) => b
    /// TODO: implement params
    //..params = or(() => params + it.params)?.toBuilder() ?? b.params
      ..aggregations = ((aggregations ?? WaterUsageAveragesAggregations.empty) + (it?.aggregations ?? WaterUsageAveragesAggregations.empty)).toBuilder()
    );
}
