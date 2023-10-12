library health_tests;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'health_test.dart';
import 'serializers.dart';

part 'health_tests.g.dart';

abstract class HealthTests implements Built<HealthTests, HealthTestsBuilder> {
  HealthTests._();

  factory HealthTests([updates(HealthTestsBuilder b)]) = _$HealthTests;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<HealthTest> get items;
  String toJson() {
    return json.encode(serializers.serializeWith(HealthTests.serializer, this));
  }

  static HealthTests fromJson(String jsonString) {
    return serializers.deserializeWith(
        HealthTests.serializer, json.decode(jsonString));
  }

  static Serializer<HealthTests> get serializer => _$healthTestsSerializer;
}
