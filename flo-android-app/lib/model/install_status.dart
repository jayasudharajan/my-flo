library install_status;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils.dart';
import 'serializers.dart';

part 'install_status.g.dart';

abstract class InstallStatus
    implements Built<InstallStatus, InstallStatusBuilder> {
  InstallStatus._();

  factory InstallStatus([updates(InstallStatusBuilder b)]) = _$InstallStatus;

  @nullable
  @BuiltValueField(wireName: 'isInstalled')
  bool get isInstalled;
  @nullable
  @BuiltValueField(wireName: 'installDate')
  String get installDate;

  Duration get duration => DateTime.now().difference(DateTimes.of(installDate, isUtc: true));

  bool isJustInstalled({Duration timeout = const Duration(days: 2)}) => (isInstalled ?? false) && (duration ?? timeout) < timeout;

  String toJson() {
    return json
        .encode(serializers.serializeWith(InstallStatus.serializer, this));
  }

  static InstallStatus fromJson(String jsonString) {
    return serializers.deserializeWith(
        InstallStatus.serializer, json.decode(jsonString));
  }

  static Serializer<InstallStatus> get serializer => _$installStatusSerializer;
}
