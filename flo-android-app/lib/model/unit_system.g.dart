// GENERATED CODE - DO NOT MODIFY BY HAND

part of unit_system;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UnitSystem _$wireImperialUs = const UnitSystem._('imperialUs');
const UnitSystem _$wireMetricKpa = const UnitSystem._('metricKpa');
const UnitSystem _$wireMetricBar = const UnitSystem._('metricBar');

UnitSystem _$wireValueOf(String name) {
  switch (name) {
    case 'imperialUs':
      return _$wireImperialUs;
    case 'metricKpa':
      return _$wireMetricKpa;
    case 'metricBar':
      return _$wireMetricBar;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<UnitSystem> _$wireValues =
    new BuiltSet<UnitSystem>(const <UnitSystem>[
  _$wireImperialUs,
  _$wireMetricKpa,
  _$wireMetricBar,
]);

Serializer<UnitSystem> _$unitSystemSerializer = new _$UnitSystemSerializer();

class _$UnitSystemSerializer implements PrimitiveSerializer<UnitSystem> {
  static const Map<String, String> _toWire = const <String, String>{
    'imperialUs': 'imperial_us',
    'metricKpa': 'metric_kpa',
    'metricBar': 'metric_bar',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'imperial_us': 'imperialUs',
    'metric_kpa': 'metricKpa',
    'metric_bar': 'metricBar',
  };

  @override
  final Iterable<Type> types = const <Type>[UnitSystem];
  @override
  final String wireName = 'unitSystem';

  @override
  Object serialize(Serializers serializers, UnitSystem object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UnitSystem deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UnitSystem.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
