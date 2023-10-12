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
import 'package:shimmer/shimmer.dart';
import 'home_settings_page.dart';
import 'model/answer.dart';
import 'model/device.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/preference_category.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';

class NeedsInstallDetailsScreen extends StatefulWidget {
  NeedsInstallDetailsScreen({Key key}) : super(key: key);

  State<NeedsInstallDetailsScreen> createState() => _NeedsInstallDetailsScreenState();
}

class _NeedsInstallDetailsScreenState extends State<NeedsInstallDetailsScreen> with AfterLayoutMixin<NeedsInstallDetailsScreen> {

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);

    locationProvider.value = locationProvider.value.rebuild((b) => b..occupants = max((b.occupants ?? 1), 1));
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    final isMetricKpa = userProvider.value.unitSystem == UnitSystem.metricKpa;
  }

  @override
  void initState() {
    super.initState();

    _page = 0;
    _pageController = PageController(initialPage: _page);
    _pages = <Widget>[
              PressureReducingValvePage(),
              InstallationOnIrrigationLinePage(),
            ];
    _nextText = "Next";
  }

  PageController _pageController;
  int _page;
  List<Widget> _pages;
  String _nextText;

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
    bool nextEnabled = true;
    if (_page == 0) {
      nextEnabled = deviceConsumer.value.prvInstallation != null;
    } else if (_page == 1) {
      nextEnabled = deviceConsumer.value.irrigationType != null;
    }

    final child = 
    WillPopScope(
      onWillPop: () async {
        if (hasPreviousPage(_pageController)) {
          _pageController.previousPage(
            duration: Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
          );
          return false;
        }
        return true;
      },
      child: Theme(
      data: floLightThemeData,
      child:
      Builder(builder: (context) =>
      Scaffold(
        //backgroundColor: Colors.transparent,
        appBar: AppBar(
          brightness: Brightness.light,
          //leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios), color: floBlue2,),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          //title: Text(S.of(context).goals),
          //centerTitle: true,
        ),
        body: PageView.builder(
          controller: _pageController,
          //physics: AlwaysScrollableScrollPhysics(),
          //itemBuilder: (context, i) => ConstrainedBox(constraints: const BoxConstraints.expand(), child: _pages[i % _pages.length]),
          itemBuilder: (context, i) => _pages[i % _pages.length],
          itemCount: _pages.length,
          onPageChanged: (i) {
            if (!hasNextPage(_pageController, _pages.length)) {
              _nextText = S.of(context).done;
            } else {
              _nextText = S.of(context).next;
            }
            setState(() {
              _page = i;
            });
          },
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DotsIndicator(
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
                    duration: Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                  );
                },
              ),
              SizedBox(height: 20),
              Enabled(enabled: nextEnabled, child: SizedBox(width: double.infinity, child: FlatButton(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                color: floBlue2,
                child: Text(_nextText, style: TextStyle(
                  color: Colors.white,
                  ),
                  textScaleFactor: 1.6,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                onPressed: () { // FIXME: add progress bar
                  if (!hasNextPage(_pageController, _pages.length)) {
                    Navigator.of(context).pop();

                    final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                    final flo = Provider.of<FloNotifier>(context, listen: false).value;
                    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
                    try {
                      flo.putDevice(Device((b) => b
                        ..id = deviceProvider.value.id
                        ..nickname = deviceProvider.value.nickname
                        ..irrigationType = deviceProvider.value.irrigationType
                        ..prvInstallation = deviceProvider.value.prvInstallation
                      ), authorization: oauth.authorization);
                      final userProvider = Provider.of<UserNotifier>(context, listen: false);
                      userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
                      deviceProvider.value.provisionNeedsInstall();
                    } catch (e) {
                      Fimber.e("putDevice", ex: e);
                    }
                  } else {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                    );
                  }
                },
              ))),
              SizedBox(height: 20),
            ],)),
          ),
          //resizeToAvoidBottomPadding: true,
        ))));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class PressureReducingValvePage extends StatefulWidget {
  PressureReducingValvePage({Key key}) : super(key: key);

  State<PressureReducingValvePage> createState() => _PressureReducingValvePageState();
}

class _PressureReducingValvePageState extends State<PressureReducingValvePage> with AfterLayoutMixin<PressureReducingValvePage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

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
    Theme(
      data: floLightThemeData,
      child:
      Builder(builder: (context) =>
        Column(children: <Widget>[
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text(ReCase(S.of(context).pressure_reducing_valve).titleCase, style: Theme.of(context).textTheme.title)),
          SizedBox(height: 20,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text(S.of(context).pressure_reducing_valve_q(S.of(context).device))),
          SizedBox(height: 30,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child:
          KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                    baseColor: Colors.grey[300].withOpacity(0.3),
                    highlightColor: Colors.grey[100].withOpacity(0.3),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ));
              } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.prv?.isNotEmpty ?? false)) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data.prv.map((item) =>
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                        RadioButton(label: item.longDisplay, value: item.key, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                          deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                          deviceConsumer.invalidate();
                        },
                          textAlign: TextAlign.left,
                          width: double.infinity,
                        ),
                    ),
                    ).toList()
                );
              } else {
                return Container();
              }
            },
          ),
            /*
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioButton(label: S.of(context).prv_is_before_my_flo, value: Device.BEFORE, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
              SizedBox(height: 15),
              RadioButton(label: S.of(context).prv_is_after_my_flo, value: Device.AFTER, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
              SizedBox(height: 15),
              RadioButton(label: S.of(context).i_dont_have_a_prv, value: Device.NO, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
              SizedBox(height: 15),
              RadioButton(label: S.of(context).not_sure, value: Answer.UNSURE, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
            ]),
               */
        ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        )));

    return child;
  }
}


class InstallationOnIrrigationLinePage extends StatefulWidget {
  InstallationOnIrrigationLinePage({Key key}) : super(key: key);

  State<InstallationOnIrrigationLinePage> createState() => _InstallationOnIrrigationLinePageState();
}

class _InstallationOnIrrigationLinePageState extends State<InstallationOnIrrigationLinePage> with AfterLayoutMixin<InstallationOnIrrigationLinePage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);

    locationProvider.value = locationProvider.value.rebuild((b) => b..occupants = max((b.occupants ?? 1), 1));
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
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
    Theme(
      data: floLightThemeData,
      child:
      Builder(builder: (context) =>
        Column(children: <Widget>[
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text(S.of(context).installation_on_irrigation_line, style: Theme.of(context).textTheme.title)),
          SizedBox(height: 20,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text(S.of(context).installation_on_irrigation_line_q(deviceConsumer.value.displayNameOf(context)),
              style: Theme.of(context).textTheme.subhead)),
          SizedBox(height: 30,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 50), child:
          KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                    baseColor: Colors.grey[300].withOpacity(0.3),
                    highlightColor: Colors.grey[100].withOpacity(0.3),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ));
              } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.irrigationType?.isNotEmpty ?? false)) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data.irrigationType.map((item) =>
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                        RadioButton(label: item.longDisplay, value: item.key, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                          deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                          deviceConsumer.invalidate();
                        },
                          textAlign: TextAlign.left,
                          width: double.infinity,
                        ),
                    ),
                    ).toList()
                );
              } else {
                return Container();
              }
            },
          ),
              /*
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioButton(label: S.of(context).sprinklers, value: Device.SPRINKLERS, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
              SizedBox(height: 15),
              RadioButton(label: ReCase(S.of(context).drip_irrigation).titleCase, value: Device.DRIP, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
              SizedBox(height: 15),
              RadioButton(label: S.of(context).flo_not_plumbed_on_irrigation, value: Device.NONE, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                deviceConsumer.invalidate();
              },
              textAlign: TextAlign.left,
              width: double.infinity,
              ),
            ]),
            */
        ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        )));

    return child;
  }
}
