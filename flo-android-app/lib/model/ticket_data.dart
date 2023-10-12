library ticket_data;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'ticket_data.g.dart';

abstract class TicketData implements Built<TicketData, TicketDataBuilder> {
  TicketData._();

  factory TicketData([updates(TicketDataBuilder b)]) = _$TicketData;

  @BuiltValueField(wireName: 'i')
  String get id;
  @BuiltValueField(wireName: 'e')
  String get encryptCode;
  String toJson() {
    return json.encode(serializers.serializeWith(TicketData.serializer, this));
  }

  static TicketData fromJson(String jsonString) {
    return serializers.deserializeWith(
        TicketData.serializer, json.decode(jsonString));
  }

  static Serializer<TicketData> get serializer => _$ticketDataSerializer;

  static TicketData get empty => TicketData((b) => b
  ..id = ""
  ..encryptCode = ""
  );
}
