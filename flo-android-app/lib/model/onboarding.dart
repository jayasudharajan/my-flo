library onboarding;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'name.dart';
import 'serializers.dart';

part 'onboarding.g.dart';

abstract class Onboarding implements Built<Onboarding, OnboardingBuilder> {
  Onboarding._();

  factory Onboarding([updates(OnboardingBuilder b)]) = _$Onboarding;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'device_id')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'event')
  Name get event;
  String toJson() {
    return json.encode(serializers.serializeWith(Onboarding.serializer, this));
  }

  static Onboarding fromJson(String jsonString) {
    return serializers.deserializeWith(
        Onboarding.serializer, json.decode(jsonString));
  }

  static Serializer<Onboarding> get serializer => _$onboardingSerializer;
}