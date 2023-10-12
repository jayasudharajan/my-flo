library email_status2;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'email_status2.g.dart';

abstract class EmailStatus2
    implements Built<EmailStatus2, EmailStatus2Builder> {
  EmailStatus2._();

  factory EmailStatus2([updates(EmailStatus2Builder b)]) = _$EmailStatus2;

  @BuiltValueField(wireName: 'isRegistered')
  bool get isRegistered;
  @BuiltValueField(wireName: 'isPending')
  bool get isPending;
  
  String toJson() {
    return json
        .encode(serializers.serializeWith(EmailStatus2.serializer, this));
  }

  static EmailStatus2 fromJson(String jsonString) {
    return serializers.deserializeWith(
        EmailStatus2.serializer, json.decode(jsonString));
  }

  static Serializer<EmailStatus2> get serializer => _$emailStatus2Serializer;
}
