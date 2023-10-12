library item_list;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'item.dart';

part 'item_list.g.dart';

abstract class ItemList implements Built<ItemList, ItemListBuilder> {
  ItemList._();

  factory ItemList([updates(ItemListBuilder b)]) = _$ItemList;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<Item> get items;
  String toJson() {
    return json.encode(serializers.serializeWith(ItemList.serializer, this));
  }

  static ItemList fromJson(String jsonString) {
    return serializers.deserializeWith(
        ItemList.serializer, json.decode(jsonString));
  }

  static Serializer<ItemList> get serializer => _$itemListSerializer;
}