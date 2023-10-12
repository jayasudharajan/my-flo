library alert_feedback;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alert_feedback.g.dart';

abstract class AlertFeedback
    implements Built<AlertFeedback, AlertFeedbackBuilder> {
  AlertFeedback._();

  factory AlertFeedback([updates(AlertFeedbackBuilder b)]) = _$AlertFeedback;

  @nullable
  @BuiltValueField(wireName: 'cause')
  int get cause;
  @nullable
  @BuiltValueField(wireName: 'shouldAcceptAsNormal')
  bool get shouldAcceptAsNormal;
  @nullable
  @BuiltValueField(wireName: 'plumbingFailure')
  int get plumbingFailure;
  @nullable
  @BuiltValueField(wireName: 'fixture')
  String get fixture;
  @nullable
  @BuiltValueField(wireName: 'causeOther')
  int get causeOther;
  @nullable
  @BuiltValueField(wireName: 'plumbingFailureOther')
  int get plumbingFailureOther;
  /// sleep_24h
  /// sleep_2h
  /// none
  @nullable
  @BuiltValueField(wireName: 'action_taken')
  String get actionTaken;

  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertFeedback.serializer, this));
  }

  static AlertFeedback fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedback.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedback> get serializer => _$alertFeedbackSerializer;

  static const String CAUSE                   = "cause";
  static const String SHOULD_ACCEPT_AS_NORMAL = "should_accept_as_normal";
  static const String PLUMBING_FAILURE        = "plumbing_failure";
  static const String FIXTURE                 = "fixture";
  static const String CAUSE_OTHER             = "cause_other";
  static const String PLUMBING_FAILURE_OTHER  = "plumbing_failure_other";
  static const String ACTION_TOKEN            = "actionTaken";
  static const String ACTION_TOKEN_            = "action_taken";

  static const String SLEEP_24H  = "sleep_24h";
  static const String SLEEP_2H  = "sleep_2h";
  static const String NONE  = "none";

  static const ACTIONS = {SLEEP_24H, SLEEP_2H, NONE};
  static const SLEEP_ACTIONS = {SLEEP_24H, SLEEP_2H};
}
