library delivery_medium;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'delivery_medium_settings.dart';
import 'serializers.dart';

part 'delivery_medium.g.dart';

abstract class DeliveryMedium implements Built<DeliveryMedium, DeliveryMediumBuilder> {
  DeliveryMedium._();

  factory DeliveryMedium([updates(DeliveryMediumBuilder b)]) = _$DeliveryMedium;

  @nullable
  @BuiltValueField(wireName: 'supported')
  bool get supported;

  @nullable
  @BuiltValueField(wireName: 'defaultSettings')
  BuiltList<DeliveryMediumSettings> get defaultSettings;
  String toJson() {
    return json.encode(serializers.serializeWith(DeliveryMedium.serializer, this));
  }

  static DeliveryMedium fromJson(String jsonString) {
    return serializers.deserializeWith(DeliveryMedium.serializer, json.decode(jsonString));
  }

  static Serializer<DeliveryMedium> get serializer => _$deliveryMediumSerializer;
}

