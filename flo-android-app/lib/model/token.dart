library token;

import 'dart:convert';

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'token.g.dart';

abstract class Token implements Built<Token, TokenBuilder> {
  Token._();

  factory Token([updates(TokenBuilder b)]) = _$Token;

  @BuiltValueField(wireName: 'token')
  String get token;
  String toJson() {
    return json.encode(serializers.serializeWith(Token.serializer, this));
  }

  static Token fromJson(String jsonString) {
    return serializers.deserializeWith(
        Token.serializer, json.decode(jsonString));
  }

  static Serializer<Token> get serializer => _$tokenSerializer;

  static Token empty = Token((b) => b
    ..token = ""
  );

  String get authorization => "Bearer ${token}";
}