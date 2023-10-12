library water_source;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'water_source.g.dart';

@BuiltValueEnum(wireName: 'waterSource')
class WaterSource extends EnumClass {
  
  static Serializer<WaterSource> get serializer => _$waterSourceSerializer;

  @BuiltValueEnumConst(wireName: 'utility')
  static const WaterSource utility = _$wireUtility;

  @BuiltValueEnumConst(wireName: 'well')
  static const WaterSource well = _$wireWell;

  const WaterSource._(String name) : super(name);

  static BuiltSet<WaterSource> get values => _$wireValues;
  static WaterSource valueOf(String name) => _$wireValueOf(name);
  static const String WELL = "well";
  static const String UTILITY = "utility";
}