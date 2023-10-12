// GENERATED CODE - DO NOT MODIFY BY HAND

part of registration_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<RegistrationPayload> _$registrationPayloadSerializer =
    new _$RegistrationPayloadSerializer();

class _$RegistrationPayloadSerializer
    implements StructuredSerializer<RegistrationPayload> {
  @override
  final Iterable<Type> types = const [
    RegistrationPayload,
    _$RegistrationPayload
  ];
  @override
  final String wireName = 'RegistrationPayload';

  @override
  Iterable<Object> serialize(
      Serializers serializers, RegistrationPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'firstname',
      serializers.serialize(object.firstName,
          specifiedType: const FullType(String)),
      'lastname',
      serializers.serialize(object.lastName,
          specifiedType: const FullType(String)),
      'country',
      serializers.serialize(object.country,
          specifiedType: const FullType(String)),
      'email',
      serializers.serialize(object.email,
          specifiedType: const FullType(String)),
      'password',
      serializers.serialize(object.password,
          specifiedType: const FullType(String)),
      'password_conf',
      serializers.serialize(object.confirmPassword,
          specifiedType: const FullType(String)),
      'phone_mobile',
      serializers.serialize(object.phoneNumber,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  RegistrationPayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RegistrationPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'firstname':
          result.firstName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'lastname':
          result.lastName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'country':
          result.country = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'email':
          result.email = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'password':
          result.password = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'password_conf':
          result.confirmPassword = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'phone_mobile':
          result.phoneNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$RegistrationPayload extends RegistrationPayload {
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String country;
  @override
  final String email;
  @override
  final String password;
  @override
  final String confirmPassword;
  @override
  final String phoneNumber;

  factory _$RegistrationPayload(
          [void Function(RegistrationPayloadBuilder) updates]) =>
      (new RegistrationPayloadBuilder()..update(updates)).build();

  _$RegistrationPayload._(
      {this.firstName,
      this.lastName,
      this.country,
      this.email,
      this.password,
      this.confirmPassword,
      this.phoneNumber})
      : super._() {
    if (firstName == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'firstName');
    }
    if (lastName == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'lastName');
    }
    if (country == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'country');
    }
    if (email == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'email');
    }
    if (password == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'password');
    }
    if (confirmPassword == null) {
      throw new BuiltValueNullFieldError(
          'RegistrationPayload', 'confirmPassword');
    }
    if (phoneNumber == null) {
      throw new BuiltValueNullFieldError('RegistrationPayload', 'phoneNumber');
    }
  }

  @override
  RegistrationPayload rebuild(
          void Function(RegistrationPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegistrationPayloadBuilder toBuilder() =>
      new RegistrationPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegistrationPayload &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        country == other.country &&
        email == other.email &&
        password == other.password &&
        confirmPassword == other.confirmPassword &&
        phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, firstName.hashCode), lastName.hashCode),
                        country.hashCode),
                    email.hashCode),
                password.hashCode),
            confirmPassword.hashCode),
        phoneNumber.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RegistrationPayload')
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('country', country)
          ..add('email', email)
          ..add('password', password)
          ..add('confirmPassword', confirmPassword)
          ..add('phoneNumber', phoneNumber))
        .toString();
  }
}

class RegistrationPayloadBuilder
    implements Builder<RegistrationPayload, RegistrationPayloadBuilder> {
  _$RegistrationPayload _$v;

  String _firstName;
  String get firstName => _$this._firstName;
  set firstName(String firstName) => _$this._firstName = firstName;

  String _lastName;
  String get lastName => _$this._lastName;
  set lastName(String lastName) => _$this._lastName = lastName;

  String _country;
  String get country => _$this._country;
  set country(String country) => _$this._country = country;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  String _password;
  String get password => _$this._password;
  set password(String password) => _$this._password = password;

  String _confirmPassword;
  String get confirmPassword => _$this._confirmPassword;
  set confirmPassword(String confirmPassword) =>
      _$this._confirmPassword = confirmPassword;

  String _phoneNumber;
  String get phoneNumber => _$this._phoneNumber;
  set phoneNumber(String phoneNumber) => _$this._phoneNumber = phoneNumber;

  RegistrationPayloadBuilder();

  RegistrationPayloadBuilder get _$this {
    if (_$v != null) {
      _firstName = _$v.firstName;
      _lastName = _$v.lastName;
      _country = _$v.country;
      _email = _$v.email;
      _password = _$v.password;
      _confirmPassword = _$v.confirmPassword;
      _phoneNumber = _$v.phoneNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegistrationPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RegistrationPayload;
  }

  @override
  void update(void Function(RegistrationPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$RegistrationPayload build() {
    final _$result = _$v ??
        new _$RegistrationPayload._(
            firstName: firstName,
            lastName: lastName,
            country: country,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            phoneNumber: phoneNumber);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
