library target;

import 'dart:convert';

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'target.g.dart';

abstract class Target implements Built<Target, TargetBuilder> {
  Target._();

  factory Target([updates(TargetBuilder b)]) = _$Target;

  @BuiltValueField(wireName: 'target')
  String get target;
  String toJson() {
    return json.encode(serializers.serializeWith(Target.serializer, this));
  }

  static Target fromJson(String jsonString) {
    return serializers.deserializeWith(
        Target.serializer, json.decode(jsonString));
  }

  static Serializer<Target> get serializer => _$targetSerializer;

  //static const Target power = const Target((b) => b
  static Target power = Target((b) => b
    ..target = "power"
  );
}