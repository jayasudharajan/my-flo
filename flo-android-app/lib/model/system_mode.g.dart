// GENERATED CODE - DO NOT MODIFY BY HAND

part of system_mode;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SystemMode _$wireHome = const SystemMode._('home');
const SystemMode _$wireAway = const SystemMode._('away');
const SystemMode _$wireSleep = const SystemMode._('sleep');

SystemMode _$wireValueOf(String name) {
  switch (name) {
    case 'home':
      return _$wireHome;
    case 'away':
      return _$wireAway;
    case 'sleep':
      return _$wireSleep;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<SystemMode> _$wireValues =
    new BuiltSet<SystemMode>(const <SystemMode>[
  _$wireHome,
  _$wireAway,
  _$wireSleep,
]);

Serializer<SystemMode> _$systemModeSerializer = new _$SystemModeSerializer();

class _$SystemModeSerializer implements PrimitiveSerializer<SystemMode> {
  static const Map<String, String> _toWire = const <String, String>{
    'home': 'home',
    'away': 'away',
    'sleep': 'sleep',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'home': 'home',
    'away': 'away',
    'sleep': 'sleep',
  };

  @override
  final Iterable<Type> types = const <Type>[SystemMode];
  @override
  final String wireName = 'systemMode';

  @override
  Object serialize(Serializers serializers, SystemMode object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  SystemMode deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      SystemMode.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
