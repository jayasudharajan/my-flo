library valve;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'serializers.dart';

part 'valve.g.dart';

abstract class Valve implements Built<Valve, ValveBuilder> {
  Valve._();

  factory Valve([updates(ValveBuilder b)]) = _$Valve;

  @nullable
  @BuiltValueField(wireName: 'target')
  String get target;
  @nullable
  @BuiltValueField(wireName: 'lastKnown')
  String get lastKnown;
  String toJson() {
    return json.encode(serializers.serializeWith(Valve.serializer, this));
  }

  static Valve fromJson(String jsonString) {
    return serializers.deserializeWith(
        Valve.serializer, json.decode(jsonString));
  }

  static Serializer<Valve> get serializer => _$valveSerializer;

  static const String OPEN = "open";
  static const String CLOSED = "closed";
  static const String OPENED = "opened";
  static const String CLOSE = "close";
  static const String IN_TRANSITION = "in_transition";
  static const String INTRANSITION = "inTransition";

  bool get open => lastKnown == OPEN || lastKnown == OPENED;
  bool get closed => lastKnown == CLOSE || lastKnown == CLOSED;
  bool get inTransitioned => lastKnown == INTRANSITION || lastKnown == IN_TRANSITION;

  Valve merge(Valve other) {
    return rebuild((b) => b..lastKnown = other?.lastKnown ?? b.lastKnown) ?? other;
  }
}