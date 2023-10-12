library puck_ticket;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'puck_ticket.g.dart';

abstract class PuckTicket implements Built<PuckTicket, PuckTicketBuilder> {
  PuckTicket._();

  factory PuckTicket([updates(PuckTicketBuilder b)]) = _$PuckTicket;

  @nullable
  @BuiltValueField(wireName: 'api_access_token')
  String get apiAccessToken;
  @nullable
  @BuiltValueField(wireName: 'cloud_hostname')
  String get cloudHostname;
  @nullable
  @BuiltValueField(wireName: 'wifi_ssid')
  String get wifiSsid;
  @nullable
  @BuiltValueField(wireName: 'wifi_password')
  String get wifiPassword;
  @nullable
  @BuiltValueField(wireName: 'wifi_encryption')
  String get wifiEncryption;
  @nullable
  @BuiltValueField(wireName: 'location_id')
  String get locationId;
  @nullable
  @BuiltValueField(wireName: 'nickname')
  String get nickname;
  @nullable
  @BuiltValueField(wireName: 'install_point')
  String get installPoint;
  @nullable
  @BuiltValueField(wireName: 'device_type')
  String get deviceType;
  @nullable
  @BuiltValueField(wireName: 'device_model')
  String get deviceModel;
  String toJson() {
    return json.encode(serializers.serializeWith(PuckTicket.serializer, this));
  }

  static PuckTicket fromJson(String jsonString) {
    return serializers.deserializeWith(
        PuckTicket.serializer, json.decode(jsonString));
  }

  static Serializer<PuckTicket> get serializer => _$puckTicketSerializer;
}

