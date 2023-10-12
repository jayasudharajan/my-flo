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

class HealthTestInterruptScreen extends StatefulWidget {
  HealthTestInterruptScreen({Key key}) : super(key: key);

  State<HealthTestInterruptScreen> createState() => _HealthTestInterruptScreenState();
}

class _HealthTestInterruptScreenState extends State<HealthTestInterruptScreen> with AfterLayoutMixin<HealthTestInterruptScreen> {
  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      final device = Provider.of<DeviceNotifier>(context, listen: false).value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      Future.delayed(Duration.zero, () async {
        _healthTest = (await flo.getHealthTest(device.id, authorization: oauth.authorization)).body;
      });
    });
  }

  HealthTest _healthTest;

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final floConsumer = Provider.of<FloNotifier>(context, listen: false);
    final flo = floConsumer.value;
    final user = Provider.of<UserNotifier>(context, listen: false).value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    //final userConsumer = Provider.of<UserNotifier>(context);
    final device = Provider.of<DeviceNotifier>(context).value;
    //final userConsumer = Provider.of<UserNotifier>(context);
    _healthTest = device.healthTest;

    var description = "It seems like the Flo by Moen device was opened or water was used during the Health Test, so the Health Test has been cancelled. To start the Health Test again, make sure the Flo device valve is closed and no fixtures are running water.";
    var description2 = "Don’t worry, your device will attempt to run health tests automatically every day to make sure you’re protected.";
    switch (_healthTest?.leakType) {
      case HealthTest.LEAK_INTERRUPT: {
        description = "The Health Test was interrupted due to water use during the test. Please make sure that there is no water running in your home and then try again.";
        description2 = "If water was not running, this may also have been caused by a pressure increase due to thermal expansion. Please wait a few minutes and then try again.";
      } break;
      case HealthTest.LEAK_SUCCESSFUL: {
      } break;
      case HealthTest.LEAK_CANCELLED: {
        description = "It seems that your Flo device valve has been opened manually or via the App.";
        description2 = "Don't worry, your device will attempt to run health tests automatically every day to make sure you're protected.";
      } break;
      case HealthTest.LEAK_CANCELED_BY_APP_OPEN: {
        description = "The Health Test has been cancelled.";
        description2 = "Don't worry, your device will attempt to run health tests automatically every day to make sure you're protected.";
      } break;
      case HealthTest.LEAK_CANCELED_BY_MANUAL_OPEN: {
        description = "It seems that your Flo device valve has been manually opened.";
        description2 = "Don't worry, your device will attempt to run health tests automatically every day to make sure you're protected.";
      } break;
      case HealthTest.LEAK_INTERRUPT_BY_WATER_USE: {
        description = "The Health Test cannot be performed when there is water running in your home. Please cease all water usage before attempting the Health Test again.";
        description2 = "Don't worry, your device will attempt to run health tests automatically every day to make sure you're protected.";
      } break;
      case HealthTest.LEAK_INTERRUPT_BY_THERMAL_EXPANSION: {
        description = "Your Health Test was not able to determine if your home is leak free due to thermal expansion in your plumbing system. This can be caused either by not having an expansion tank, or having a defective one. Please wait a few minutes and then try again. If this issue persists, please click troubleshoot to learn more or contact Flo Support.";
        description2 = "";
      } break;
      default: {
      }
    }

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
            //Transform.translate(offset: Offset(-10, 0), child: Image.asset('assets/ic_checked.png', width: 65, height: 65)),
            SizedBlueCircleIcon(),
            SizedBox(height: 30),
            Text(S.of(context).health_test_interrupted, style: Theme.of(context).textTheme.title),
            SizedBox(height: 20),
            Text(description, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
            SizedBox(height: 20),
            Text(description2, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
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
