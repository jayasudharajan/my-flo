library location_payload;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'location_payload.g.dart';

/**
 * "nickname": "string",
  "address": "string",
  "address2": "string",
  "city": "string",
  "state": "string",
  "country": "string",
  "postalCode": "string",
  "timezone": "string",
  "gallonsPerDayGoal": 0,
  "occupants": 0,
  "stories": 0,
  "isProfileComplete": true,
  "waterShutoffKnown": "no",
  "indoorAmenities": [
    "string"
  ],
  "outdoorAmenities": [
    "string"
  ],
  "plumbingAppliances": [
    "string"
  ],
  "locationType": "sfh",
  "residenceType": "primary",
  "waterSource": "utility",
  "locationSize": "lte_700",
  "showerBathCount": 0,
  "toiletCount": 0,
  "plumbingType": "copper",
  "waterUtility": "string",
  "homeownersInsurance": "string",
  "hasPastWaterDamage": true,
  "pastWaterDamageClaimAmount": "lte_10k_usd"
 */
abstract class LocationPayload implements Built<LocationPayload, LocationPayloadBuilder> {
  LocationPayload._();

  factory LocationPayload([updates(LocationPayloadBuilder b)]) = _$LocationPayload;

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
  int get gallonsPerDayGoal;
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
  String get waterShutoffKnown;
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
  String get locationType;
  @nullable
  @BuiltValueField(wireName: 'residenceType')
  String get residenceType;
  @nullable
  @BuiltValueField(wireName: 'waterSource')
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
  @nullable
  @BuiltValueField(wireName: 'homeownersInsurance')
  String get homeownersInsurance;
  @nullable
  @BuiltValueField(wireName: 'hasPastWaterDamage')
  bool get hasPastWaterDamage;
  @nullable
  @BuiltValueField(wireName: 'pastWaterDamageClaimAmount')
  String get pastWaterDamageClaimAmount;
  String toJson() {
    return json.encode(serializers.serializeWith(LocationPayload.serializer, this));
  }

  static LocationPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        LocationPayload.serializer, json.decode(jsonString));
  }

  static Serializer<LocationPayload> get serializer => _$locationPayloadSerializer;

  static LocationPayload get empty {
    return LocationPayload((b) => b
    ..address = ""
    ..city = ""
    );
  }
}