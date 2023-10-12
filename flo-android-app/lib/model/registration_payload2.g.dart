// GENERATED CODE - DO NOT MODIFY BY HAND

part of registration_payload2;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<RegistrationPayload2> _$registrationPayload2Serializer =
    new _$RegistrationPayload2Serializer();

class _$RegistrationPayload2Serializer
    implements StructuredSerializer<RegistrationPayload2> {
  @override
  final Iterable<Type> types = const [
    RegistrationPayload2,
    _$RegistrationPayload2
  ];
  @override
  final String wireName = 'RegistrationPayload2';

  @override
  Iterable<Object> serialize(
      Serializers serializers, RegistrationPayload2 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'email',
      serializers.serialize(object.email,
          specifiedType: const FullType(String)),
      'password',
      serializers.serialize(object.password,
          specifiedType: const FullType(String)),
      'firstName',
      serializers.serialize(object.firstName,
          specifiedType: const FullType(String)),
      'lastName',
      serializers.serialize(object.lastName,
          specifiedType: const FullType(String)),
      'country',
      serializers.serialize(object.country,
          specifiedType: const FullType(String)),
      'phone',
      serializers.serialize(object.phone,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  RegistrationPayload2 deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RegistrationPayload2Builder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'email':
          result.email = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'password':
          result.password = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'firstName':
          result.firstName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'lastName':
          result.lastName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'country':
          result.country = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'phone':
          result.phone = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$RegistrationPayload2 extends RegistrationPayload2 {
  @override
  final String email;
  @override
  final String password;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String country;
  @override
  final String phone;

  factory _$RegistrationPayload2(
          [void Function(RegistrationPayload2Builder) updates]) =>
      (new RegistrationPayload2Builder()..update(updates)).build();

  _$RegistrationPayload2._(
      {this.email,
      this.password,
      this.firstName,
      this.lastName,
      this.country,
      this.phone})
      : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'email');
    }
    if (password == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'password');
    }
    if (firstName == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'firstName');
    }
    if (lastName == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'lastName');
    }
    if (country == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'country');
    }
    if (phone == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload2', 'phone');
    }
  }

  @override
  RegistrationPayload2 rebuild(
          void Function(RegistrationPayload2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegistrationPayload2Builder toBuilder() =>
      new RegistrationPayload2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegistrationPayload2 &&
        email == other.email &&
        password == other.password &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        country == other.country &&
        phone == other.phone;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, email.hashCode), password.hashCode),
                    firstName.hashCode),
                lastName.hashCode),
            country.hashCode),
        phone.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RegistrationPayload2')
          ..add('email', email)
          ..add('password', password)
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('country', country)
          ..add('phone', phone))
        .toString();
  }
}

class RegistrationPayload2Builder
    implements Builder<RegistrationPayload2, RegistrationPayload2Builder> {
  _$RegistrationPayload2 _$v;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  String _password;
  String get password => _$this._password;
  set password(String password) => _$this._password = password;

  String _firstName;
  String get firstName => _$this._firstName;
  set firstName(String firstName) => _$this._firstName = firstName;

  String _lastName;
  String get lastName => _$this._lastName;
  set lastName(String lastName) => _$this._lastName = lastName;

  String _country;
  String get country => _$this._country;
  set country(String country) => _$this._country = country;

  String _phone;
  String get phone => _$this._phone;
  set phone(String phone) => _$this._phone = phone;

  RegistrationPayload2Builder();

  RegistrationPayload2Builder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _password = _$v.password;
      _firstName = _$v.firstName;
      _lastName = _$v.lastName;
      _country = _$v.country;
      _phone = _$v.phone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegistrationPayload2 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RegistrationPayload2;
  }

  @override
  void update(void Function(RegistrationPayload2Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$RegistrationPayload2 build() {
    final _$result = _$v ??
        new _$RegistrationPayload2._(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            country: country,
            phone: phone);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
