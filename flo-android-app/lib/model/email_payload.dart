library email_payload;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'email_payload.g.dart';

abstract class EmailPayload
    implements Built<EmailPayload, EmailPayloadBuilder> {
  EmailPayload._();

  factory EmailPayload([updates(EmailPayloadBuilder b)]) = _$EmailPayload;

  @BuiltValueField(wireName: 'email')
  String get email;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(EmailPayload.serializer, this));
  }

  static EmailPayload fromJson(String jsonString) {
    return serializers.deserializeWith(
        EmailPayload.serializer, json.decode(jsonString));
  }

  static Serializer<EmailPayload> get serializer => _$emailPayloadSerializer;
}
