library ticket2;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'ticket2.g.dart';

abstract class Ticket2 implements Built<Ticket2, Ticket2Builder> {
  Ticket2._();

  factory Ticket2([updates(Ticket2Builder b)]) = _$Ticket2;

  @BuiltValueField(wireName: 'data')
  String get data;
  String toJson() {
    return json.encode(serializers.serializeWith(Ticket2.serializer, this));
  }

  static Ticket2 fromJson(String jsonString) {
    return serializers.deserializeWith(
        Ticket2.serializer, json.decode(jsonString));
  }

  static Serializer<Ticket2> get serializer => _$ticket2Serializer;

  static Ticket2 get empty => Ticket2((b) => b
  ..data = ""
  );
}
