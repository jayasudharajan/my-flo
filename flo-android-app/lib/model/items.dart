library items;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'location.dart';
import 'serializers.dart';
import 'item.dart';

part 'items.g.dart';

abstract class Items implements Built<Items, ItemsBuilder> {
  Items._();

  factory Items([updates(ItemsBuilder b)]) = _$Items;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<BuiltMap<String, BuiltList<Item>>> get items;

  //BuiltList<Item> get prvItems => or(() => items.first[Location.PRV]);
  //BuiltList<Item> get prvItems => or(() => items.first[Location.PRV]);

  String toJson() {
    return json.encode(serializers.serializeWith(Items.serializer, this));
  }

  static Items fromJson(String jsonString) {
    return serializers.deserializeWith(
        Items.serializer, json.decode(jsonString));
  }

  static Serializer<Items> get serializer => _$itemsSerializer;
}