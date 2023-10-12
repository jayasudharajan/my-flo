library change_password;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'change_password.g.dart';

abstract class ChangePassword
    implements Built<ChangePassword, ChangePasswordBuilder> {
  ChangePassword._();

  factory ChangePassword([updates(ChangePasswordBuilder b)]) = _$ChangePassword;

  @BuiltValueField(wireName: 'oldPassword')
  String get oldPassword;
  @BuiltValueField(wireName: 'newPassword')
  String get newPassword;
  String toJson() {
    return json
        .encode(serializers.serializeWith(ChangePassword.serializer, this));
  }

  static ChangePassword fromJson(String jsonString) {
    return serializers.deserializeWith(
        ChangePassword.serializer, json.decode(jsonString));
  }

  static Serializer<ChangePassword> get serializer =>
      _$changePasswordSerializer;
}