library subscription_provider;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'subscription_provider.g.dart';

abstract class SubscriptionProvider
    implements Built<SubscriptionProvider, SubscriptionProviderBuilder> {
  SubscriptionProvider._();

  factory SubscriptionProvider([updates(SubscriptionProviderBuilder b)]) =
  _$SubscriptionProvider;

  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  @nullable
  @BuiltValueField(wireName: 'isActive')
  bool get isActive;
  /*
  name:
  type: string
  token:
  type: string
  couponId:
  type: string
  */

  String toJson() {
    return json.encode(
        serializers.serializeWith(SubscriptionProvider.serializer, this));
  }

  static SubscriptionProvider fromJson(String jsonString) {
    return serializers.deserializeWith(
        SubscriptionProvider.serializer, json.decode(jsonString));
  }

  static Serializer<SubscriptionProvider> get serializer =>
      _$subscriptionProviderSerializer;
}
