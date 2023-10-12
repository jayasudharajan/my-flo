library location_role;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';

part 'location_role.g.dart';

abstract class LocationRole
    implements Built<LocationRole, LocationRoleBuilder> {
  LocationRole._();

  factory LocationRole([updates(LocationRoleBuilder b)]) = _$LocationRole;

  @BuiltValueField(wireName: 'locationId')
  String get locationId;
  @BuiltValueField(wireName: 'role')
  BuiltList<String> get role;
  String toJson() {
    return json
        .encode(serializers.serializeWith(LocationRole.serializer, this));
  }

  static LocationRole fromJson(String jsonString) {
    return serializers.deserializeWith(
        LocationRole.serializer, json.decode(jsonString));
  }

  static Serializer<LocationRole> get serializer => _$locationRoleSerializer;
}