library registration_payload2;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'registration_payload2.g.dart';

/**
 * {
 *   "email": "andrew@flotechnologies.com",
 *   "firstName": "Andrew",
 *   "lastName": "Chen",
 *   "password": "",
 *   "phone": "",
 *   "country": "us"
 * }
 */
abstract class RegistrationPayload2
    implements Built<RegistrationPayload2, RegistrationPayload2Builder> {
  RegistrationPayload2._();

  factory RegistrationPayload2([updates(RegistrationPayload2Builder b)]) =
      _$RegistrationPayload2;

  /**
   * {
   *    "email": "andrew+0606@flotechnologies.com",
   *    "firstName": "string",
   *    "lastName": "string",
   *    "password": "Abcd1234",
   *    "phone": "+13104043914",
   *    "country": "us"
   *  }
   */
  @BuiltValueField(wireName: 'email')
  String get email;
  @BuiltValueField(wireName: 'password')
  String get password;
  @BuiltValueField(wireName: 'firstName')
  String get firstName;
  @BuiltValueField(wireName: 'lastName')
  String get lastName;
  @BuiltValueField(wireName: 'country')
  String get country;
  @BuiltValueField(wireName: 'phone')
  String get phone;
  String toJson() {
    return json.encode(
        serializers.serializeWith(RegistrationPayload2.serializer, this));
  }

  static RegistrationPayload2 fromJson(String jsonString) {
    return serializers.deserializeWith(
        RegistrationPayload2.serializer, json.decode(jsonString));
  }

  static Serializer<RegistrationPayload2> get serializer =>
      _$registrationPayload2Serializer;
}