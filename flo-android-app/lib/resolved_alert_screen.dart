import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:built_collection/built_collection.dart';
import 'package:faker/faker.dart';
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
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'flo_stream_service.dart';
import 'home_settings_page.dart';
import 'model/alarm.dart';
import 'model/alarm_action.dart';
import 'model/alert.dart';
import 'model/alert_action.dart';
import 'model/alert_feedback.dart';
import 'model/alert_feedback_option.dart';
import 'model/alert_feedback_step.dart';
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
import 'package:timeago/timeago.dart' as timeago;


class ResolvedAlertScreen extends StatefulWidget {
  ResolvedAlertScreen({Key key}) : super(key: key);

  State<ResolvedAlertScreen> createState() => _ResolvedAlertScreenState();
}

class _ResolvedAlertScreenState extends State<ResolvedAlertScreen> with AfterLayoutMixin<ResolvedAlertScreen> {
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
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final user = Provider.of<UserNotifier>(context, listen: false).value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      final alarmsProvider = Provider.of<AlarmsNotifier>(context, listen: false);
      final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
      final alert = Provider.of<AlertNotifier>(context, listen: false).value;
      _pendingValveSubject = PublishSubject<bool>();
      _pendingValveSub = _pendingValveSubject.debounceTime(Duration(seconds: 20)).listen((_) {
        setState(() {
          _pendingValve = null;
        });
      });

      final alarms = (await flo.getAlarms(authorization: oauth.authorization)).body;
      alarmsProvider.value = alarms.items;
      //floStreamService.login();
      Fimber.d("ResolvedAlertScreen: device: ${alert.device?.displayName}: ${alert.deviceId}");
      Fimber.d("ResolvedAlertScreen: device: ${alert.device?.displayName}: ${alert.device?.id}");
      Fimber.d("ResolvedAlertScreen: alert.createAt: ${alert.createAt}");
      Fimber.d("ResolvedAlertScreen: alert.createAtDateTime: ${alert.createAtDateTime}");
      Fimber.d("ResolvedAlertScreen: alert.resolvedAt: ${alert.resolvedAt}");
      Fimber.d("ResolvedAlertScreen: alert.resolvedAtDateTime: ${alert.resolvedAtDateTime}");
      Fimber.d("ResolvedAlertScreen: alert.createAgo: ${alert.createAgo}");
      Fimber.d("ResolvedAlertScreen: alert.resolutionDate: ${alert.resolutionDate}");
      /*
      _sub = floStreamService.device(alert.deviceId)
          .where((it) => it != null)
      .map((device) {
        alertProvider.value = alert.rebuild((b) => b..device = alert?.device?.merge(device)?.toBuilder() ?? device.toBuilder());
        final isConnected = device.isConnected ?? false;
        if (_isConnected != isConnected) {
          setState(() { _isConnected = isConnected; });
        }
        return device;
      })
          .map((it) => it.valve).distinct().where((it) => it != _valve).listen((valve) {
        setState(() {
          _valve = valve;
        });
      }, onError: (err) {
        Fimber.e("", ex: err);
      });
      */

      setState(() {});
    });
  }
  
  /*
  @override
  void didUpdateWidget(ResolvedAlertScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
  */

  @override
  void dispose() {
    _sub?.cancel();
    _pendingValveSub?.cancel();
    super.dispose();
  }
  
  @override
  void afterFirstLayout(BuildContext context) async {
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final user = Provider.of<UserNotifier>(context, listen: false).value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final now = DateTime.now();

    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    //final device = Provider.of<DeviceNotifier>(context).value;
    final alertProvider = Provider.of<AlertNotifier>(context);
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final location = or(() => locationsConsumer.value.firstWhere((location) => location.id == alertProvider.value.locationId));
    final device = or(() => location?.devices?.firstWhere((device) => device.id == alertProvider.value.deviceId));
    alertProvider.value = alertProvider.value.rebuild((b) => b
      ..location = location?.toBuilder() ?? b.location
      ..device = device?.toBuilder() ?? b.device
    );
    var alert = alertProvider.value;
    final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
    //final userConsumer = Provider.of<UserNotifier>(context);

    if (alert == Alert.empty) {
      return Container();
    }
    /*
    if (_alerts?.isEmpty ?? true) {
      return Container();
    }
    */

    /*
    final alert = $(_alerts).shuffled().first;
    */
    //Fimber.d("alert: ${alert.rebuild((b) => b..alarm = null)}");
    Fimber.d("alert: ${alert}");

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
              Padding(padding: EdgeInsets.only(top: 5), child: alert.alarm.severity == Alarm.CRITICAL ? Image.asset('assets/ic_critical.png', width: 65, height: 65) : alert.alarm.severity == Alarm.WARNING ? Image.asset('assets/ic_warning.png', width: 65, height: 65) : Image.asset('assets/ic_info_cyan.png', width: 65, height: 65)),
              SizedBox(width: 8),
              Expanded(child: AutoSizeText(alert.displayTitle ?? alert.alarm?.displayName ?? "", style: Theme.of(context).textTheme.title, textScaleFactor: 1.1, maxLines: 2,)),
            ],
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            ),
            SizedBox(height: 8),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${alert.location?.displayName}, ${alert.device?.displayName}", style: Theme.of(context).textTheme.subhead, textScaleFactor: 1.0,)),
            SizedBox(height: 8),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(alert.createAgo, style: Theme.of(context).textTheme.caption, textScaleFactor: 1.1,)),
            SizedBox(height: 30),
            //Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("On ${DateFormat.MMMMd().add_jm().format(alert.createAtDateTime)}, placeholder{alert.description}, ${Iterable<int>.generate(20).map((_) => faker.lorem.sentence()).join()}", style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.8)), textScaleFactor: 1.0,)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${alert.displayMessage}", style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.8)), textScaleFactor: 1.0,)),
            SizedBox(height: 30),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: AlertSummary3(alert)),
            /*
            StreamBuilder<Device>(
              initialData: alert.device,
              stream: floStreamService.device(alert.macAddress)
                  .where((it) => it != null)
                  .map((device) {
                Fimber.d("AlertScreen: device: $device");
                alertProvider.value = alert.rebuild((b) => b..device = alert?.device?.merge(device)?.toBuilder() ?? device.toBuilder());
                return alertProvider.value.device;
              }),
              builder: (context, snapshot) =>
                  Enabled(enabled: _pendingValve == null && (snapshot.data?.isConnected ?? false), child: ValvePipeButton(checked: _pendingValve ?? (snapshot.data?.valve?.open ?? false), factor: 1.2, onChange: (it) async {
                    _pendingValve = !it;
                    _pendingValve ? await flo.openValveById(alert.deviceId, authorization: oauth.authorization) : await flo.closeValveById(alert.deviceId, authorization: oauth.authorization);
                    _pendingValveSubject.add(_pendingValve);
                    setState(() {});
                    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
                    alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                    alertsStateConsumer.invalidate();
                    return true;
                  })),
            ),
            */
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        ),
      ),
    ]);

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

