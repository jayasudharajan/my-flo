library app_info;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'app_info.g.dart';

abstract class AppInfo implements Built<AppInfo, AppInfoBuilder> {
  AppInfo._();

  factory AppInfo([updates(AppInfoBuilder b)]) = _$AppInfo;

  @BuiltValueField(wireName: 'appName')
  String get appName;
  @BuiltValueField(wireName: 'appVersion')
  String get appVersion;
  String toJson() {
    return json.encode(serializers.serializeWith(AppInfo.serializer, this));
  }

  static AppInfo fromJson(String jsonString) {
    return serializers.deserializeWith(
        AppInfo.serializer, json.decode(jsonString));
  }

  static Serializer<AppInfo> get serializer => _$appInfoSerializer;
}
