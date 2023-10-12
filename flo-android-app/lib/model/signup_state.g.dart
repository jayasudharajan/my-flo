// GENERATED CODE - DO NOT MODIFY BY HAND

part of signup_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SignUpState extends SignUpState {
  @override
  final String email;
  @override
  final String password;
  @override
  final String confirmPassword;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String phoneNumber;
  @override
  final String country;
  @override
  final bool agreedTerms;

  factory _$SignUpState([void Function(SignUpStateBuilder) updates]) =>
      (new SignUpStateBuilder()..update(updates)).build();

  _$SignUpState._(
      {this.email,
      this.password,
      this.confirmPassword,
      this.firstName,
      this.lastName,
      this.phoneNumber,
      this.country,
      this.agreedTerms})
      : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'email');
    }
    if (password == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'password');
    }
    if (confirmPassword == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'confirmPassword');
    }
    if (firstName == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'firstName');
    }
    if (lastName == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'lastName');
    }
    if (phoneNumber == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'phoneNumber');
    }
    if (country == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'country');
    }
    if (agreedTerms == null) {
      throw new BuiltValueNullFieldError('SignUpState', 'agreedTerms');
    }
  }

  @override
  SignUpState rebuild(void Function(SignUpStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SignUpStateBuilder toBuilder() => new SignUpStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SignUpState &&
        email == other.email &&
        password == other.password &&
        confirmPassword == other.confirmPassword &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        phoneNumber == other.phoneNumber &&
        country == other.country &&
        agreedTerms == other.agreedTerms;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, email.hashCode), password.hashCode),
                            confirmPassword.hashCode),
                        firstName.hashCode),
                    lastName.hashCode),
                phoneNumber.hashCode),
            country.hashCode),
        agreedTerms.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SignUpState')
          ..add('email', email)
          ..add('password', password)
          ..add('confirmPassword', confirmPassword)
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('phoneNumber', phoneNumber)
          ..add('country', country)
          ..add('agreedTerms', agreedTerms))
        .toString();
  }
}

class SignUpStateBuilder implements Builder<SignUpState, SignUpStateBuilder> {
  _$SignUpState _$v;

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

  String _firstName;
  String get firstName => _$this._firstName;
  set firstName(String firstName) => _$this._firstName = firstName;

  String _lastName;
  String get lastName => _$this._lastName;
  set lastName(String lastName) => _$this._lastName = lastName;

  String _phoneNumber;
  String get phoneNumber => _$this._phoneNumber;
  set phoneNumber(String phoneNumber) => _$this._phoneNumber = phoneNumber;

  String _country;
  String get country => _$this._country;
  set country(String country) => _$this._country = country;

  bool _agreedTerms;
  bool get agreedTerms => _$this._agreedTerms;
  set agreedTerms(bool agreedTerms) => _$this._agreedTerms = agreedTerms;

  SignUpStateBuilder();

  SignUpStateBuilder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _password = _$v.password;
      _confirmPassword = _$v.confirmPassword;
      _firstName = _$v.firstName;
      _lastName = _$v.lastName;
      _phoneNumber = _$v.phoneNumber;
      _country = _$v.country;
      _agreedTerms = _$v.agreedTerms;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SignUpState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$SignUpState;
  }

  @override
  void update(void Function(SignUpStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$SignUpState build() {
    final _$result = _$v ??
        new _$SignUpState._(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            country: country,
            agreedTerms: agreedTerms);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
