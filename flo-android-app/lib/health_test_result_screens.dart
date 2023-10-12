import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:flotechnologies/device_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'home_settings_page.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/health_test.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:intl/intl.dart';

class HealthTestResultScreen extends StatefulWidget {
  HealthTestResultScreen({Key key}) : super(key: key);

  State<HealthTestResultScreen> createState() => _HealthTestResultScreenState();
}

class _HealthTestResultScreenState extends State<HealthTestResultScreen> with AfterLayoutMixin<HealthTestResultScreen> {
  @override
  void afterFirstLayout(BuildContext context) async {
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    _healthTest = (await flo.getHealthTest(device.id, authorization: oauth.authorization)).body;
    setState(() { });
  }

  HealthTest _healthTest;


  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final user = Provider.of<UserNotifier>(context, listen: false).value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final now = DateTime.now();

    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final device = Provider.of<DeviceNotifier>(context).value;
    //final userConsumer = Provider.of<UserNotifier>(context);
    _healthTest = device.healthTest ?? _healthTest;
    if (_healthTest == null) {
      return Container();
    }

    final duration = _healthTest.duration;
    final lossPressure = _healthTest.lossPressure ?? 0;
    final leakLossMaxGal = _healthTest?.leakLossMaxGal ?? 0;

    final child =
      Stack(children: <Widget>[
      FloGradientAmberBackground(),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(S.of(context).health_test),
          centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
          children: <Widget>[
            Transform.translate(offset: Offset(-10, 0), child: Image.asset('assets/ic_warning.png', width: 65, height: 65)),
            SizedBox(height: 15),
            Text(ReCase(S.of(context).small_drip_detected).titleCase, style: Theme.of(context).textTheme.title),
            SizedBox(height: 20),
            Text(S.of(context).leaked_desc, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
            SizedBox(height: 30),
            Row(children: <Widget>[
              Flexible(child: Column(children: <Widget>[
                Text("${duration.inMinutes} min.", style: Theme.of(context).textTheme.subhead), // FIXME
                SizedBox(height: 5),
                Text(S.of(context).health_test_duration, softWrap: true,), // FIXME
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
              )),
              SizedBox(width: 15),
              Flexible(flex: 2, child: Column(children: <Widget>[
                Text(user.unitSystemOr().volumeText(context, lossPressure), style: Theme.of(context).textTheme.subhead),
                SizedBox(height: 5),
                Text(S.of(context).est_daily_waste_if_ignored, softWrap: true,), // FIXME
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
              )),
              SizedBox(width: 15),
              Flexible(child: Column(children: <Widget>[
                Text("${NumberFormat('#.#').format(lossPressure * 100)}%", style: Theme.of(context).textTheme.subhead),
                SizedBox(height: 5),
                Text(S.of(context).pressure_loss, softWrap: true,), // FIXME
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
              )),
            ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            SizedBox(height: 15),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          )),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          //color: Theme.of(context).scaffoldBackgroundColor,
          color: Colors.transparent,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 20),
              RoundedBlueLight(FlatButton(
                  child: Text(S.of(context).troubleshoot, style: TextStyle(color: Colors.white), textScaleFactor: 1.2), // FIXME
                  onPressed: () {
                    Navigator.of(context).pushNamed('/404');
                  }),
                width: double.infinity,
              ),
              SizedBox(height: 20),
            ],)),
        ),
      ),

    ]);

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class HealthTestNoLeakResultScreen extends StatefulWidget {
  HealthTestNoLeakResultScreen({Key key}) : super(key: key);

  State<HealthTestNoLeakResultScreen> createState() => _HealthTestNoLeakResultScreenState();
}

class _HealthTestNoLeakResultScreenState extends State<HealthTestNoLeakResultScreen> with AfterLayoutMixin<HealthTestNoLeakResultScreen> {
  @override
  void afterFirstLayout(BuildContext context) {

  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);

    final child =
    Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          //leading: CloseButton(),
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(S.of(context).health_test),
          centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
      Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Transform.translate(offset: Offset(-10, 0), child: Image.asset('assets/ic_checked.png', width: 65, height: 65)),
              Text(S.of(context).no_leak_detected, style: Theme.of(context).textTheme.title),
            ],),
            SizedBox(height: 20),
            Text(S.of(context).no_leak_detected_description_1, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
            SizedBox(height: 20),
            Text(S.of(context).no_leak_detected_description_2, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
            SizedBox(height: 30),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
        ))]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: BottomAppBar(
          elevation: 0,
          //color: Theme.of(context).scaffoldBackgroundColor,
          color: Colors.transparent,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FloOutlineButton(
                  child: Text(S.of(context).done, style: TextStyle(color: Colors.white), textScaleFactor: 1.2), // FIXME
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              ),
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
