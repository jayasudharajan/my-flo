library alert_statistics;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'notifications.dart';
import 'serializers.dart';

part 'alert_statistics.g.dart';

abstract class AlertStatistics
    implements Built<AlertStatistics, AlertStatisticsBuilder> {
  AlertStatistics._();

  factory AlertStatistics([updates(AlertStatisticsBuilder b)]) =
  _$AlertStatistics;

  @nullable
  @BuiltValueField(wireName: 'pending')
  Notifications get pending;
  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertStatistics.serializer, this));
  }

  static AlertStatistics fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertStatistics.serializer, json.decode(jsonString));
  }

  static Serializer<AlertStatistics> get serializer =>
      _$alertStatisticsSerializer;
}