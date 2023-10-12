library delivery_medium_settings;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'delivery_medium_settings.g.dart';

abstract class DeliveryMediumSettings
    implements Built<DeliveryMediumSettings, DeliveryMediumSettingsBuilder> {
  DeliveryMediumSettings._();

  factory DeliveryMediumSettings([updates(DeliveryMediumSettingsBuilder b)]) =
  _$DeliveryMediumSettings;

  @nullable
  @BuiltValueField(wireName: 'systemMode')
  //int get systemMode;
  String get systemMode;
  @nullable
  @BuiltValueField(wireName: 'enabled')
  bool get enabled;
  String toJson() {
    return json.encode(
        serializers.serializeWith(DeliveryMediumSettings.serializer, this));
  }

  static DeliveryMediumSettings fromJson(String jsonString) {
    return serializers.deserializeWith(
        DeliveryMediumSettings.serializer, json.decode(jsonString));
  }

  static Serializer<DeliveryMediumSettings> get serializer =>
      _$deliveryMediumSettingsSerializer;
}

