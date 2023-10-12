library amenity;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'amenity.g.dart';


@BuiltValueEnum(wireName: 'amenity')
class Amenity extends EnumClass {
  
  static Serializer<Amenity> get serializer => _$amenitySerializer;

  @BuiltValueEnumConst(wireName: 'bathtub')
  static const Amenity bathtub = _$wireBathtub;
  @deprecated
  @BuiltValueEnumConst(wireName: 'bath_tub')
  static const Amenity bathTub = _$wireBathTub;
  @BuiltValueEnumConst(wireName: 'dishwasher')
  static const Amenity dishwasher = _$wireDishwasher;
  @BuiltValueEnumConst(wireName: 'expansion_tank')
  static const Amenity expansionTank = _$wireExpansionTank;
  @BuiltValueEnumConst(wireName: 'fountain')
  static const Amenity fountain = _$wireFountain;
  @BuiltValueEnumConst(wireName: 'hottub')
  static const Amenity hottub = _$wireHottub;
  @deprecated
  @BuiltValueEnumConst(wireName: 'hot_tub')
  static const Amenity hotTub = _$wireHotTub;
  @BuiltValueEnumConst(wireName: 'ice_maker')
  static const Amenity iceMaker = _$wireIceMaker;
  @BuiltValueEnumConst(wireName: 'pool')
  static const Amenity pool = _$wirePool;
  @BuiltValueEnumConst(wireName: 'recirculation_pump')
  static const Amenity recirculationPump = _$wireRecirculationPump;
  @BuiltValueEnumConst(wireName: 'tankless_water_heater')
  static const Amenity tanklessWaterHeater = _$wireTanklessWaterHeater;
  @BuiltValueEnumConst(wireName: 'washing_machine')
  static const Amenity washingMachine = _$wireWashingMachine;
  @BuiltValueEnumConst(wireName: 'whole_home_filtration')
  static const Amenity wholeHomeFiltration = _$wireWholeHomeFiltration;
  @BuiltValueEnumConst(wireName: 'whole_home_humidifer')
  static const Amenity wholeHomeHumidifer = _$wireWholeHomeHumidifer;
  @BuiltValueEnumConst(wireName: 'sprinklers')
  static const Amenity sprinklers = _$wireSprinklers;
  @BuiltValueEnumConst(wireName: 'galvanized_plumbing')
  static const Amenity galvanizedPlumbing = _$wireGalvanizedPlumbing;

  @BuiltValueEnumConst(wireName: 'pond')
  static const Amenity pond = _$wirePond;
  @BuiltValueEnumConst(wireName: 'pool_with_auto_pool_filter')
  static const Amenity poolWithAutoPoolFilter = _$wirePoolWithAutoPoolFilter;
  @BuiltValueEnumConst(wireName: 'reverse_osmosis')
  static const Amenity reverseOsmosis = _$wireReverseOsmosis;
  @BuiltValueEnumConst(wireName: 'water_softener')
  static const Amenity waterSoftener = _$wireWaterSoftener;
  @BuiltValueEnumConst(wireName: 'pressure_reducing_valve')
  static const Amenity pressureReducingValve = _$wirePressureReducingValve;

  const Amenity._(String name) : super(name);

  static BuiltSet<Amenity> get values => _$wireValues;
  static Amenity valueOf(String name) => _$wireValueOf(name);
}

class Amenities {
  
  static const String bathtub = 'bathtub';
  @deprecated
  static const String bathTub = 'bath_tub';
  static const String dishwasher = 'dishwasher';
  static const String expansionTank = 'expansion_tank';
  static const String fountain = 'fountain';
  static const String hottub = 'hottub';
  @deprecated
  static const String hotTub = 'hot_tub';
  static const String iceMaker = 'ice_maker';
  static const String pool = 'pool';
  static const String recirculationPump = 'recirculation_pump';
  static const String tanklessWaterHeater = 'tankless_water_heater';
  static const String washingMachine = 'washing_machine';
  static const String wholeHomeFiltration = 'whole_home_filtration';
  static const String wholeHomeHumidifer = 'whole_home_humidifer';
  static const String sprinklers = 'sprinklers';
  static const String galvanizedPlumbing = 'galvanized_plumbing';

  static const String pond = 'pond';
  //static const String poolWithAutoPoolFilter = 'pool_with_auto_pool_filter';
  static const String poolWithAutoPoolFilter = 'pool_with_auto_pool_filler';
  static const String reverseOsmosis = 'reverse_osmosis';
  static const String waterSoftener = 'water_softener';
  static const String pressureReducingValve = 'pressure_reducing_valve';
}
