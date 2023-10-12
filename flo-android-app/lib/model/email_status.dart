library email_status;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'email_status.g.dart';

abstract class EmailStatus
    implements Built<EmailStatus, EmailStatusBuilder> {
  EmailStatus._();

  factory EmailStatus([updates(EmailStatusBuilder b)]) = _$EmailStatus;

  @BuiltValueField(wireName: 'is_registered')
  bool get isRegistered;
  @BuiltValueField(wireName: 'is_pending')
  bool get isPending;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(EmailStatus.serializer, this));
  }

  static EmailStatus fromJson(String jsonString) {
    return serializers.deserializeWith(
        EmailStatus.serializer, json.decode(jsonString));
  }

  static Serializer<EmailStatus> get serializer => _$emailStatusSerializer;
}
