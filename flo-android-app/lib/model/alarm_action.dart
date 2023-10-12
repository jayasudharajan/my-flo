library alarm_action;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alarm_action.g.dart';

abstract class AlarmAction implements Built<AlarmAction, AlarmActionBuilder> {
  AlarmAction._();

  factory AlarmAction([updates(AlarmActionBuilder b)]) = _$AlarmAction;

  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  @nullable
  @BuiltValueField(wireName: 'text')
  String get text;
  @nullable
  @BuiltValueField(wireName: 'displayOnStatus')
  int get displayOnStatus;
  @nullable
  @BuiltValueField(wireName: 'sort')
  int get sort;
  @nullable
  @BuiltValueField(wireName: 'snoozeSeconds')
  int get snoozeSeconds;

  String toJson() {
    return json.encode(serializers.serializeWith(AlarmAction.serializer, this));
  }

  static AlarmAction fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlarmAction.serializer, json.decode(jsonString));
  }

  static Serializer<AlarmAction> get serializer => _$alarmActionSerializer;
}
