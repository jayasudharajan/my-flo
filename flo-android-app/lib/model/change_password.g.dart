// GENERATED CODE - DO NOT MODIFY BY HAND

part of change_password;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ChangePassword> _$changePasswordSerializer =
    new _$ChangePasswordSerializer();

class _$ChangePasswordSerializer
    implements StructuredSerializer<ChangePassword> {
  @override
  final Iterable<Type> types = const [ChangePassword, _$ChangePassword];
  @override
  final String wireName = 'ChangePassword';

  @override
  Iterable<Object> serialize(Serializers serializers, ChangePassword object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'oldPassword',
      serializers.serialize(object.oldPassword,
          specifiedType: const FullType(String)),
      'newPassword',
      serializers.serialize(object.newPassword,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ChangePassword deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ChangePasswordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'oldPassword':
          result.oldPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'newPassword':
          result.newPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ChangePassword extends ChangePassword {
  @override
  final String oldPassword;
  @override
  final String newPassword;

  factory _$ChangePassword([void Function(ChangePasswordBuilder) updates]) =>
      (new ChangePasswordBuilder()..update(updates)).build();

  _$ChangePassword._({this.oldPassword, this.newPassword}) : super._() {
    if (oldPassword == null) {
      throw new BuiltValueNullFieldError('ChangePassword', 'oldPassword');
    }
    if (newPassword == null) {
      throw new BuiltValueNullFieldError('ChangePassword', 'newPassword');
    }
  }

  @override
  ChangePassword rebuild(void Function(ChangePasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChangePasswordBuilder toBuilder() =>
      new ChangePasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChangePassword &&
        oldPassword == other.oldPassword &&
        newPassword == other.newPassword;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, oldPassword.hashCode), newPassword.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ChangePassword')
          ..add('oldPassword', oldPassword)
          ..add('newPassword', newPassword))
        .toString();
  }
}

class ChangePasswordBuilder
    implements Builder<ChangePassword, ChangePasswordBuilder> {
  _$ChangePassword _$v;

  String _oldPassword;
  String get oldPassword => _$this._oldPassword;
  set oldPassword(String oldPassword) => _$this._oldPassword = oldPassword;

  String _newPassword;
  String get newPassword => _$this._newPassword;
  set newPassword(String newPassword) => _$this._newPassword = newPassword;

  ChangePasswordBuilder();

  ChangePasswordBuilder get _$this {
    if (_$v != null) {
      _oldPassword = _$v.oldPassword;
      _newPassword = _$v.newPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChangePassword other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ChangePassword;
  }

  @override
  void update(void Function(ChangePasswordBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ChangePassword build() {
    final _$result = _$v ??
        new _$ChangePassword._(
            oldPassword: oldPassword, newPassword: newPassword);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
