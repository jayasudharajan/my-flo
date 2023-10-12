library subscription;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'subscription_provider.dart';

part 'subscription.g.dart';

abstract class Subscription implements Built<Subscription, SubscriptionBuilder> {
  Subscription._();

  factory Subscription([updates(SubscriptionBuilder b)]) = _$Subscription;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'isActive')
  bool get isActive;
  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;
  @nullable
  @BuiltValueField(wireName: 'providerInfo')
  SubscriptionProvider get provider;

  String toJson() {
    return json.encode(serializers.serializeWith(Subscription.serializer, this));
  }

  static Subscription fromJson(String jsonString) {
    return serializers.deserializeWith(
        Subscription.serializer, json.decode(jsonString));
  }

  static Serializer<Subscription> get serializer => _$subscriptionSerializer;

  static Subscription get empty {
    return Subscription((b) => b
        ..id = ""
        );
  }
}