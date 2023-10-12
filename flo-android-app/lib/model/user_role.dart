library user_role;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'user_role.g.dart';

abstract class UserRole implements Built<UserRole, UserRoleBuilder> {
  UserRole._();

  factory UserRole([updates(UserRoleBuilder b)]) = _$UserRole;

  @BuiltValueField(wireName: 'userId')
  String get userId;
  @BuiltValueField(wireName: 'roles')
  BuiltList<String> get roles;
  String toJson() {
    return json.encode(serializers.serializeWith(UserRole.serializer, this));
  }

  static UserRole fromJson(String jsonString) {
    return serializers.deserializeWith(
        UserRole.serializer, json.decode(jsonString));
  }

  static Serializer<UserRole> get serializer => _$userRoleSerializer;
}