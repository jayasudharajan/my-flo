library add_flo_device_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'certificate.dart';
import 'certificate2.dart';
import 'id.dart';
import 'ticket.dart';
import 'ticket2.dart';
import 'token.dart';
import 'wifi.dart';

part 'add_flo_device_state.g.dart';

abstract class AddFloDeviceState
    implements Built<AddFloDeviceState, AddFloDeviceStateBuilder> {
  AddFloDeviceState._();

  factory AddFloDeviceState([updates(AddFloDeviceStateBuilder b)]) = _$AddFloDeviceState;

  @nullable
  String get model; // deviceModel
  @nullable
  String get modelDisplay; // deviceModel
  @nullable
  String get deviceMake; // deviceMake

  @nullable
  String get nickname;
  @nullable
  BuiltList<WifiNetwork> get wifiList;
  @nullable
  BuiltList<Wifi> get floDeviceWifiList;

  @nullable
  Ticket get ticket;
  @nullable
  Ticket2 get ticket2;
  @nullable
  Certificate2 get certificate;
  @nullable
  bool get error;

  // home router
  @nullable
  Wifi get wifi;
  @nullable
  String get password;

  @nullable
  bool get pluggedPowerCord;
  @nullable
  bool get pluggedOutlet;
  @nullable
  bool get lightsOn;
  /// last ssid
  @nullable
  String get ssid;
  @nullable
  String get deviceSsid;
  @nullable
  int get currentPage;
  @nullable
  String get deviceId;
  @nullable
  Id get location;
}