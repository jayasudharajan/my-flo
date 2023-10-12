library flo_detect_events;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'flo_detect_event.dart';
import 'serializers.dart';

part 'flo_detect_events.g.dart';

abstract class FloDetectEvents
    implements Built<FloDetectEvents, FloDetectEventsBuilder> {
  FloDetectEvents._();

  factory FloDetectEvents([updates(FloDetectEventsBuilder b)]) =
  _$FloDetectEvents;

  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<FloDetectEvent> get items;

  @nullable
  @BuiltValueField(serialize: false)
  String get fixture => items.first.fixture;

  @nullable
  @BuiltValueField(serialize: false)
  double get flow => items.map((it) => it.flow).reduce((that, it) => that + it);

  @nullable
  @BuiltValueField(serialize: false)
  double get gpm => items.map((it) => it.gpm).reduce((that, it) => that + it);

  String toJson() {
    return json
        .encode(serializers.serializeWith(FloDetectEvents.serializer, this));
  }

  static FloDetectEvents fromJson(String jsonString) {
    return serializers.deserializeWith(
        FloDetectEvents.serializer, json.decode(jsonString));
  }

  static Serializer<FloDetectEvents> get serializer =>
      _$floDetectEventsSerializer;

  FloDetectEvents operator +(FloDetectEvents it) {
    if (it == null) return this;
    return rebuild((b) =>
    b
      ..items = ListBuilder((items?.toList() ?? <FloDetectEvent>[]) +
          (it?.items?.toList() ?? <FloDetectEvent>[]))
    );
  }
}
