library name;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'name.g.dart';

abstract class Name implements Built<Name, NameBuilder> {
  Name._();

  factory Name([updates(NameBuilder b)]) = _$Name;

  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  String toJson() {
    return json.encode(serializers.serializeWith(Name.serializer, this));
  }

  static Name fromJson(String jsonString) {
    return serializers.deserializeWith(
        Name.serializer, json.decode(jsonString));
  }

  static Serializer<Name> get serializer => _$nameSerializer;
}
