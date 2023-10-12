library alert1;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../utils.dart';
import 'alert.dart';
import 'alert1_notification.dart';
import 'icd.dart';
import 'serializers.dart';

part 'alert1.g.dart';

abstract class Alert1 implements Built<Alert1, Alert1Builder> {
  Alert1._();

  factory Alert1([updates(Alert1Builder b)]) = _$Alert1;

  @nullable
  @BuiltValueField(wireName: 'notification')
  Alert1Notification get notification;
  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'icd')
  Icd get icd;
  @nullable
  @BuiltValueField(wireName: 'ts')
  String get ts;
  String toJson() {
    return json.encode(serializers.serializeWith(Alert1.serializer, this));
  }

  @nullable
  static Alert1 fromJson(String jsonString) {
    return or(() => serializers.deserializeWith(Alert1.serializer, json.decode(jsonString)));
  }

  @nullable
  static Alert1 fromMap2(Map<String, dynamic> map) {
    return or(() => serializers.deserializeWith(Alert1.serializer, map));
  }

  @nullable
  static Alert1 fromJsonObject(JsonObject jsonObject) {
    return or(() => serializers.deserializeWith(Alert1.serializer, jsonObject.asMap));
  }

  @nullable
  static Alert1 from(dynamic value) {
    return as<Alert1>(value) ??
           let(as<Map<String, dynamic>>(value), (it) => Alert1.fromMap2(it)) ??
           let(as<JsonObject>(value), (it) => Alert1.fromJsonObject(it)) ??
           let(as<String>(value), (it) => Alert1.fromJson(it));
  }

  static Serializer<Alert1> get serializer => _$alert1Serializer;

  Future<Alert> toAlert(material.BuildContext context) async {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    try {
      final alert = await flo.getAlert(id, authorization: oauth.authorization).then((it) => it.body);
      final location = await flo.getLocation(alert.locationId, authorization: oauth.authorization).then((it) => it.body);
      final device = await flo.getDevice(alert.deviceId, authorization: oauth.authorization).then((it) => it.body);

      return alert.rebuild((b) => b
        ..device = device.toBuilder()
        ..location = location.toBuilder()
      );
    } catch (err) {
      Fimber.e("", ex: err);
    }
    return Alert.empty;
  }
}
