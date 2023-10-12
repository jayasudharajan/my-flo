library alert_feedback_option;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils.dart';
import 'alert_feedback.dart';
import 'serializers.dart';

import 'alert_feedback_step.dart';

part 'alert_feedback_option.g.dart';

abstract class AlertFeedbackOption
    implements Built<AlertFeedbackOption, AlertFeedbackOptionBuilder> {
  AlertFeedbackOption._();

  factory AlertFeedbackOption([updates(AlertFeedbackOptionBuilder b)]) =
  _$AlertFeedbackOption;

  @nullable
  @BuiltValueField(wireName: 'property')
  String get property;
  @nullable
  @BuiltValueField(wireName: 'displayText')
  String get displayText;
  @nullable
  @BuiltValueField(wireName: 'sortOrder')
  int get sortOrder;
  @nullable
  @nullable
  @BuiltValueField(wireName: 'action')
  String get action;
  @nullable
  @BuiltValueField(wireName: 'value')
  Object get value;
  ///"flow": {
  ///"tag": "sleep_flow"
  ///}
  @nullable
  @BuiltValueField(wireName: 'flow')
  AlertFeedbackStep get flow;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertFeedbackOption.serializer, this));
  }

  static AlertFeedbackOption fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFeedbackOption.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFeedbackOption> get serializer =>
      _$alertFeedbackOptionSerializer;

  AlertFeedbackOption get payload => AlertFeedbackOption((b) => b
    ..property = property
    ..value = value
  );

  //sleepDuration
  bool get hasAction => property == AlertFeedback.ACTION_TOKEN || property == AlertFeedback.ACTION_TOKEN_;
  bool get hasSleepDuration => hasAction && AlertFeedback.SLEEP_ACTIONS.contains(value);
  // default Duration.zero or null
  Duration get sleepDuration => hasSleepDuration ? Duration(hours: value == AlertFeedback.SLEEP_24H ? 24 : value == AlertFeedback.SLEEP_2H ? 2 : 0) : Duration.zero;

  AlertFeedbackOption toFeedback() =>
    AlertFeedbackOption((b) => b
      ..property = property
      ..value = value
    );

  @deprecated
  AlertFeedback get feedback {
    final alertFeedbackBuilder = AlertFeedback().toBuilder();
    try {
      if (property == AlertFeedback.CAUSE) {
        alertFeedbackBuilder.cause = Ints.parse(value);
      }
      else if (property == AlertFeedback.SHOULD_ACCEPT_AS_NORMAL) {
        alertFeedbackBuilder.shouldAcceptAsNormal = Bools.parse(value);
      }
      else if (property == AlertFeedback.PLUMBING_FAILURE) {
        alertFeedbackBuilder.plumbingFailure = Ints.parse(value);
      }
      else if (property == AlertFeedback.FIXTURE) {
          alertFeedbackBuilder.fixture = value?.toString();
      }
      else if (property == AlertFeedback.CAUSE_OTHER) {
        alertFeedbackBuilder.cause = Ints.parse(value);
      }
      else if (property == AlertFeedback.PLUMBING_FAILURE_OTHER) {
        alertFeedbackBuilder.plumbingFailureOther = Ints.parse(value);
      }
      else if (property == AlertFeedback.ACTION_TOKEN || property == AlertFeedback.ACTION_TOKEN_) {
        alertFeedbackBuilder.actionTaken = value?.toString();
      }
    } catch (err) {
      Fimber.e("${this}", ex: err);
    }
    return alertFeedbackBuilder.build();
  }
}
