library alarms;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:superpower/superpower.dart';
import 'serializers.dart';

import 'alarm.dart';

part 'alarms.g.dart';

abstract class Alarms implements Built<Alarms, AlarmsBuilder> {
  Alarms._();

  factory Alarms([updates(AlarmsBuilder b)]) = _$Alarms;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<Alarm> get items;

  List<Alarm> get criticals => items
      .where((it) => it.parent == null)
      .where((it) => it.severity == Alarm.CRITICAL)
      //.sortedBy((it) => it.displayName);
      .toList()
      ..sort((a, b) => a.displayName?.compareTo(b?.displayName) ?? 0);
  List<Alarm> get warnings => $(items)
      .where((it) => it.parent == null)
      .where((it) => it.severity == Alarm.WARNING)
      //.sortedBy((it) => it.displayName);
      .toList()
      ..sort((a, b) => a.displayName?.compareTo(b?.displayName) ?? 0);
  List<Alarm> get infos => $(items)
      .where((it) => it.parent == null)
      .where((it) => it.severity == Alarm.INFO)
      //.sortedBy((it) => it.displayName);
      .toList()
      ..sort((a, b) => a.displayName?.compareTo(b?.displayName) ?? 0);

  List<Alarm> get displays => $(items)
      .where((it) => it.parent == null)
      .where((it) => !it.isShutoff ?? false)
      .where((it) => !it.isInternal ?? false)
      .where((it) => it.active ?? false)
      .toList();

  List<Alarm> get criticalsDisplay => criticals
      .where((it) => it.deliveryMedium.userConfigurable ?? false)
      .where((it) => !it.isShutoff ?? false)
      .where((it) => !it.isInternal ?? false)
      .where((it) => it.active ?? false)
      .toList();
  List<Alarm> get warningsDisplay => warnings
      .where((it) => it.deliveryMedium.userConfigurable ?? false)
      .where((it) => !it.isShutoff ?? false)
      .where((it) => !it.isInternal ?? false)
      .where((it) => it.active ?? false)
      .toList();
  List<Alarm> get infosDisplay => infos
      .where((it) => it.deliveryMedium.userConfigurable ?? false)
      .where((it) => !it.isShutoff ?? false)
      .where((it) => !it.isInternal ?? false)
      .where((it) => it.active ?? false)
      .toList();

  String toJson() {
    return json.encode(serializers.serializeWith(Alarms.serializer, this));
  }

  static Alarms fromJson(String jsonString) {
    return serializers.deserializeWith(
        Alarms.serializer, json.decode(jsonString));
  }

  static Serializer<Alarms> get serializer => _$alarmsSerializer;
  static Alarms empty = Alarms((b) => b..items = ListBuilder(<Alarm>[]));
}