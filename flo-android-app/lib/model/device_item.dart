library device_item;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'item.dart';

part 'device_item.g.dart';

abstract class DeviceItem implements Built<DeviceItem, DeviceItemBuilder> {
  DeviceItem._();

  factory DeviceItem([updates(DeviceItemBuilder b)]) = _$DeviceItem;

  @nullable
  @BuiltValueField(wireName: 'type')
  Item get type;

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
    return json.encode(serializers.serializeWith(DeviceItem.serializer, this));
  }

  static DeviceItem fromJson(String jsonString) {
    return serializers.deserializeWith(
        DeviceItem.serializer, json.decode(jsonString));
  }

  static Serializer<DeviceItem> get serializer => _$deviceItemSerializer;
}
