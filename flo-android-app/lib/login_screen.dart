import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:version/version.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'flo_stream_service.dart';
import 'generated/i18n.dart';

import 'model/flo.dart';
import 'package:flutter/services.dart';
import 'package:fimber/fimber.dart';

import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'validations.dart';
import 'providers.dart';
import 'package:package_info/package_info.dart';
import 'package:chopper/chopper.dart' as chopper;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  var _autovalidate = false;
  var _animated = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _loading = false;

  FocusNode _emailFocusNode = FocusNode();
  bool _emailAutovalidate = false;

  FocusNode _passwordFocusNode = FocusNode();
  bool _passwordAutovalidate = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailAutovalidate) {
        return;
      }
      if (!_emailFocusNode.hasFocus) {
        setState(() => _emailAutovalidate = true);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordAutovalidate) {
        return;
      }
      if (!_passwordFocusNode.hasFocus) {
        setState(() => _passwordAutovalidate = true);
      }
    });

    getUriLinksStream().listen((Uri uri) {
      Fimber.d("applink: $uri");
      if (uri.host == "registration2" || uri.host == "register2") {
        Future.delayed(Duration.zero, () async {
          final flo = Provider.of<FloNotifier>(context, listen: false).value;
          final oauthProvider = Provider.of<OauthTokenNotifier>(context, listen: false);
          try {
            final oauth = await flo.loginByToken2(uri.pathSegments.first);
            Fimber.d("uri.pathSegments.first: ${uri.pathSegments.first}");
            Fimber.d("oauth: $oauth");
            final prefs = Provider
                .of<PrefsNotifier>(context, listen: false)
                .value ?? await SharedPreferences.getInstance();
            oauthProvider.value = oauth;
            SharedPreferencesUtils.putOauth(prefs, oauth);
            navigator.pushNamedAndRemoveUntil(
                '/splash', ModalRoute.withName('/'));
          } catch (err) {
            // Maybe Invalid session. // TODO: Display a message
            Fimber.e("", ex: err);
          }
        });
      }
    }, onError: (err) {
      Fimber.e("", ex: err);
    });

    Future.delayed(Duration.zero, () async {
      WiFiForIoTPlugin.forceWifiUsage(false);
      final floConsumer = Provider.of<FloNotifier>(context, listen: false);
      final floStreamServiceProvider = Provider.of<FloStreamServiceNotifier>(context, listen: false);
      if (floConsumer.value is FloMocked) {
        /*
        if (isInDebugMode) {
          floConsumer.current = Flo.createDev();
        } else {
          floConsumer.current = Flo.createProd();
        }
        */
        floConsumer.value = Flo.of(context);
        floStreamServiceProvider.value = FloFirestoreService();
        floConsumer.invalidate();
      }
    });
  }

  String emailValidator(BuildContext context, String text) {
    if (text.isEmpty) {
      return S.of(context).please_enter_a_valid_email;
    } else if (!isValidEmail(text)) {
      return S.of(context).please_enter_a_valid_email;
    }
    return null;
  }

  String passwordValidator(BuildContext context, String text) {
    if (text.isEmpty) {
      return S.of(context).should_not_be_empty;
    } else if (hasWhitespace(text)) {
      return S.of(context).no_whitespace;
    }
    return null;
  }

  Widget demoButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await demo();
      },
      backgroundColor: floBlue2.withOpacity(0.7),
      icon: Icon(Icons.cloud_off),
      label: Text(S.of(context).demo),
    );

  }

  Future<bool> demo() async  {
    final oauthTokenConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
    final loginConsumer = Provider.of<LoginStateNotifier>(context, listen: false);
    final floConsumer = Provider.of<FloNotifier>(context, listen: false);
    final floStreamProvider = Provider.of<FloStreamServiceNotifier>(context, listen: false);

    floConsumer.value = FloMocked();
    loginConsumer.value = loginConsumer.value.rebuild((b) => b
      ..password = ""
      ..email="demo@flotechnologies.com"
      ..isEmailValid = true
      ..isPasswordValid = true
    );
    floStreamProvider.value = FloStreamServiceMocked();
    oauthTokenConsumer.value = await floConsumer.value.loginByUsername(loginConsumer.value.email, loginConsumer.value.password);
    setState(() {
      _loading = false;
      _animated = true;
    });
    Timer(Duration(milliseconds: 300), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
      SystemChrome.restoreSystemUIOverlays();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarIconBrightness: Brightness.dark,
        //statusBarColor: floLightBackground, 
        //systemNavigationBarColor: floLightBackground,
        //systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    Fimber.d(Localizations.localeOf(context).toString());
    final oauthTokenConsumer = Provider.of<OauthTokenNotifier>(context);

    final _loginFormKey = GlobalKey<FormState>();
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    final prefsConsumer = Provider.of<PrefsNotifier>(context);
    final flo = floConsumer.value;
    if (emailController.text == null || emailController.text.isEmpty) {
      emailController.text = loginConsumer.value.email;
    }
    return Theme(
      data: floLightThemeData,
      child:
        Scaffold(
            //floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            //floatingActionButton: SafeArea(child: Padding(padding: EdgeInsets.only(bottom: 30, right: 0), child: Transform.scale(scale: 0.7, child: demoButton(context)),)),
            resizeToAvoidBottomPadding: false,
            body: Builder(builder: (context) => Stack(children: <Widget>[
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  loginConsumer.invalidate();
                }, child: SafeArea(
                child: SingleChildScrollView(child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 41.0),
                    child: Form(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: 30),
                        Image.asset('assets/ic_flo_logo_light.png', height: 50),
                        SizedBox(height: 50),
                        Text(S.of(context).welcome_to_flo, textScaleFactor: 1.6),
                        SizedBox(height: 20),
                        TextFormField(
                          focusNode: _emailFocusNode,
                          controller: addTextChangedListener(emailController, (text) {
                            loginConsumer.value = loginConsumer.value.rebuild((b) => b..email = text);
                          }),
                          //textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autovalidate: _emailAutovalidate,
                          validator: (text) {
                            final errorText = emailValidator(context, text);
                            loginConsumer.value = loginConsumer.value.rebuild((b) => b..isEmailValid = errorText == null);
                            return errorText;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: S.of(context).your_email,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 18.0),
                          ),
                        ),
                        SizedBox(height: 10),
                        PasswordField(
                          focusNode: _passwordFocusNode,
                          autovalidate: _passwordAutovalidate,
                          text: loginConsumer.value.password,
                          textInputAction: TextInputAction.done,
                          onTextChanged: (text) {
                            loginConsumer.value = loginConsumer.value.rebuild((b) => b..password = text);
                          },
                          validator: (text) {
                            final errorText = passwordValidator(context, text);
                            loginConsumer.value = loginConsumer.value.rebuild((b) => b..isPasswordValid = errorText == null);
                            return errorText;
                          },
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            height: 57,
                            child: FlatButton(
                              onPressed: () async {
                                Fimber.d("login pressed");
                                FocusScope.of(context).requestFocus(FocusNode());
                                loginConsumer.value = loginConsumer.value.rebuild((b) => b
                                ..isPasswordValid = passwordValidator(context, loginConsumer.value.password) == null
                                ..isEmailValid = emailValidator(context, loginConsumer.value.email) == null);
                                if (loginConsumer.value.isPasswordValid && loginConsumer.value.isEmailValid) {
                                  Fimber.d("valid");
                                  Fimber.d("email: ${loginConsumer.value.email}");
                                  Fimber.d("password: ${loginConsumer.value.password}");
                                  try {
                                    setState(() => _loading = true);
                                    final flo = Provider.of<FloNotifier>(context, listen: false).value;
                                    Fimber.d("flo is FloMocked: ${flo is FloMocked}");
                                    final oauth = await flo.loginByUsername(loginConsumer.value.email, loginConsumer.value.password);
                                    Fimber.d("oauth: $oauth");
                                    oauthTokenConsumer.value = oauth;
                                    oauthTokenConsumer.invalidate();
                                    setState(() {
                                      _loading = false;
                                      _animated = true;
                                    });
                                    SharedPreferencesUtils.putOauth(prefsConsumer.value, oauthTokenConsumer.value);
                                    Timer(Duration(milliseconds: 300), () {
                                      Navigator.of(context).pushReplacementNamed('/home');
                                    });
                                  } catch (err) {
                                      Fimber.e("", ex: err);
                                      Fimber.e("err.runtimeType: ${err.runtimeType}", ex: err);
                                      setState(() => _loading = false);
                                      loginConsumer.value = loginConsumer.value.rebuild((b) => b..autovalidate = true);
                                      loginConsumer.invalidate();
                                      showDialog(
                                        context: context,
                                        builder: (context2) {
                                          return Theme(
                                              data: floLightThemeData,
                                              child: FloErrorDialog(
                                                error: let<chopper.Response, Error>(err, (it) => HttpError(it.base)) ?? err,
                                                title: as<chopper.Response>(err)?.statusCode == HttpStatus.badRequest ? Text("Flo Error 003")
                                                    : as<chopper.Response>(err)?.statusCode == HttpStatus.locked ? Text("Flo Error 012")
                                                    : null,
                                                content: as<chopper.Response>(err)?.statusCode == HttpStatus.badRequest ? Text(S.of(context).invalid_username_or_password)
                                                    : as<chopper.Response>(err)?.statusCode == HttpStatus.locked ? RichText(
                                                    text: TextSpan(
                                                        children: <TextSpan>[
                                                          SimpleTextSpan(
                                                            context,
                                                            text: "Your account has been locked. Please contact customer support at ", // FIXME: translatable
                                                          ),
                                                          SimpleTextSpan(
                                                            context,
                                                            text: S.of(context).support_phone_number,
                                                            url: "tel://${S.of(context).support_phone_number}",
                                                          ),
                                                          SimpleTextSpan(
                                                            context,
                                                            text: " or email ", // FIXME: translatable
                                                          ),
                                                          SimpleTextSpan(
                                                            context,
                                                            text: S.of(context).support_email,
                                                            url: "mailto:${S.of(context).support_email}",
                                                          ),
                                                          SimpleTextSpan(
                                                            context,
                                                            text: ".",
                                                          ),
                                                        ])
                                                )
                                                    : null,
                                              )
                                          );
                                        },
                                      );
                                  }
                                } else {
                                  setState(() {
                                    _emailAutovalidate = true;
                                    _passwordAutovalidate = true;
                                  });
                                }
                              },
                              padding: EdgeInsets.all(15.0),
                              child: Text(S.of(context).log_in, style: TextStyle(color: Colors.white, fontSize: 21)),
                              color: floBlue2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                            )),
                        SizedBox(height: 10),
                        Center(child:
                        FlatButton(
                          child: Text(S.of(context).trouble_logging_in_q, style: TextStyle(
                            fontSize: 16,
                            color: floPrimaryColor,
                            decoration: TextDecoration.underline,
                          )),
                          onPressed: () {
                            Navigator.of(context).pushNamed("/forgot_password");
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                        )),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 57,
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            child: AutoSizeText(S.of(context).create_new_account, style: TextStyle(color: floPrimaryColor, fontSize: 21), overflow: TextOverflow.ellipsis,),
                            color: floLightBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                            onPressed: () {
                              Navigator.of(context).pushNamed("/signup");
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    )))))),
        Align(
          alignment: Alignment.bottomCenter,
          child: RevealProgressButton(animated: _animated),
        ),
        FutureBuilder<PackageInfo>(future: PackageInfo.fromPlatform(), builder: (context, snapshot) {
          if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done) {
            final version = or(() => Version.parse(snapshot.data.version));
            return Positioned(right: 40, top: 40, child: GestureDetector(child: FlatButton(child: Text(version != null ? "v${version?.major}.${version?.minor}.${version?.patch}" : "${snapshot.data.version}"), onPressed: () async {
            }),
              onDoubleTap: () async {
                await demo();
              } ,
            ));
          } else {
            return Container();
          }
        }),
        Center(child: _loading ? CircularProgressIndicator() : Container()),
          ])
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //demoButton(context),
              SizedBox(height: 10),
              Center(child: Padding(padding: EdgeInsets.only(bottom: 30), child: ViewSetupGuide())),
            ],
          ),
      ),
    );
  }
}

/*
class DemoButton extends StatelessWidget {
  Widget build(BuildContext context) {
    final oauthTokenConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
    final loginConsumer = Provider.of<LoginStateNotifier>(context, listen: false);
    final floConsumer = Provider.of<FloNotifier>(context, listen: false);
    final floStreamProvider = Provider.of<FloStreamServiceNotifier>(context, listen: false);

    return FloatingActionButton.extended(
      onPressed: () async {
        floConsumer.value = FloMocked();
        loginConsumer.value = loginConsumer.value.rebuild((b) => b
          ..password = ""
          ..email="demo@flotechnologies.com"
          ..isEmailValid = true
          ..isPasswordValid = true
        );
        floStreamProvider.value = FloStreamServiceMocked();
        oauthTokenConsumer.value = (await floConsumer.value.loginByUsername(loginConsumer.value.email, loginConsumer.value.password)).body;
        setState(() {
          _loading = false;
          _animated = true;
        });
        Timer(Duration(milliseconds: 300), () {
          Navigator.of(context).pushReplacementNamed('/home');
        });
      },
      backgroundColor: floBlue2,
      icon: Icon(Icons.cloud_off),
      label: Text(S.of(context).demo),
    );

  }
}
*/

