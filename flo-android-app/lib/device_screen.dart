import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/flo_stream_service.dart';
import 'package:flotechnologies/model/system_mode.dart';
import 'package:flotechnologies/model/unit_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'health_test_screen.dart';
import 'model/app_info.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/health_test.dart';
import 'model/install_status.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/telemetry.dart';
import 'model/telemetry2.dart';
import 'model/valve.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceScreen extends StatefulWidget {
  DeviceScreen({Key key}) : super(key: key);

  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> with TickerProviderStateMixin, AfterLayoutMixin<DeviceScreen>, WidgetsBindingObserver {

  Subject<Telemetry2> _telemetry;
  Subject<Device> _device;
  bool _pendingValve;
  PublishSubject<bool> _pendingValveSubject;
  StreamSubscription _pendingValveSub;
  StreamSubscription _ping;
  StreamSubscription _sub3;


  @override
  void dispose() {
    _ping?.cancel();
    _sub3?.cancel();
    _device?.close();
    _telemetry?.close();
    _pendingValveSub?.cancel();
    super.dispose();
  }

  AppLifecycleState _lifecycleState;
  bool _isInstallOpen = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.inactive: {
        _ping?.cancel();
      }
      break;
      case AppLifecycleState.resumed: {
        Fimber.d("resume");
      }
      break;
      case AppLifecycleState.paused: {
        _ping?.cancel();
      }
      break;
      case AppLifecycleState.suspending: {
        _ping?.cancel();
      }
      break;
    }
  }

  @override
  void initState() {
    super.initState();
    _device = BehaviorSubject<Device>();
    _telemetry = BehaviorSubject<Telemetry2>();
    _pendingValveSubject = PublishSubject<bool>();
    _pendingValveSub = _pendingValveSubject.debounceTime(Duration(seconds: 20)).listen((_) {
      setState(() {
        _pendingValve = null;
      });
    });

    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final isDemo = flo is FloMocked;
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;
    Fimber.d("device: ${device}");
    Future.delayed(Duration.zero, () async {
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
      final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
      final locationProvider = Provider.of<LocationNotifier>(context, listen: false);
      final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
      Fimber.d("${deviceConsumer.value}");
      _device.add(deviceConsumer.value);
      _telemetry.add(deviceConsumer.value.telemetries?.current ?? Telemetry2.empty);

      try {
        final flo = Provider.of<FloNotifier>(context, listen: false).value;

        Future.delayed(Duration.zero, () async {
          try {
          final device = Provider.of<DeviceNotifier>(context, listen: false).value;
          final newDevice = (await flo.getDevice(device.id, authorization: oauthConsumer.value.authorization)).body;
          locationProvider.value = locationProvider.value.rebuild((b) => b
          ..devices = ListBuilder((locationProvider.value?.devices?.toList() ?? [])..remove(device)..add(newDevice)));
          locationProvider.invalidate();
          deviceConsumer.value = newDevice;
          deviceConsumer.invalidate();
          _device.add(deviceConsumer.value);
          } catch (e) {
            Fimber.e("", ex: e);
          }
        });

        final platform = await PackageInfo.fromPlatform();
        final res = await flo.presence(AppInfo((b) => b
          ..appName = "flo-android-app2"
          ..appVersion = platform.version
        ), authorization: oauthConsumer.value.authorization);
        _ping?.cancel();
        _ping = Observable.range(0, 1<<16)
            .interval(Duration(seconds: 30))
            .flatMap((it) => Stream.fromFuture(flo.presence(AppInfo((b) => b
          ..appName = "flo-android-app2"
          ..appVersion = platform.version
        ), authorization: oauthConsumer.value.authorization)))
            .listen((_) {});
        Fimber.d("$res");
        Fimber.d("${res.body}");
        final firestoreToken = await flo.getFirestoreToken(authorization: oauthConsumer.value.authorization);
        final firebaseUser = await floStreamService.login(firestoreToken.body.token);
        Fimber.d("DeviceScreen: user: ${firebaseUser}");
          _sub3 = Observable(floStreamService.device(deviceConsumer.value.macAddress))
              .distinct()
              .map((it) {
                final deviceProvider = Provider.of<DeviceNotifier>(navigator.of().context, listen: false);
                deviceProvider.value = deviceProvider.value.merge(it);
                return deviceProvider.value;
              })
              .distinct()
              .listen((it) {
                if (_device?.isClosed ?? true) {
                } else {
                  _device?.add(it);
                  final isConnected = it.isConnected ?? false;
                  if (!isConnected) _telemetry.add(Telemetry2.empty);
                  else _telemetry.add(it?.telemetries?.current);
                }
              });
      } catch (e) {
        Fimber.e("DeviceScreen", ex: e);
      }
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;

    if (!_isInstallOpen) {
      Future.delayed(Duration.zero, () async {
        final bool isNeededShowNeedsInstall = await device.isNeededShowNeedsInstallAsync ?? false;
        Fimber.d("isNeededShowNeedsInstall: $isNeededShowNeedsInstall");
        Fimber.d("device.installStatus: ${device.installStatus}");
        Fimber.d("device.installStatus?.isJustInstalled(): ${device.installStatus?.isJustInstalled()}");
        Fimber.d("device.installStatus?.duration: ${device.installStatus?.duration}");
        if (isNeededShowNeedsInstall) {
          Navigator.of(context).pushNamed('/needs_install');
          _isInstallOpen = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("build");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
    final flo = Provider.of<FloNotifier>(context).value;
    final isDemo = flo is FloMocked;
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    final oauth = oauthConsumer.value;
    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
    if (deviceConsumer.value == Device.empty) {
      Fimber.e("Current device is Device.empty");
      Navigator.of(context).pop();
    }
    if (alertsStateConsumer.value.dirty ?? false) {
      alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = false);
      Future(() async {
        try {
          final alertStatistics = (await flo.getAlertStatistics(authorization: oauth.authorization)).body;
          deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..notifications = alertStatistics.toBuilder());
        } catch (err) {
          Fimber.e("", ex: err);
        }
      });
    }

    final wifIcon = StreamBuilder<Device>(stream: _device, builder: (context, snapshot) {
      Widget wifIcon;
      final isConnected = snapshot.data?.isConnected ?? false;
      if (isConnected) {
        wifIcon = WifiSignalIcon(snapshot.data?.connectivity?.rssi?.toDouble() ?? -40, color: Colors.white);
      } else {
        wifIcon = SvgPicture.asset('assets/ic_wifi_offline.svg', height: 26,);
      }
      return wifIcon;
    });

    final systemModeIcon = StreamBuilder<Device>(stream: _device, builder: (context, snapshot) {
      final device = snapshot.data;
      return SystemModeBadge(device: device);
    });

    final unit = userConsumer.value.unitSystem ?? UnitSystem.metricKpa;
    final bool isMetric = (userConsumer.value.unitSystem == UnitSystem.metricKpa) ?? false;
    final child =
      Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Stack(children: <Widget>[
          FloGradientBackground(),
          Material(color: Colors.transparent, child:
        SafeArea(child: NestedScrollView(
            //controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                  brightness: Brightness.dark,
                  leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                  //backgroundColor: Colors.transparent,
                  //backgroundColor: Color(0xFF0C679C),
                  //backgroundColor: Color(0xFF073F62),
                  // centerTitle: true,
                    //expandedHeight: 1.0,
                    //flexibleSpace: Container(),
                    floating: true,
                    snap: true,
                    //pinned: true,
                    actions: <Widget>[
                      FlatButton(child: 
                          Row(children: <Widget>[
                            Text(ReCase(S.of(context).device_settings).titleCase, style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white.withOpacity(0.5)),),
                            SizedBox(width: 5,),
                            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white.withOpacity(0.5)),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/device_settings');
                          },
                      )
                    ],
                  ),
            ],
          body: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Row(children: <Widget>[
            SizedBox(width: 25,),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
              Text(deviceConsumer.value.displayNameOfOr(context) ?? S.of(context).nickname, style: Theme.of(context).textTheme.title, maxLines: 1, overflow: TextOverflow.ellipsis,),
              SizedBox(height: 5,),
              Text(location.displayName, style: Theme.of(context).textTheme.subtitle.copyWith(color: Colors.white.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis,),
              SizedBox(height: 10,),
              Row(children: <Widget>[
                //Icon(Icons.wifi),
                wifIcon,
                SizedBox(width: 8,),
                systemModeIcon,
              ],)
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
            )),
            StreamBuilder<Device>(stream: _device, builder: (context, snapshot) =>
    //Enabled(
    //enabled: _pendingValve == null && (snapshot?.data?.isConnected ?? false), child: pipe ?? ValvePipeButton(checked: _pendingValve ?? valveOpened, factor: 1.2,
    //onChange: (checked) async => await onValvePressed(context, checked),
    //)); }
            Enabled(enabled: _pendingValve == null && (snapshot?.data?.isConnected ?? false) && !(snapshot?.data?.valve?.inTransitioned ?? false), child: IconButton(icon: Transform.translate(offset: Offset(32, 10), child: FloDeviceOnOffIcon2(_pendingValve ?? (snapshot?.data?.valve?.open ?? false), snapshot?.data?.isConnected ?? false)),
              iconSize: 96,
              onPressed: () async {
                final valveOpened = ((snapshot?.data?.valve?.open) ?? false);
                await onValvePressed(context, valveOpened);
              },
            ))),
            SizedBox(width: 20,),
          ],
          ),
          StreamBuilder<Device>(stream: _device, builder: (context, snapshot) {
            final device = snapshot.data;
            Fimber.d("DeviceScreen: NotificationCard: ${device?.notifications}");

            Fimber.d("_isInstallOpen: $_isInstallOpen");
            if (!_isInstallOpen) {
              device?.isNeededShowNeedsInstallAsync?.then((isNeededShowNeedsInstall) {
                Fimber.d("isNeededShowNeedsInstall: $isNeededShowNeedsInstall");
                Fimber.d("device.installStatus: ${device.installStatus}");
                Fimber.d("device.installStatus?.isJustInstalled(): ${device.installStatus?.isJustInstalled()}");
                Fimber.d("device.installStatus?.duration: ${device.installStatus?.duration}");
                if (isNeededShowNeedsInstall) {
                  Navigator.of(context).pushNamed('/needs_install');
                  _isInstallOpen = true;
                }
              });
            }
            //Fimber.d("Telemetry: ${snapshot?.data?.telemetries?.current}");
            return Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: NotificationCard(
              notification: device?.notifications?.pending,
              device: device,
              systemMode: device?.systemMode,
              orElse: YoureSecure(margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20.0)),
            ));
          }),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Colors.white.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(children: [
                Meter(
                  width: wp(26),
                  stream: _telemetry
                  .map((it) {
                    Fimber.d("pressure: ${it}");
                    return it;
                  })
                  .map((it) => it.pressure ?? 0)
                  .map((it) => isMetric ? toKpa(it) : it),
                  labelText: Text(isMetric ? S.of(context).kpa : S.of(context).psi_, style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),),
                  //min: isMetric ? toKpa(0) : 0,
                  //max: isMetric ? toKpa(100) : 100,
                  //minText: Text("  ${isMetric ? NumberFormat("#.#").format(toKpa(0)) : 0}"), // FIXME
                  //maxText: Text("${isMetric ? NumberFormat("#.#").format(toKpa(100)) : 100}"), // FIXME
                  //min: isMetric ? 0 : 0,
                  //max: isMetric ? 700 : 100,
                  //minText: Text("  ${NumberFormat("#.#").format(isMetric ? 0 : 0)}"), // FIXME
                  //maxText: Text("${NumberFormat("#.#").format(isMetric ? 700 : 100)}"), // FIXME
                  min: deviceConsumer.value.hardwareThresholds?.minPressure(unit)?.toDouble() ?? 0,
                  max: deviceConsumer.value.hardwareThresholds?.maxPressure(unit)?.toDouble() ?? 100,
                  minText: Text("  ${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.pressureThreshold(unit)?.minValue ?? 0)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  maxText: Text("${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.pressureThreshold(unit)?.maxValue ?? 100)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  warningMin: deviceConsumer.value?.hardwareThresholds?.pressureThreshold(unit)?.okMin?.toDouble(),
                  warningMax: deviceConsumer.value?.hardwareThresholds?.pressureThreshold(unit)?.okMax?.toDouble(),
                ),
                Text(S.of(context).pressure, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),),
                SizedBox(height: 10,)
                ]),
                Column(children: [
                Meter(
                  width: wp(26),
                  background: Image.asset('assets/bg_meter_max.png', width: wp(26)),
                  stream: _telemetry
                  .map((it) {
                    Fimber.d("flow: ${it}");
                    return it;
                  })
                  .map((it) => it.flow ?? 0)
                  .map((it) => isMetric ? toLiters(it) : it),
                  labelText: Text(isMetric ? "lpm" : "gpm", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),),
                  // dynamic conversion
                  //min: isMetric ? toLiters(0) : 0,
                  //max: isMetric ? toLiters(16) : 16,
                  // text format
                  //minText: Text("  ${isMetric ? NumberFormat("#.#").format(toLiters(0)) : 0}"), // FIXME
                  //maxText: Text("${isMetric ? NumberFormat("#.#").format(toLiters(16)) : 16}"), // FIXME
                  // fixed
                  //min: isMetric ? 0 : 0,
                  //max: isMetric ? 60 : 16,
                  //minText: Text("  ${NumberFormat("#.#").format(isMetric ? 0 : 0)}"), // FIXME
                  //maxText: Text("${NumberFormat("#.#").format(isMetric ? 60 : 16)}"), // FIXME
                  min: deviceConsumer.value.hardwareThresholds?.flowThreshold(unit)?.minValue?.toDouble() ?? 0,
                  max: deviceConsumer.value.hardwareThresholds?.flowThreshold(unit)?.maxValue?.toDouble() ?? 16,
                  minText: Text("  ${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.flowThreshold(unit)?.minValue ?? 0)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  maxText: Text("${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.flowThreshold(unit)?.maxValue ?? 16)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  warningMin: deviceConsumer.value?.hardwareThresholds?.flowThreshold(unit)?.okMin?.toDouble(),
                  warningMax: deviceConsumer.value?.hardwareThresholds?.flowThreshold(unit)?.okMax?.toDouble(),
                  warningMinAngle: 0,
                ),
                Text(ReCase(S.of(context).flow_rate).titleCase, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),),
                SizedBox(height: 10,)
                ]),
                Column(children: [
                  Meter(
                  width: wp(26),
                  stream: _telemetry
                  .map((it) {
                    Fimber.d("temperature: ${it}");
                    return it;
                  })
                  .map((it) => it.temperature ?? 0)
                  .map((it) => isMetric ? toCelsius(it) : it),
                  labelText: Text(isMetric ? "°C" : "°F", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),), // FIXME
                  //min: isMetric ? toCelsius(0) : 0,
                  //max: isMetric ? toCelsius(100) : 100,
                  //minText: Text("  ${isMetric ? NumberFormat("#.#").format(toCelsius(0)) : 0}"),
                  //maxText: Text("${isMetric ? NumberFormat("#.#").format(toCelsius(100)) : 100}"),
                  //min: isMetric ? -16 : 0,
                  //max: isMetric ? 40 : 100,
                  //minText: Text("  ${NumberFormat("#.#").format(isMetric ? -16 : 0)}"),
                  //maxText: Text("${NumberFormat("#.#").format(isMetric ? 40 : 100)}"),
                  min: deviceConsumer.value.hardwareThresholds?.temperatureThreshold(unit)?.minValue?.toDouble() ?? 0,
                  max: deviceConsumer.value.hardwareThresholds?.temperatureThreshold(unit)?.maxValue?.toDouble() ?? 100,
                  minText: Text("  ${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.temperatureThreshold(unit)?.minValue ?? 0)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  maxText: Text("${NumberFormat("#").format(deviceConsumer.value.hardwareThresholds?.temperatureThreshold(unit)?.maxValue ?? 100)}", style: TextStyle(color: Color(0xFFF7FAFC))),
                  warningMin: deviceConsumer.value?.hardwareThresholds?.temperatureThreshold(unit)?.okMin?.toDouble(),
                  warningMax: deviceConsumer.value?.hardwareThresholds?.temperatureThreshold(unit)?.okMax?.toDouble(),
                  showFloat: false,
                ),
                Text(S.of(context).temperature, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),),
                SizedBox(height: 10,)
                ]),
            ],),
          ),
          //SizedBox(height: 10,),
          StreamBuilder<Device>(stream: _device, builder: (context, snapshot) {
            final device = snapshot.data;
            final running = (device?.healthTest?.running ?? false);
            final isConnected = snapshot.data?.isConnected ?? false;
            final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
            deviceConsumer.value = deviceConsumer.value.merge(device);
            //Fimber.d("healthTest: ${device?.healthTest}");
            //Fimber.d("healthTest.running: ${device?.healthTest}");
          return Card(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20.0),
            color: Colors.white,
            child: Column(
              //mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: double.infinity,),
                SizedBox(height: 10,),
                Padding(padding: EdgeInsets.only(left: 16, right: 12), child:
                Row(children: <Widget>[
                  Expanded(child: Text(!running ? S.of(context).check_your_plumbing_for_leaks : S.of(context).running_health_test_, style: Theme.of(context).textTheme.subhead.copyWith(color: Color(0xFF626262)), textScaleFactor: 1.1)),
                  IconButton(
                    //icon: Icon(Icons.info_outline, color: floBlue),
                    icon: SvgPicture.asset('assets/ic_info_grey.svg'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context2) =>
                            Theme(data: floLightThemeData, child: Builder(builder: (context2) => AlertDialog(
                              title: Text(ReCase(S.of(context).about_health_test).titleCase),
                              content: Text(S.of(context).run_health_test_hint),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).ok),
                                  onPressed: () { Navigator.of(context2).pop(); },
                                ),
                              ],
                            ))),
                      );
                    },
                  ),
                ],
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                 ),
                Center(child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(floButtonRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 1.0],
                      colors: [
                        Color(0xFF3EBBE2),
                        Color(0xFF2790BE),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(0),
                    padding: EdgeInsets.all(0),
                    child:
                    Enabled(enabled: isConnected, child: FlatButton(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(floButtonRadius)),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      child: Text(!running ? ReCase(S.of(context).run_health_test).titleCase : ReCase(S.of(context).view_progress).titleCase, style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white), textScaleFactor: 1.1),
                      onPressed: () {
                        //final device = Provider.of<DeviceNotifier>(context, listen: false).value;
                        final device = snapshot.data;
                        final installed = device?.installStatus?.isInstalled ?? false;
                        if (running) {
                          Navigator.of(context).pushNamed('/health_test');
                        } else if (!installed) {
                          showDialog(
                            context: context,
                            builder: (context2) =>
                                Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                                    AlertDialog(
                                      title: Text(S.of(context).can_not_run_health_test),
                                      content: Text(S.of(context).device_not_installed),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                            //Navigator.of(context2).pushReplacementNamed('/health_test'); // TESTING
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ))),
                          );
                        //} else if ((device?.telemetries?.current?.flow ?? 0) > 0) {
                        } else if ((device?.telemetries?.current?.flow ?? 0) > 1.1) {
                          showDialog(
                            context: context,
                            builder: (context2) =>
                                Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                                    AlertDialog(
                                      title: Text(S.of(context).can_not_run_health_test),
                                      content: Text(S.of(context).flow_open),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ))),
                          );
                        } else if ((device?.telemetries?.current?.pressure ?? 0) < 10 && (device?.valve?.open ?? false)) {
                          showDialog(
                            context: context,
                            builder: (context2) =>
                                Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                                    AlertDialog(
                                      title: Text(S.of(context).can_not_run_health_test),
                                      content: Text(S.of(context).psi_below_10_valve_opened),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ))),
                          );
                        } else if ((device?.telemetries?.current?.pressure ?? 0) < 10 && (device?.valve?.closed ?? true)) {
                          showDialog(
                            context: context,
                            builder: (context2) =>
                                Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                                    AlertDialog(
                                      title: Text(S.of(context).can_not_run_health_test),
                                      content: Text(S.of(context).psi_below_10_valve_closed),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ))),
                          );
                        } else if ((device?.telemetries?.current?.pressure ?? 0) > 10 && (device?.valve?.closed ?? true)) {
                          showDialog(
                            context: context,
                            builder: (context2) =>
                                Theme(data: floLightThemeData, child: Builder(builder: (context3) =>
                                    AlertDialog(
                                      title: Text(S.of(context).can_not_run_health_test),
                                      content: Text(S.of(context).psi_above_10_valve_closed),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).ok),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    ))),
                          );
                        } else {
                        showDialog(
                          context: context,
                          builder: (context2) =>
                            Theme(data: floLightThemeData, child: Builder(builder: (context2) =>
                              WillPopScope(
                                onWillPop: () async {
                                  Navigator.of(context).pop();
                                  return false;
                                }, child: 
                            AlertDialog(
                              title: Text(S.of(context).run_health_test),
                              content: Text(S.of(context).health_tests_continue_q),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context2).pop();
                                  },
                                ),
                                FlatButton(
                                  child:  Text(S.of(context).run,
                                    //style: Theme.of(context2).textTheme.button.copyWith(fontWeight: FontWeight.bold),
                                  ), // FIXME
                                  onPressed: () {
                                    Navigator.of(context2).pushReplacementNamed('/health_test');
                                  },
                                ),
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            )))),
                        );
                        }
                      }),),
                    ),
                )),
                SizedBox(height: 20,),
          ],));}),
          SizedBox(height: 20,),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20.0),
              //child: WaterUsageCard(macAddress: deviceConsumer.value.macAddress,)
          ),
          SizedBox(height: 80,),
        ],))
      )))]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: BottomAppBar(
          color: Colors.transparent,
          elevation: 0.0,
          child:
            Column(children: <Widget>[
              StreamBuilder<Device>(stream: _device, builder: (context2, snapshot) {
                final device = snapshot?.data;
                final valveOpened = ((snapshot?.data?.valve?.open) ?? false);
                if (_pendingValve != null && _pendingValve == valveOpened) {
                  _pendingValve = null;
                }
                Widget pipe;
                if ((device?.healthTest?.status == HealthTest.RUNNING) ?? false) {
                  pipe = ValvePipeButton2(checked: valveOpened ?? true,
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
                    },);
                }
              return Enabled(
                  enabled: _pendingValve == null && (snapshot?.data?.isConnected ?? false) && !(snapshot?.data?.valve?.inTransitioned ?? false), child: pipe ?? ValvePipeButton(checked: _pendingValve ?? valveOpened, factor: 1.2,
                onChange: (checked) async => await onValvePressed(context, checked),
              )); }
              ),
              SizedBox(height: 30,),
    ],
              mainAxisSize: MainAxisSize.min,
            ),
        ),
      );

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }

  Future<bool> onValvePressed(BuildContext context, bool checked) async {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final deviceConsumer = Provider.of<DeviceNotifier>(context, listen: false);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
                  bool consumed = false;
                  await showDialog(
                    context: context,
                    builder: (context) =>
                        Theme(data: floLightThemeData, child: Builder(builder: (context2) =>
                            WillPopScope(
                                onWillPop: () async {
                                  Navigator.of(context).pop();
                                  consumed = true;
                                  return false;
                                }, child:
                            AlertDialog(
                              title: Text(checked ? ReCase(S.of(context).turn_off_water).titleCase : ReCase(S.of(context).turn_on_water).titleCase),
                              content: Text(checked ? S.of(context).please_confirm_you_want_your_flo_device_to_turn_off_your_water
                                  : S.of(context).please_confirm_you_want_your_flo_device_to_turn_on_your_water),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    consumed = true;
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child:  Text(checked ? ReCase(S.of(context).turn_off).titleCase : ReCase(S.of(context).turn_on).titleCase,
                                    //style: Theme.of(context2).textTheme.button.copyWith(fontWeight: FontWeight.bold),
                                  ), // FIXME
                                  onPressed: () async {
                                    setState(() {
                                      _pendingValve = !checked;
                                    });
                                    _pendingValveSubject.add(!checked);
                                    try {
                                      flo.setValveOpenById(deviceConsumer.value.id, open: !checked, authorization: oauthConsumer.value.authorization);
                                    } catch (e) {
                                      Fimber.e("", ex: e);
                                    }
                                    final locationsProvider = Provider.of<LocationNotifier>(context, listen: false);
                                    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                                    final userProvider = Provider.of<UserNotifier>(context, listen: false);
                                    deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                      ..valve = deviceConsumer.value?.valve?.rebuild((b) => b..lastKnown = !checked ? Valve.OPEN : Valve.CLOSED)?.toBuilder()
                                    );
                                    //_device.add(deviceConsumer.value);
                                    //deviceConsumer.invalidate();

                                    final devices = $(locationProvider.value.devices);
                                    devices..removeWhere((it) => it.id == deviceConsumer.value.id)
                                      ..add(deviceConsumer.value);
                                    locationProvider.value = locationProvider.value.rebuild((b) => b..devices = ListBuilder(devices));
                                    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
                                    deviceConsumer.invalidate();
                                    Navigator.of(context).pop();
                                    //_rotationController.forward(from: _begin);
                                  },
                                ),
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            )))),
                  );
                  return consumed;
                }
}


class ValveButtonOn extends StatelessWidget {
  ValveButtonOn({Key key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
              Image.asset('assets/bg_valve.png', height: 40),
                Positioned.fill(child: Padding(padding: EdgeInsets.only(left: 5, bottom: 1), child: Align(alignment: Alignment.centerLeft, child:
                    Image.asset('assets/ic_valve_on_button.png', height: 30,)
                 )),
              ),
              Positioned.fill(child: Padding(padding: EdgeInsets.only(right: 14, bottom: 1), child: Align(alignment: Alignment.centerRight, child: Text("ON", style: TextStyle(color: Colors.green))))),
              ]);
  }
}

class ValveButtonOff extends StatelessWidget {
  ValveButtonOff({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
              Image.asset('assets/bg_valve.png', height: 40),
              Positioned.fill(child: Padding(padding: EdgeInsets.only(left: 5, bottom: 1), child: Align(alignment: Alignment.centerLeft, child:
                  Image.asset('assets/ic_valve_off_button.png', height: 30,),
              ))),
    ]);
  }
}

class ValveButton extends StatefulWidget {
  ValveButton({Key key,
    this.checked,
    this.factor = 1,
  }) : super(key: key);
  final bool checked;
  final double factor;

  _ValveButtonState createState() => _ValveButtonState();
}

class _ValveButtonState extends State<ValveButton> with AfterLayoutMixin<ValveButton> {
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
    //_valveOnButton = Image.asset('assets/ic_valve_on_button.png', height: 30 * widget.factor);
    //_valveOffButton = Image.asset('assets/ic_valve_off_button.png', height: 30 * widget.factor);
    _valveOnButton = Transform.rotate(angle: !_checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_on_button.png', height: 30 * widget.factor,));
    _valveOffButton = Transform.rotate(angle: !_checked ? 0 : (pi / 2), child: Image.asset('assets/ic_valve_off_button.png', height: 30 * widget.factor,));
    Fimber.d("$_checked");
  }
  // false
  // init -> build -> after
  // true
  // init -> build -> after

  @override
  void afterFirstLayout(BuildContext context) {
    Fimber.d("$_checked");
  }

  @override
  void didUpdateWidget(ValveButton oldWidget) {
    if (oldWidget.checked != widget.checked) {
      Fimber.d("");
      _end += (pi / 2);
      _checked = widget.checked ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    //_checked = widget.checked ?? false;
    Fimber.d("$_checked");
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
              Positioned.fill(child: Padding(padding: EdgeInsets.only(right: 10 * widget.factor, bottom: 1 * widget.factor), child: Align(alignment: Alignment.centerRight, child: Text("OFF", style: TextStyle(color: Color(0xFFD8EAF1)), textScaleFactor: widget.factor * 1.1)))),
              ]);
  }
}

/*
class ValvePipeButton extends StatefulWidget {
}
 */

class ValvePipeButton extends StatefulWidget {
  ValvePipeButton({Key key,
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
  State<ValvePipeButton> createState() => _ValvePipeButtonState();
}

class _ValvePipeButtonState extends State<ValvePipeButton> with AfterLayoutMixin<ValvePipeButton> {
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
    Fimber.d("");
    if (Theme.of(context).platform != TargetPlatform.iOS) {
    Fimber.d("${_scrollController.position.maxScrollExtent}");
    //_scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 8 * _scrollController.position.maxScrollExtent.toInt()), curve: Curves.linear);
      }
    //setState(() {
      //_trickyOpacity = 0;
    //});
    //});
    } else {
      // TODO: implement
    }
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
              itemCount: 1<<16,
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
                itemCount: 1<<16,
              ),
            )),
            !_waterOn ? Positioned.fill(child: Align(alignment: Alignment.centerRight, child: Container(color: floBlue2, height: 40,
            width: wp(50),
            ))) : Container(),
            Align(alignment: Alignment.center, child: InkWell(child: ValveButton(checked: _waterOn, factor: widget.factor,),
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

class Meter extends StatefulWidget {
  Meter({Key key,
  @required
  this.labelText,
  @required
  this.minText,
  @required
  this.maxText,
  this.background,
  @required
  this.width,
  @required
  this.stream,
  this.min = 0,
  this.max = 100,
  //this.color = const Colors.white.withOpacity(0.5),
  //this.warningColor = const Colors.white.withOpacity(0.5),
  this.color = const Color(0xFF18D8ED),
  this.warningColor,
  this.warningMinAngle = 2 * pi * (45 / 360),
  this.warningMaxAngle = 2 * pi * (45 / 360),
  this.warningMin = double.infinity,
  this.warningMax = double.infinity,
  this.showFloat = true,
  this.duration = const Duration(milliseconds: 3000),
  }) : super(key: key);

  final Widget labelText;
  final Widget minText;
  final Widget maxText;
  final double min;
  final double max;
  final double warningMinAngle;
  final double warningMaxAngle;
  final double warningMin;
  final double warningMax;
  final Color color; // pill shadow color
  final Color warningColor; // pill shadow color for warning
  final Widget background;
  final double width;
  final Stream<double> stream;
  final bool showFloat;
  final Duration duration;

  @override
  State<Meter> createState() => _MeterState();
}

class _MeterState extends State<Meter> with AfterLayoutMixin<Meter> {

  double _begin = 0;
  double _beginLimited = 0;
  Color _color;
  Color _warningColor;
  double _warningMinAngle;
  double _warningMaxAngle;
  double _maxAngle = toAngle(360) - toAngle(120);
  double max;
  double min;
  double percentAngle;

  @override
  void initState() {
    super.initState();
    //_color = widget.color ?? Colors.lightBlue; // Color(0xFF3EBBE2)
    //_warningColor = widget.warningColor ?? Colors.red;

    //_color = Color(0xFF4ec1e4); // Color(0xFF3EBBE2)
    //_color = Color(0xFF3EBBE2);
    //_warningColor = Colors.red[400];
    _color = widget.color ?? Color(0xFF18D8ED);
    _warningColor = widget.warningColor ?? Colors.red[300];

    max = widget.max;
    min = widget.min;
    double delta = max - min;
    percentAngle = _maxAngle / delta;

    if (false && (widget.warningMin != null && widget.warningMin != double.infinity)) { // FIXME
      _warningMinAngle = percentAngle * ((widget.warningMin - min));
    } else {
      _warningMinAngle = widget.warningMinAngle;
    }
    if (false && (widget.warningMax != null && widget.warningMax != double.infinity)) { // FIXME
      _warningMaxAngle = percentAngle * ((max - widget.warningMax));
    } else {
      _warningMaxAngle = widget.warningMaxAngle;
    }
  }

  Duration _duration = Duration.zero;

  @override
  void afterFirstLayout(BuildContext context) {
    if (_duration != widget.duration) {
      Future.delayed(Duration(milliseconds: 1000), () {
        _duration = widget.duration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(stream: widget.stream, initialData: 0.0, builder: (context, snapshot) {
      final data = snapshot.data ?? 0.0;
      final limitedData = math.max(math.min(data, max), min);
      return Stack(
                children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 15), child: widget.background ?? Image.asset('assets/bg_meter_min_max.png', width: widget.width,)),
              Container(
                  margin: EdgeInsets.only(top: widget.width / 10),
                  width: widget.width * 19 / 26,
                 height: widget.width * 19 / 26,
                //margin: EdgeInsets.all(80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.5), offset: Offset(0, 5), blurRadius: 12),
                  ],
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 12), child: Animator(
                  key: UniqueKey(),
                  tickerMixin: TickerMixin.tickerProviderStateMixin,
                  duration: _duration,
                        //endAnimationListener: (anim) => _beginLimited = anim.value,
                        tween: Tween<double>(begin: _beginLimited - min, end: limitedData - min),
                        curve: Curves.decelerate,
                        builder: (anim) {
                          _beginLimited = anim.value;
                          return Transform.rotate(
                          angle: math.min(math.max(anim.value * percentAngle, 0), _maxAngle),
                          child: 
                          Container(
                            width: widget.width + 4,
                            height: widget.width + 4,
                            // -90 -30 degree
                            child: Transform.rotate(angle: toAngle(-30), child: Align(alignment: Alignment.centerLeft,
                             child: Pill(
                               //color: Colors.white.withOpacity(0.7),
                               color: (anim.value * percentAngle < _warningMinAngle || anim.value * percentAngle > (_maxAngle - _warningMaxAngle)) ? _warningColor : _color,
                               //shadowColor: (anim.value < widget.warningMinAngle || anim.value > _maxAngle - widget.warningMinAngle) ? _warningColor : _color,
                             size: Size(14, 5)))),
                          )
                        );}
                      )),
              Column(children: <Widget>[
                SizedBox(height: 10,),
                    Animator(
                        key: UniqueKey(),
                        tickerMixin: TickerMixin.tickerProviderStateMixin,
                      duration: _duration,
                      tween: Tween<double>(begin: _begin, end: data),
                      curve: Curves.decelerate,
                      builder: (anim) {
                        _begin = anim.value;
                        final floatNumber = ((anim.value * 10.0).round() % 10);
                        return Row(children: <Widget>[
                          Text("${widget.showFloat ? "" : " "}  ${NumberFormat("###").format(anim.value.toInt())}",
                            style: TextStyle(
                                color: Colors.black, fontSize: 24),),
                          Opacity(opacity: widget.showFloat ? (floatNumber == 0 ? 0.8 : 1) : 0, child: Text(".${NumberFormat("#").format(floatNumber.toInt())}", style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 16,
                              height: 1.5),))
                        ],);
                      }),
                widget.labelText,
              ],),
              //Positioned(bottom: 15, left: 0, child: Text("  0")), // FIXME
              //Positioned(bottom: 15, right: 0, child: Text("100")), // FIXME
              Positioned(bottom: 11, left: 0, child: widget.minText),
              Positioned(bottom: 11, right: 0, child: widget.maxText),
              ],
                alignment: AlignmentDirectional.center,
              );
    });
  }
}

class FloDeviceOnOffIcon2 extends StatelessWidget {
  const FloDeviceOnOffIcon2(this.opened, this.isConnected, {Key key}) : super(key: key);
  final bool opened;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: isConnected ? 1.0 : 0.5, child: opened ? Image.asset('assets/ic_flo_device_on.png', height: 70,)
        : Image.asset('assets/ic_flo_device_off.png', height: 70,));
  }
}

double toAngle(double degree) => 2 * pi * (degree / 360);

