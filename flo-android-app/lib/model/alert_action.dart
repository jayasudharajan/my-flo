library alert_action;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alert_action.g.dart';

abstract class AlertAction implements Built<AlertAction, AlertActionBuilder> {
  AlertAction._();

  factory AlertAction([updates(AlertActionBuilder b)]) = _$AlertAction;

  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'alarmIds')
  BuiltList<int> get alarmIds;
  @nullable
  @BuiltValueField(wireName: 'snoozeSeconds')
  int get snoozeSeconds;

  String toJson() {
    return json.encode(serializers.serializeWith(AlertAction.serializer, this));
  }

  static AlertAction fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertAction.serializer, json.decode(jsonString));
  }

  static Serializer<AlertAction> get serializer => _$alertActionSerializer;
}
