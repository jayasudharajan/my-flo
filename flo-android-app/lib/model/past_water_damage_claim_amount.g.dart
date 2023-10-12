// GENERATED CODE - DO NOT MODIFY BY HAND

part of past_water_damage_claim_amount;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PastWaterDamageClaimAmount _$wireLte_10k_usd =
    const PastWaterDamageClaimAmount._('lte_10k_usd');
const PastWaterDamageClaimAmount _$wireGt_10k_usd_lte_50k_usd =
    const PastWaterDamageClaimAmount._('gt_10k_usd_lte_50k_usd');
const PastWaterDamageClaimAmount _$wireGt_50k_usd_lte_100k_usd =
    const PastWaterDamageClaimAmount._('gt_50k_usd_lte_100k_usd');
const PastWaterDamageClaimAmount _$wireGt_100K_usd =
    const PastWaterDamageClaimAmount._('gt_100K_usd');

PastWaterDamageClaimAmount _$wireValueOf(String name) {
  switch (name) {
    case 'lte_10k_usd':
      return _$wireLte_10k_usd;
    case 'gt_10k_usd_lte_50k_usd':
      return _$wireGt_10k_usd_lte_50k_usd;
    case 'gt_50k_usd_lte_100k_usd':
      return _$wireGt_50k_usd_lte_100k_usd;
    case 'gt_100K_usd':
      return _$wireGt_100K_usd;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<PastWaterDamageClaimAmount> _$wireValues =
    new BuiltSet<PastWaterDamageClaimAmount>(const <PastWaterDamageClaimAmount>[
  _$wireLte_10k_usd,
  _$wireGt_10k_usd_lte_50k_usd,
  _$wireGt_50k_usd_lte_100k_usd,
  _$wireGt_100K_usd,
]);

Serializer<PastWaterDamageClaimAmount> _$pastWaterDamageClaimAmountSerializer =
    new _$PastWaterDamageClaimAmountSerializer();

class _$PastWaterDamageClaimAmountSerializer
    implements PrimitiveSerializer<PastWaterDamageClaimAmount> {
  static const Map<String, String> _toWire = const <String, String>{
    'lte_10k_usd': 'lte_10k_usd',
    'gt_10k_usd_lte_50k_usd': 'gt_10k_usd_lte_50k_usd',
    'gt_50k_usd_lte_100k_usd': 'gt_50k_usd_lte_100k_usd',
    'gt_100K_usd': 'gt_100K_usd',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'lte_10k_usd': 'lte_10k_usd',
    'gt_10k_usd_lte_50k_usd': 'gt_10k_usd_lte_50k_usd',
    'gt_50k_usd_lte_100k_usd': 'gt_50k_usd_lte_100k_usd',
    'gt_100K_usd': 'gt_100K_usd',
  };

  @override
  final Iterable<Type> types = const <Type>[PastWaterDamageClaimAmount];
  @override
  final String wireName = 'pastWaterDamageClaimAmount';

  @override
  Object serialize(Serializers serializers, PastWaterDamageClaimAmount object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PastWaterDamageClaimAmount deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PastWaterDamageClaimAmount.valueOf(
          _fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
