import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/device_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'home_settings_page.dart';
import 'model/app_info.dart';
import 'model/device.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/health_test.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'model/valve.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:intl/intl.dart';


class HealthTestScreen extends StatefulWidget {
  HealthTestScreen({Key key}) : super(key: key);

  State<HealthTestScreen> createState() => _HealthTestScreenState();
}

class _HealthTestScreenState extends State<HealthTestScreen> with AfterLayoutMixin<HealthTestScreen>, TickerProviderStateMixin<HealthTestScreen> {
  AnimationController _scaleController;
  AnimationController _colorController;
  AnimationController _progressController;
  Animation<double> _progressAnimation;
  Animation<Color> _colorAnimation;
  //int _circles;
  bool _loaded = false;
  StreamSubscription _sub;
  StreamSubscription _sub2;
  StreamSubscription _deviceSub;
  //Subject<Device> _device = BehaviorSubject();
  Stream<Device> _device;

  @override
  void dispose() {
    _sub?.cancel();
    _sub2?.cancel();
    _deviceSub?.cancel();
    _scaleController?.dispose();
    _colorController?.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _colorController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _colorAnimation = ColorTween(
                    begin: Color(0xFF61CC37),
                    end: Color(0xFF1D7DB7),
                  ).animate(_colorController);
    _progressController = AnimationController(vsync: this, duration: Duration(minutes: 5));
    _progressAnimation = CurvedAnimation(
                  parent: Tween(begin: 0.0, end: 1.0).animate(_progressController),
                  curve: Curves.linear,
                );
    /*
    _scaleAnimation = CurvedAnimation(
                  parent: Tween(begin: 1.0, end: 0.8).animate(_scaleController),
                  curve: Curves.fastOutSlowIn,
                );
    */
    _loaded = false;

    _device = Stream.empty();

    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);

    locationProvider.value = locationProvider.value.rebuild((b) => b..occupants = max((b.occupants ?? 1), 1));
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    final isMetricKpa = userProvider.value.unitSystem == UnitSystem.metricKpa;

    Future.delayed(Duration.zero, () async {
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
      final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
      final device = deviceConsumer.value;
      final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final prefs = Provider.of<PrefsNotifier>(context, listen: false).value;
      //_device.add(deviceConsumer.value);
      setState(() {
        _device = Stream.fromIterable([deviceConsumer.value]);
      });

      try {
        final roundId = prefs.getString("health_test_round_id");
        Fimber.d("device.healthTest: ${device.healthTest}");

        HealthTest runningHealthTest;
        if (device.healthTest?.isRunning ?? false) {
          _scaleController.forward();
          _colorController.forward();
          runningHealthTest = await flo.getHealthTestOrRun(device.id, device.healthTest, authorization: oauthConsumer.value.authorization);
          if (runningHealthTest == null) {
            Navigator.of(context).pushReplacementNamed('/health_test_interrupt');
            return;
          }
          final now = DateTime.now();
          final startDate = DateTimes.ofNull(runningHealthTest?.startDate) ?? now;
          final shouldEndDate = startDate.add(Duration(minutes: 5));
          final progress = (now.difference(startDate)).inSeconds / (shouldEndDate.difference(startDate)).inSeconds;
          await _progressController.animateTo(progress, duration: Duration(milliseconds: 200), curve: Curves.fastOutSlowIn);
          _progressController.forward(from: progress);
        } else {
          if (device.healthTest != null) {
            runningHealthTest = (await flo.getHealthTestOrRun(device.id, device.healthTest, authorization: oauthConsumer.value.authorization));
          } else {
            runningHealthTest = (await flo.runHealthTest(device.id, authorization: oauthConsumer.value.authorization)).body;
          }
          Fimber.d("running2: ${runningHealthTest}");
        }
        if (runningHealthTest == null) {
          Navigator.of(context).pushReplacementNamed('/health_test_interrupt');
          return;
        }

        prefs.setString("health_test_round_id", runningHealthTest?.roundId);
        final platform = await PackageInfo.fromPlatform();
        final res = await flo.presence(AppInfo((b) => b
          ..appName = "flo-android-app2"
          ..appVersion = platform.version
        ), authorization: oauthConsumer.value.authorization);
        _sub2 = Observable.range(0, 1<<16)
            .interval(Duration(seconds: 30))
            .flatMap((it) => Stream.fromFuture(flo.presence(AppInfo((b) => b
          ..appName = "flo-android-app2"
          ..appVersion = platform.version
        ), authorization: oauthConsumer.value.authorization)))
            .listen((_) {});
        final firestoreToken = await flo.getFirestoreToken(
            authorization: oauthConsumer.value.authorization);
        final firebaseUser = await floStreamService.login(
            firestoreToken.body.token);
        Fimber.d("user: ${firebaseUser}");
        setState(() {
          _deviceSub?.cancel();
          /*
          _deviceSub = Observable(floStreamService.device(deviceConsumer.value.macAddress))
          .map((it) {
            //Fimber.d("valveState: ${it.valveState}");
            Fimber.d("it.valve: ${it.valve}");
            return it;
          })
          .map((it) => it.mergeValve(it.valveState))
          .listen((it) {
            _device.add(it);
          }, onError: (e) {
            Fimber.e("$e");
          });
          */

          _device = floStreamService.device(deviceConsumer.value.macAddress)
              .map((it) => it.mergeValve(it.valveState))
              .map((it) => it.mergeValve(it.valve));

          _sub = Observable(floStreamService.healthTest(deviceConsumer.value.macAddress))
              .doOnData((it) {
            Fimber.d("healthTest: $it");
          })
              .doOnData((it) {
            Fimber.d("healthTest: ${it.status}");
            switch (it?.status) {
              case HealthTest.PENDING: {
              }
              break;
              case HealthTest.RUNNING: {
                _scaleController.forward();
                _colorController.forward();
                _progressController.forward();
              }
              break;
              case HealthTest.COMPLETED: {
                if (_completed) return;
                _completed = true;

                //Navigator.of(context).pushReplacementNamed('/health_test_result'); // small drip
                _progressController.animateTo(1.0, duration: Duration(milliseconds: 200), curve: Curves.fastOutSlowIn);
                prefs.setString("health_test_round_id", null);
                Future(() async {
                  final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                  final healthTest = (await flo.getHealthTest(deviceConsumer.value.id, authorization: oauthConsumer.value.authorization)).body;
                  deviceProvider.value = deviceProvider.value.rebuild((b) => b
                    ..healthTest = healthTest?.toBuilder()
                  );

                  if ((healthTest?.leakType ?? HealthTest.LEAK_SUCCESSFUL) == HealthTest.LEAK_SUCCESSFUL) {
                    //Navigator.of(context).pushReplacementNamed('/health_test_result'); // FOR TESTING
                    Navigator.of(context).pushReplacementNamed('/health_test_no_leak_result');
                  } else {
                    Navigator.of(context).pushReplacementNamed('/health_test_result');
                  }
                });
              }
              break;
              case HealthTest.CANCELED:
              case HealthTest.CANCELLED: {
                if (_completed) return;
                _completed = true;
                Future(() async {
                  prefs.setString("health_test_round_id", null);
                  final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                  try  {
                    //final healthTest = (await flo.getHealthTest(deviceConsumer.value.id, authorization: oauthConsumer.value.authorization)).body;
                    //deviceProvider.value = deviceProvider.value.rebuild((b) => b
                    //  ..healthTest = healthTest?.toBuilder()
                    //);
                  } catch (e) {
                    Fimber.e("", ex: e);
                  }
                  Navigator.of(context).pushReplacementNamed('/health_test_interrupt');
                });
              }
              break;
              case HealthTest.TIMEOUT: {
                if (_completed) return;
                _completed = true;
                Fimber.d("HealthTest.TIMEOUT");
                prefs.setString("health_test_round_id", null);
                Future(() async {
                  final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                  final healthTest = (await flo.getHealthTest(deviceConsumer.value.id, authorization: oauthConsumer.value.authorization)).body;
                  deviceProvider.value = deviceProvider.value.rebuild((b) => b
                    ..healthTest = healthTest?.toBuilder()
                  );
                  Navigator.of(context).pushReplacementNamed('/health_test_interrupt');
                });
              }
              break;
              default: {
                Fimber.d("HealthTest status UNKNOWN: ${it?.status}");
              }
            }
          })
              .doOnError((e) {
            showDialog(
              context: context,
              builder: (context2) =>
                  Theme(data: floLightThemeData, child: Builder(builder: (context2) => AlertDialog(
                    title: Text(S.of(context).timeout),
                    actions: <Widget>[
                      FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () {
                          Navigator.of(context2).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  ))),
            );
          })
              .listen((_) {}, onError: (e) {
            Fimber.e("$e");
          });
        });
      } catch (err) {
        Fimber.e("", ex: err);
      }
      /*
        _device = floStreamService.device(deviceConsumer.value.macAddress)
            .asBroadcastStream(onCancel: (sub) => sub.cancel());
            */
      /*
      while (true) {
        await Future.delayed(Duration(seconds: 3), () {});
        _scaleController.forward();
        _colorController.forward();
        _progressController.forward();
        await Future.delayed(Duration(seconds: 4), () {});
        _progressController.reverse();
        await Future.delayed(Duration(seconds: 4), () {});
        _scaleController.reverse();
        _colorController.reverse();
        await Future.delayed(Duration(seconds: 1), () {});
      }
      */
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {

  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final flo = Provider.of<FloNotifier>(context).value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
    final device = deviceConsumer.value;
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);

    final child =
      Stack(children: <Widget>[
      FloGradientBackground(),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(S.of(context).health_test),
          centerTitle: true,
          actions: <Widget>[
            SimpleCloseButton(onPressed: () {
              showDialog(
                  context: context,
                  builder: (context2) =>
                  Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                      AlertDialog(
                        title: Text(S.of(context).cancel_health),
                        content: Text(S.of(context).are_you_sure_you_want_to_cancel_health_test_q),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(S.of(context).no),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                            child:  Text(S.of(context).yes), // FIXME
                            onPressed: () async {
                              try {
                                flo.setValveOpenById(deviceConsumer.value.id, open: true, authorization: oauthConsumer.value.authorization);
                              } catch (e) {
                                Fimber.e("", ex: e);
                              }
                              final locationsProvider = Provider.of<LocationNotifier>(context, listen: false);
                              final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                              final userProvider = Provider.of<UserNotifier>(context, listen: false);
                              deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                ..valve = deviceConsumer.value?.valve?.rebuild((b) => b..lastKnown = Valve.OPENED)?.toBuilder()
                              );
                              deviceConsumer.invalidate();

                              final devices = $(locationProvider.value.devices);
                              devices..removeWhere((it) => it.id == deviceConsumer.value.id)
                                ..add(deviceConsumer.value);
                              locationProvider.value = locationProvider.value.rebuild((b) => b..devices = ListBuilder(devices));
                              userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
                              deviceConsumer.invalidate();
                              Navigator.of(context2).pop();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                      ))),
              );
            },)
          ],
        ),
        resizeToAvoidBottomPadding: true,
        body: Column(
          children: <Widget>[
          Spacer(flex: 2,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).running_health_test_, style: Theme.of(context).textTheme.title)),
          SizedBox(height: 20,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("Your ${device.nickname ?? "device"} is currently checking your plumbing for leaks. Please do not turn on any fixtures during the test.", textScaleFactor: 1.1,)), // FIXME
          SizedBox(height: 10,),
          SizedBox(height: 320, child: Center(child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
            Animator(
              key: UniqueKey(),
              tickerMixin: TickerMixin.tickerProviderStateMixin,
              duration: Duration(milliseconds: 1200),
              cycles: !_loaded ? 0 : 1,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              //curve: Curves.easeOutSine,
              curve: Curves.easeInSine,
              //curve: Curves.easeInOutSine,
              //curve: Curves.easeOut,
              //curve: Curves.easeInOutQuart,
              //curve: Curves.linear,
              //curve: Interval(0.5, 1.0, curve: Curves.linear),
              //curve: Curves.fastOutSlowIn,
              builder: (anim) =>
              Opacity(opacity: 0.2 + 0.6 * (1-anim.value),
                child: AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, _) => Container(
                  width: 270 + 70 * anim.value,
                  height: 270 + 70 * anim.value,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ))
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: Tween(begin: 1.0, end: 0.8).animate(_scaleController),
                  curve: Curves.fastOutSlowIn,
                ),
                child: AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, _) => Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    shape: BoxShape.circle,
                  ),
                )),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) =>
                CircularProgressIndicator(
                  value: _progressAnimation.value,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26A2EE)),
                  strokeWidth: 220,
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: Tween(begin: 0.6, end: 1.0).animate(_scaleController),
                  curve: Curves.fastOutSlowIn,
                ),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), offset: Offset(0, 5), blurRadius: 14),
                    ],
                  ),
                )),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: Tween(begin: 1.0, end: 0.0).animate(_scaleController),
                  curve: Curves.fastOutSlowIn,
                ),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_colorAnimation.value),),
              ),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: Tween(begin: 0.0, end: 1.0).animate(_scaleController),
                  curve: Curves.fastOutSlowIn,
                ),
                child: 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) => Text("${(_progressAnimation.value * 100).toInt()}", style: TextStyle(color: Colors.black), textScaleFactor: 4.0,),
                      ),
                      Padding(padding: EdgeInsets.only(top: 10), child: Text(" %", style: TextStyle(color: Colors.black), textScaleFactor: 1.5)),
                    ],
                  ),
              ),
          ]))),
          AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) => Visibility(visible: _progressAnimation.value > 0.0, child:
          Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${DateFormat.ms().format(DateFormat.ms().parse("00:00")?.add((Duration(minutes: 5) * (1-_progressAnimation.value))))}",  style: Theme.of(context).textTheme.subhead))),
          )),
          SizedBox(height: 5),
          AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) => Visibility(visible: _progressAnimation.value > 0.0, child:
          Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).time_remaining, textScaleFactor: 0.9,))),
          )),
          Spacer(),
          StreamBuilder<bool>(stream: _device
          .map((it) {
            /*
            Fimber.d("v.valveState: ${it.valveState}");
            Fimber.d("v.valve: ${it.valve}");
            */
            return it;
          })
              .map((it) => it?.valve?.open ?? true), initialData: true, builder: (context, snapshot) => Enabled(
            enabled: !(snapshot?.data ?? true), child:
              ValvePipeButton2(checked: snapshot?.data ?? true,
                onChange: (checked) async {
                  bool consumed = false;
                  await showDialog(
                    context: context,
                    builder: (context2) =>
                        Theme(data: floLightThemeData, child: Builder(builder: (context2) =>
                            WillPopScope(
                                onWillPop: () async {
                                  Navigator.of(context).pop();
                                  consumed = true;
                                  return false;
                                }, child:
                            AlertDialog(
                              title: Text(S.of(context).cancel_health),
                              content: Text(S.of(context).are_you_sure_you_want_to_cancel_health_test_q),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).no),
                                  onPressed: () {
                                    consumed = true;
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child:  Text(S.of(context).yes), // FIXME
                                  onPressed: () async {
                                    try {
                                      flo.setValveOpenById(deviceConsumer.value.id, open: !checked, authorization: oauthConsumer.value.authorization);
                                    } catch (e) {
                                      Fimber.e("", ex: e);
                                    }
                                    final locationsProvider = Provider.of<LocationNotifier>(context, listen: false);
                                    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                                    final userProvider = Provider.of<UserNotifier>(context, listen: false);
                                    deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                      ..valve = deviceConsumer.value?.valve?.rebuild((b) => b..lastKnown = !checked ? Valve.OPENED : Valve.CLOSED)?.toBuilder()
                                    );
                                    deviceConsumer.invalidate();

                                    final devices = $(locationProvider.value.devices);
                                    devices..removeWhere((it) => it.id == deviceConsumer.value.id)
                                      ..add(deviceConsumer.value);
                                    locationProvider.value = locationProvider.value.rebuild((b) => b..devices = ListBuilder(devices));
                                    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
                                    deviceConsumer.invalidate();
                                    Navigator.of(context2).pop();
                                    Navigator.of(context).pushReplacementNamed('/health_test_interrupt');
                                    //_rotationController.forward(from: _begin);
                                  },
                                ),
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            )))),
                  );
                  return consumed;
              },)
          )),
          Spacer(flex: 2),
        ],
        //mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),

    ]);

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class ValvePipeButton2 extends StatefulWidget {
  ValvePipeButton2({Key key,
    this.checked,
    this.factor = 1.2,
    this.onChange,
    this.onChanged,
  }) : super(key: key);

  final bool checked;
  final double factor;
  final Consumers<bool, Future<bool>> onChange;
  final ValueChanged<bool> onChanged;

  @override
  State<ValvePipeButton2> createState() => _ValvePipeButtonState();
}

class _ValvePipeButtonState extends State<ValvePipeButton2> with AfterLayoutMixin<ValvePipeButton2> {
  bool _waterOn = false;
  double _begin = 0.0;
  double _end = 0.0;
  ScrollController _scrollController;
  ScrollController _scrollControllerOff;
  double _trickyOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _waterOn = widget.checked;
    _begin = 0.0;
    _end = 0.0;
    _scrollController = ScrollController();
    _scrollControllerOff = ScrollController();
  }

@override
  void afterFirstLayout(BuildContext context) {
    Fimber.d("${_scrollController.position.maxScrollExtent}");
    //_scrollController.addListener(() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 5 * _scrollController.position.maxScrollExtent.toInt()), curve: Curves.linear);
    //setState(() {
      //_trickyOpacity = 0;
    //});
    //});
  }

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    _waterOn = widget.checked;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
            Container(height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(color: floCyan.withOpacity(0.3), offset: Offset(0, 5), blurRadius: 20),
                ],
              ),
            child: ListView.builder(
              reverse: true,
              itemExtent: 700,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Image.asset('assets/bg_water_flow.png', fit: BoxFit.fitWidth);
              },
              itemCount: 1<<31,
            ),
            ),
            Opacity(opacity: _waterOn ? _trickyOpacity : 1, child: Container(height: 50,
              child: ListView.builder(
                reverse: true,
                itemExtent: 700,
                controller: _scrollControllerOff,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  return Image.asset('assets/bg_water_flow.png', fit: BoxFit.fitWidth);
                },
                itemCount: 1<<31,
              ),
            )),
            !_waterOn ? Positioned.fill(child: Align(alignment: Alignment.centerRight, child: Container(color: floBlue2, height: 40,
            width: wp(50),
            ))) : Container(),
            Align(alignment: Alignment.center, child: InkWell(child: ValveButton2(checked: _waterOn, factor: widget.factor,),
            onTap: () async {
              if (widget.onChange != null) {
                final consumed = await widget.onChange(_waterOn);
                if (consumed) return;
              }
              setState(() {
                _end = _begin + (pi / 2);
                _waterOn = !_waterOn;
              });
              if (widget.onChanged != null) {
                await widget.onChanged(_waterOn);
              }
            },
          )),
          ]);
  }
}

class ValveButton2 extends StatefulWidget {
  ValveButton2({Key key,
    this.checked,
    this.factor = 1,
  }) : super(key: key);
  final bool checked;
  final double factor;

  _ValveButtonState createState() => _ValveButtonState();
}

class _ValveButtonState extends State<ValveButton2> with AfterLayoutMixin<ValveButton2> {
  bool _checked;
  double _begin = 0.0;
  double _end = (pi / 2);
  Widget _valveOnButton;
  Widget _valveOffButton;

  @override
  void initState() {
    super.initState();
    _checked = widget.checked ?? false;
    _begin = 0.0;
    _end = 0.0;
     //_checkedAngle = _checked ? 0 : (pi / 2);
     //_checkedAngle = (pi / 2);

    //_valveOnButton = Transform.rotate(angle: _checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_on_button.png', height: 30 * widget.factor,));
    //_valveOffButton = Transform.rotate(angle: !_checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_off_button.png', height: 30 * widget.factor,));

    //_valveOnButton = Transform.rotate(angle: 0, child: Image.asset('assets/ic_valve_on_button.png', height: 30 * widget.factor,));
    //_valveOffButton = Transform.rotate(angle: 0 , child: Image.asset('assets/ic_valve_off_button.png', height: 30 * widget.factor,));

    _valveOnButton = Transform.rotate(angle: !_checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_on_button.png', height: 30 * widget.factor,));
    _valveOffButton = Transform.rotate(angle: !_checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_off_button.png', height: 30 * widget.factor,));
    //Fimber.d("$_checked");
  }
  // false
  // init -> build -> after
  // true
  // init -> build -> after

  @override
  void afterFirstLayout(BuildContext context) {
    //Fimber.d("$_checked");
  }

  @override
  void didUpdateWidget(ValveButton2 oldWidget) {
    if (oldWidget.checked != widget.checked) {
      //Fimber.d("");
      _end += (pi / 2);
      _checked = widget.checked ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    //_checked = widget.checked ?? false;
    //Fimber.d("$_checked");
    return _checked ? Stack(children: [
              Image.asset('assets/bg_valve.png', height: 40 * widget.factor),
                Positioned.fill(child: Padding(padding: EdgeInsets.only(left: 5 * widget.factor, bottom: 1 * widget.factor), child: Align(alignment: Alignment.centerLeft, child:
                Animator(
                    key: UniqueKey(),
                    tickerMixin: TickerMixin.tickerProviderStateMixin,
                  endAnimationListener: (anim) {
                    _begin = anim.animation.value;
                  },
                  duration: Duration(milliseconds: 250),
                  tween: Tween<double>(begin: _begin, end: _end),
                  curve: Curves.fastOutSlowIn,
                  builder: (anim) => Transform.rotate(
                    angle: anim.value,
                    child: _valveOnButton,
                  )),
                 )),
              ),
              Positioned.fill(child: Padding(padding: EdgeInsets.only(right: 13 * widget.factor, bottom: 2 * widget.factor), child: Align(alignment: Alignment.centerRight, child: Text("ON", style: TextStyle(color: Colors.green[400]), textScaleFactor: widget.factor * 1.1,)))), // FIXME
              ])
            : Stack(children: [
              Image.asset('assets/bg_valve.png', height: 40 * widget.factor),
                Positioned.fill(child: Padding(padding: EdgeInsets.only(left: 5 * widget.factor, bottom: 1 * widget.factor), child: Align(alignment: Alignment.centerLeft, child:
                Animator(
                    key: UniqueKey(),
                    tickerMixin: TickerMixin.tickerProviderStateMixin,
                  endAnimationListener: (anim) {
                    _begin = anim.animation.value;
                  },
                  duration: Duration(milliseconds: 250),
                  tween: Tween<double>(begin: _begin, end: _end),
                  curve: Curves.fastOutSlowIn,
                  builder: (anim) => Transform.rotate(
                    angle: anim.value,
                    child: _valveOffButton,
                  )),
                 )),
              ),
              Positioned.fill(child: Padding(padding: EdgeInsets.only(right: 10 * widget.factor, bottom: 1 * widget.factor), child: Align(alignment: Alignment.centerRight, child: Text("END\nTEST", style: TextStyle(color: Color(0xFFD8EAF1)), textScaleFactor: widget.factor * 0.8)))), // FIXME
              ]);
  }
}
