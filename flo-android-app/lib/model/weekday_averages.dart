library weekday_averages;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'weekday_averages.g.dart';

abstract class WeekdayAverages
    implements Built<WeekdayAverages, WeekdayAveragesBuilder> {
  WeekdayAverages._();

  factory WeekdayAverages([updates(WeekdayAveragesBuilder b)]) = _$WeekdayAverages;

  @nullable
  @BuiltValueField(wireName: 'value')
  double get value;
  @nullable
  @BuiltValueField(wireName: 'dayOfWeek')
  int get dayOfWeek;
  String toJson() {
    return json
        .encode(serializers.serializeWith(WeekdayAverages.serializer, this));
  }

  static WeekdayAverages fromJson(String jsonString) {
    return serializers.deserializeWith(
        WeekdayAverages.serializer, json.decode(jsonString));
  }

  static Serializer<WeekdayAverages> get serializer => _$weekdayAveragesSerializer;

  WeekdayAverages operator +(WeekdayAverages it) =>
      rebuild((b) => b
        /// TODO: implement dayOfWeek
        ..value = (value != null || it.value != null) ? (value ?? 0) + (it.value ?? 0) : null
      );

  static WeekdayAverages get empty => WeekdayAverages((b) => b
  );
}
