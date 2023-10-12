library jsonrpc;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'jsonrpc.g.dart';

abstract class JsonRpc<T>
    implements Built<JsonRpc<T>, JsonRpcBuilder<T>> {
  JsonRpc._();

  factory JsonRpc([void Function(JsonRpcBuilder<T>) updates]) = _$JsonRpc<T>;

  @nullable
  @BuiltValueField(wireName: 'jsonrpc')
  String get jsonrpc;
  @nullable
  @BuiltValueField(wireName: 'method')
  String get method;
  @nullable
  @BuiltValueField(wireName: 'params')
  T get params;
  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  String toJson() {
    return json
        .encode(serializers.serializeWith(JsonRpc.serializer, this));
  }

  static JsonRpc<T> fromJson<T>(String jsonString) {
    return serializers.deserializeWith(
        JsonRpc.serializer, json.decode(jsonString));
  }

  static Serializer<JsonRpc> get serializer => _$jsonRpcSerializer;
}