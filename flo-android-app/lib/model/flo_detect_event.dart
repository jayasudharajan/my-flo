library flo_detect_event;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart' as material;
import '../utils.dart';
import 'fixture.dart';
import 'flo_detect_feedback.dart';
import 'serializers.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'flo_detect_event.g.dart';

abstract class FloDetectEvent implements Built<FloDetectEvent, FloDetectEventBuilder> {
  FloDetectEvent._();

  factory FloDetectEvent([updates(FloDetectEventBuilder b)]) = _$FloDetectEvent;

  @nullable
  @BuiltValueField(wireName: 'computationId')
  String get computationId;
  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;
  @nullable
  @BuiltValueField(wireName: 'duration') // what's the unit?
  int get duration;
  @nullable
  @BuiltValueField(wireName: 'fixture')
  String get fixture;
  @nullable
  @BuiltValueField(wireName: 'feedback')
  FloDetectFeedback get feedback;
  @nullable
  @BuiltValueField(wireName: 'type')
  int get type;
  @nullable
  @BuiltValueField(wireName: 'start')
  String get start;
  @nullable
  @BuiltValueField(wireName: 'end')
  String get end;
  @nullable
  @BuiltValueField(wireName: 'flow')
  double get flow;
  @nullable
  @BuiltValueField(wireName: 'gpm')
  double get gpm;

  DateTime get startDateTime => DateTimes.of(start, isUtc: true);
  DateTime get endDateTime => DateTimes.of(end, isUtc: true);
  String get durationDisplay => timeago.format(startDateTime, until: endDateTime, allowFromNow: true, locale: 'en_duration');
  String get id => "${startDateTime} ${type} ${fixture} ${flow ?? 0}";

  String get selectedFixture => feedback?.correctFixture ?? fixture;
  int get selectedFixtureType => Fixture.typeBy(selectedFixture);

  String toJson() {
    return json.encode(serializers.serializeWith(FloDetectEvent.serializer, this));
  }

  static FloDetectEvent fromJson(String jsonString) {
    return serializers.deserializeWith(
        FloDetectEvent.serializer, json.decode(jsonString));
  }

  static Serializer<FloDetectEvent> get serializer => _$floDetectEventSerializer;

  static const String ASC = "asc";
  static const String DESC = "desc";

  String wasDisplay(material.BuildContext context) {
    return Fixture.displayByName(context, fixture);
  }

  String display(material.BuildContext context) {
    //return Fixture.displayByName(context, selectedFixture);
    return Fixture.displayBy(context, selectedFixtureType);
  }

  FloDetectEvent putFeedbackBy(int type) {
    return putFeedback(Fixture.nameBy(type));
  }

  FloDetectEvent putFeedback(String it) { // name
    return rebuild((b) => b..feedback = FloDetectFeedback((b) => b
      ..cases = fixture == it ? FloDetectFeedback.CONFIRM : FloDetectFeedback.WRONG
      ..correctFixture = it
    )?.toBuilder()
    );
  }
}
