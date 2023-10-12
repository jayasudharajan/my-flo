library response_error;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'response_error.g.dart';

abstract class ResponseError
    implements Built<ResponseError, ResponseErrorBuilder> {
  ResponseError._();

  factory ResponseError([updates(ResponseErrorBuilder b)]) = _$ResponseError;

  @BuiltValueField(wireName: 'error')
  bool get error;
  @BuiltValueField(wireName: 'message')
  String get message;
  String toJson() {
    return json
        .encode(serializers.serializeWith(ResponseError.serializer, this));
  }

  static ResponseError fromJson(String jsonString) {
    return serializers.deserializeWith(
        ResponseError.serializer, json.decode(jsonString));
  }

  static Serializer<ResponseError> get serializer => _$responseErrorSerializer;
}
