library flo_detect;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'device.dart';
import 'fixture.dart';
import 'serializers.dart';
import 'package:intl/intl.dart';

part 'flo_detect.g.dart';

abstract class FloDetect implements Built<FloDetect, FloDetectBuilder> {
  FloDetect._();

  factory FloDetect([updates(FloDetectBuilder b)]) = _$FloDetect;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;
  @nullable
  Device get device;
  @nullable
  @BuiltValueField(wireName: 'startDate')
  String get startDate;
  @nullable
  @BuiltValueField(wireName: 'endDate')
  String get endDate;
  @nullable
  @BuiltValueField(wireName: 'isStale')
  bool get isStale;
  @nullable
  @BuiltValueField(wireName: 'fixtures')
  BuiltList<Fixture> get fixtures;
  @nullable
  @BuiltValueField(wireName: 'computeStartDate')
  String get computeStartDate;
  @nullable
  @BuiltValueField(wireName: 'computeEndDate')
  String get computeEndDate;
  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;

  double get gallons => (fixtures?.isNotEmpty ?? false) ? fixtures.map((it) => it.gallons).reduce((that, it) => that + it) : 0;

  DateTime get computeStartDateTime => DateTimes.of(computeStartDate, isUtc: true);
  DateTime get computeEndDateTime => DateTimes.of(computeEndDate, isUtc: true);
  String get computeEndDateTimeFormatted => DateFormat.MMMd().add_jm().format(computeEndDateTime);

  String toJson() {
    return json.encode(serializers.serializeWith(FloDetect.serializer, this));
  }

  static FloDetect fromJson(String jsonString) {
    return serializers.deserializeWith(
        FloDetect.serializer, json.decode(jsonString));
  }

  static Serializer<FloDetect> get serializer => _$floDetectSerializer;

  static const String DURATION_24H = "24h";
  static const String DURATION_7D = "7d";
  static const Set<String> DURATIONS = const {DURATION_24H, DURATION_7D};
  static const String LEARNING = "learning";
  static const String EXECUTED = "executed";
  static const Set<String> STATUSES = const {LEARNING, EXECUTED};

  FloDetect operator+(FloDetect it) {
    final fixtureList = Maps.reduce<int, Fixture>(Maps.fromIterable2<int, Fixture>(fixtures, key: (item) => item.type),
        Maps.fromIterable2<int, Fixture>(it.fixtures, key: (item) => item.type),
        reduce: (that, it) => that + it
    ).values;

    final gallons = (fixtureList?.isNotEmpty ?? false) ? fixtureList.map((it) => it.gallons).reduce((that, it) => that + it) : 0;

    return rebuild((b) => b
      ..status = [status, it.status].contains(EXECUTED) ? EXECUTED : [status, it.status].firstWhere((that) => that != null, orElse: null)
      ..fixtures = ListBuilder(fixtureList.map((fixture) => fixture.rebuild((b) => b
        ..ratio = gallons != 0 ? (b.gallons / gallons) : b.gallons
      ))));
  }

  //bool get isLearning => status == LEARNING;
  bool get isLearning => status != null ? status == LEARNING : false;
}