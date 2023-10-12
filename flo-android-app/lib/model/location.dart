library location;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:superpower/superpower.dart';
import '../utils.dart';
import 'alert_statistics.dart';
import 'amenity.dart';
import 'answer.dart';
import 'device.dart';
import 'id.dart';
import 'irrigation_schedule.dart';
import 'location_size.dart';
import 'notifications.dart';
import 'past_water_damage_claim_amount.dart';
import 'pending_system_mode.dart';
import 'plumbing_type.dart';
import 'location_type.dart';
import 'residence_type.dart';
import 'serializers.dart';
import 'subscription.dart';
import 'system_mode.dart';
import 'user_role.dart';
import 'water_source.dart';

part 'location.g.dart';

abstract class Location implements Built<Location, LocationBuilder> {
  Location._();

  factory Location([updates(LocationBuilder b)]) = _$Location;

  @nullable
  @BuiltValueField(wireName: 'id', serialize:  false)
  String get id;
  @nullable
  @BuiltValueField(wireName: 'users')
  BuiltList<Id> get users;
  @nullable
  @BuiltValueField(wireName: 'devices')
  BuiltList<Device> get devices;
  @nullable
  @BuiltValueField(wireName: 'userRoles')
  BuiltList<UserRole> get userRoles;
  @nullable
  @BuiltValueField(wireName: 'account')
  Id get account;

  @nullable
  @BuiltValueField(wireName: 'nickname')
  String get nickname;
  @nullable
  @BuiltValueField(wireName: 'address')
  String get address;
  @nullable
  @BuiltValueField(wireName: 'address2')
  String get address2;
  @nullable
  @BuiltValueField(wireName: 'city')
  String get city;
  @nullable
  @BuiltValueField(wireName: 'state')
  String get state;
  @nullable
  @BuiltValueField(wireName: 'country')
  String get country;
  @nullable
  @BuiltValueField(wireName: 'postalCode')
  String get postalCode;
  @nullable
  @BuiltValueField(wireName: 'timezone')
  String get timezone;
  @nullable
  @BuiltValueField(wireName: 'gallonsPerDayGoal')
  double get gallonsPerDayGoal;
  @nullable
  @BuiltValueField(wireName: 'occupants')
  int get occupants;
  @nullable
  @BuiltValueField(wireName: 'stories')
  int get stories;
  @nullable
  @BuiltValueField(wireName: 'isProfileComplete')
  bool get isProfileComplete;
  @nullable
  @BuiltValueField(wireName: 'waterShutoffKnown')
  Answer get waterShutoffKnown;
  @nullable
  @BuiltValueField(wireName: 'indoorAmenities')
  BuiltList<String> get indoorAmenities;
  @nullable
  @BuiltValueField(wireName: 'outdoorAmenities')
  BuiltList<String> get outdoorAmenities;
  @nullable
  @BuiltValueField(wireName: 'plumbingAppliances')
  BuiltList<String> get plumbingAppliances;
  @nullable
  @BuiltValueField(wireName: 'locationType')
  //String get locationType;
  LocationType get locationType;
  @nullable
  @BuiltValueField(wireName: 'residenceType')
  //ResidenceType get residenceType;
  String get residenceType;
  @nullable
  @BuiltValueField(wireName: 'waterSource')
  //WaterSource get waterSource;
  String get waterSource;
  @nullable
  @BuiltValueField(wireName: 'locationSize')
  String get locationSize;
  @nullable
  @BuiltValueField(wireName: 'showerBathCount')
  int get showerBathCount;
  @nullable
  @BuiltValueField(wireName: 'toiletCount')
  int get toiletCount;
  @nullable
  @BuiltValueField(wireName: 'plumbingType')
  String get plumbingType;
  //PlumbingType get plumbingType;
  @nullable
  @BuiltValueField(wireName: 'homeownersInsurance')
  String get homeownersInsurance;
  @nullable
  @BuiltValueField(wireName: 'hasPastWaterDamage')
  bool get hasPastWaterDamage;
  @nullable
  @BuiltValueField(wireName: 'pastWaterDamageClaimAmount')
  PastWaterDamageClaimAmount get pastWaterDamageClaimAmount;
  @nullable
  @BuiltValueField(wireName: 'systemMode')
  PendingSystemMode get systemModes;

  PendingSystemMode get systemMode {
    if (systemModes?.target?.isNotEmpty ?? false) return systemModes;

    if (isLearning) { // all(devices) are learning
      return PendingSystemMode((b) => b
        ..target = SystemMode.SLEEP
        ..isLocked = true
      );
    } else { // first of devices is not learning
      return or(() => $(devices).where((it) => !it.isLearning).first.systemMode) ?? PendingSystemMode((b) => b
        ..target = SystemMode.SLEEP
        ..isLocked = true
      );
    }
  }

  @nullable
  @BuiltValueField(wireName: 'createdAt', serialize:  false)
  String get createdAt;
  @nullable
  @BuiltValueField(wireName: 'updatedAt', serialize:  false)
  String get updatedAt;
  @nullable
  @BuiltValueField(wireName: 'waterUtility')
  String get waterUtility;
  @nullable
  @BuiltValueField(wireName: 'subscription')
  Subscription get subscription;
  @nullable
  @BuiltValueField(wireName: 'irrigationSchedule')
  IrrigationSchedule get irrigationSchedule;
  @nullable
  @BuiltValueField(wireName: 'notifications')
  AlertStatistics get notifications;

  @nullable
  @BuiltValueField(serialize: false)
  bool get dirty;

  String toJson() {
    return json.encode(serializers.serializeWith(Location.serializer, this));
  }

  static Location fromJson(String jsonString) {
    return serializers.deserializeWith(
        Location.serializer, json.decode(jsonString));
  }

  static Serializer<Location> get serializer => _$locationSerializer;

  static Location get empty {
    return Location((b) => b
      ..id = ""
      ..state = ""
      ..country = "us"
      ..postalCode = ""
      ..timezone = ""
      ..isProfileComplete = false
      ..account = Id((b) => b..id = "").toBuilder()
      ..dirty = false
    );
  }

  //static const Location EMPTY = const Location();
  static Location EMPTY = Location();
  static Location UNKOWN = Location((b) => b..id = "ffffffff-ffff-4fff-8fff-fffffffffff1");
  bool get isEmpty => this == empty || this == EMPTY;

  Id toId() => Id((b) => b..id = id);

  bool get isLearning {
    // (systemMode?.learning ?? true) || $(devices).all((it) => it.isLearning);
     //Fimber.d("isLearning for ${nickname}? ${(systemMode?.learning ?? true)}");
     //Fimber.d("isLearning systemMode for ${nickname}? ${(systemMode)}");
    return (devices?.isNotEmpty ?? false) ? devices?.every((it) => it.isLearning) : true;
  }

  IrrigationSchedule get mergedIrrigationSchedule {
    final List<BuiltList<String>> times = $(devices).flatMap((it) => it?.irrigationSchedule?.computed?.times ?? BuiltList<BuiltList<String>>(BuiltList<String>()))
    .onEach((it) {
      Fimber.d("each ${it}");
    })
    .append(irrigationSchedule?.computed?.times ?? BuiltList<BuiltList<String>>(BuiltList<String>()))
    .distinct()
        .toList();
    Fimber.d("original ${ irrigationSchedule?.computed?.times }");
    Fimber.d("merged ${ BuiltList<BuiltList<String>>(times) }");
    return irrigationSchedule?.rebuild((b) => b..computed = b?.computed?.build()?.rebuild((b2) => b2..times = ListBuilder<BuiltList<String>>(times))?.toBuilder() ?? b.computed);
  }

  String get displayName => nickname ?? address ?? "";

  /// copper                Copper
  /// galvanized             Galvanized
  /// cpvc                CPVC
  /// pex                    PEX
  /// other                Other
  /// unknown                Not Sure
  static const String PIPE_TYPE = "pipe_type";

  /// bathtub             Bathtub
  /// hottub                 Hot Tub
  /// clotheswasher         Washer/Dryer
  /// dishwasher             Dishwasher
  /// icemaker_ref         Refridgerator with Ice Maker
  static const String FIXTURE_INDOOR = "fixture_indoor";

  /// pool                 Swimming Pool
  /// pool_filter         Swimming Pool with auto pool filter
  /// hottub                 Hot Tub
  /// fountain             Fountain
  /// pond                 Pond
  static const String FIXTURE_OUTDOOR = "fixture_outdoor";

  /// tankless                 Tankless Water Heater
  /// exp_tank                 Expansion Tank
  /// home_filter             Whole Home Filtration System
  /// home_humidifier         Whole Home Humidifier
  /// re_pump                 Recirculation Pump
  /// rev_osmosis             Reverse Osmosis
  /// softener                 Water Softener
  /// prv                     Pressure Reducing Valve
  static const String HOME_APPLIANCE = "home_appliance";

  /// sprinklers                 Sprinklers
  /// drip                     Drip Irrigation
  /// drip_sprinkler             Sprinklers & Drip Irrigation
  /// none                     Flo is not plumbed on my irrigation
  static const String IRRIGATION_TYPE = "irrigation_type";

  /// before                 Before Flo
  /// after                 After Flo
  /// none                 I don't have a PRV
  /// unknown             Not Sure
  static const String PRV = "prv";


  static const String LOCATION_SIZE = "location_size";
  static const String RESIDENCE_TYPE = "residence_type";


  static const Set<String> FIXTURES = const {
    FIXTURE_INDOOR,
    FIXTURE_OUTDOOR,
    HOME_APPLIANCE,
  };

  static const Set<String> ALL_PROFILES = const {
    PIPE_TYPE,
    FIXTURE_INDOOR,
    FIXTURE_OUTDOOR,
    HOME_APPLIANCE,
    IRRIGATION_TYPE,
    PRV,
    LOCATION_SIZE,
    RESIDENCE_TYPE,
  };

  static const Set<String> PROFILES = const {
    PIPE_TYPE,
    FIXTURE_INDOOR,
    FIXTURE_OUTDOOR,
    HOME_APPLIANCE,
    //IRRIGATION_TYPE, // on device settings and device details
    //PRV, // on device settings and device details
    RESIDENCE_TYPE,
  };

  bool get isSecure => (devices?.isNotEmpty ?? false) ? devices?.every((it) => it.isSecure) ?? false : false;
}