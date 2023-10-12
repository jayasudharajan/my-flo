library duration_value;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'duration_value.g.dart';

abstract class DurationValue
    implements
        Built<DurationValue, DurationValueBuilder> {
  DurationValue._();

  factory DurationValue(
      [updates(DurationValueBuilder b)]) =
  _$DurationValue;

  @nullable
  @BuiltValueField(wireName: 'value')
  double get value;
  @nullable
  @BuiltValueField(wireName: 'startDate')
  String get startDate;
  @nullable
  @BuiltValueField(wireName: 'endDate')
  String get endDate;
  String toJson() {
    return json.encode(
        serializers.serializeWith(DurationValue.serializer, this));
  }

  static DurationValue fromJson(String jsonString) {
    return serializers.deserializeWith(
        DurationValue.serializer, json.decode(jsonString));
  }

  static Serializer<DurationValue> get serializer =>
      _$durationValueSerializer;

  DurationValue operator +(DurationValue it) =>
      rebuild((b) => b
      /// TODO: implement startDate, endDate
          ..value = (value != null || it.value != null) ? (value ?? 0) + (it.value ?? 0) : null
      );

  static DurationValue get empty => DurationValue((b) => b
      //..value = 0.0 // the Duraation +operator can handle that value is null
  );
}
