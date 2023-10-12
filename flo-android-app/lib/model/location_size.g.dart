// GENERATED CODE - DO NOT MODIFY BY HAND

part of location_size;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const LocationSize _$wireLte700 = const LocationSize._('lte_700');
const LocationSize _$wireGt_700_ft_lte_1000_ft =
    const LocationSize._('gt_700_ft_lte_1000_ft');
const LocationSize _$wireGt_1000_ft_lte_2000_ft =
    const LocationSize._('gt_1000_ft_lte_2000_ft');
const LocationSize _$wireGt_2000_ft_lte_4000_ft =
    const LocationSize._('gt_2000_ft_lte_4000_ft');
const LocationSize _$wireGt_4000_ft = const LocationSize._('gt_4000_ft');

LocationSize _$wireValueOf(String name) {
  switch (name) {
    case 'lte_700':
      return _$wireLte700;
    case 'gt_700_ft_lte_1000_ft':
      return _$wireGt_700_ft_lte_1000_ft;
    case 'gt_1000_ft_lte_2000_ft':
      return _$wireGt_1000_ft_lte_2000_ft;
    case 'gt_2000_ft_lte_4000_ft':
      return _$wireGt_2000_ft_lte_4000_ft;
    case 'gt_4000_ft':
      return _$wireGt_4000_ft;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<LocationSize> _$wireValues =
    new BuiltSet<LocationSize>(const <LocationSize>[
  _$wireLte700,
  _$wireGt_700_ft_lte_1000_ft,
  _$wireGt_1000_ft_lte_2000_ft,
  _$wireGt_2000_ft_lte_4000_ft,
  _$wireGt_4000_ft,
]);

Serializer<LocationSize> _$locationSizeSerializer =
    new _$LocationSizeSerializer();

class _$LocationSizeSerializer implements PrimitiveSerializer<LocationSize> {
  static const Map<String, String> _toWire = const <String, String>{
    'lte_700': 'lte_700',
    'gt_700_ft_lte_1000_ft': 'gt_700_ft_lte_1000_ft',
    'gt_1000_ft_lte_2000_ft': 'gt_1000_ft_lte_2000_ft',
    'gt_2000_ft_lte_4000_ft': 'gt_2000_ft_lte_4000_ft',
    'gt_4000_ft': 'gt_4000_ft',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'lte_700': 'lte_700',
    'gt_700_ft_lte_1000_ft': 'gt_700_ft_lte_1000_ft',
    'gt_1000_ft_lte_2000_ft': 'gt_1000_ft_lte_2000_ft',
    'gt_2000_ft_lte_4000_ft': 'gt_2000_ft_lte_4000_ft',
    'gt_4000_ft': 'gt_4000_ft',
  };

  @override
  final Iterable<Type> types = const <Type>[LocationSize];
  @override
  final String wireName = 'locationSize';

  @override
  Object serialize(Serializers serializers, LocationSize object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  LocationSize deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      LocationSize.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
