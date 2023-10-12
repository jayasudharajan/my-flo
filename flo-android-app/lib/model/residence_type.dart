library residence_type;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'residence_type.g.dart';

@BuiltValueEnum(wireName: 'residenceType')
class ResidenceType extends EnumClass {
  
  static Serializer<ResidenceType> get serializer => _$residenceTypeSerializer;

  @BuiltValueEnumConst(wireName: 'primary')
  static const ResidenceType primary = _$wirePrimary;

  @BuiltValueEnumConst(wireName: 'rental')
  static const ResidenceType rental = _$wireRental;

  @BuiltValueEnumConst(wireName: 'vacation')
  static const ResidenceType vacation = _$wireVacation;

  @BuiltValueEnumConst(wireName: 'other')
  static const ResidenceType other = _$wireOther;

  const ResidenceType._(String name) : super(name);

  static BuiltSet<ResidenceType> get values => _$wireValues;
  static ResidenceType valueOf(String name) => _$wireValueOf(name);

  static const String PRIMARY = "primary";
  static const String RENTAL = "rental";
  static const String VACATION = "vacation";
  static const String OTHER = "other";
}