// GENERATED CODE - DO NOT MODIFY BY HAND

part of account_role;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AccountRole> _$accountRoleSerializer = new _$AccountRoleSerializer();

class _$AccountRoleSerializer implements StructuredSerializer<AccountRole> {
  @override
  final Iterable<Type> types = const [AccountRole, _$AccountRole];
  @override
  final String wireName = 'AccountRole';

  @override
  Iterable<Object> serialize(Serializers serializers, AccountRole object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'accountId',
      serializers.serialize(object.accountId,
          specifiedType: const FullType(String)),
    ];
    if (object.roles != null) {
      result
        ..add('roles')
        ..add(serializers.serialize(object.roles,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    return result;
  }

  @override
  AccountRole deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AccountRoleBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'accountId':
          result.accountId = serializers.deserialize(value,
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

class _$AccountRole extends AccountRole {
  @override
  final String accountId;
  @override
  final BuiltList<String> roles;

  factory _$AccountRole([void Function(AccountRoleBuilder) updates]) =>
      (new AccountRoleBuilder()..update(updates)).build();

  _$AccountRole._({this.accountId, this.roles}) : super._() {
    if (accountId == null) {
      throw new BuiltValueNullFieldError('AccountRole', 'accountId');
    }
  }

  @override
  AccountRole rebuild(void Function(AccountRoleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AccountRoleBuilder toBuilder() => new AccountRoleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AccountRole &&
        accountId == other.accountId &&
        roles == other.roles;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, accountId.hashCode), roles.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AccountRole')
          ..add('accountId', accountId)
          ..add('roles', roles))
        .toString();
  }
}

class AccountRoleBuilder implements Builder<AccountRole, AccountRoleBuilder> {
  _$AccountRole _$v;

  String _accountId;
  String get accountId => _$this._accountId;
  set accountId(String accountId) => _$this._accountId = accountId;

  ListBuilder<String> _roles;
  ListBuilder<String> get roles => _$this._roles ??= new ListBuilder<String>();
  set roles(ListBuilder<String> roles) => _$this._roles = roles;

  AccountRoleBuilder();

  AccountRoleBuilder get _$this {
    if (_$v != null) {
      _accountId = _$v.accountId;
      _roles = _$v.roles?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AccountRole other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AccountRole;
  }

  @override
  void update(void Function(AccountRoleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AccountRole build() {
    _$AccountRole _$result;
    try {
      _$result = _$v ??
          new _$AccountRole._(accountId: accountId, roles: _roles?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'roles';
        _roles?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AccountRole', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
