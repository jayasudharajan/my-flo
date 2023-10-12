library alert_feedback_flow_tags;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'alert_feedback_step.dart';

part 'alert_feedback_flow_tags.g.dart';

abstract class AlertFeedbackFlowTags implements Built<AlertFeedbackFlowTags, AlertFeedbackFlowTagsBuilder> {
  AlertFeedbackFlowTags._();

  factory AlertFeedbackFlowTags([updates(AlertFeedbackFlowTagsBuilder b)]) = _$AlertFeedbackFlowTags;

  @nullable
  @BuiltValueField(wireName: 'sleep_flow')
  AlertFeedbackStep get sleepFlow;
  String toJson() {
    return json.encode(serializers.serializeWith(AlertFeedbackFlowTags.serializer, this));
  }

  static AlertFeedbackFlowTags fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedbackFlowTags.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedbackFlowTags> get serializer => _$alertFeedbackFlowTagsSerializer;
}