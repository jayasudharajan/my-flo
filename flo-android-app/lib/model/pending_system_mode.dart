library pending_system_mode;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'system_mode.dart';

part 'pending_system_mode.g.dart';

abstract class PendingSystemMode implements Built<PendingSystemMode, PendingSystemModeBuilder> {
  PendingSystemMode._();

  factory PendingSystemMode([updates(PendingSystemModeBuilder b)]) = _$PendingSystemMode;

  @nullable
  @BuiltValueField(wireName: 'target')
  String get target;
  @nullable
  @BuiltValueField(wireName: 'shouldInherit')
  bool get shouldInherit;
  @nullable
  @BuiltValueField(wireName: 'revertMinutes')
  int get revertMinutes;
  @nullable
  @BuiltValueField(wireName: 'revertMode')
  String get revertMode;
  @nullable
  @BuiltValueField(wireName: 'revertScheduledAt')
  String get revertScheduledAt;

  @nullable
  @BuiltValueField(wireName: 'isLocked')
  bool get isLocked;
  @nullable
  @BuiltValueField(wireName: 'lastKnown')
  String get lastKnown;

  String toJson() {
    return json.encode(serializers.serializeWith(PendingSystemMode.serializer, this));
  }

  static PendingSystemMode fromJson(String jsonString) {
    return serializers.deserializeWith(
        PendingSystemMode.serializer, json.decode(jsonString));
  }

  static Serializer<PendingSystemMode> get serializer => _$pendingSystemModeSerializer;

  static PendingSystemMode get empty => PendingSystemMode((b) => b
  ..target = ""
  ..shouldInherit = true
  ..revertMinutes = 0
  ..revertMode = ""
  ..revertScheduledAt = ""
  );

  @deprecated
  bool get learning => isLearning;

  bool get isLearning => (target ?? lastKnown ?? SystemMode.SLEEP) == SystemMode.SLEEP && (isLocked ?? false);
}