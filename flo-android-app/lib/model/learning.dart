library learning;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'learning.g.dart';

abstract class Learning implements Built<Learning, LearningBuilder> {
  Learning._();

  factory Learning([updates(LearningBuilder b)]) = _$Learning;

  @nullable
  @BuiltValueField(wireName: 'outOfLearningDate')
  String get outOfLearningDate;
  String toJson() {
    return json.encode(serializers.serializeWith(Learning.serializer, this));
  }

  static Learning fromJson(String jsonString) {
    return serializers.deserializeWith(
        Learning.serializer, json.decode(jsonString));
  }

  static Serializer<Learning> get serializer => _$learningSerializer;
}