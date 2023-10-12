library account;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'account.g.dart';

abstract class Account implements Built<Account, AccountBuilder> {
  Account._();

  factory Account([updates(AccountBuilder b)]) = _$Account;

  @BuiltValueField(wireName: 'id')
  String get id;
  String toJson() {
    return json.encode(serializers.serializeWith(Account.serializer, this));
  }

  static Account fromJson(String jsonString) {
    return serializers.deserializeWith(
        Account.serializer, json.decode(jsonString));
  }

  static Serializer<Account> get serializer => _$accountSerializer;
}