library alert_feedbacks;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'alert_feedback.dart';
import 'alert_feedback_option.dart';
import 'serializers.dart';

part 'alert_feedbacks.g.dart';

abstract class AlertFeedbacks
    implements Built<AlertFeedbacks, AlertFeedbacksBuilder> {
  AlertFeedbacks._();

  factory AlertFeedbacks([updates(AlertFeedbacksBuilder b)]) = _$AlertFeedbacks;

  @nullable
  @BuiltValueField(wireName: 'userId')
  String get userId;
  @nullable
  @deprecated
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'createdAt')
  String get createdAt;
  @nullable
  @BuiltValueField(wireName: 'feedback')
  BuiltList<AlertFeedbackOption> get feedbacks;

  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertFeedbacks.serializer, this));
  }

  static AlertFeedbacks fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedbacks.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedbacks> get serializer => _$alertFeedbacksSerializer;
}
