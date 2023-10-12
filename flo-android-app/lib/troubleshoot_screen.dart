import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:faker/faker.dart';
import 'package:flotechnologies/device_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'home_settings_page.dart';
import 'model/alarm.dart';
import 'model/alert.dart';
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
import 'package:zendesk/zendesk.dart';



class TroubleshootScreen extends StatefulWidget {
  TroubleshootScreen({Key key}) : super(key: key);

  State<TroubleshootScreen> createState() => _TroubleshootScreenState();
}

class _TroubleshootScreenState extends State<TroubleshootScreen> with AfterLayoutMixin<TroubleshootScreen> {
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
      _pendingValveSubject = PublishSubject<bool>();
      _pendingValveSub = _pendingValveSubject.debounceTime(Duration(seconds: 20)).listen((_) {
        setState(() {
          _pendingValve = null;
        });
      });
    });
  }

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
    final user = Provider.of<UserNotifier>(context).value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    //final device = Provider.of<DeviceNotifier>(context).value;
    final alertProvider = Provider.of<AlertNotifier>(context);
    final alert = alertProvider.value;
    //final userConsumer = Provider.of<UserNotifier>(context);
    Fimber.d("alert?.alarm.displayName: ${alert?.alarm?.displayName}");
    Fimber.d("alert?.alarm.severity: ${alert?.alarm?.severity}");
    Fimber.d("alert?.alarm.severity: ${alert?.alarm?.supportOptions}");

    if (alert == Alert()) {
      return Container();
    }
    final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;

    /*
    Links to Zendesk article: Water Pressure Over Recommended Max: https://support.meetflo.com/hc/en-us/articles/360022528514-Water-Pressure-Over-Recommended-Max
    High Water Pressure: https://support.meetflo.com/hc/en-us/articles/115000744413-High-Water-Pressure
    Low Water Pressure: https://support.meetflo.com/hc/en-us/articles/115000744393-Low-Water-Pressure
    Freeze Warning: https://support.meetflo.com/hc/en-us/articles/115000744493-Freeze-Warning
    Hot Water: https://support.meetflo.com/hc/en-us/articles/115000764394-Hot-Water
    */
    Fimber.d("device.displayName: ${alert?.device?.displayName}");
    Fimber.d("device.macAddress: ${alert?.device?.macAddress}");

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
          title: Text(S.of(context).troubleshoot),
          centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body: SingleChildScrollView(child:
        Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child:
              Text(alert.displayTitle ?? alert.alarm?.displayName ?? "", style: Theme.of(context).textTheme.title, textScaleFactor: 1.1,),
            ),
            SizedBox(height: 5),
            or(() => alert?.alarm?.supportOptions?.first) != null ? Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: SizedBox(width: double.infinity, child: FlatButton(
              onPressed: () async {
                await launch(
                  "https://${or(() => alert?.alarm?.supportOptions?.first)?.actionPath}/1",
                  option: CustomTabsOption(
                      toolbarColor: Theme.of(context).primaryColor,
                      enableDefaultShare: true,
                      enableUrlBarHiding: true,
                      showPageTitle: true,
                      //animation: CustomTabsAnimation.slideIn()
                  ),
                );
              },
              child: Row(children: <Widget>[
                SizedBox(width: 20),
                SvgPicture.asset('assets/ic_subject2.svg'),
                SizedBox(width: 12),
                Expanded(child: Text(S.of(context).view_tips, textScaleFactor: 1.2,)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios, size: 16),
                SizedBox(width: 10),
              ],),
              padding: EdgeInsets.symmetric(vertical: 15),
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ))) : Container(),
            SizedBox(height: 5),
            Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16.0),
              color: Colors.white,
              child: Padding(padding: EdgeInsets.all(25), child: Column(children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Column(children: <Widget>[
                    Text(S.of(context).water_concierge, style: Theme.of(context).textTheme.title, textScaleFactor: 0.9,),
                    SizedBox(height: 8),
                    Text(S.of(context).live_troubleshooting_support, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 0.9,),
                  ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                  )),
                  (alert?.location?.subscription?.isActive ?? false) ? OpenChatButton(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20)) : FloActivateButton(onPressed: () {
                    Navigator.of(context).pushNamed("/floprotect");
                  },),
                ],
                ),
                SizedBox(height: 15),
                Row(children: <Widget>[
                  (alert?.location?.subscription?.isActive ?? false) ? FloProtectActiveCircleAvatar() : FloProtectInactiveCircleAvatar(),
                  SizedBox(width: 15),
                  Expanded(child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(S.of(context).water_concierge_alert_tip(alert.displayTitle ?? alert.alarm.displayName ?? ""), style: TextStyle(color: Color(0xFF073F62).withOpacity(0.5))),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Color(0xFF073F62).withOpacity(0.1), offset: Offset(0, 5), blurRadius: 14)
                      ],
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.zero,
                          topRight: Radius.circular(16.0),
                          bottomLeft: Radius.circular(16.0),
                          bottomRight: Radius.circular(16.0),
                      ),
                      border: Border.all(color: Color(0xFF073F62).withOpacity(0.1), width: 1),
                    ),
                  )),
                ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
              )),
            )))),
            SizedBox(height: 15),
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: AlertSummary3(alert)),
            SizedBox(height: 30),
            /*
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child: Row(children: <Widget>[
              Flexible(child: Column(children: <Widget>[
                Text("${duration.inMinutes} min.", style: Theme.of(context).textTheme.subhead), // FIXME
                SizedBox(height: 5),
                Text(S.of(context).health_test_duration, softWrap: true,), // FIXME
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
              )),
              SizedBox(width: 15),
              Flexible(flex: 2, child: Column(children: <Widget>[
                Text(isMetric ? "${NumberFormat("#.#").format(toLiters(leakLossMaxGal))} liters" : "${NumberFormat("#.#").format(leakLossMaxGal)} gal.", style: Theme.of(context).textTheme.subhead),
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
            */
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
              Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: alert.alarm.severity == Alarm.CRITICAL
                  ? FlatButton(
                child: Text(S.of(context).keep_my_water_running, textScaleFactor: 1.1,),
                padding: EdgeInsets.symmetric(vertical: 15),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: () async {
                  _pendingValve = true;
                  flo.openValveById(alert.deviceId, authorization: oauth.authorization);
                  final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
                  alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                  alertsStateConsumer.invalidate();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )
                  : alert.alarm.isSmallDrip ? FloLightBlueGradientButton(FlatButton(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(floButtonRadius)),
                  child: Text(S.of(context).run_health_test, style: TextStyle(color: Colors.white), textScaleFactor: 1.1),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/health_test');
                    Navigator.of(context).pop();
                  }),
              ) : Container(),
              )),
              SizedBox(height: 15),
              Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SizedBox(width: double.infinity, child: FlatButton(
                child: Text(ReCase(S.of(context).clear_alert).titleCase, textScaleFactor: 1.1,),
                padding: EdgeInsets.symmetric(vertical: 15),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: () async {
                  final res = await showClearAlert(context, alert);
                  if (res) {
                    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
                    alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                    alertsStateConsumer.invalidate();
                    Navigator.of(context).pop();
                  }
                },
              ))),
              alert.alarm.severity == Alarm.CRITICAL ? SizedBox(height: 20) : Container(),
              alert.alarm.severity == Alarm.CRITICAL
                  ?
              StreamBuilder<Device>(
                initialData: alert.device,
                stream: floStreamService.device(alert.device.macAddress)
                    .where((it) => it != null)
                    .map((device) {
                  alertProvider.value = alert.rebuild((b) => b..device = alert?.device?.merge(device)?.toBuilder() ?? alert?.device);
                  return alertProvider.value.device;
                }),
                builder: (context, snapshot) {
                  final valveOpen = snapshot.data?.valve?.open ?? false; // ignore inTransition
                  //final valveClosed = snapshot.data?.valve?.closed ?? false; // ignore inTransition
                  //if (valveClosed) {
                  //  Navigator.of(context).pop();
                  //}
                  if (_pendingValve != null && _pendingValve == valveOpen) {
                    _pendingValve = null;
                  }
                  return Enabled(enabled: _pendingValve == null && (snapshot.data?.isConnected ?? false), child: ValvePipeButton(checked: _pendingValve ?? valveOpen, factor: 1.2, onChange: (it) async {
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
                      final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
                      alertsStateConsumer.value = alertsStateConsumer.value.rebuild((b) => b..dirty = true);
                      alertsStateConsumer.invalidate();
                       */

                      return true;
                    }));
                }
              )
                  : Container(),
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
                    ),
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
