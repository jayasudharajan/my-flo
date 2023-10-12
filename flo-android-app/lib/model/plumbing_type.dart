library plumbing_type;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plumbing_type.g.dart';

@BuiltValueEnum(wireName: 'plumbingType')
class PlumbingType extends EnumClass {
  
  static Serializer<PlumbingType> get serializer => _$plumbingTypeSerializer;

  @BuiltValueEnumConst(wireName: 'copper')
  static const PlumbingType copper = _$wireCopper;

  @BuiltValueEnumConst(wireName: 'galvanized')
  static const PlumbingType galvanized = _$wireGalvanized;

  @BuiltValueEnumConst(wireName: 'unsure')
  static const PlumbingType unsure = _$wireUnsure;


  const PlumbingType._(String name) : super(name);

  static BuiltSet<PlumbingType> get values => _$wireValues;
  static PlumbingType valueOf(String name) => _$wireValueOf(name);

  static const String COPPER = "copper";
  static const String GALVANIZED = "galvanized";
  static const String UNSURE = "unsure";
}