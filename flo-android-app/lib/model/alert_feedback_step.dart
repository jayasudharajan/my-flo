library alert_feedback_step;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'alert_feedback_option.dart';

part 'alert_feedback_step.g.dart';

abstract class AlertFeedbackStep implements Built<AlertFeedbackStep, AlertFeedbackStepBuilder> {
  AlertFeedbackStep._();

  factory AlertFeedbackStep([updates(AlertFeedbackStepBuilder b)]) = _$AlertFeedbackStep;

  @nullable
  @BuiltValueField(wireName: 'titleText')
  String get titleText;
  @nullable
  @BuiltValueField(wireName: 'type')
  String get type;
  @nullable
  @BuiltValueField(wireName: 'options')
  BuiltList<AlertFeedbackOption> get options;
  @nullable
  @BuiltValueField(wireName: 'tag')
  String get tag;
  String toJson() {
    return json.encode(serializers.serializeWith(AlertFeedbackStep.serializer, this));
  }

  static AlertFeedbackStep fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedbackStep.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedbackStep> get serializer => _$alertFeedbackStepSerializer;
  static const String LIST = "list";
  static const String TEXT = "text";

  static const String SLEEP_FLOW  = "sleep_flow";

}