library token_jsonrpc;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'jsonrpc.dart';
import 'serializers.dart';

import 'token_params.dart';

part 'token_jsonrpc.g.dart';
//JsonRpc<TokenParams>
abstract class TokenJsonRpc
    implements Built<TokenJsonRpc, TokenJsonRpcBuilder> {
  TokenJsonRpc._();

  factory TokenJsonRpc([updates(TokenJsonRpcBuilder b)]) = _$TokenJsonRpc;

  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @BuiltValueField(wireName: 'method')
  String get method;
  @BuiltValueField(wireName: 'params')
  TokenParams get params;
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json
        .encode(serializers.serializeWith(TokenJsonRpc.serializer, this));
  }

  static TokenJsonRpc fromJson(String jsonString) {
    return serializers.deserializeWith(
        TokenJsonRpc.serializer, json.decode(jsonString));
  }

  static Serializer<TokenJsonRpc> get serializer => _$tokenJsonRpcSerializer;
  static TokenJsonRpc get empty => TokenJsonRpc((b) => b
    ..jsonrpc = ''
    ..method = ''
    ..params = TokenParams.empty.toBuilder()
    ..id = 0
    );
}