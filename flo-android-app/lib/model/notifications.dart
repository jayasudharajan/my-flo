library notifications;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:superpower/superpower.dart';
import '../utils.dart';
import 'alarm.dart';
import 'serializers.dart';

part 'notifications.g.dart';

/**
 * criticalCount	number
 * warningCount	number
 * infoCount	number
 */
abstract class Notifications implements Built<Notifications, NotificationsBuilder> {
  Notifications._();

  factory Notifications([updates(NotificationsBuilder b)]) = _$Notifications;


  /// DateTime
  @nullable
  @BuiltValueField(wireName: 'fsUpdate')
  String get fsUpdate;

  DateTime get fsUpdateDateTime => DateTimes.of(fsUpdate);

  @nullable
  @BuiltValueField(wireName: 'criticalCount')
  int get criticalCountFlatten;
  @nullable
  @BuiltValueField(wireName: 'warningCount')
  int get warningCountFlatten;
  @nullable
  @BuiltValueField(wireName: 'infoCount')
  int get infoCountFlatten;

  @nullable
  @BuiltValueField(wireName: 'alarmCount')
  BuiltList<Alarm> get alarmCounts;

  int get criticalCount => countOf(Alarm.CRITICAL);
  int get warningCount => countOf(Alarm.WARNING);
  int get infoCount => countOf(Alarm.INFO);

  int totalOf(String severity) => (alarmCounts?.isNotEmpty ?? false) ? or(() => alarmCounts
      ?.where((alarm) => alarm.severity == severity)
      ?.map((alarm) => alarm.count ?? 0)
      ?.reduce((that, it) => that + it)) : 0;

  int countOf(String severity) => (alarmCounts?.isNotEmpty ?? false) ? or(() => $(alarmCounts)
      ?.where((alarm) => alarm.severity == severity)
      // Comment for merging devices
      //?.distinctBy((alarm) => alarm.id)
      ?.count() ?? 0) ?? 0 : 0;

  bool get hasSeverity => or(() => alarmCounts?.any((alarm) => alarm.severity == null)) ?? false;

  String toJson() {
    return json.encode(serializers.serializeWith(Notifications.serializer, this));
  }

  static Notifications fromJson(String jsonString) {
    return serializers.deserializeWith(
        Notifications.serializer, json.decode(jsonString));
  }

  static Serializer<Notifications> get serializer => _$notificationsSerializer;

  static Notifications get empty => Notifications((b) => b
  ..criticalCountFlatten = 0
  ..warningCountFlatten = 0
  ..infoCountFlatten = 0
  );

  Notifications operator +(Notifications it) => rebuild((b) => b
    ..alarmCounts = ListBuilder<Alarm>(<Alarm>[
      ...(alarmCounts ?? <Alarm>[]),
      ...(it.alarmCounts ?? <Alarm>[])
    ])
    ..criticalCountFlatten = orEmpty<int>(criticalCountFlatten) + orEmpty<int>(it.criticalCountFlatten)
    ..warningCountFlatten = orEmpty<int>(warningCountFlatten) + orEmpty<int>(it.warningCountFlatten)
    ..infoCountFlatten = orEmpty<int>(infoCountFlatten) + orEmpty<int>(it.infoCountFlatten)
  );

}