library hardware_thresholds;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'threshold.dart';
import 'unit_system.dart';

part 'hardware_thresholds.g.dart';

abstract class HardwareThresholds
    implements Built<HardwareThresholds, HardwareThresholdsBuilder> {
  HardwareThresholds._();

  factory HardwareThresholds([updates(HardwareThresholdsBuilder b)]) =
      _$HardwareThresholds;

  @nullable
  @BuiltValueField(wireName: 'gpm')
  Threshold get gpm;
  @nullable
  @BuiltValueField(wireName: 'psi')
  Threshold get psi;
  @nullable
  @BuiltValueField(wireName: 'lpm')
  Threshold get lpm;
  @nullable
  @BuiltValueField(wireName: 'kPa')
  Threshold get kPa;
  @nullable
  @BuiltValueField(wireName: 'tempC')
  Threshold get celsius;
  @nullable
  @BuiltValueField(wireName: 'tempF')
  Threshold get fahrenheit;
  String toJson() {
    return json
        .encode(serializers.serializeWith(HardwareThresholds.serializer, this));
  }

  static HardwareThresholds fromJson(String jsonString) {
    return serializers.deserializeWith(
        HardwareThresholds.serializer, json.decode(jsonString));
  }

  static Serializer<HardwareThresholds> get serializer =>
      _$hardwareThresholdsSerializer;

  Threshold temperatureThreshold(UnitSystem unit) => unit == UnitSystem.imperialUs ? fahrenheit : celsius;
  int maxTemperature(UnitSystem unit) => temperatureThreshold(unit)?.maxValue ?? 100;
  int minTemperature(UnitSystem unit) => temperatureThreshold(unit)?.minValue ?? 0;
  Threshold pressureThreshold(UnitSystem unit) => unit == UnitSystem.imperialUs ? psi : kPa;
  int maxPressure(UnitSystem unit) => pressureThreshold(unit)?.maxValue ?? 100;
  int minPressure(UnitSystem unit) => pressureThreshold(unit)?.minValue ?? 0;
  Threshold flowThreshold(UnitSystem unit) => unit == UnitSystem.imperialUs ? gpm : lpm;
  int maxFlow(UnitSystem unit) => flowThreshold(unit)?.maxValue ?? 100;
  int minFlow(UnitSystem unit) => flowThreshold(unit)?.minValue ?? 0;
}