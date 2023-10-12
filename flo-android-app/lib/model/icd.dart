library icd;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'icd.g.dart';

abstract class Icd implements Built<Icd, IcdBuilder> {
  Icd._();

  factory Icd([updates(IcdBuilder b)]) = _$Icd;

  @nullable
  @BuiltValueField(wireName: 'device_id')
  String get deviceId;
  @nullable
  @BuiltValueField(wireName: 'time_zone')
  String get timeZone;
  @nullable
  @BuiltValueField(wireName: 'icd_id')
  String get icdId;
  @nullable
  @BuiltValueField(wireName: 'system_mode')
  int get systemMode;
  String toJson() {
    return json.encode(serializers.serializeWith(Icd.serializer, this));
  }

  static Icd fromJson(String jsonString) {
    return serializers.deserializeWith(Icd.serializer, json.decode(jsonString));
  }

  static Serializer<Icd> get serializer => _$icdSerializer;
}