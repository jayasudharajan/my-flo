library telemetry;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'package:faker/faker.dart';
part 'telemetry.g.dart';


@deprecated
abstract class Telemetry implements Built<Telemetry, TelemetryBuilder> {
  Telemetry._();

  factory Telemetry([updates(TelemetryBuilder b)]) = _$Telemetry;

  @BuiltValueField(wireName: 'did')
  String get deviceId;
  @BuiltValueField(wireName: 'wf')
  double get waterFlow;
  @BuiltValueField(wireName: 'f')
  double get flow;
  @BuiltValueField(wireName: 't')
  double get temperature;
  @BuiltValueField(wireName: 'p')
  double get pressure;
  @BuiltValueField(wireName: 'ts')
  int get timestamp;
  @BuiltValueField(wireName: 'sm')
  int get systemMode;
  @BuiltValueField(wireName: 'sw1')
  int get switch1;
  @BuiltValueField(wireName: 'sw2')
  int get switch2;
  @BuiltValueField(wireName: 'v')
  int get valve;
  @BuiltValueField(wireName: 'freq')
  double get wifiFrequency;
  @BuiltValueField(wireName: 'rssi')
  double get rssi;
  @BuiltValueField(wireName: 'mbps')
  double get mbps;
  String toJson() {
    return json.encode(serializers.serializeWith(Telemetry.serializer, this));
  }

  static Telemetry fromJson(String jsonString) {
    return serializers.deserializeWith(
        Telemetry.serializer, json.decode(jsonString));
  }

  static Serializer<Telemetry> get serializer => _$telemetrySerializer;

  // TODO faker
  static Telemetry get random {
    return Telemetry((b) => b
    ..deviceId = "fffffffff"
    ..waterFlow = faker.randomGenerator.decimal(scale: 16.0)
    ..flow = faker.randomGenerator.decimal(scale: 16.0)
    ..temperature = faker.randomGenerator.decimal(scale: 100.0)
    ..pressure = faker.randomGenerator.decimal(scale: 100.0)
    ..timestamp = DateTime.now().millisecondsSinceEpoch * 1000
    ..systemMode = faker.randomGenerator.integer(2)
    ..switch1 = 1
    ..switch2 = 0
    ..valve = 1
    ..wifiFrequency = 2447
    ..rssi = -37
    ..mbps = 144
    );
  }
}