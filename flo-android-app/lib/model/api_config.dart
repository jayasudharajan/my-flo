library api_config;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'api_config.g.dart';

abstract class ApiConfig implements Built<ApiConfig, ApiConfigBuilder> {
  ApiConfig._();

  factory ApiConfig([updates(ApiConfigBuilder b)]) = _$ApiConfig;

  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;
  @nullable
  @BuiltValueField(wireName: 'url')
  String get url;

  String toJson() {
    return json.encode(serializers.serializeWith(ApiConfig.serializer, this));
  }

  static ApiConfig fromJson(String jsonString) {
    return serializers.deserializeWith(
        ApiConfig.serializer, json.decode(jsonString));
  }

  static Serializer<ApiConfig> get serializer => _$apiConfigSerializer;
}
