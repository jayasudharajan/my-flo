library alerts;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'alert.dart';
import 'serializers.dart';

part 'alerts.g.dart';

abstract class Alerts implements Built<Alerts, AlertsBuilder> {
  Alerts._();

  factory Alerts([updates(AlertsBuilder b)]) = _$Alerts;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<Alert> get items;
  @nullable
  @BuiltValueField(wireName: 'page')
  int get page;
  @nullable
  @BuiltValueField(wireName: 'total')
  int get total;
  String toJson() {
    return json.encode(serializers.serializeWith(Alerts.serializer, this));
  }

  static Alerts fromJson(String jsonString) {
    return serializers.deserializeWith(
        Alerts.serializer, json.decode(jsonString));
  }

  static Serializer<Alerts> get serializer => _$alertsSerializer;
}