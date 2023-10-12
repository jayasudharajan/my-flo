library firmware_properties_result;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'firmware_properties.dart';
import 'serializers.dart';

part 'firmware_properties_result.g.dart';

abstract class FirmwarePropertiesResult
    implements Built<FirmwarePropertiesResult, FirmwarePropertiesResultBuilder> {
  FirmwarePropertiesResult._();

  factory FirmwarePropertiesResult([updates(FirmwarePropertiesResultBuilder b)]) =
  _$FirmwarePropertiesResult;

  @nullable
  @BuiltValueField(wireName: 'result')
  FirmwareProperties get result;

  String toJson() {
    return json
        .encode(serializers.serializeWith(FirmwarePropertiesResult.serializer, this));
  }

  static FirmwarePropertiesResult fromJson(String jsonString) {
    return serializers.deserializeWith(
        FirmwarePropertiesResult.serializer, json.decode(jsonString));
  }

  static Serializer<FirmwarePropertiesResult> get serializer =>
      _$firmwarePropertiesResultSerializer;
}
