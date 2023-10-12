// GENERATED CODE - DO NOT MODIFY BY HAND

part of location_role;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<LocationRole> _$locationRoleSerializer =
    new _$LocationRoleSerializer();

class _$LocationRoleSerializer implements StructuredSerializer<LocationRole> {
  @override
  final Iterable<Type> types = const [LocationRole, _$LocationRole];
  @override
  final String wireName = 'LocationRole';

  @override
  Iterable<Object> serialize(Serializers serializers, LocationRole object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'locationId',
      serializers.serialize(object.locationId,
          specifiedType: const FullType(String)),
      'role',
      serializers.serialize(object.role,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
    ];

    return result;
  }

  @override
  LocationRole deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LocationRoleBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'locationId':
          result.locationId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'role':
          result.role.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$LocationRole extends LocationRole {
  @override
  final String locationId;
  @override
  final BuiltList<String> role;

  factory _$LocationRole([void Function(LocationRoleBuilder) updates]) =>
      (new LocationRoleBuilder()..update(updates)).build();

  _$LocationRole._({this.locationId, this.role}) : super._() {
    if (locationId == null) {
      throw new BuiltValueNullFieldError('LocationRole', 'locationId');
    }
    if (role == null) {
      throw new BuiltValueNullFieldError('LocationRole', 'role');
    }
  }

  @override
  LocationRole rebuild(void Function(LocationRoleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LocationRoleBuilder toBuilder() => new LocationRoleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LocationRole &&
        locationId == other.locationId &&
        role == other.role;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, locationId.hashCode), role.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LocationRole')
          ..add('locationId', locationId)
          ..add('role', role))
        .toString();
  }
}

class LocationRoleBuilder
    implements Builder<LocationRole, LocationRoleBuilder> {
  _$LocationRole _$v;

  String _locationId;
  String get locationId => _$this._locationId;
  set locationId(String locationId) => _$this._locationId = locationId;

  ListBuilder<String> _role;
  ListBuilder<String> get role => _$this._role ??= new ListBuilder<String>();
  set role(ListBuilder<String> role) => _$this._role = role;

  LocationRoleBuilder();

  LocationRoleBuilder get _$this {
    if (_$v != null) {
      _locationId = _$v.locationId;
      _role = _$v.role?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LocationRole other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LocationRole;
  }

  @override
  void update(void Function(LocationRoleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LocationRole build() {
    _$LocationRole _$result;
    try {
      _$result = _$v ??
          new _$LocationRole._(locationId: locationId, role: role.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'role';
        role.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'LocationRole', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
