library app_config;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:version/version.dart';
import 'serializers.dart';

part 'app_config.g.dart';

abstract class AppConfig implements Built<AppConfig, AppConfigBuilder> {
  AppConfig._();

  factory AppConfig([updates(AppConfigBuilder b)]) = _$AppConfig;

  @nullable
  @BuiltValueField(wireName: 'minVersion')
  String get minVersion;

  Version get minVersioned => Version.parse(minVersion);

  String toJson() {
    return json.encode(serializers.serializeWith(AppConfig.serializer, this));
  }

  static AppConfig fromJson(String jsonString) {
    return serializers.deserializeWith(
        AppConfig.serializer, json.decode(jsonString));
  }

  static Serializer<AppConfig> get serializer => _$appConfigSerializer;
}
