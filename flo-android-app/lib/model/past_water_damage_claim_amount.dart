library past_water_damage_claim_amount;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'past_water_damage_claim_amount.g.dart';

@BuiltValueEnum(wireName: 'pastWaterDamageClaimAmount')
class PastWaterDamageClaimAmount extends EnumClass {
  
  static Serializer<PastWaterDamageClaimAmount> get serializer => _$pastWaterDamageClaimAmountSerializer;

  @BuiltValueEnumConst(wireName: 'lte_10k_usd')
  static const PastWaterDamageClaimAmount lte_10k_usd = _$wireLte_10k_usd;

  @BuiltValueEnumConst(wireName: 'gt_10k_usd_lte_50k_usd')
  static const PastWaterDamageClaimAmount gt_10k_usd_lte_50k_usd = _$wireGt_10k_usd_lte_50k_usd;

  @BuiltValueEnumConst(wireName: 'gt_50k_usd_lte_100k_usd')
  static const PastWaterDamageClaimAmount gt_50k_usd_lte_100k_usd = _$wireGt_50k_usd_lte_100k_usd;

  @BuiltValueEnumConst(wireName: 'gt_100K_usd')
  static const PastWaterDamageClaimAmount gt_100K_usd = _$wireGt_100K_usd;


  const PastWaterDamageClaimAmount._(String name) : super(name);

  static BuiltSet<PastWaterDamageClaimAmount> get values => _$wireValues;
  static PastWaterDamageClaimAmount valueOf(String name) => _$wireValueOf(name);
}
