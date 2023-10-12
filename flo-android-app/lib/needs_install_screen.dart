import 'dart:math';

import 'package:after_layout/after_layout.dart';
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
import 'device_screen.dart';
import 'home_settings_page.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';

class NeedsInstallScreen extends StatefulWidget {
  NeedsInstallScreen({Key key}) : super(key: key);

  State<NeedsInstallScreen> createState() => _NeedsInstallScreenState();
}

class _NeedsInstallScreenState extends State<NeedsInstallScreen> with AfterLayoutMixin<NeedsInstallScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);

    locationProvider.value = locationProvider.value.rebuild((b) => b..occupants = max((b.occupants ?? 1), 1));
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    final isMetricKpa = userProvider.value.unitSystem == UnitSystem.metricKpa;
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
          automaticallyImplyLeading: false,
          elevation: 0.0,
          //title: Text(S.of(context).goals),
          //centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
        Column(children: <Widget>[
          Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: Text(S.of(context).congratulations_on_installing_your_flo_device, style: Theme.of(context).textTheme.title)),
          SizedBox(height: 20,),
          // FIXME
          Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: Text("In order to ensure ${deviceConsumer.value?.nickname ?? "the device"} is installed properly, please take a few minutes to complete a couple more steps while your installer is still at your home!")),
          SizedBox(height: 40,),
          FlatButton(
            shape: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
              bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
            ),
            child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: 
          Row(children: <Widget>[
            Column(children: <Widget>[
              Text(ReCase(S.of(context).device_details).titleCase, style: Theme.of(context).textTheme.title),
              Text(ReCase(S.of(context).almost_done).titleCase, style: Theme.of(context).textTheme.subhead.copyWith(color: floAmber)),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: Theme.of(context).textTheme.subhead.fontSize,),
          ],)),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed("/needs_install_details");
          },
          ),
          /*
          FlatButton(
            shape: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
            ),
            child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: 
          Row(children: <Widget>[
            Column(children: <Widget>[
              Text("Device Diagnostic", style: Theme.of(context).textTheme.title),
              Text("Not Started", style: Theme.of(context).textTheme.subhead.copyWith(color: floRed)),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: Theme.of(context).textTheme.subhead.fontSize,),
          ],)),
          onPressed: () {
            Navigator.of(context).pushNamed("/needs_install_details");
          },
          ),
          */
          SizedBox(height: 100,),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        ),
       ]));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
