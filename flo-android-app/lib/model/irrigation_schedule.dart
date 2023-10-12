library irrigation_schedule;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'schedule.dart';

part 'irrigation_schedule.g.dart';

abstract class IrrigationSchedule
    implements Built<IrrigationSchedule, IrrigationScheduleBuilder> {
  IrrigationSchedule._();

  factory IrrigationSchedule([updates(IrrigationScheduleBuilder b)]) =
      _$IrrigationSchedule;

  @nullable
  @BuiltValueField(wireName: 'computed')
  Schedule get computed;
  @nullable
  @BuiltValueField(wireName: 'isEnabled')
  bool get enabled;
  @nullable
  @BuiltValueField(wireName: 'updatedAt', serialize: false)
  String get updatedAt;
  String toJson() {
    return json
        .encode(serializers.serializeWith(IrrigationSchedule.serializer, this));
  }

  static IrrigationSchedule fromJson(String jsonString) {
    return serializers.deserializeWith(
        IrrigationSchedule.serializer, json.decode(jsonString));
  }

  static Serializer<IrrigationSchedule> get serializer =>
      _$irrigationScheduleSerializer;
}