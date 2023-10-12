library flo_detect_feedback;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'flo_detect_feedback.g.dart';

abstract class FloDetectFeedback
    implements Built<FloDetectFeedback, FloDetectFeedbackBuilder> {
  FloDetectFeedback._();

  factory FloDetectFeedback([updates(FloDetectFeedbackBuilder b)]) =
  _$FloDetectFeedback;

  @nullable
  @BuiltValueField(wireName: 'case')
  int get cases;
  @nullable
  @BuiltValueField(wireName: 'correctFixture')
  String get correctFixture;
  String toJson() {
    return json
        .encode(serializers.serializeWith(FloDetectFeedback.serializer, this));
  }

  static FloDetectFeedback fromJson(String jsonString) {
    return serializers.deserializeWith(
        FloDetectFeedback.serializer, json.decode(jsonString));
  }

  static Serializer<FloDetectFeedback> get serializer =>
      _$floDetectFeedbackSerializer;

  static const int CONFIRM = 0;
  static const int WRONG = 1;
  static const int INFORM = 2;

  static const Set<int> CASES = {
    CONFIRM,
    WRONG,
    INFORM,
  };
}
