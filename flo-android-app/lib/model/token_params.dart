library token_params;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'token_params.g.dart';

abstract class TokenParams implements Built<TokenParams, TokenParamsBuilder> {
  TokenParams._();

  factory TokenParams([updates(TokenParamsBuilder b)]) = _$TokenParams;

  @BuiltValueField(wireName: 'token')
  String get token;
  String toJson() {
    return json.encode(serializers.serializeWith(TokenParams.serializer, this));
  }

  static TokenParams fromJson(String jsonString) {
    return serializers.deserializeWith(
        TokenParams.serializer, json.decode(jsonString));
  }

  static Serializer<TokenParams> get serializer => _$tokenParamsSerializer;
  static TokenParams get empty => TokenParams((b) => b
    ..token = ''
    );
}
