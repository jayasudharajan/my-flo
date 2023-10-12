library system_mode;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'system_mode.g.dart';

@BuiltValueEnum(wireName: 'systemMode')
class SystemMode extends EnumClass {
  
  static Serializer<SystemMode> get serializer => _$systemModeSerializer;

  @BuiltValueEnumConst(wireName: 'home')
  static const SystemMode home = _$wireHome;

  @BuiltValueEnumConst(wireName: 'away')
  static const SystemMode away = _$wireAway;

  @BuiltValueEnumConst(wireName: 'sleep')
  static const SystemMode sleep = _$wireSleep;

  const SystemMode._(String name) : super(name);

  static BuiltSet<SystemMode> get values => _$wireValues;
  static SystemMode valueOf(String name) => _$wireValueOf(name);

  static const HOME = "home";
  static const SLEEP = "sleep";
  static const AWAY = "away";
}