library health_test;

import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

part 'health_test.g.dart';

abstract class HealthTest implements Built<HealthTest, HealthTestBuilder> {
  HealthTest._();

  factory HealthTest([updates(HealthTestBuilder b)]) = _$HealthTest;

  @nullable
  @BuiltValueField(wireName: 'roundId')
  String get roundId;
  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;
  @nullable
  @BuiltValueField(wireName: 'type')
  String get type;
  @nullable
  @BuiltValueField(wireName: 'leakType')
  int get leakType;
  @nullable
  @BuiltValueField(wireName: 'leakLossMinGal')
  double get leakLossMinGal;
  @nullable
  @BuiltValueField(wireName: 'leakLossMaxGal')
  double get leakLossMaxGal;
  @nullable
  @BuiltValueField(wireName: 'startPressure')
  double get startPressure;
  @nullable
  @BuiltValueField(wireName: 'endPressure')
  double get endPressure;
  //@nullable
  //@BuiltValueField(wireName: 'startRawPayload')
  //BuiltMap<String, Object> get startRawPayload;
  //@nullable
  //@BuiltValueField(wireName: 'endRawPayload')
  //BuiltMap<String, Object> get endRawPayload;
  @nullable
  @BuiltValueField(wireName: 'created')
  String get created;
  @nullable
  @BuiltValueField(wireName: 'updated')
  String get updated;
  @nullable
  @BuiltValueField(wireName: 'startDate')
  String get startDate;
  @nullable
  @BuiltValueField(wireName: 'endDate')
  String get endDate;

  String toJson() {
    return json.encode(serializers.serializeWith(HealthTest.serializer, this));
  }

  static HealthTest fromJson(String jsonString) {
    return serializers.deserializeWith(
        HealthTest.serializer, json.decode(jsonString));
  }

  static Serializer<HealthTest> get serializer => _$healthTestSerializer;

  static const String PENDING = "pending";
  static const String RUNNING = "running";
  static const String COMPLETED = "completed";
  static const String CANCELLED = "cancelled";
  static const String CANCELED = "canceled";
  static const String TIMEOUT = "timeout";

  ///
  /// 1: Leak Cat1
  /// 2: Leak Cat2
  /// 3: Leak Cat3
  /// 4: Leak Cat4
  /// 0: reserved (equivalent to -5 or -6 up in previous firmware versions)
  ///    leak_type = 0 → General interruption (backwards compatibility: water interruption or thermal expansion)
  ///
  /// -1: Test successful
  /// -2: reserved (equivalent to -3 or -4 up in previous firmware versions)
  /// -3: Test canceled by opening the valve via directive (ie. APP canceled)
  /// -4: Test canceled by opening the valve manually
  /// -5: Test interrupted by water use
  /// -6: Test interrupted due to thermal expansion
  /// ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/772177924/Health+Test
  static const int LEAK_CAT4 = 4;
  static const int LEAK_CAT3 = 3;
  static const int LEAK_CAT2 = 2;
  static const int LEAK_CAT1 = 1;
  static const int LEAK_INTERRUPT = 0; // bitwise would be smarter
  static const int LEAK_SUCCESSFUL = -1; // bitwise would be smarter
  static const int LEAK_CANCELLED = -2; // bitwise would be smarter
  static const int LEAK_CANCELED_BY_APP_OPEN = -3; // bitwise would be smarter
  static const int LEAK_CANCELED_BY_MANUAL_OPEN = -4; // bitwise would be smarter
  static const int LEAK_INTERRUPT_BY_WATER_USE = -5; // bitwise would be smarter
  static const int LEAK_INTERRUPT_BY_THERMAL_EXPANSION = -6; // bitwise would be smarter
  static Set<int> LEAK_TYPES = [
    LEAK_CAT4,
    LEAK_CAT3,
    LEAK_CAT2,
    LEAK_CAT1,
    LEAK_INTERRUPT,
    LEAK_SUCCESSFUL,
    LEAK_CANCELLED,
    LEAK_CANCELED_BY_APP_OPEN,
    LEAK_CANCELED_BY_MANUAL_OPEN,
    LEAK_INTERRUPT_BY_WATER_USE,
    LEAK_INTERRUPT_BY_THERMAL_EXPANSION,
  ].toSet();

  @deprecated
  bool get running => ((status ?? COMPLETED) == PENDING) || ((status ?? COMPLETED) == RUNNING);
  bool get isRunning => running;
  bool get isNotRunning => !isRunning;
  bool get isCanceled => ((status ?? COMPLETED) == CANCELED) || ((status ?? COMPLETED) == CANCELLED);
  bool get isNotCanceled => !isCanceled;

  DateTime get startDateTime => DateTimes.of(startDate, isUtc: true);
  DateTime get endDateTime => DateTimes.of(endDate, isUtc: true);

  bool get isValid => roundId != null && status != null && startDate != null;

  Duration get duration => endDateTime.difference(startDateTime);

  double get lossPressure {
    final _startPressure = startPressure ?? 0;
    final _endPressure = endPressure ?? 0;
    return (startPressure != null && endPressure != null) ? _startPressure - _endPressure : null;
  }

  double get lossPressureRatio => lossPressure != null ? lossPressure / max(startPressure, 1) : null;
}
