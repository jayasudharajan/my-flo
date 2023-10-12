// GENERATED CODE - DO NOT MODIFY BY HAND

part of location_type;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const LocationType _$wireSingleFamilyHouse =
    const LocationType._('singleFamilyHouse');
const LocationType _$wireApartment = const LocationType._('apartment');
const LocationType _$wireCondo = const LocationType._('condo');
const LocationType _$wireOther = const LocationType._('other');

LocationType _$wireValueOf(String name) {
  switch (name) {
    case 'singleFamilyHouse':
      return _$wireSingleFamilyHouse;
    case 'apartment':
      return _$wireApartment;
    case 'condo':
      return _$wireCondo;
    case 'other':
      return _$wireOther;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<LocationType> _$wireValues =
    new BuiltSet<LocationType>(const <LocationType>[
  _$wireSingleFamilyHouse,
  _$wireApartment,
  _$wireCondo,
  _$wireOther,
]);

Serializer<LocationType> _$locationTypeSerializer =
    new _$LocationTypeSerializer();

class _$LocationTypeSerializer implements PrimitiveSerializer<LocationType> {
  static const Map<String, String> _toWire = const <String, String>{
    'singleFamilyHouse': 'sfh',
    'apartment': 'apartment',
    'condo': 'condo',
    'other': 'other',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'sfh': 'singleFamilyHouse',
    'apartment': 'apartment',
    'condo': 'condo',
    'other': 'other',
  };

  @override
  final Iterable<Type> types = const <Type>[LocationType];
  @override
  final String wireName = 'locationType';

  @override
  Object serialize(Serializers serializers, LocationType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  LocationType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      LocationType.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
