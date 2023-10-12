library forgot_password_state;

import 'package:built_value/built_value.dart';

part 'forgot_password_state.g.dart';

abstract class ForgotPasswordState
    implements Built<ForgotPasswordState, ForgotPasswordStateBuilder> {
  ForgotPasswordState._();

  factory ForgotPasswordState([updates(ForgotPasswordStateBuilder b)]) = _$ForgotPasswordState;

  String get email;
  String get password;
  bool get autovalidate;
  bool get isEmailValid;
  bool get isEmailAvailable;
  bool get isPasswordValid;

  String get confirmPassword;
  String get firstName;
  String get lastName;
  String get phoneNumber;
  String get country;
  bool get agreedTerms;
}
