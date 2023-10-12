library telemetry2;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:faker/faker.dart';
import 'serializers.dart';

part 'telemetry2.g.dart';

abstract class Telemetry2 implements Built<Telemetry2, Telemetry2Builder> {
  Telemetry2._();

  factory Telemetry2([updates(Telemetry2Builder b)]) = _$Telemetry2;

  //@deprecated
  //@nullable
  //@BuiltValueField(wireName: 'gpm')
  //double get gpm;
  //@deprecated
  //@nullable
  //@BuiltValueField(wireName: 'psi')
  //double get psi;
  @nullable
  @BuiltValueField(wireName: 'gpm')
  double get flow;
  @nullable
  @BuiltValueField(wireName: 'psi')
  double get pressure;

  double get temperature => fahrenheit;

  @nullable
  @BuiltValueField(wireName: 'tempF')
  double get fahrenheit;
  @nullable
  @BuiltValueField(wireName: 'updated', serialize: false)
  String get updated;
  String toJson() {
    return json.encode(serializers.serializeWith(Telemetry2.serializer, this));
  }

  static Telemetry2 fromJson(String jsonString) {
    return serializers.deserializeWith(
        Telemetry2.serializer, json.decode(jsonString));
  }

  static Serializer<Telemetry2> get serializer => _$telemetry2Serializer;
  static Telemetry2 get empty => Telemetry2((b) => b
    ..pressure = 0
    ..fahrenheit = 0
    ..flow = 0
  );

  static Telemetry2 get random {
    return Telemetry2((b) => b
      //..flow = faker.randomGenerator.decimal(scale: 16.0)
      ..flow = 0 // For testing health test
      ..fahrenheit = faker.randomGenerator.decimal(scale: 100.0)
      ..pressure = faker.randomGenerator.decimal(scale: 100.0)
    );
  }
}

