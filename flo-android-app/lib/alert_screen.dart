import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flotechnologies/device_screen.dart';
import 'package:flotechnologies/model/device.dart';
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
import 'package:rxdart/rxdart.dart';
import 'model/alarm.dart';
import 'model/alert.dart';
import 'model/alert.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/valve.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';


class AlertScreen extends StatefulWidget {
  AlertScreen({Key key}) : super(key: key);

  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with AfterLayoutMixin<AlertScreen> {
  Iterable<Alert> _alerts;
  @Nullable
  Valve _valve;
  @Nullable
  bool _pendingValve;
  PublishSubject<bool> _pendingValveSubject;
  StreamSubscription _pendingValveSub;
  bool _isConnected = false;
  @Nullable
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    //arguments
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final user = Provider.of<UserNotifier>(context, listen: false).value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      final alarmsProvider = Provider.of<AlarmsNotifier>(context, listen: false);
      final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
      final alertProvider = Provider.of<AlertNotifier>(context, listen: false);
      alertProvider.value = Alert.from(ModalRoute.of(context).settings.arguments) ?? alertProvider.value;
      //final firestoreToken = await flo.getFirestoreToken(authorization: oauth.authorization);
      //final firebaseUser = await floStreamService.login(firestoreToken.body.token);
      _pendingValveSubject = PublishSubject<bool>();
      _pendingValveSub = _pendingValveSubject.debounceTime(Duration(seconds: 20)).listen((_) {
        setState(() {
          _pendingValve = null;
        });
      });

      /*
      final alarms = (await flo.getAlarms(authorization: oauth.authorization)).body;
      alarmsProvider.value = alarms.items;
      final alarm = or(() => alarmsProvider.value.firstWhere((alarm) => alarm.id == alertProvider.value.alarm.id));
      alertProvider.value = alertProvider.value.rebuild((b) => b
          ..alarm = alarm?.toBuilder() ?? b.alarm
      );
      */
      final alert = alertProvider.value;
      /*
      final alerts = (await flo.getAlertsByDeviceId(, status: Alert.TRIGGERED, authorization: oauth.authorization)).body;
      _alerts = alerts.items.map((alert) => alert.rebuild((b) => b
        ..alarm = or(() => alarms.items.firstWhere((alarm) => b.alarm.id == alarm.id).toBuilder()) ?? null
      ));
      */

      Fimber.d("AlertScreen: device: ${alert.device?.displayName}: ${alert.deviceId}");
      Fimber.d("AlertScreen: device: ${alert.device?.displayName}: ${alert.device?.id}");
      Fimber.d("AlertScreen: device.macAddress: ${alert.device?.displayName}: ${alert?.device?.macAddress}");
      Fimber.d("AlertScreen: alert.createAt: ${alert.createAt}");
      Fimber.d("AlertScreen: alert.createAgo: ${alert.createAgo}");
      Fimber.d("AlertScreen: alert.resolutionDate: ${alert.resolutionDate}");
      Fimber.d("AlertScreen: alert.resolvedAt: ${alert.resolvedAt}");

      setState(() {});

      final device = (await flo.getDevice(alert.device?.id, authorization: oauth.authorization)).body;
      if ((device.firmwareProperties?.isAlarmShutoffTimeRemaining ?? false)) {
        await showDialog(
            context: activeContext,
            builder: (context) => ThemeBuilder(data: floLightThemeData, builder: (context) =>
                KeepWaterRunningDialog(device))
        );
      }
    });
  }

  BuildContext _context;
  BuildContext get activeContext => _context ?? context;

  @override
  void dispose() {
    _sub?.cancel();
    _pendingValveSub?.cancel();
    super.dispose();
  }
  
  @override
  void afterFirstLayout(BuildContext context) {
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    Fimber.d("");
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final alertProvider = Provider.of<AlertNotifier>(context);
    alertProvider.value = Alert.from(ModalRoute.of(context).settings.arguments) ?? alertProvider.value;
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final location = or(() => locationsConsumer.value.firstWhere((location) => location.id == alertProvider.value.locationId));
    final device = or(() => location?.devices?.firstWhere((device) => device.id == alertProvider.value.deviceId));
    alertProvider.value = alertProvider.value.rebuild((b) => b
      ..location = location?.toBuilder() ?? b.location
      ..device = device?.toBuilder() ?? b.device
    );
    var alert = alertProvider.value;

    Fimber.d("${alert?.device?.macAddress}");

    if (alert == null || alert.isEmpty || alert.alarm?.severity == null || alert.device == null) {
      return Container();
    }

    Fimber.d("alert: ${alert}");
    final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;

    final child =
      Stack(children: <Widget>[
        (alert?.alarm?.severity == Alarm.CRITICAL ?? false) ? FloGradientRedBackground() : (alert?.alarm?.severity == Alarm.WARNING ?? false) ? FloGradientAmberBackground() : FloGradientBackground(),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(ReCase((alert.alarm?.severity == Alarm.CRITICAL ?? false) ? S.of(context).critical_alert
              : (alert.alarm?.severity == Alarm.WARNING ?? false) ? S.of(context).warning_alert
              : S.of(context).informative_alert
          ).titleCase),
          centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body: SingleChildScrollView(child:
        Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child:
            Row(children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 5), child: alert.alarm?.severity == Alarm.CRITICAL ? Image.asset('assets/ic_critical.png', width: 65, height: 65) : alert.alarm?.severity == Alarm.WARNING ? Image.asset('assets/ic_warning.png', width: 65, height: 65) : Image.asset('assets/ic_info_cyan.png', width: 65, height: 65)),
              SizedBox(width: 8),
              Expanded(child: AutoSizeText(alert.displayTitle ??  alert.alarm?.displayName ?? "", style: Theme.of(context).textTheme.title, textScaleFactor: 1.1, maxLines: 2,)),
            ],
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${alert.location?.displayName}, ${alert.device?.displayName}", style: Theme.of(context).textTheme.subhead, textScaleFactor: 1.0,)),
            SizedBox(height: 8),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(alert.createAgo, style: Theme.of(context).textTheme.caption, textScaleFactor: 1.1,)),
            SizedBox(height: 20),
            //Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("On ${DateFormat.MMMMd().add_jm().format(alert.createAtDateTime)}, placeholder{alert.description}, ${Iterable<int>.generate(20).map((_) => faker.lorem.sentence()).join()}", style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.8)), textScaleFactor: 1.0,)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${alert.displayMessage}", style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.8)), textScaleFactor: 1.0,)),
            SizedBox(height: 30),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: AlertSummary3(alert)),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        ),
        bottomNavigationBar:
        BottomAppBar(
          elevation: 0,
          //color: Theme.of(context).scaffoldBackgroundColor,
          color: Colors.transparent,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0), child:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 10),
              Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: FloLightBlueGradientButton(FlatButton(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(floButtonRadius)),
                  child: Text(S.of(context).troubleshoot, style: TextStyle(color: Colors.white), textScaleFactor: 1.2),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/troubleshoot');
                  }),
              ))),
              SizedBox(height: 15),
              Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: FlatButton(
                child: Text(ReCase(S.of(context).clear_alert).titleCase, textScaleFactor: 1.2,),
                padding: EdgeInsets.symmetric(vertical: 15),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: () async {
                  final res = await showClearAlert(context, alert);
                  Fimber.d("dismissed showClearAlert: $res");
                  if (res) {
                    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
                    alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                    alertsStateConsumer.invalidate();
                    Navigator.of(context).pop();
                  }
                },
              ))),
              SizedBox(height: 20),
              Visibility(visible: alert.alarm?.severity == Alarm.CRITICAL, child: StreamBuilder<Device>(
                  initialData: alert.device,
                  stream: floStreamService.device(alert.device.macAddress)
                      .where((it) => it != null)
                      .map((device) {
                    Fimber.d("AlertScreen: device: ${device?.displayName}");
                    Fimber.d("AlertScreen: device.valve: ${device?.valve}");
                    alertProvider.value = alert.rebuild((b) => b..device = alert?.device?.merge(device)?.toBuilder() ?? device.toBuilder());
                    return alertProvider.value.device;
                  }),
                  builder: (context2, snapshot) {
                    final valveOpen = snapshot.data?.valve?.open ?? false; // ignore inTransition
                    final valveClosed = snapshot.data?.valve?.closed ?? false; // ignore inTransition
                    //if (valveClosed) {
                    //  Navigator.of(context).pop();
                    //}
                    if (_pendingValve != null && _pendingValve == valveOpen) {
                      _pendingValve = null;
                    }
                    return Enabled(enabled: _pendingValve == null && (snapshot.data?.isConnected ?? false), child: ValvePipeButton(checked: _pendingValve ?? (valveOpen ?? false), factor: 1.2, onChange: (it) async {
                      final res = await onValvePressed(context, valveOpen, snapshot.data?.id);
                      if (res) {
                        final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
                        alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                        alertsStateConsumer.invalidate();
                        //Navigator.of(context).pop();
                      }
                      /*
                  _pendingValve = !it;
                  _pendingValve ? await flo.openValveById(alert.deviceId, authorization: oauth.authorization) : await flo.closeValveById(alert.deviceId, authorization: oauth.authorization);
                  _pendingValveSubject.add(_pendingValve);
                  setState(() {});
                  final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
                  alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                  alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                  alertsStateConsumer.invalidate();
                  */
                      return true;
                    }));
                  }
              )),
              SizedBox(height: 40),
            ],)
          ),
        ),
      ),
    ]);

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }

  Future<bool> onValvePressed(BuildContext context, bool checked, String deviceId) async {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
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
                        flo.setValveOpenById(deviceId, open: !checked, authorization: oauthConsumer.value.authorization);
                      } catch (e) {
                        Fimber.e("", ex: e);
                      }
                      final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                      locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
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

