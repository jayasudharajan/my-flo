library locale;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'region.dart';
import 'timezone.dart';

part 'locale.g.dart';

abstract class Locale
    implements Built<Locale, LocaleBuilder> {
  Locale._();

  factory Locale([updates(LocaleBuilder b)]) = _$Locale;

  @BuiltValueField(wireName: 'name')
  String get name;
  @BuiltValueField(wireName: 'locale')
  String get locale;
  @nullable
  @BuiltValueField(wireName: 'regions')
  BuiltList<Region> get regions;
  @nullable
  @BuiltValueField(wireName: 'timezones')
  BuiltList<TimeZone> get timezones;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(Locale.serializer, this));
  }

  static Locale fromJson(String jsonString) {
    return serializers.deserializeWith(
        Locale.serializer, json.decode(jsonString));
  }

  static Serializer<Locale> get serializer => _$localeSerializer;
}
