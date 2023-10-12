library alert_firmware_value;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'alert_firmware_value.g.dart';

abstract class AlertFirmwareValue
    implements Built<AlertFirmwareValue, AlertFirmwareValueBuilder> {
  AlertFirmwareValue._();

  factory AlertFirmwareValue([updates(AlertFirmwareValueBuilder b)]) =
  _$AlertFirmwareValue;

  @nullable
  @BuiltValueField(wireName: 'gpm')
  double get gpm;
  @nullable
  @BuiltValueField(wireName: 'galUsed')
  double get galUsed;
  @nullable
  @BuiltValueField(wireName: 'psiDelta')
  double get psiDelta;
  @nullable
  @BuiltValueField(wireName: 'leakLossMinGal')
  double get leakLossMinGal;
  @nullable
  @BuiltValueField(wireName: 'leakLossMaxGal')
  double get leakLossMaxGal;
  @nullable
  @BuiltValueField(wireName: 'flowEventDuration')
  double get flowEventDurationInSeconds;

  // FIXME: Not support 3.123455s
  Duration get flowEventDuration => Duration(seconds: flowEventDurationInSeconds?.round() ?? 0);

  String toJson() {
    return json
        .encode(serializers.serializeWith(AlertFirmwareValue.serializer, this));
  }

  static AlertFirmwareValue fromJson(String jsonString) {
    return serializers.deserializeWith(
        AlertFirmwareValue.serializer, json.decode(jsonString));
  }

  static Serializer<AlertFirmwareValue> get serializer =>
      _$alertFirmwareValueSerializer;
}
