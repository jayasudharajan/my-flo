// GENERATED CODE - DO NOT MODIFY BY HAND

part of plumbing_type;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlumbingType _$wireCopper = const PlumbingType._('copper');
const PlumbingType _$wireGalvanized = const PlumbingType._('galvanized');
const PlumbingType _$wireUnsure = const PlumbingType._('unsure');

PlumbingType _$wireValueOf(String name) {
  switch (name) {
    case 'copper':
      return _$wireCopper;
    case 'galvanized':
      return _$wireGalvanized;
    case 'unsure':
      return _$wireUnsure;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<PlumbingType> _$wireValues =
    new BuiltSet<PlumbingType>(const <PlumbingType>[
  _$wireCopper,
  _$wireGalvanized,
  _$wireUnsure,
]);

Serializer<PlumbingType> _$plumbingTypeSerializer =
    new _$PlumbingTypeSerializer();

class _$PlumbingTypeSerializer implements PrimitiveSerializer<PlumbingType> {
  static const Map<String, String> _toWire = const <String, String>{
    'copper': 'copper',
    'galvanized': 'galvanized',
    'unsure': 'unsure',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'copper': 'copper',
    'galvanized': 'galvanized',
    'unsure': 'unsure',
  };

  @override
  final Iterable<Type> types = const <Type>[PlumbingType];
  @override
  final String wireName = 'plumbingType';

  @override
  Object serialize(Serializers serializers, PlumbingType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PlumbingType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PlumbingType.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
