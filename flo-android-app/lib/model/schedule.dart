library schedule;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'schedule.g.dart';

abstract class Schedule implements Built<Schedule, ScheduleBuilder> {
  Schedule._();

  factory Schedule([updates(ScheduleBuilder b)]) = _$Schedule;

  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;
  @nullable
  @BuiltValueField(wireName: 'times')
  BuiltList<BuiltList<String>> get times;
  String toJson() {
    return json.encode(serializers.serializeWith(Schedule.serializer, this));
  }

  static Schedule fromJson(String jsonString) {
    return serializers.deserializeWith(
        Schedule.serializer, json.decode(jsonString));
  }

  static Serializer<Schedule> get serializer => _$scheduleSerializer;

  static const String FOUND = "schedule_found";
  static const String NOT_FOUND = "schedule_not_found";
  static const String NO_IRRIGATION_IN_HOME = "no_irrigation_in_home";
  static const String LEARNING = "learning";
  static const String INTERNAL_ERROR = "internal_error";
}
