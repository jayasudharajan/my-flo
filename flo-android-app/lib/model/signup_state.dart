library signup_state;

import 'package:built_value/built_value.dart';

part 'signup_state.g.dart';

abstract class SignUpState
    implements Built<SignUpState, SignUpStateBuilder> {
  SignUpState._();

  factory SignUpState([updates(SignUpStateBuilder b)]) = _$SignUpState;

  String get email;
  String get password;
  String get confirmPassword;
  String get firstName;
  String get lastName;
  String get phoneNumber;
  String get country;
  bool get agreedTerms;
}
