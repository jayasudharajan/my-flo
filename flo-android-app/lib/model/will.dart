library will;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'will.g.dart';

abstract class Will implements Built<Will, WillBuilder> {
  Will._();

  factory Will([updates(WillBuilder b)]) = _$Will;

  @BuiltValueField(wireName: 'status')
  String get status;
  String toJson() {
    return json.encode(serializers.serializeWith(Will.serializer, this));
  }

  static Will fromJson(String jsonString) {
    return serializers.deserializeWith(
        Will.serializer, json.decode(jsonString));
  }

  static Serializer<Will> get serializer => _$willSerializer;
}
