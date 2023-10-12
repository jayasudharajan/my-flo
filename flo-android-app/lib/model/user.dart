library user;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'device_alerts_settings.dart';
import 'id.dart';
import 'account_role.dart';
import 'location_role.dart';
import 'serializers.dart';
import 'unit_system.dart';

part 'user.g.dart';

abstract class User implements Built<User, UserBuilder> {
  User._();

  factory User([updates(UserBuilder b)]) = _$User;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'email')
  String get email;
  @nullable
  @BuiltValueField(wireName: 'isActive')
  bool get isActive;
  @nullable
  @BuiltValueField(wireName: 'firstName')
  String get firstName;
  @nullable
  @BuiltValueField(wireName: 'lastName')
  String get lastName;
  @nullable
  @BuiltValueField(wireName: 'phoneMobile')
  String get phoneMobile;
  @nullable
  @BuiltValueField(wireName: 'locations')
  BuiltList<Id> get locations;
  @nullable
  @BuiltValueField(wireName: 'locationRoles')
  BuiltList<LocationRole> get locationRoles;
  @nullable
  @BuiltValueField(wireName: 'accountRole')
  AccountRole get accountRole;
  @nullable
  @BuiltValueField(wireName: 'account')
  Id get account;

  @nullable
  @BuiltValueField(wireName: 'middleName')
  String get middleName;
  @nullable
  @BuiltValueField(wireName: 'prefixName')
  String get prefixName;
  @nullable
  @BuiltValueField(wireName: 'suffixName')
  String get suffixName;
  @nullable
  @BuiltValueField(wireName: 'unitSystem')
  UnitSystem get unitSystem;
  @nullable
  @BuiltValueField(wireName: 'locale')
  String get locale;

  @nullable
  @BuiltValueField(wireName: 'alarmSettings')
  BuiltList<DeviceAlertsSettings> get alertsSettings;
  @nullable
  @BuiltValueField(wireName: 'enabledFeatures')
  BuiltList<String> get enabledFeatures;

  @nullable
  bool get dirty;

  UnitSystem unitSystemOr({UnitSystem unit = UnitSystem.imperialUs}) => unitSystem ?? unit;

  String toJson() {
    return json.encode(serializers.serializeWith(User.serializer, this));
  }

  static User fromJson(String jsonString) {
    return serializers.deserializeWith(
        User.serializer, json.decode(jsonString));
  }

  static Serializer<User> get serializer => _$userSerializer;
  static User get empty => User((b) => b
    ..id = ""
    ..email = ""
    ..isActive = false
    ..firstName = ""
    ..lastName = ""
    ..phoneMobile = ""
    ..locations = ListBuilder()
    ..locationRoles = ListBuilder()
    ..accountRole = AccountRole((b) => b..accountId = "ffffffff-ffff-4fff-8fff-ffffffffffff").toBuilder()
    ..account = Id((b) => b..id = "ffffffff-ffff-4fff-8fff-ffffffffffff").toBuilder());

  static const String DEVELOPER_MENU = "developerMenu";

  bool get isMetric => (unitSystem != UnitSystem.imperialUs) ?? false;
}
