library location_size;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'location_size.g.dart';

@BuiltValueEnum(wireName: 'locationSize')
class LocationSize extends EnumClass {
  

  static Serializer<LocationSize> get serializer => _$locationSizeSerializer;

  @BuiltValueEnumConst(wireName: 'lte_700')
  static const LocationSize lte_700 = _$wireLte700;

  @BuiltValueEnumConst(wireName: 'gt_700_ft_lte_1000_ft')
  static const LocationSize gt_700_ft_lte_1000_ft = _$wireGt_700_ft_lte_1000_ft;

  @BuiltValueEnumConst(wireName: 'gt_1000_ft_lte_2000_ft')
  static const LocationSize gt_1000_ft_lte_2000_ft = _$wireGt_1000_ft_lte_2000_ft;

  @BuiltValueEnumConst(wireName: 'gt_2000_ft_lte_4000_ft')
  static const LocationSize gt_2000_ft_lte_4000_ft = _$wireGt_2000_ft_lte_4000_ft;

  @BuiltValueEnumConst(wireName: 'gt_4000_ft')
  static const LocationSize gt_4000_ft = _$wireGt_4000_ft;


  const LocationSize._(String name) : super(name);

  static BuiltSet<LocationSize> get values => _$wireValues;
  static LocationSize valueOf(String name) => _$wireValueOf(name);

  static const String LTE_700 = 'lte_700';
  static const String GT_700_FT_LTE_1000_FT = 'gt_700_ft_lte_1000_ft';
  static const String GT_1000_FT_LTE_2000_FT = 'gt_1000_ft_lte_2000_ft';
  static const String GT_2000_FT_LTE_4000_FT = 'gt_2000_ft_lte_4000_ft';
  static const String GT_4000_FT = 'gt_4000_ft';
}
