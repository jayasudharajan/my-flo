library water_usage_averages_aggregations;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

import 'weekday_averages.dart';
import 'duration_value.dart';

part 'water_usage_averages_aggregations.g.dart';

abstract class WaterUsageAveragesAggregations
    implements
        Built<WaterUsageAveragesAggregations,
            WaterUsageAveragesAggregationsBuilder> {
  WaterUsageAveragesAggregations._();

  factory WaterUsageAveragesAggregations(
      [updates(WaterUsageAveragesAggregationsBuilder b)]) =
  _$WaterUsageAveragesAggregations;

  @nullable
  @BuiltValueField(wireName: 'dayOfWeekAvg')
  WeekdayAverages get weekdayAverages;
  @nullable
  @BuiltValueField(wireName: 'prevCalendarWeekDailyAvg')
  DurationValue get weekdailyAverages;
  @nullable
  @BuiltValueField(wireName: 'monthlyAvg')
  DurationValue get monthlyAverages;

  String toJson() {
    return json.encode(serializers.serializeWith(
        WaterUsageAveragesAggregations.serializer, this));
  }

  static WaterUsageAveragesAggregations fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsageAveragesAggregations.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsageAveragesAggregations> get serializer =>
      _$waterUsageAveragesAggregationsSerializer;

  WaterUsageAveragesAggregations operator +(WaterUsageAveragesAggregations it) =>
      rebuild((b) => b
        ..weekdayAverages = ((weekdayAverages ?? WeekdayAverages.empty) + (it?.weekdayAverages ?? WeekdayAverages.empty)).toBuilder()
        ..weekdailyAverages = ((weekdailyAverages ?? DurationValue.empty) + (it?.weekdailyAverages) ?? DurationValue.empty).toBuilder()
        ..monthlyAverages = ((monthlyAverages ?? DurationValue.empty) + (it?.monthlyAverages) ?? DurationValue.empty).toBuilder()
      );

  static WaterUsageAveragesAggregations get empty => WaterUsageAveragesAggregations((b) => b
      ..weekdayAverages = WeekdayAverages.empty.toBuilder()
      ..weekdailyAverages = DurationValue.empty.toBuilder()
      ..monthlyAverages = DurationValue.empty.toBuilder()
  );
}
