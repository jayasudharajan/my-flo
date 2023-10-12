library registration_payload;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'registration_payload.g.dart';

abstract class RegistrationPayload
    implements Built<RegistrationPayload, RegistrationPayloadBuilder> {
  RegistrationPayload._();

  factory RegistrationPayload([updates(RegistrationPayloadBuilder b)]) = _$RegistrationPayload;

  @BuiltValueField(wireName: 'firstname')
  String get firstName;
  @BuiltValueField(wireName: 'lastname')
  String get lastName;
  @BuiltValueField(wireName: 'country')
  String get country;
  @BuiltValueField(wireName: 'email')
  String get email;
  @BuiltValueField(wireName: 'password')
  String get password;
  @BuiltValueField(wireName: 'password_conf')
  String get confirmPassword;
  @BuiltValueField(wireName: 'phone_mobile')
  String get phoneNumber;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(RegistrationPayload.serializer, this));
  }

  static RegistrationPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        RegistrationPayload.serializer, json.decode(jsonString));
  }

  static Serializer<RegistrationPayload> get serializer => _$registrationPayloadSerializer;
}
