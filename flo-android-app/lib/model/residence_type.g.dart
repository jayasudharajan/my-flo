// GENERATED CODE - DO NOT MODIFY BY HAND

part of residence_type;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ResidenceType _$wirePrimary = const ResidenceType._('primary');
const ResidenceType _$wireRental = const ResidenceType._('rental');
const ResidenceType _$wireVacation = const ResidenceType._('vacation');
const ResidenceType _$wireOther = const ResidenceType._('other');

ResidenceType _$wireValueOf(String name) {
  switch (name) {
    case 'primary':
      return _$wirePrimary;
    case 'rental':
      return _$wireRental;
    case 'vacation':
      return _$wireVacation;
    case 'other':
      return _$wireOther;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<ResidenceType> _$wireValues =
    new BuiltSet<ResidenceType>(const <ResidenceType>[
  _$wirePrimary,
  _$wireRental,
  _$wireVacation,
  _$wireOther,
]);

Serializer<ResidenceType> _$residenceTypeSerializer =
    new _$ResidenceTypeSerializer();

class _$ResidenceTypeSerializer implements PrimitiveSerializer<ResidenceType> {
  static const Map<String, String> _toWire = const <String, String>{
    'primary': 'primary',
    'rental': 'rental',
    'vacation': 'vacation',
    'other': 'other',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'primary': 'primary',
    'rental': 'rental',
    'vacation': 'vacation',
    'other': 'other',
  };

  @override
  final Iterable<Type> types = const <Type>[ResidenceType];
  @override
  final String wireName = 'residenceType';

  @override
  Object serialize(Serializers serializers, ResidenceType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ResidenceType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ResidenceType.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
