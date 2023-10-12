import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'generated/i18n.dart';
import 'model/email_payload.dart';
import 'package:flutter/services.dart';
import 'package:fimber/fimber.dart';
import 'model/flo.dart';
import 'themes.dart';
import 'validations.dart';
import 'widgets.dart';
import 'providers.dart';


class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordScreen> with AfterLayoutMixin<ForgotPasswordScreen> {

  TextEditingController _resetPassowrdTextController;
  Flo flo;

  @override
  void initState() {
    super.initState();
    _resetPassowrdTextController = TextEditingController();
    Future(() {
      final floConsumer = Provider.of<FloNotifier>(context, listen: false);
      flo = floConsumer.value;
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final loginProvider = Provider.of<LoginStateNotifier>(context, listen: true);
    addTextChangedListener(_resetPassowrdTextController, (text) {
      loginProvider.value = loginProvider.value.rebuild((b) => b..email = text);
    });
  }

  @override
  void dispose() {
    _resetPassowrdTextController?.dispose();
    super.dispose();
  }

  bool _autovalidate = false;
  bool _isEmailValid = false;
  bool _loading = false;
  String _notUsedEmail = "";

  String validate(BuildContext context, String text) {
    if (text.isEmpty) {
      return S.of(context).please_enter_email;
    } else if (!isValidEmail(text)) {
      return S.of(context).please_enter_a_valid_email;
    } else if (text == _notUsedEmail) {
      return S.of(context).email_is_unavailable;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    //final loginConsumer = Provider.of<LoginStateNotifier>(context);
    //final loginProvider = Provider.of<LoginStateNotifier>(context, listen: false);
    //_resetPassowrdTextController.text = loginConsumer.value.email;
    return Theme(
        data: floLightThemeData,
        child: Scaffold(
            appBar: AppBar(
            brightness: Brightness.light,
            leading: IconButton(icon: Icon(Icons.close),
              onPressed: () {
                  Navigator.of(context).pop();
              }
            ),
            iconTheme: IconThemeData(
              color: floBlue2,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          resizeToAvoidBottomInset: false,
          body: Builder(builder: (scaffoldContext) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).trouble_logging_in_q, textScaleFactor: 2.0,)),
                SizedBox(height: 40),
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).having_difficulty_logging_into_your_flo_account_you_can_simply,
                  textScaleFactor: 1.2,
                  style: TextStyle(
                    height: 1.4,
                    color: Colors.grey[600],
                  ),
                )
                ),
                SizedBox(height: 40),
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: TextButton(
                  label: Text(S.of(context).reset_password, style: TextStyle(color: Colors.white), textScaleFactor: 1.6,),
                  color: floBlue2,
                  padding: EdgeInsets.all(20.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return Theme(data: floLightThemeData,
                              child: AlertDialog(
                                title: Text(S.of(context).reset_password),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(S.of(context).reset_password_instructions_will_be_emailed),
                                    SizedBox(height: 20),
                                    Stack(children: <Widget>[
                                      TextFormField(
                                        controller: _resetPassowrdTextController,
                                        keyboardType: TextInputType.emailAddress,
                                        autovalidate: _autovalidate,
                                        validator: (text) => validate(context, text),
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
                                      _loading ? Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(top: 15, right: 15), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))) : Container(),
                                    ],),
                                  ],),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text(S.of(context).cancel),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child: Text(S.of(context).ok),
                                    onPressed: () async { 
                                      final email = _resetPassowrdTextController.text;
                                      _isEmailValid = validate(context, email) == null;

                                      if (_isEmailValid) {
                                        try {
                                          setState(() => _loading = true);
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          //final isEmailUsed = await flo.isEmailUsed(email);
                                          final isEmailUsed = true;
                                          // TODO: Disable this feature until we provide the email status from the same reset-password API
                                          if (isEmailUsed) {
                                            flo.resetPassword2(EmailPayload((b) => b..email = email)).then((res) {
                                              setState(() => _loading = false);
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Theme(
                                                      data: floLightThemeData,
                                                      child: AlertDialog(
                                                        title: Text(S.of(context).reset_password),
                                                        // TODO: put this string format into i18n arb
                                                        content: Text("${S.of(context).if_account_exists_password_reset_email_sent_to} ${email}"),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child: Text(S.of(context).ok),
                                                            onPressed: () {
                                                              Navigator.of(context).pushNamed('/login');
                                                            },
                                                          ),
                                                        ],
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                                      )
                                                  );
                                                },
                                              );
                                            })
                                            .catchError((err) {
                                              setState(() => _loading = false);
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Theme(
                                                      data: floLightThemeData,
                                                      child: AlertDialog(
                                                        title: Text(S.of(context).reset_password),
                                                        content: Text(S.of(context).something_went_wrong_please_retry),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child: Text(S.of(context).ok),
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                        ],
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                                      )
                                                  );
                                                },
                                              );
                                            });
                                          } else {
                                              FocusScope.of(context).requestFocus(FocusNode());
                                              setState(() {
                                                _notUsedEmail = email;
                                                _loading = false;
                                                _autovalidate = true;
                                              });
                                          }
                                        } catch (err) {
                                          Fimber.d("", ex: err);
                                          setState(() {
                                            _notUsedEmail = email;
                                            _loading = false;
                                            _autovalidate = true;
                                          });
                                        }
                                      } else {
                                        FocusScope.of(context).requestFocus(FocusNode());
                                        setState(() => _autovalidate = true);
                                      }
                                    },
                                  ),
                                ],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              ));
                        });
                  },
                ))),
              ]),
        )));
  }
}
