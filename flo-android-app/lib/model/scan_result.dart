library scan_result;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'wifi.dart';

part 'scan_result.g.dart';

abstract class ScanResult
    implements Built<ScanResult, ScanResultBuilder> {
  ScanResult._();

  factory ScanResult([updates(ScanResultBuilder b)]) =
      _$ScanResult;

  @BuiltValueField(wireName: 'result')
  BuiltList<Wifi> get result;
  String toJson() {
    return json
        .encode(serializers.serializeWith(ScanResult.serializer, this));
  }

  static ScanResult fromJson(String jsonString) {
    return serializers.deserializeWith(
        ScanResult.serializer, json.decode(jsonString));
  }

  static Serializer<ScanResult> get serializer => _$scanResultSerializer;
}