import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'generated/i18n.dart';
import 'model/email_payload.dart';
import 'model/locales.dart';
import 'model/login_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'model/locale.dart' as FloLocale;
import 'package:phone_number/phone_number.dart';
import 'package:fimber/fimber.dart';
import 'model/response_error.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';
import 'themes.dart';
import 'providers.dart';
import 'package:country_code_picker/country_code_picker.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //final _pageController = PageController(viewportFraction: 1.0);
  final _pageController = PageController(
    keepPage: true,
  );
  static const _kDuration = const Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;
  int _page = 0;

  // NOTICE: DO NOT CHANGE the order unless you checked validate(page)
  final List<Widget> _pages = <Widget>[
    SignUpPage1(),
    SignUpPage2(),
  ];

  static onTap(index) {
    Fimber.d("$index selected.");
  }

  bool _isValid = false;

  bool onWillPop() {
    if (_pageController.page.round() == _pageController.initialPage)
      return true;
    else {
      _pageController.previousPage(
        duration: Duration(milliseconds: 200),
        curve: Curves.linear,
      );
      return false;
    }
  }

bool validate(LoginState loginState, int page) {
  Fimber.d("$page $loginState");
  if (page == 0) {
     return loginState.email.isNotEmpty &&
            isValidEmail(loginState.email) &&
            loginState.password.isNotEmpty &&
            loginState.registeredEmail != loginState.email &&
            loginState.confirmPassword.isNotEmpty &&
            loginState.password == loginState.confirmPassword;
   } else if (page == 1) {
     return loginState.firstName.isNotEmpty &&
            loginState.lastName.isNotEmpty &&
            loginState.phoneNumber.isNotEmpty &&
            loginState.isValidPhoneNumber &&
            loginState.country.isNotEmpty &&
            loginState.agreedTerms;
   }
   return false;
}

  bool _loading = false;

  @override
  void initState() {
    _loading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //_isValid = validate(context, currentPage(_pageController));
    //final loginProvider = Provider.of<LoginStateNotifier>(context, listen: false);
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    _pageController.addListener(() {
      int currentPage = _pageController.page.round();
      bool pageChanged = currentPage != _page;
      if (pageChanged) {
        setState(() {
          _page = currentPage;
        });
      }
    });
    final flo = floConsumer.value;
    return Theme(
      data: floLightThemeData,
      child: WillPopScope(
          onWillPop: () =>  Future.sync(onWillPop),
          child: Scaffold(
              resizeToAvoidBottomPadding: false,
              body: Builder(builder: (scaffoldContext) => InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    loginConsumer.invalidate();
                  }, child: SafeArea(
                  child: Stack(
                      children: <Widget>[
                        PageView.builder(
                          physics: SimpleNeverScrollableScrollPhysics(),
                          controller: _pageController,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return Padding(padding: EdgeInsets.only(bottom: 125), child: _pages[index % _pages.length]);
                          },
                        ),
                        Positioned(
                          bottom: 20.0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(height: 15,
                                    child: DotsIndicator(
                                      controller: _pageController,
                                      itemCount: _pages.length,
                                      color: floDotColor,
                                      selectedColor: floBlue2,
                                      maxZoom: 1.7,
                                      onPageSelected: (page) {
                                        setState(() {
                                          _page = page;
                                        });
                                        _pageController.animateToPage(
                                          page,
                                          duration: _kDuration,
                                          curve: _kCurve,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(width: 30),
                                      TextButton(
                                        padding: EdgeInsets.symmetric(vertical: 25),
                                        color: floLightBlue,
                                        label: Text("", style: TextStyle(
                                          color: floPrimaryColor,
                                        ),
                                        ),
                                        onPressed: () {
                                          if (!hasPreviousPage(_pageController)) {
                                            Navigator.of(context).pop();
                                          }
                                          _pageController.previousPage(
                                            duration: _kDuration,
                                            curve: _kCurve,
                                          );
                                        },
                                        icon: Icon(Icons.arrow_back_ios, color: floPrimaryColor, size: 16, ),
                                        shape: CircleBorder(),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Opacity(opacity: validate(loginConsumer.value, _page) ? 1.0 : 0.3, child: TextButton(
                                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                            color: floBlue2,
                                            label: Text(S.of(context).next, style: TextStyle(
                                              color: Colors.white,
                                            ),
                                              textScaleFactor: 1.6,
                                            ),
                                            onPressed: () async {
                                              if (_page == 0) {
                                                if (loginConsumer.value.email.isNotEmpty &&
                                                    isValidEmail(loginConsumer.value.email) &&
                                                    loginConsumer.value.password.isNotEmpty &&
                                                    loginConsumer.value.confirmPassword.isNotEmpty &&
                                                    loginConsumer.value.password == loginConsumer.value.confirmPassword) {
                                                  setState(() => _loading = true);
                                                  try {
                                                  final res = await flo.emailStatus2(loginConsumer.value.email);
                                                  setState(() => _loading = false);
                                                  final emailStatus = res.body;
                                                  if (emailStatus.isPending) {
                                                    Navigator.of(context).pushReplacementNamed('/verify_email');
                                                  } else if (emailStatus.isRegistered) {
                                                    loginConsumer.value = loginConsumer.value.rebuild((b) => b
                                                    ..registeredEmail = emailStatus.isRegistered ? b.email : b.registeredEmail);
                                                    loginConsumer.invalidate();
                                                  } else {
                                                    _pageController.nextPage(
                                                      duration: _kDuration,
                                                      curve: Curves.fastOutSlowIn,
                                                    );
                                                  }
                                                  } catch (e) {
                                                    setState(() => _loading = false);
                                                    showDialog(context: context,
                                                      builder: (context) => FloErrorDialog(
                                                          title: Text("Flo Error 011"),
                                                          content: Text(S.of(context).unexpected_error_creating_account),
                                                      )
                                                    );
                                                    Fimber.e("", ex: e);
                                                  }
                                                }
                                              } else if (_page == 1) {
                                                if (loginConsumer.value.firstName.isNotEmpty &&
                                                  loginConsumer.value.lastName.isNotEmpty &&
                                                  loginConsumer.value.phoneNumber.isNotEmpty &&
                                                  loginConsumer.value.isValidPhoneNumber &&
                                                  loginConsumer.value.country.isNotEmpty &&
                                                  loginConsumer.value.agreedTerms
                                                ) {
                                                  try {
                                                    setState(() => _loading = true);
                                                    //final res = await flo.registrationWithState2(loginConsumer.current);
                                                    final res = await flo.registrationWithState2(loginConsumer.value);
                                                    setState(() => _loading = false);
                                                    if (!res.isSuccessful) {
                                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).something_went_wrong_please_retry)));
                                                    }
                                                    Navigator.of(context).pushReplacementNamed('/verify_email');
                                                  } catch (err) {
                                                    setState(() => _loading = false);
                                                    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).something_went_wrong_please_retry)));
                                                  }
                                                } else {
                                                  Fimber.d("${loginConsumer.value}");
                                                  Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).something_went_wrong_please_retry)));
                                                  /*
                                                  if (!loginConsumer.current.agreedTerms) {
                                                    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
                                                      content: Text("Please agree the Terms & Conditions")
                                                    ));
                                                  }
                                                  */
                                                }
                                              }
                                            },
                                            suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16, )),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                                          ))),
                                      SizedBox(width: 40),
                                    ],),
                                ]),
                          ),
                        ),
                        Center(child: _loading ? CircularProgressIndicator() : Container())
                      ])
              )
              ))
          )
      ),
    );
  }
}

class SignUpPage1 extends StatefulWidget {
  @override
  _SignUpPage1State createState() => _SignUpPage1State();
}

class _SignUpPage1State  extends State<SignUpPage1> {
  final emailController = TextEditingController();
  bool _autovalidate = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  final focus1 = FocusNode();
  final focus2 = FocusNode();
  final focus3 = FocusNode();

  @override
  void initState() {
    focus1.addListener(() {
      if (_autovalidate) {
        return;
      }
      if (!focus1.hasFocus) {
        setState(() => _autovalidate = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    if (emailController.text == null || emailController.text.isEmpty) {
      emailController.text = loginConsumer.value.email;
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
          children: <Widget>[
            Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(S.of(context).create_new_account, textScaleFactor: 2.0),
                  SizedBox(height: 20),
                  TextFormField(
                    focusNode: focus1,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (term) {
                       FocusScope.of(context).requestFocus(focus2);
                    },
                    controller: addTextChangedListener(emailController, (text) {
                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..email = text..email = text);
                    }),
                    keyboardType: TextInputType.emailAddress,
                    autovalidate: _autovalidate,
                    validator: (text) {
                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..isEmailValid = false);
                      if (text.isEmpty) {
                        return S.of(context).please_enter_email;
                      } else if (!isValidEmail(text)) {
                        return S.of(context).please_enter_a_valid_email;
                      } else if (loginConsumer.value.registeredEmail == text ||
                       loginConsumer.value.pendingEmail == text) {
                        return S.of(context).email_is_unavailable;
                      }
                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..isEmailValid = true);
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: S.of(context).email,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 18.0),
                    ),
                  ),
                  SizedBox(height: 15),
                  PasswordField(
                    focusNode: focus2,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (term) { FocusScope.of(context).requestFocus(focus3); },
                    text: loginConsumer.value.password,
                    onTextChanged: (text) {
                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..password = text);
                    }
                  ),
                  SizedBox(height: 15),
                  PasswordField(
                    focusNode: focus3,
                    textInputAction: TextInputAction.done,
                    text: loginConsumer.value.confirmPassword,
                    labelText: S.of(context).confirm_password,
                    onTextChanged: (text) {
                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..confirmPassword = text);
                    },
                    validator: (text) {
                      if (loginConsumer.value.password != text) {
                        return S.of(context).passwords_do_not_match;
                      }
                      return null;
                    },
                  ),
                ])
            ),
            TextButton(
              label: Text(S.of(context).i_already_have_an_account, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.2,),
              suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: floPrimaryColor, size: 13, )),
              onPressed: ()  {
                Navigator.of(context).pushReplacementNamed("/login");
                //Navigator.of(context).pop();
              },
            ),
            SizedBox(height: 10),
          ]),
    );
  }
}

class SignUpPage2 extends StatefulWidget {
  @override
  _SignUpPage2State createState() => _SignUpPage2State();
}

class _SignUpPage2State  extends State<SignUpPage2> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  bool _firstNameAutovalidate = false;
  bool _lastNameAutovalidate = false;
  bool _phoneNumberAutovalidate = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  final focus1 = FocusNode();
  final focus2 = FocusNode();
  final focus3 = FocusNode();

  String _phoneNumberErrorText = null;
  bool _agreedTerms = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      focus3.addListener(() async {
        Fimber.d("focus3: ${focus3.hasFocus}");
        if (!focus3.hasFocus) {
          await validatePhone(context);
        }
      });
    });
  }

  validatePhone(BuildContext context) async {
    if (!_phoneNumberAutovalidate) {
      setState(() {
        _phoneNumberAutovalidate = true;
      });
    }
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    try {
      final region = loginConsumer.value.phoneCountry.isNotEmpty ? loginConsumer.value.phoneCountry : loginConsumer.value.country;
      Fimber.d("region: ${region}");
      final phoneNumber = await PhoneNumber.parse(phoneNumberController.text, region: region.toUpperCase());
      phoneNumberController.text = phoneNumber['international'];
      loginConsumer.value = loginConsumer.value.rebuild((b) => b
        ..phoneNumber = phoneNumberController.text
        ..isValidPhoneNumber = true);
      phoneNumberController.text = phoneNumberController.text.replaceFirst(RegExp(r'\+\d+'), '');
      loginConsumer.invalidate();
      setState(() => _phoneNumberErrorText = null);
    } catch (err) {
      Fimber.d("", ex: err);
      loginConsumer.value = loginConsumer.value.rebuild((b) => b
        ..isValidPhoneNumber = true);
      setState(() => _phoneNumberErrorText = S.of(context).invalid_phone_number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    final localesConsumer = Provider.of<LocalesNotifier>(context);
    flo.countries().then((it) {
      localesConsumer.value = Locales((b) => b..locales = ListBuilder(it));
      print(localesConsumer.value);
      localesConsumer.invalidate();
    }).catchError((err) => Fimber.e("", ex: err));
    if (firstNameController.text == null || firstNameController.text.isEmpty) {
      firstNameController.text = loginConsumer.value.firstName;
    }
    addTextChangedListener(firstNameController, (text) {
      loginConsumer.value = loginConsumer.value.rebuild((b) => b..firstName = text);
      //loginConsumer.invalidate();
      if (!_firstNameAutovalidate) {
        if (text.isNotEmpty) {
          setState(() {
            _firstNameAutovalidate = true;
          });
        }
      }
    });
    if (lastNameController.text == null || lastNameController.text.isEmpty) {
      lastNameController.text = loginConsumer.value.lastName;
    }
    addTextChangedListener(lastNameController, (text) {
      loginConsumer.value = loginConsumer.value.rebuild((b) => b..lastName = text);
      //loginConsumer.invalidate();
      if (!_lastNameAutovalidate) {
        if (text.isNotEmpty) {
          setState(() {
            _lastNameAutovalidate = true;
          });
        }
      }
    });
    if (phoneNumberController.text == null || phoneNumberController.text.isEmpty) {
      phoneNumberController.text = loginConsumer.value.phoneNumber ?? "";
    }
    return Scaffold(
          resizeToAvoidBottomPadding: false,
          body: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(S.of(context).please_enter_the_following_information_to_continue, textScaleFactor: 2.0),
          SizedBox(height: 20),
          TextFormField(
            controller: firstNameController,
            keyboardType: TextInputType.text,
            focusNode: focus1,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (term) { FocusScope.of(context).requestFocus(focus2); },
            autovalidate: _firstNameAutovalidate,
            validator: (text) {
              if (text.isEmpty) {
                return S.of(context).should_not_be_empty;
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: S.of(context).first_name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              contentPadding: EdgeInsets.only(left: 25, right: 10, top: 18, bottom: 18),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: lastNameController,
            keyboardType: TextInputType.text,
            focusNode: focus2,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (term) { FocusScope.of(context).requestFocus(focus3); },
            autovalidate: _lastNameAutovalidate,
            validator: (text) {
              if (text.isEmpty) {
                return S.of(context).should_not_be_empty;
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: S.of(context).last_name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              contentPadding: EdgeInsets.only(left: 25, right: 10, top: 18, bottom: 18),
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: floLightBlue, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Colors.white,
              shape: BoxShape.rectangle,
            ),
            child: SimplePickerDropdown<FloLocale.Locale>(
                  initialValue: FloLocale.Locale((b) => b
                  ..locale = loginConsumer.value.country.toLowerCase()
                  ..name = ""),
                  selection: (locale) => locale.locale,
                  hint: Text(S.of(context).country, textAlign: TextAlign.center),
                  items: sort(localesConsumer.value.locales.toList(), (a, b) => a.locale.compareTo(b.locale)),
                  builder: (locale) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text("${locale.name}"),
                    );
                  },
                  onValuePicked: (locale) {
                    loginConsumer.value = loginConsumer.value.rebuild((b) => b
                    ..country = locale.locale
                    ..phoneCountry = locale.locale
                    );
                    Fimber.d("selected $locale");
                    Fimber.d("country ${loginConsumer.value.country}");
                    Fimber.d("phoneCountry ${loginConsumer.value.phoneCountry}");
                    validatePhone(context);
                    loginConsumer.invalidate();
                  },
                ),
          ),
          SizedBox(height: 10),
          Stack(children: [TextFormField(
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            focusNode: focus3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (text) async {
              await validatePhone(context);
            },
            autovalidate: _phoneNumberAutovalidate,
            validator: (text) {
              loginConsumer.value = loginConsumer.value.rebuild((b) => b
              ..phoneNumber = text);
              if (text.isEmpty) {
                return S.of(context).should_not_be_empty;
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: S.of(context).phone_number,
              errorText: _phoneNumberErrorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              //contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 18.0),
              contentPadding: EdgeInsets.only(left: 70, top: 18, bottom: 18, right: 10),
            ),
          ),
          Padding(padding: EdgeInsets.only(left: 0), child: SimpleCountryCodePicker(
                  onPicked: (country) {
                    loginConsumer.value = loginConsumer.value.rebuild((b) => b
                    ..phoneCountry = country.code
                    );
                    validatePhone(context);
                  },
                  // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                  //initialSelection: loginConsumer.current.phoneCountry.isNotEmpty ? loginConsumer.current.phoneCountry : loginConsumer.current.country.toUpperCase(),
                  initialSelection: loginConsumer.value.country.toUpperCase(),
                  favorite: [loginConsumer.value.country.toUpperCase()],
                  // optional. Shows only country name and flag
                  showCountryOnly: false,
                  // optional. Shows only country name and flag when popup is closed.
                  //showOnlyCountryCodeWhenClosed: false,
                  // optional. aligns the flag and the Text left
                  //alignLeft: false,
                )),
          ]),
          SizedBox(height: 10),
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: loginConsumer.value.agreedTerms,
                      //value: _agreedTerms,
                      onChanged: (checked) {
                        loginConsumer.subject.add(loginConsumer.value.rebuild((b) => b..agreedTerms = checked));
                      },
                    )),
                Expanded(child:
                InkWell(
                  child:
                    Html(data: S.of(context).i_agree_with_the__terms_and_conditions_, defaultTextStyle: TextStyle(fontSize: 16, color: floPrimaryColor)),
                  onTap: () {
                    loginConsumer.value = loginConsumer.value.rebuild((b) => b..agreedTerms = true);
                    loginConsumer.invalidate();
                    //setState(() => _agreedTerms = true);
                    Navigator.of(context).pushNamed("/terms");
                  },
                ),
                ),
              ]),
        ])));
  }
}

class VerifyEmailScreen extends StatefulWidget {
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailState();
}

class _VerifyEmailState  extends State<VerifyEmailScreen> {

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    return Theme(
        data: floLightThemeData,
        child: Scaffold(
          body: Builder(builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(S.of(context).verify_your_email_address, textScaleFactor: 2.0,),
                      SizedBox(height: 20),
                      Text(S.of(context).an_email_has_been_sent_to, textScaleFactor: 1.2,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(loginConsumer.value.email != "" ? loginConsumer.value.email : "example@gmail.com", textScaleFactor: 1.2,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(S.of(context).please_check_your_email_to_verify_you_account, textScaleFactor: 1.2,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ]))
                ),
                Center(child: FlatButton(
                  child: Text(S.of(context).resend_email,
                    style: TextStyle(
                      color: floPrimaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    textScaleFactor: 1.3,
                  ),
                  onPressed: () async {
                    try {
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).loading)));
                      final res = await flo.resendEmail2(EmailPayload((b) => b..email = loginConsumer.value.email));
                      Fimber.d("$res");
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).the_verification_email_has_been_sent_again)));
                    } catch (err) {
                      Fimber.d("", ex: err);
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).something_went_wrong_please_retry)));
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                )),
                SizedBox(height: 20),
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: TextButton(
                  label: Text(S.of(context).check_inbox, style: TextStyle(color: Colors.white), textScaleFactor: 1.6,),
                  //suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18, )),
                  color: floBlue2,
                  padding: EdgeInsets.all(20.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  onPressed: () {
                    try {
                      AppAvailability.launchApp(Platform.isIOS ? "message://" : "com.google.android.gm").then((_) {
                        Fimber.d("App Email launched!");
                      }).catchError((err) {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(S.of(context).not_found)
                        ));
                        Fimber.d("", ex: err);
                      });
                    } catch (err) {
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).not_found)));
                    }
                  },
                ))),
                SizedBox(height: 40),
              ])),
        ));
  }
}

