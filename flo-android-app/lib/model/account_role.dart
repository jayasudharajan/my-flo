library account_role;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'account_role.g.dart';

abstract class AccountRole implements Built<AccountRole, AccountRoleBuilder> {
  AccountRole._();

  factory AccountRole([updates(AccountRoleBuilder b)]) = _$AccountRole;

  @BuiltValueField(wireName: 'accountId')
  String get accountId;
  @BuiltValueField(wireName: 'roles')
  @nullable
  BuiltList<String> get roles;
  String toJson() {
    return json.encode(serializers.serializeWith(AccountRole.serializer, this));
  }

  static AccountRole fromJson(String jsonString) {
    return serializers.deserializeWith(
        AccountRole.serializer, json.decode(jsonString));
  }

  static Serializer<AccountRole> get serializer => _$accountRoleSerializer;
}