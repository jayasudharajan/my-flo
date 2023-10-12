library threshold;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'threshold.g.dart';

abstract class Threshold implements Built<Threshold, ThresholdBuilder> {
  Threshold._();

  factory Threshold([updates(ThresholdBuilder b)]) = _$Threshold;

  @BuiltValueField(wireName: 'okMin')
  int get okMin;
  @BuiltValueField(wireName: 'okMax')
  int get okMax;
  @BuiltValueField(wireName: 'maxValue')
  int get maxValue;
  @BuiltValueField(wireName: 'minValue')
  int get minValue;
  String toJson() {
    return json.encode(serializers.serializeWith(Threshold.serializer, this));
  }

  static Threshold fromJson(String jsonString) {
    return serializers.deserializeWith(Threshold.serializer, json.decode(jsonString));
  }

  static Serializer<Threshold> get serializer => _$thresholdSerializer;
}