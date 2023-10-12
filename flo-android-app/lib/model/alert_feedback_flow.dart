library alert_feedback_flow;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'alert_feedback_step.dart';
import 'alert_feedback_flow_tags.dart';

part 'alert_feedback_flow.g.dart';

abstract class AlertFeedbackFlow
    implements Built<AlertFeedbackFlow, AlertFeedbackFlowBuilder> {
  AlertFeedbackFlow._();

  factory AlertFeedbackFlow([updates(AlertFeedbackFlowBuilder b)]) =
  _$AlertFeedbackFlow;

  @nullable
  @BuiltValueField(wireName: 'systemMode')
  String get systemMode;
  @nullable
  @BuiltValueField(wireName: 'flow')
  AlertFeedbackStep get flow;
  @nullable
  @BuiltValueField(wireName: 'flowTags')
  AlertFeedbackFlowTags get flowTags;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertFeedbackFlow.serializer, this));
  }

  static AlertFeedbackFlow fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedbackFlow.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedbackFlow> get serializer =>
      _$alertFeedbackFlowSerializer;
}