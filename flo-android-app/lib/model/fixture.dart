library fixture;

import 'dart:convert';
import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flotechnologies/generated/i18n.dart';
import 'package:flutter/material.dart' as material;
import 'serializers.dart';

part 'fixture.g.dart';

abstract class Fixture implements Built<Fixture, FixtureBuilder> {
  Fixture._();

  factory Fixture([updates(FixtureBuilder b)]) = _$Fixture;

  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  @nullable
  @BuiltValueField(wireName: 'index')
  int get index;
  @nullable
  @BuiltValueField(wireName: 'type')
  int get type;
  @nullable
  @BuiltValueField(wireName: 'gallons')
  double get gallons;
  @nullable
  @BuiltValueField(wireName: 'ratio')
  double get ratio;
  @nullable
  @BuiltValueField(wireName: 'numEvents')
  int get numEvents;
  String toJson() {
    return json.encode(serializers.serializeWith(Fixture.serializer, this));
  }

  static Fixture fromJson(String jsonString) {
    return serializers.deserializeWith(
        Fixture.serializer, json.decode(jsonString));
  }

  static Serializer<Fixture> get serializer => _$fixtureSerializer;

  /// Names
  static const String TOILET = "toilet";
  static const String SHOWER = "shower";
  static const String SHOWER_BATH = "shower/bath";
  static const String FAUCET = "faucet";
  static const String APPLIANCE = "appliance";
  static const String POOL = "pool";
  static const String IRRIGATION = "irrigation";
  static const String OTHER = "other";

  /* v1
  static const TYPE_SHOWER = 1;
  static const TYPE_TOILET = 2;
  static const TYPE_APPLIANCE = 3;
  static const TYPE_FAUCET = 4;
  static const TYPE_OTHER = 5;
  static const TYPE_IRRIGATION = 6;
  static const TYPE_POOL = 7;
  */

  /// Types
  static const TYPE_SHOWER = 0;
  static const TYPE_TOILET = 1;
  static const TYPE_APPLIANCE = 2;
  static const TYPE_FAUCET = 3;
  static const TYPE_OTHER = 4;
  static const TYPE_IRRIGATION = 5;
  static const TYPE_POOL = 6;

  /// Name Set
  static const Set<String> FIXTURES = {TOILET, SHOWER_BATH, FAUCET, APPLIANCE, POOL, IRRIGATION, OTHER};

  /// Type Set
  static const Set<int> FIXTURE_TYPES = const {...FIXTURE_TYPES_NO_OTHER, TYPE_OTHER};
  static const Set<int> FIXTURE_TYPES_NO_OTHER = {TYPE_TOILET, TYPE_SHOWER, TYPE_FAUCET, TYPE_APPLIANCE, TYPE_POOL, TYPE_IRRIGATION};

  /*
  static const Map<int, String> FIXTURE_MAP = {
    TYPE_TOILET: TOILET,
    TYPE_SHOWER: SHOWER,
    TYPE_FAUCET: FAUCET,
    TYPE_APPLIANCE: APPLIANCE,
    TYPE_POOL: POOL,
    TYPE_IRRIGATION: IRRIGATION,
    TYPE_OTHER: OTHER,
  };
  */
  static int typeBy(String key) {
    switch (key) {
      case TOILET: return TYPE_TOILET;
      case SHOWER: return TYPE_SHOWER;
      case SHOWER_BATH: return TYPE_SHOWER;
      case FAUCET: return TYPE_FAUCET;
      case APPLIANCE: return TYPE_APPLIANCE;
      case POOL: return TYPE_POOL;
      case IRRIGATION: return TYPE_IRRIGATION;
      case OTHER: return TYPE_OTHER;
    }
    return TYPE_OTHER;
  }

  // FIXME: Map?
  static String nameBy(int type) {
    switch (type) {
      case TYPE_TOILET: return TOILET;
      case TYPE_SHOWER: return SHOWER_BATH;
      case TYPE_FAUCET: return FAUCET;
      case TYPE_APPLIANCE: return APPLIANCE;
      case TYPE_POOL: return POOL;
      case TYPE_IRRIGATION: return IRRIGATION;
      case TYPE_OTHER: return OTHER;
    }
    return OTHER;
  }

  String display(material.BuildContext context) {
    return displayBy(context, type);
  }

  static String displayByName(material.BuildContext context, String name) {
    return displayBy(context, typeBy(name));
  }

  // FIXME: Map?
  static String displayBy(material.BuildContext context, int type) {
    switch (type) {
      case TYPE_TOILET: return S.of(context).toilet;
      case TYPE_SHOWER: return S.of(context).shower_bath;
      case TYPE_FAUCET: return S.of(context).faucet;
      case TYPE_APPLIANCE: return S.of(context).appliance;
      case TYPE_POOL: return S.of(context).pool_hot_tub;
      case TYPE_IRRIGATION: return S.of(context).irrigation;
      case TYPE_OTHER: return S.of(context).other_;
    }
    return S.of(context).other_;
  }

  Fixture operator+(Fixture it) => it.type == type ? rebuild((b) => b
    ..gallons = (gallons ?? 0) + (it.gallons ?? 0)
    ..numEvents = (numEvents ?? 0) + (it.numEvents ?? 0)
    ..ratio = (ratio ?? 0) + (it.ratio ?? 0) /// you have to count the factor outside and divide by it
  ) : this;
}
