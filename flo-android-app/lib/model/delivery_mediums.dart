library delivery_mediums;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'delivery_medium.dart';
import 'serializers.dart';

part 'delivery_mediums.g.dart';

abstract class DeliveryMediums
    implements Built<DeliveryMediums, DeliveryMediumsBuilder> {
  DeliveryMediums._();

  factory DeliveryMediums([updates(DeliveryMediumsBuilder b)]) = _$DeliveryMediums;

  @nullable
  @BuiltValueField(wireName: 'sms')
  DeliveryMedium get sms;
  @nullable
  @BuiltValueField(wireName: 'push')
  DeliveryMedium get push;
  @nullable
  @BuiltValueField(wireName: 'call')
  DeliveryMedium get call;
  @nullable
  @BuiltValueField(wireName: 'email')
  DeliveryMedium get email;

  @nullable
  @BuiltValueField(wireName: 'userConfigurable')
  bool get userConfigurable;

  String toJson() {
    return json
        .encode(serializers.serializeWith(DeliveryMediums.serializer, this));
  }

  static DeliveryMediums fromJson(String jsonString) {
    return serializers.deserializeWith(
        DeliveryMediums.serializer, json.decode(jsonString));
  }

  static Serializer<DeliveryMediums> get serializer =>
      _$deliveryMediumsSerializer;

  //bool get isNotEmpty => [sms, push, call, email].any((it) => (it?.supported ?? false) && (userConfigurable ?? false));
  bool get isNotEmpty => [sms, push, call, email].any((it) => (it?.supported ?? false));
  bool get isEmpty => !isNotEmpty;
}
