library item;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'item.g.dart';

abstract class Item implements Built<Item, ItemBuilder> {
  Item._();

  factory Item([updates(ItemBuilder b)]) = _$Item;

  @nullable
  @BuiltValueField(wireName: 'key')
  String get key;
  @nullable
  @BuiltValueField(wireName: 'shortDisplay')
  String get shortDisplay;
  @nullable
  @BuiltValueField(wireName: 'longDisplay')
  String get longDisplay;
  @nullable
  @BuiltValueField(wireName: 'lang')
  String get language;
  String toJson() {
    return json.encode(serializers.serializeWith(Item.serializer, this));
  }

  @nullable
  String get longDisplay2 => longDisplay ?? shortDisplay ?? key;
  @nullable
  String get shortDisplay2 => shortDisplay ?? key;

  static Item fromJson(String jsonString) {
    return serializers.deserializeWith(
        Item.serializer, json.decode(jsonString));
  }

  static Serializer<Item> get serializer => _$itemSerializer;
}
