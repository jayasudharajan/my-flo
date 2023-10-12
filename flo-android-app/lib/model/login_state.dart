library login_state;

import 'package:built_value/built_value.dart';

part 'login_state.g.dart';

abstract class LoginState
    implements Built<LoginState, LoginStateBuilder> {
  LoginState._();

  factory LoginState([updates(LoginStateBuilder b)]) = _$LoginState;

  String get email;
  String get password;
  bool get autovalidate;
  bool get isEmailValid;
  bool get isPasswordValid;
  bool get isValidPhoneNumber;

  String get confirmPassword;
  String get firstName;
  String get lastName;
  String get phoneNumber;
  String get country;
  String get phoneCountry;
  bool get agreedTerms;
  String get registeredEmail;
  String get pendingEmail;

  static LoginState get empty => LoginState((b) => b
        ..autovalidate = false
        ..email = ""
        ..password = ""

        ..isEmailValid = false
        ..isPasswordValid = false
        ..isValidPhoneNumber = false
        ..registeredEmail = ""
        ..pendingEmail = ""

        ..confirmPassword = ""
        ..firstName = ""
        ..lastName = ""
        ..phoneNumber = ""
        ..phoneCountry = ""
        ..country = ""
        ..agreedTerms = false
      );
}
