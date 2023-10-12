library push_notification_token;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'push_notification_token.g.dart';


/// {
/// "mobile_device_id": "",
/// "client_id": "",
/// "user_id": "",
/// "token": "",
/// "client_type": 2,
/// "created_at": "",
/// "updated_at": "",
/// "is_disabled": 2
/// }
///
/// response:
/// {
///  "mobile_device_id": "ffffffffffffffff",
///  "aws_endpoint_id": "4b9c05af-4831-450d-9fae-ffffffffffff",
///  "client_id": "86d05ffc-3730-4b07-bcd1-ffffffffffff",
///  "user_id": "c5154f16-7fcc-4f28-92d1-ffffffffffff",
///  "token": "eS1-FFFFFFFFFFFFFFFFFFFFFFFFFFF",
///  "client_type": 3,
///  "mobile_device_id_client_id": "ffffffffffffffff:86d05ffc-3730-4b07-bcd1-ffffffffffff",
///  "created_at": "2019-10-04T19:37:41.639Z",
///  "updated_at": "2019-10-04T19:37:41.639Z"
///}
abstract class PushNotificationToken
    implements Built<PushNotificationToken, PushNotificationTokenBuilder> {
  PushNotificationToken._();

  factory PushNotificationToken([updates(PushNotificationTokenBuilder b)]) =
  _$PushNotificationToken;

  @nullable
  @BuiltValueField(wireName: 'mobile_device_id')
  String get mobileDeviceId;
  @nullable
  @BuiltValueField(wireName: 'client_id')
  String get clientId;
  @nullable
  @BuiltValueField(wireName: 'user_id')
  String get userId;
  @nullable
  @BuiltValueField(wireName: 'token')
  String get token;

  @nullable
  @BuiltValueField(wireName: 'aws_endpoint_id')
  String get awsEndpointId;

  @nullable
  @BuiltValueField(wireName: 'client_type')
  int get clientType;
  @nullable
  @BuiltValueField(wireName: 'created_at')
  String get createdAt;
  @nullable
  @BuiltValueField(wireName: 'updated_at')
  String get updatedAt;
  @nullable
  @BuiltValueField(wireName: 'is_disabled')
  int get isDisabled;

  String toJson() {
    return json.encode(
        serializers.serializeWith(PushNotificationToken.serializer, this));
  }

  static PushNotificationToken fromJson(String jsonString) {
    return serializers.deserializeWith(
        PushNotificationToken.serializer, json.decode(jsonString));
  }

  static Serializer<PushNotificationToken> get serializer =>
      _$pushNotificationTokenSerializer;
}

