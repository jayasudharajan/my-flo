library locales;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'locale.dart';

part 'locales.g.dart';

abstract class Locales
    implements Built<Locales, LocalesBuilder> {
  Locales._();

  factory Locales([updates(LocalesBuilder b)]) = _$Locales;

  @BuiltValueField(wireName: 'locales')
  BuiltList<Locale> get locales;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(Locales.serializer, this));
  }

  static Locales fromJson(String jsonString) {
    return serializers.deserializeWith(
        Locales.serializer, json.decode(jsonString));
  }

  static Serializer<Locales> get serializer => _$localesSerializer;
}
