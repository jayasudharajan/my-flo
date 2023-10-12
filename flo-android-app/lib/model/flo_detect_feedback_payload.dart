library flo_detect_feedback_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'flo_detect_feedback.dart';
import 'serializers.dart';

part 'flo_detect_feedback_payload.g.dart';

abstract class FloDetectFeedbackPayload
    implements Built<FloDetectFeedbackPayload, FloDetectFeedbackPayloadBuilder> {
  FloDetectFeedbackPayload._();

  factory FloDetectFeedbackPayload([updates(FloDetectFeedbackPayloadBuilder b)]) =
  _$FloDetectFeedbackPayload;

  @nullable
  @BuiltValueField(wireName: 'feedback')
  FloDetectFeedback get feedback;
  String toJson() {
    return json
        .encode(serializers.serializeWith(FloDetectFeedbackPayload.serializer, this));
  }

  static FloDetectFeedbackPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        FloDetectFeedbackPayload.serializer, json.decode(jsonString));
  }

  static Serializer<FloDetectFeedbackPayload> get serializer =>
      _$floDetectFeedbackPayloadSerializer;
}

