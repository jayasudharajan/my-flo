library api_configs;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'api_config.dart';

part 'api_configs.g.dart';

abstract class ApiConfigs implements Built<ApiConfigs, ApiConfigsBuilder> {
  ApiConfigs._();

  factory ApiConfigs([updates(ApiConfigsBuilder b)]) = _$ApiConfigs;

  @nullable
  @BuiltValueField(wireName: 'v2')
  ApiConfig get v2;
  String toJson() {
    return json.encode(serializers.serializeWith(ApiConfigs.serializer, this));
  }

  static ApiConfigs fromJson(String jsonString) {
    return serializers.deserializeWith(
        ApiConfigs.serializer, json.decode(jsonString));
  }

  static Serializer<ApiConfigs> get serializer => _$apiConfigsSerializer;
}
