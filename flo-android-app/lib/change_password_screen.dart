import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'device_screen.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'providers.dart';
import 'themes.dart';
import 'validations.dart';
import 'widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  ChangePasswordScreen({Key key}) : super(key: key);

  State<ChangePasswordScreen> createState() => _SettingsState();
}

class _SettingsState extends State<ChangePasswordScreen> {

  @override
  void initState() {
    super.initState();
    _password = "";
    _newPassword = "";
    _confirmPassword = "";
    _passwordValidate = false;
    _newPasswordValidate = false;
    _confirmPasswordValidate = false;
  }

  String _password = "";
  String _newPassword = "";
  String _confirmPassword = "";
  bool _passwordValidate = false;
  bool _newPasswordValidate = false;
  bool _confirmPasswordValidate = false;

  final focus1 = FocusNode();
  final focus2 = FocusNode();
  final focus3 = FocusNode();

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);

    final child = 
    Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          centerTitle: true,
          elevation: 0.0,
          title: Text(ReCase(S.of(context).change_password).titleCase), // FIXME
        ),
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
      SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Column(children: <Widget>[
          Text(ReCase(S.of(context).old_password).titleCase, style: Theme.of(context).textTheme.subhead), // FIXME
          SizedBox(height: 20,),
                  Theme(data: floLightThemeData, child: PasswordField(
                    focusNode: focus1,
                    textInputAction: TextInputAction.next,
                    hintText: S.of(context).password,
                    onFieldSubmitted: (term) { FocusScope.of(context).requestFocus(focus2); },
                    text: _password,
                    //autovalidate: _passwordValidate,
                    onTextChanged: (text) {
                      _password = text;
                    }
                  ),
                  ),
                  SizedBox(height: 15),
                  Text(ReCase(S.of(context).new_password).titleCase, style: Theme.of(context).textTheme.subhead), // FIXME
                  SizedBox(height: 15),
                  Theme(data: floLightThemeData, child: PasswordField(
                    focusNode: focus2,
                    textInputAction: TextInputAction.next,
                    text: _newPassword,
                    hintText: ReCase(S.of(context).new_password).titleCase,
                    onFieldSubmitted: (term) { FocusScope.of(context).requestFocus(focus3); },
                    //autovalidate: _newPasswordValidate,
                    onTextChanged: (text) {
                      _newPassword = text;
                    },
                  ),
                  ),
                  SizedBox(height: 15),
                  Text(ReCase(S.of(context).confirm_password).titleCase, style: Theme.of(context).textTheme.subhead), // FIXME
                  SizedBox(height: 15),
                  Theme(data: floLightThemeData, child: PasswordField(
                    focusNode: focus3,
                    textInputAction: TextInputAction.done,
                    text: _confirmPassword,
                    hintText: ReCase(S.of(context).confirm_password).titleCase,
                    //autovalidate: _confirmPasswordValidate,
                    onTextChanged: (text) {
                      _confirmPassword = text;
                    },
                    validator: (text) {
                      if (_confirmPassword != _newPassword) {
                        return S.of(context).passwords_do_not_match;
                      }
                      return null;
                    },
                  ),
                  ),
          SizedBox(height: 20,),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
        ))
      )]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: BottomAppBar(
          elevation: 0,
          //color: Theme.of(context).scaffoldBackgroundColor,
          color: Colors.transparent,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 20),
              SizedBox(width: double.infinity, child: RoundedBlueLight(FlatButton(
                  child: Text(ReCase(S.of(context).change_password).titleCase, style: TextStyle(color: Colors.white), textScaleFactor: 1.2), // FIXME
                  onPressed: () async {
                    try {
                      final res = await flo.changePassword(userConsumer.value.id, _password, _newPassword, authorization: oauthConsumer.value.authorization);
                      showDialog(
                          context: context,
                          builder: (context2) =>
                              Theme(
                                  data: floLightThemeData,
                                  child: AlertDialog(
                                    title: Text(ReCase(S.of(context).change_password).titleCase),
                                    content: Text(S.of(context).your_password_has_been_successfully_changed),
                                    actions: <Widget>[
                                      FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () async {
                                            Navigator.of(context2).pop();
                                            Navigator.of(context).pop();
                                          }),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                  )
                              )
                      );
                    } catch (e) {
                      Fimber.e("", ex: e);
                      showDialog(
                          context: context,
                          builder: (context) =>
                              Theme(
                                  data: floLightThemeData,
                                  child: AlertDialog(
                                    title: Text(ReCase(S.of(context).change_password).titleCase),
                                    content: Text(S.of(context).something_went_wrong_please_retry),
                                    actions: <Widget>[
                                      FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          }),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                  )
                              )
                      );
                    }
                    //Navigator.of(context).pushNamed('/404');
                  }),
                width: double.infinity,
              )),
              SizedBox(height: 20),
            ],)),
            ),
        );

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
