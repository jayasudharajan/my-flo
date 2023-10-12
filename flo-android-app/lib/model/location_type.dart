library location_type;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'location_type.g.dart';

@BuiltValueEnum(wireName: 'locationType')
class LocationType extends EnumClass {
  
  static Serializer<LocationType> get serializer => _$locationTypeSerializer;

  @BuiltValueEnumConst(wireName: 'sfh')
  static const LocationType singleFamilyHouse = _$wireSingleFamilyHouse;

  @BuiltValueEnumConst(wireName: 'apartment')
  static const LocationType apartment = _$wireApartment;

  @BuiltValueEnumConst(wireName: 'condo')
  static const LocationType condo = _$wireCondo;

  @BuiltValueEnumConst(wireName: 'other')
  static const LocationType other = _$wireOther;

  const LocationType._(String name) : super(name);

  static BuiltSet<LocationType> get values => _$wireValues;
  static LocationType valueOf(String name) => _$wireValueOf(name);
}