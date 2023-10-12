// GENERATED CODE - DO NOT MODIFY BY HAND

part of user_role;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserRole> _$userRoleSerializer = new _$UserRoleSerializer();

class _$UserRoleSerializer implements StructuredSerializer<UserRole> {
  @override
  final Iterable<Type> types = const [UserRole, _$UserRole];
  @override
  final String wireName = 'UserRole';

  @override
  Iterable<Object> serialize(Serializers serializers, UserRole object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'userId',
      serializers.serialize(object.userId,
          specifiedType: const FullType(String)),
      'roles',
      serializers.serialize(object.roles,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
    ];

    return result;
  }

  @override
  UserRole deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserRoleBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'userId':
          result.userId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'roles':
          result.roles.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$UserRole extends UserRole {
  @override
  final String userId;
  @override
  final BuiltList<String> roles;

  factory _$UserRole([void Function(UserRoleBuilder) updates]) =>
      (new UserRoleBuilder()..update(updates)).build();

  _$UserRole._({this.userId, this.roles}) : super._() {
    if (userId == null) {
      throw new BuiltValueNullFieldError('UserRole', 'userId');
    }
    if (roles == null) {
      throw new BuiltValueNullFieldError('UserRole', 'roles');
    }
  }

  @override
  UserRole rebuild(void Function(UserRoleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserRoleBuilder toBuilder() => new UserRoleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserRole && userId == other.userId && roles == other.roles;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, userId.hashCode), roles.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserRole')
          ..add('userId', userId)
          ..add('roles', roles))
        .toString();
  }
}

class UserRoleBuilder implements Builder<UserRole, UserRoleBuilder> {
  _$UserRole _$v;

  String _userId;
  String get userId => _$this._userId;
  set userId(String userId) => _$this._userId = userId;

  ListBuilder<String> _roles;
  ListBuilder<String> get roles => _$this._roles ??= new ListBuilder<String>();
  set roles(ListBuilder<String> roles) => _$this._roles = roles;

  UserRoleBuilder();

  UserRoleBuilder get _$this {
    if (_$v != null) {
      _userId = _$v.userId;
      _roles = _$v.roles?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserRole other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$UserRole;
  }

  @override
  void update(void Function(UserRoleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserRole build() {
    _$UserRole _$result;
    try {
      _$result = _$v ?? new _$UserRole._(userId: userId, roles: roles.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'UserRole', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
