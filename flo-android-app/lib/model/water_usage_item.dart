library water_usage_item;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../utils.dart';
import 'serializers.dart';

part 'water_usage_item.g.dart';

abstract class WaterUsageItem implements Built<WaterUsageItem, WaterUsageItemBuilder> {
  WaterUsageItem._();

  factory WaterUsageItem([updates(WaterUsageItemBuilder b)]) = _$WaterUsageItem;

  @nullable
  @BuiltValueField(wireName: 'time')
  String get time;
  @nullable
  @BuiltValueField(wireName: 'gallonsConsumed')
  double get gallonsConsumed;

  @nullable
  DateTime get datetime => DateTime.tryParse(time).toLocal();
  @nullable
  DateTime get today => DateTimes.today(from: datetime);

  String toJson() {
    return json.encode(serializers.serializeWith(WaterUsageItem.serializer, this));
  }

  static WaterUsageItem fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsageItem.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsageItem> get serializer => _$waterUsageItemSerializer;

  WaterUsageItem merge(WaterUsageItem it) => it != null ? ((time == it.time) ? rebuild((b) => b..gallonsConsumed += it.gallonsConsumed) : this) : this;

  WaterUsageItem operator +(WaterUsageItem it) => merge(it);
}
