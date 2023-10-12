// GENERATED CODE - DO NOT MODIFY BY HAND

part of login_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginState extends LoginState {
  @override
  final String email;
  @override
  final String password;
  @override
  final bool autovalidate;
  @override
  final bool isEmailValid;
  @override
  final bool isPasswordValid;
  @override
  final bool isValidPhoneNumber;
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
  final String phoneCountry;
  @override
  final bool agreedTerms;
  @override
  final String registeredEmail;
  @override
  final String pendingEmail;

  factory _$LoginState([void Function(LoginStateBuilder) updates]) =>
      (new LoginStateBuilder()..update(updates)).build();

  _$LoginState._(
      {this.email,
      this.password,
      this.autovalidate,
      this.isEmailValid,
      this.isPasswordValid,
      this.isValidPhoneNumber,
      this.confirmPassword,
      this.firstName,
      this.lastName,
      this.phoneNumber,
      this.country,
      this.phoneCountry,
      this.agreedTerms,
      this.registeredEmail,
      this.pendingEmail})
      : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('LoginState', 'email');
    }
    if (password == null) {
      throw new BuiltValueNullFieldError('LoginState', 'password');
    }
    if (autovalidate == null) {
      throw new BuiltValueNullFieldError('LoginState', 'autovalidate');
    }
    if (isEmailValid == null) {
      throw new BuiltValueNullFieldError('LoginState', 'isEmailValid');
    }
    if (isPasswordValid == null) {
      throw new BuiltValueNullFieldError('LoginState', 'isPasswordValid');
    }
    if (isValidPhoneNumber == null) {
      throw new BuiltValueNullFieldError('LoginState', 'isValidPhoneNumber');
    }
    if (confirmPassword == null) {
      throw new BuiltValueNullFieldError('LoginState', 'confirmPassword');
    }
    if (firstName == null) {
      throw new BuiltValueNullFieldError('LoginState', 'firstName');
    }
    if (lastName == null) {
      throw new BuiltValueNullFieldError('LoginState', 'lastName');
    }
    if (phoneNumber == null) {
      throw new BuiltValueNullFieldError('LoginState', 'phoneNumber');
    }
    if (country == null) {
      throw new BuiltValueNullFieldError('LoginState', 'country');
    }
    if (phoneCountry == null) {
      throw new BuiltValueNullFieldError('LoginState', 'phoneCountry');
    }
    if (agreedTerms == null) {
      throw new BuiltValueNullFieldError('LoginState', 'agreedTerms');
    }
    if (registeredEmail == null) {
      throw new BuiltValueNullFieldError('LoginState', 'registeredEmail');
    }
    if (pendingEmail == null) {
      throw new BuiltValueNullFieldError('LoginState', 'pendingEmail');
    }
  }

  @override
  LoginState rebuild(void Function(LoginStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginStateBuilder toBuilder() => new LoginStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginState &&
        email == other.email &&
        password == other.password &&
        autovalidate == other.autovalidate &&
        isEmailValid == other.isEmailValid &&
        isPasswordValid == other.isPasswordValid &&
        isValidPhoneNumber == other.isValidPhoneNumber &&
        confirmPassword == other.confirmPassword &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        phoneNumber == other.phoneNumber &&
        country == other.country &&
        phoneCountry == other.phoneCountry &&
        agreedTerms == other.agreedTerms &&
        registeredEmail == other.registeredEmail &&
        pendingEmail == other.pendingEmail;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(0,
                                                                email.hashCode),
                                                            password.hashCode),
                                                        autovalidate.hashCode),
                                                    isEmailValid.hashCode),
                                                isPasswordValid.hashCode),
                                            isValidPhoneNumber.hashCode),
                                        confirmPassword.hashCode),
                                    firstName.hashCode),
                                lastName.hashCode),
                            phoneNumber.hashCode),
                        country.hashCode),
                    phoneCountry.hashCode),
                agreedTerms.hashCode),
            registeredEmail.hashCode),
        pendingEmail.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LoginState')
          ..add('email', email)
          ..add('password', password)
          ..add('autovalidate', autovalidate)
          ..add('isEmailValid', isEmailValid)
          ..add('isPasswordValid', isPasswordValid)
          ..add('isValidPhoneNumber', isValidPhoneNumber)
          ..add('confirmPassword', confirmPassword)
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('phoneNumber', phoneNumber)
          ..add('country', country)
          ..add('phoneCountry', phoneCountry)
          ..add('agreedTerms', agreedTerms)
          ..add('registeredEmail', registeredEmail)
          ..add('pendingEmail', pendingEmail))
        .toString();
  }
}

class LoginStateBuilder implements Builder<LoginState, LoginStateBuilder> {
  _$LoginState _$v;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  String _password;
  String get password => _$this._password;
  set password(String password) => _$this._password = password;

  bool _autovalidate;
  bool get autovalidate => _$this._autovalidate;
  set autovalidate(bool autovalidate) => _$this._autovalidate = autovalidate;

  bool _isEmailValid;
  bool get isEmailValid => _$this._isEmailValid;
  set isEmailValid(bool isEmailValid) => _$this._isEmailValid = isEmailValid;

  bool _isPasswordValid;
  bool get isPasswordValid => _$this._isPasswordValid;
  set isPasswordValid(bool isPasswordValid) =>
      _$this._isPasswordValid = isPasswordValid;

  bool _isValidPhoneNumber;
  bool get isValidPhoneNumber => _$this._isValidPhoneNumber;
  set isValidPhoneNumber(bool isValidPhoneNumber) =>
      _$this._isValidPhoneNumber = isValidPhoneNumber;

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

  String _phoneCountry;
  String get phoneCountry => _$this._phoneCountry;
  set phoneCountry(String phoneCountry) => _$this._phoneCountry = phoneCountry;

  bool _agreedTerms;
  bool get agreedTerms => _$this._agreedTerms;
  set agreedTerms(bool agreedTerms) => _$this._agreedTerms = agreedTerms;

  String _registeredEmail;
  String get registeredEmail => _$this._registeredEmail;
  set registeredEmail(String registeredEmail) =>
      _$this._registeredEmail = registeredEmail;

  String _pendingEmail;
  String get pendingEmail => _$this._pendingEmail;
  set pendingEmail(String pendingEmail) => _$this._pendingEmail = pendingEmail;

  LoginStateBuilder();

  LoginStateBuilder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _password = _$v.password;
      _autovalidate = _$v.autovalidate;
      _isEmailValid = _$v.isEmailValid;
      _isPasswordValid = _$v.isPasswordValid;
      _isValidPhoneNumber = _$v.isValidPhoneNumber;
      _confirmPassword = _$v.confirmPassword;
      _firstName = _$v.firstName;
      _lastName = _$v.lastName;
      _phoneNumber = _$v.phoneNumber;
      _country = _$v.country;
      _phoneCountry = _$v.phoneCountry;
      _agreedTerms = _$v.agreedTerms;
      _registeredEmail = _$v.registeredEmail;
      _pendingEmail = _$v.pendingEmail;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LoginState;
  }

  @override
  void update(void Function(LoginStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LoginState build() {
    final _$result = _$v ??
        new _$LoginState._(
            email: email,
            password: password,
            autovalidate: autovalidate,
            isEmailValid: isEmailValid,
            isPasswordValid: isPasswordValid,
            isValidPhoneNumber: isValidPhoneNumber,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            country: country,
            phoneCountry: phoneCountry,
            agreedTerms: agreedTerms,
            registeredEmail: registeredEmail,
            pendingEmail: pendingEmail);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
