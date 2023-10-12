library string_items;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'string_items.g.dart';

abstract class StringItems implements Built<StringItems, StringItemsBuilder> {
  StringItems._();

  factory StringItems([updates(StringItemsBuilder b)]) = _$StringItems;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<String> get items;
  String toJson() {
    return json.encode(serializers.serializeWith(StringItems.serializer, this));
  }

  static StringItems fromJson(String jsonString) {
    return serializers.deserializeWith(
        StringItems.serializer, json.decode(jsonString));
  }

  static Serializer<StringItems> get serializer => _$stringItemsSerializer;
}
