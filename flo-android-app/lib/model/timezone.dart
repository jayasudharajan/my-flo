library timezone;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'timezone.g.dart';

abstract class TimeZone
    implements Built<TimeZone, TimeZoneBuilder> {
  TimeZone._();

  factory TimeZone([updates(TimeZoneBuilder b)]) = _$TimeZone;

  @BuiltValueField(wireName: 'tz')
  String get tz;
  @nullable
  @BuiltValueField(wireName: 'display')
  String get display;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(TimeZone.serializer, this));
  }

  static TimeZone fromJson(String jsonString) {
    return serializers.deserializeWith(
        TimeZone.serializer, json.decode(jsonString));
  }

  static Serializer<TimeZone> get serializer => _$timeZoneSerializer;
  static TimeZone get empty => TimeZone((b) => b
  ..tz = ""
  );

  static const String UTC = "UTC";
}
