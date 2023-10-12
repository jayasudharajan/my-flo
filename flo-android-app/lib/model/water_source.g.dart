// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_source;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WaterSource _$wireUtility = const WaterSource._('utility');
const WaterSource _$wireWell = const WaterSource._('well');

WaterSource _$wireValueOf(String name) {
  switch (name) {
    case 'utility':
      return _$wireUtility;
    case 'well':
      return _$wireWell;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<WaterSource> _$wireValues =
    new BuiltSet<WaterSource>(const <WaterSource>[
  _$wireUtility,
  _$wireWell,
]);

Serializer<WaterSource> _$waterSourceSerializer = new _$WaterSourceSerializer();

class _$WaterSourceSerializer implements PrimitiveSerializer<WaterSource> {
  static const Map<String, String> _toWire = const <String, String>{
    'utility': 'utility',
    'well': 'well',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'utility': 'utility',
    'well': 'well',
  };

  @override
  final Iterable<Type> types = const <Type>[WaterSource];
  @override
  final String wireName = 'waterSource';

  @override
  Object serialize(Serializers serializers, WaterSource object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  WaterSource deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      WaterSource.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
