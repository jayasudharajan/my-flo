library config;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

import 'api_configs.dart';
import 'app_config.dart';

part 'config.g.dart';

abstract class Config implements Built<Config, ConfigBuilder> {
  Config._();

  factory Config([updates(ConfigBuilder b)]) = _$Config;

  @nullable
  @BuiltValueField(wireName: 'api')
  ApiConfigs get api;
  @nullable
  @BuiltValueField(wireName: 'iosApp')
  AppConfig get iosApp;
  @nullable
  @BuiltValueField(wireName: 'androidApp')
  AppConfig get androidApp;
  @nullable
  @BuiltValueField(wireName: 'enabledFeatures')
  BuiltList<String> get enabledFeatures;
  String toJson() {
    return json.encode(serializers.serializeWith(Config.serializer, this));
  }

  static Config fromJson(String jsonString) {
    return serializers.deserializeWith(
        Config.serializer, json.decode(jsonString));
  }

  static Serializer<Config> get serializer => _$configSerializer;
}
