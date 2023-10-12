library add_puck_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'certificate.dart';
import 'certificate2.dart';
import 'id.dart';
import 'ticket.dart';
import 'ticket2.dart';
import 'token.dart';
import 'wifi.dart';

part 'add_puck_state.g.dart';

abstract class AddPuckState
    implements Built<AddPuckState, AddPuckStateBuilder> {
  AddPuckState._();

  factory AddPuckState([updates(AddPuckStateBuilder b)]) = _$AddPuckState;

  @nullable
  String get model; // deviceModel
  @nullable
  String get modelDisplay; // deviceModel
  @nullable
  String get deviceMake; // deviceMake
  @nullable
  String get nickname;
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
  int get currentPage;
  @nullable
  String get deviceId;
  @nullable
  Id get location;
}