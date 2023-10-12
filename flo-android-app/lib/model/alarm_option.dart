library alarm_option;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alarm_option.g.dart';

abstract class AlarmOption
    implements Built<AlarmOption, AlarmOptionBuilder> {
  AlarmOption._();

  factory AlarmOption([updates(AlarmOptionBuilder b)]) = _$AlarmOption;

  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  @nullable
  @BuiltValueField(wireName: 'text')
  String get text;
  @nullable
  @BuiltValueField(wireName: 'alarmId')
  int get alarmId;
  @nullable
  @BuiltValueField(wireName: 'actionPath')
  String get actionPath;
  @nullable
  @BuiltValueField(wireName: 'actionType')
  int get actionType;
  @nullable
  @BuiltValueField(wireName: 'sort')
  int get sort;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlarmOption.serializer, this));
  }

  static AlarmOption fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlarmOption.serializer, json.decode(jsonString));
  }

  static Serializer<AlarmOption> get serializer =>
      _$alarmOptionSerializer;
}