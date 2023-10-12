// GENERATED CODE - DO NOT MODIFY BY HAND

part of forgot_password_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ForgotPasswordState extends ForgotPasswordState {
  @override
  final String email;
  @override
  final String password;
  @override
  final bool autovalidate;
  @override
  final bool isEmailValid;
  @override
  final bool isEmailAvailable;
  @override
  final bool isPasswordValid;
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

  factory _$ForgotPasswordState(
          [void Function(ForgotPasswordStateBuilder) updates]) =>
      (new ForgotPasswordStateBuilder()..update(updates)).build();

  _$ForgotPasswordState._(
      {this.email,
      this.password,
      this.autovalidate,
      this.isEmailValid,
      this.isEmailAvailable,
      this.isPasswordValid,
      this.confirmPassword,
      this.firstName,
      this.lastName,
      this.phoneNumber,
      this.country,
      this.agreedTerms})
      : super._() {
    if (email == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'email');
    }
    if (password == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'password');
    }
    if (autovalidate == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'autovalidate');
    }
    if (isEmailValid == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'isEmailValid');
    }
    if (isEmailAvailable == null) {
      throw new BuiltValueNullFieldError(
          'ForgotPasswordState', 'isEmailAvailable');
    }
    if (isPasswordValid == null) {
      throw new BuiltValueNullFieldError(
          'ForgotPasswordState', 'isPasswordValid');
    }
    if (confirmPassword == null) {
      throw new BuiltValueNullFieldError(
          'ForgotPasswordState', 'confirmPassword');
    }
    if (firstName == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'firstName');
    }
    if (lastName == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'lastName');
    }
    if (phoneNumber == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'phoneNumber');
    }
    if (country == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'country');
    }
    if (agreedTerms == null) {
      throw new BuiltValueNullFieldError('ForgotPasswordState', 'agreedTerms');
    }
  }

  @override
  ForgotPasswordState rebuild(
          void Function(ForgotPasswordStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ForgotPasswordStateBuilder toBuilder() =>
      new ForgotPasswordStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ForgotPasswordState &&
        email == other.email &&
        password == other.password &&
        autovalidate == other.autovalidate &&
        isEmailValid == other.isEmailValid &&
        isEmailAvailable == other.isEmailAvailable &&
        isPasswordValid == other.isPasswordValid &&
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
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc($jc(0, email.hashCode),
                                                password.hashCode),
                                            autovalidate.hashCode),
                                        isEmailValid.hashCode),
                                    isEmailAvailable.hashCode),
                                isPasswordValid.hashCode),
                            confirmPassword.hashCode),
                        firstName.hashCode),
                    lastName.hashCode),
                phoneNumber.hashCode),
            country.hashCode),
        agreedTerms.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ForgotPasswordState')
          ..add('email', email)
          ..add('password', password)
          ..add('autovalidate', autovalidate)
          ..add('isEmailValid', isEmailValid)
          ..add('isEmailAvailable', isEmailAvailable)
          ..add('isPasswordValid', isPasswordValid)
          ..add('confirmPassword', confirmPassword)
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('phoneNumber', phoneNumber)
          ..add('country', country)
          ..add('agreedTerms', agreedTerms))
        .toString();
  }
}

class ForgotPasswordStateBuilder
    implements Builder<ForgotPasswordState, ForgotPasswordStateBuilder> {
  _$ForgotPasswordState _$v;

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

  bool _isEmailAvailable;
  bool get isEmailAvailable => _$this._isEmailAvailable;
  set isEmailAvailable(bool isEmailAvailable) =>
      _$this._isEmailAvailable = isEmailAvailable;

  bool _isPasswordValid;
  bool get isPasswordValid => _$this._isPasswordValid;
  set isPasswordValid(bool isPasswordValid) =>
      _$this._isPasswordValid = isPasswordValid;

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

  ForgotPasswordStateBuilder();

  ForgotPasswordStateBuilder get _$this {
    if (_$v != null) {
      _email = _$v.email;
      _password = _$v.password;
      _autovalidate = _$v.autovalidate;
      _isEmailValid = _$v.isEmailValid;
      _isEmailAvailable = _$v.isEmailAvailable;
      _isPasswordValid = _$v.isPasswordValid;
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
  void replace(ForgotPasswordState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ForgotPasswordState;
  }

  @override
  void update(void Function(ForgotPasswordStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ForgotPasswordState build() {
    final _$result = _$v ??
        new _$ForgotPasswordState._(
            email: email,
            password: password,
            autovalidate: autovalidate,
            isEmailValid: isEmailValid,
            isEmailAvailable: isEmailAvailable,
            isPasswordValid: isPasswordValid,
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
