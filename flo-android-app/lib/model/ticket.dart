library ticket;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'ticket_data.dart';

part 'ticket.g.dart';

abstract class Ticket implements Built<Ticket, TicketBuilder> {
  Ticket._();

  factory Ticket([updates(TicketBuilder b)]) = _$Ticket;

  @BuiltValueField(wireName: 'data')
  TicketData get data;
  String toJson() {
    return json.encode(serializers.serializeWith(Ticket.serializer, this));
  }

  static Ticket fromJson(String jsonString) {
    return serializers.deserializeWith(
        Ticket.serializer, json.decode(jsonString));
  }

  static Serializer<Ticket> get serializer => _$ticketSerializer;

  static Ticket get empty => Ticket((b) => b
  ..data = TicketData.empty.toBuilder()
  );
}
