import 'dart:math' as math;
import 'package:after_layout/after_layout.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
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
import 'package:shimmer/shimmer.dart';
import 'package:tinycolor/tinycolor.dart';
import 'generated/i18n.dart';
import 'model/alarm.dart';
import 'model/alarms.dart';
import 'model/alert_settings.dart';
import 'model/flo.dart';

import 'model/system_mode.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:speech_bubble/speech_bubble.dart';

class AlertsSettingsScreen extends StatefulWidget {
  AlertsSettingsScreen({Key key}) : super(key: key);

  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> with AfterLayoutMixin<AlertsSettingsScreen>, TickerProviderStateMixin<AlertsSettingsScreen> {

  /*
  List<Alarm> _criticalAlarms = const <Alarm>[];
  List<Alarm> _warningAlarms = const <Alarm>[];
  List<Alarm> _infoAlarms = const <Alarm>[];
  */
  TabController _controller;
  Alarms _alarms = Alarms.empty;
  static const int TAB_AWAY = 0; 
  static const int TAB_HOME = 1; 
  double _dripLevel = 1;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      vsync: this,
    );
    _controller.index = TAB_HOME;
    _loaded = false;
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      final user = userProvider.value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      try {
        Future(() async {
          userProvider.value = (await flo.getUser(oauth.userId, authorization: oauth.authorization)).body;
        });
        _alarms = (await flo.getAlarms(authorization: oauth.authorization)).body;
        final alertsSettingsStateProvider = Provider.of<AlertsSettingsStateNotifier>(context, listen: false);
        final device = Provider.of<DeviceNotifier>(context, listen: false).value;
        final alertsSettings = or(() => userProvider.value?.alertsSettings?.firstWhere((it) => it.deviceId == device.id));
        alertsSettingsStateProvider.value = alertsSettingsStateProvider.value.rebuild((b) => b..systemMode = device.systemMode?.lastKnown ?? SystemMode.HOME);
        setState(() {
          _dripLevel = alertsSettings?.smallDripSensitivity?.toDouble() ?? 1;
          if (alertsSettingsStateProvider.value.systemMode == SystemMode.AWAY) {
            _controller.animateTo(TAB_AWAY);
          } else {
            alertsSettingsStateProvider.value = alertsSettingsStateProvider.value.rebuild((b) => b..systemMode = SystemMode.HOME);
            _controller.animateTo(TAB_HOME);
          }
          _loaded = true;
        });
      } catch (e) {
        Fimber.e("", ex: e);
      }
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
  }

  putSmallDripSensitivity(BuildContext context, int sensitivity) async {
    try {
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final device = Provider.of<DeviceNotifier>(context, listen: false).value;
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      final user = userProvider.value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      final res = await flo.putSmallDripSensitivity(sensitivity, userId: user.id, deviceId: device.id, authorization: oauth.authorization);
      Future(() async {
        userProvider.value = (await flo.getUser(oauth.userId, authorization: oauth.authorization)).body;
      });
    } catch (err) {
        Fimber.d("", ex: err);
    }
  }

  Widget speechBubble(Color color, {Widget child}) {
    return Material(
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
      color: color,
      elevation: 1.0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: child ?? Container(),
      ),
    );
  }

  Widget nip(Color color, {Offset offset = const Offset(0, 0)}) {
    return Transform.translate(
      offset: offset,
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(45 / 360),
        child: Material(
          borderRadius: BorderRadius.all(
            Radius.circular(1.5),
          ),
          color: color,
          child: Container(
            height: 10.0,
            width: 10.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final alarmsProvider = Provider.of<AlarmsNotifier>(context, listen: false);
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;
    final alertsSettingsStateProvider = Provider.of<AlertsSettingsStateNotifier>(context);
    final systemMode = alertsSettingsStateProvider.value.systemMode;
    final userProvider = Provider.of<UserNotifier>(context);
    final user = userProvider.value;
    final alertsSettings = or(() => userProvider.value?.alertsSettings?.firstWhere((it) => it.deviceId == device.id));
    //Fimber.d("alertsSettings ${alertsSettings}");

    final criticalsDisplay = _alarms.criticalsDisplay;
        //.where((it) => or(() => deviceAlertSettings.settingsMap[it.id].systemMode == alertsSettingsStateProvider.value.systemMode) ?? false);
    final warningsDisplay = _alarms.warningsDisplay;
        //.where((it) => or(() => deviceAlertSettings.settingsMap[it.id].systemMode == alertsSettingsStateProvider.value.systemMode) ?? false);
    final infosDisplay = _alarms.infosDisplay;
        //.where((it) => or(() => deviceAlertSettings.settingsMap[it.id].systemMode == alertsSettingsStateProvider.value.systemMode) ?? false);

    final child = WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      }, child: GestureDetector(
      child: Scaffold(
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
        AnimatedSwitcher(duration: Duration(milliseconds: 300), child: _loaded ? SafeArea(child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                floating: true,
                title: Text(S.of(context).alerts_settings, textScaleFactor: 1.2,),
                centerTitle: true,
              ),
              SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), sliver:
              SliverList(delegate: SliverChildListDelegate(
                <Widget>[
                  Text(S.of(context).health_test_drip_sensitivity, style: Theme.of(context).textTheme.subhead),
                SizedBox(height: 20),
                  Row(children: <Widget>[
                    Text(ReCase(S.of(context).least_sensitive).titleCase, style: Theme.of(context).textTheme.subhead),
                    Spacer(),
                    Text(ReCase(S.of(context).most_sensitive).titleCase, style: Theme.of(context).textTheme.subhead),
                  ],),
                  SizedBox(height: 8),
                  Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                child: Stack(children: <Widget>[
                  //Image.asset('assets/ic_drips_bar.png'),
                  Padding(padding: EdgeInsets.symmetric(vertical: 3, horizontal: 3), child: IgnorePointer(ignoring: true, child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      //activeTrackColor: floLightCyan.withOpacity(0.9),
                      activeTrackColor: Color(0xFF5EA5C0).withOpacity(0.4),
                      inactiveTrackColor: Colors.transparent,
                      trackHeight: 43.0,
                      thumbColor: Colors.transparent,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                      tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
                      //trackShape: RectangularSliderTrackShape(disabledThumbGapWidth: 0),
                      trackShape: SimpleRoundedRectSliderTrackShape(),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: SimpleSlider(
                      showText: false,
                      value: _dripLevel ?? 1,
                        min: 0,
                        max: 4,
                      divisions: 4,
                      excludeMin: true,
                      onChanged: (value) async {
                        await putSmallDripSensitivity(context, value.toInt());
                      }),
                  ))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Row(children: <Widget>[
                  SizedBox(width: 10,),
                  //SvgPicture.asset('assets/ic_drip.svg', height: 8),
                  Container(width: 30, height: 30, child: IconButton(icon: SvgPicture.asset('assets/ic_drip.svg', height: 28), onPressed: () {
                    _dripLevel = 1;
                    putSmallDripSensitivity(context, _dripLevel.toInt());
                    setState(() {});
                  }, padding: EdgeInsets.all(0))),
                  Pill2(color: Color(0xFF5EA5C0).withOpacity(0.4), size: const Size(45, 1),),
                  Container(width: 30, height: 30, child: IconButton(icon: SvgPicture.asset('assets/ic_drip.svg', height: 22), onPressed: () {
                    _dripLevel = 2;
                    putSmallDripSensitivity(context, _dripLevel.toInt());
                    setState(() {});
                  }, padding: EdgeInsets.all(0))),
                  Pill2(color: Color(0xFF5EA5C0).withOpacity(0.4), size: const Size(45, 1),),
                  Container(width: 30, height: 30, child: IconButton(icon: SvgPicture.asset('assets/ic_drip.svg', height: 14), onPressed: () {
                    _dripLevel = 3;
                    putSmallDripSensitivity(context, _dripLevel.toInt());
                    setState(() {});
                  }, padding: EdgeInsets.all(0))),
                  Pill2(color: Color(0xFF5EA5C0).withOpacity(0.4), size: const Size(45, 1),),
                  Container(width: 30, height: 30, child: IconButton(icon: SvgPicture.asset('assets/ic_drip.svg', height: 8), onPressed: () {
                    _dripLevel = 4;
                    putSmallDripSensitivity(context, _dripLevel.toInt());
                    setState(() {});
                  }, padding: EdgeInsets.all(0))),
                  SizedBox(width: 10,),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround
                  )),
                ],
                  alignment: AlignmentDirectional.center,
                ),
                )))),
                  Transform.translate(offset: Offset(0, -16 + 7.07), child: Row(children: <Widget>[
                    _dripLevel == 1 ? nip(Color(0xFF5EA5C0), offset: Offset(20, 0)) : Container(width: 7.07),
                    Container(),
                    _dripLevel == 2 ? nip(Color(0xFF5EA5C0), offset: Offset(7, 0)) : Container(width: 7.07),
                    Container(),
                    _dripLevel == 3 ? nip(Color(0xFF5EA5C0), offset: Offset(-8, 0)) : Container(width: 7.07),
                    Container(),
                    _dripLevel == 4 ? nip(Color(0xFF5EA5C0), offset: Offset(-18, 0)) : Container(width: 7.07),
                  ],
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                  )),
                Transform.translate(offset: Offset(0, -16), child: Row(children: <Widget>[
                  _dripLevel == 1 ? speechBubble(Color(0xFF5EA5C0), child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).biggest_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("1 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    ))) : Container(),
                  Container(),
                  _dripLevel == 2 ? speechBubble(Color(0xFF5EA5C0), child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).bigger_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("2 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    ))) : Container(),
                  Container(),
                  _dripLevel == 3 ? speechBubble(Color(0xFF5EA5C0), child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).small_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("2 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    ))) : Container(),
                  Container(),
                  _dripLevel == 4 ? speechBubble(Color(0xFF5EA5C0), child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).any_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("2 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    ))) : Container(),
                  ],
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                )),
                /*
                Transform.translate(offset: Offset(0, -16), child: Row(children: <Widget>[
                  _dripLevel == 1 ? SimpleSpeechBubble(
                    width: 30,
                    color: Color(0xFF5EA5C0),
                    nipLocation: NipLocation.TOP,
                    nipOffset: Offset(-14, 0),
                    child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).biggest_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("1 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    )),
                  ) : Container(width: 30, height: 30),
                  Container(width: 45, height: 1),
                  _dripLevel == 2 ? SimpleSpeechBubble(
                    width: 30,
                    color: Color(0xFF5EA5C0),
                    nipLocation: NipLocation.TOP,
                    nipOffset: Offset(-3, 0),
                    child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(S.of(context).bigger_drips, style: Theme.of(context).textTheme.subhead),
                        //SizedBox(height: 5),
                        //Text("2 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                      ],
                    )),
                  ) : Container(width: 30, height: 30),
                  Container(width: 45, height: 1),
                  _dripLevel == 3 ? SimpleSpeechBubble(
                      width: 30,
                      color: Color(0xFF5EA5C0),
                      nipLocation: NipLocation.TOP,
                      nipOffset: Offset(5, 0),
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(S.of(context).small_drips, style: Theme.of(context).textTheme.subhead),
                          //SizedBox(height: 5),
                          //Text("3 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                        ],
                      ))
                  ) : Container(width: 30, height: 30),
                  Container(width: 45, height: 1),
                  _dripLevel == 4 ? SimpleSpeechBubble(
                      width: 30,
                      color: Color(0xFF5EA5C0),
                      nipLocation: NipLocation.TOP,
                      nipOffset: Offset(9, 0),
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(S.of(context).any_drips, style: Theme.of(context).textTheme.subhead),
                          //SizedBox(height: 5),
                          //Text("4 DROP / MIN", textScaleFactor: 0.8, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
                        ],
                      ))
                  ) : Container(width: 30, height: 30),
                ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                )),
                */
                //SizedBox(height: 20),
                Center(child:
                Container(
                    width: 150,
                    height: 40,
                    padding: EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), offset: Offset(0, 10), blurRadius: 25),
                      ],
                    ),
                    child: TabBar(
                      indicatorColor: Colors.red,
                      onTap: (i) async {
                        final alertsSettingsStateProvider = Provider.of<AlertsSettingsStateNotifier>(context, listen: false);
                        if (i == 0) {
                          alertsSettingsStateProvider.value = alertsSettingsStateProvider.value.rebuild((b) => b..systemMode = SystemMode.AWAY);
                        } else {
                          alertsSettingsStateProvider.value = alertsSettingsStateProvider.value.rebuild((b) => b..systemMode = SystemMode.HOME);
                        }
                        alertsSettingsStateProvider.invalidate();
                      },
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black.withOpacity(0.3),
                      labelPadding: EdgeInsets.symmetric(vertical: 10),
                      tabs: <Widget>[
                        Tab(
                          text: S.of(context).away,
                        ),
                        Tab(
                          text: S.of(context).home,
                        ),
                      ],
                      indicator: BubbleTabIndicator(
                        indicatorHeight: 35.0,
                        indicatorColor: Colors.white,
                        tabBarIndicatorSize: TabBarIndicatorSize.label,
                      ),
                      controller: _controller,
                    ))
                ),
                SizedBox(height: 10),
                criticalsDisplay.isNotEmpty ?
                  Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 10),
                        Row(children: <Widget>[
                          SizedBox(width: 20),
                          // linear-gradient(180deg, #5BE9F9 0%, #12C3EA 100%)
                          Pill2(size: const Size(10, 10), color: floRed,),
                          SizedBox(width: 20),
                          Expanded(child: Text(ReCase(S.of(context).critical_alerts).titleCase, style: Theme.of(context).accentTextTheme.title, textScaleFactor: 0.89)),
                          FlatButton(child: Text(S.of(context).edit_all, style: Theme.of(context).textTheme.subhead.copyWith(
                            color: Color(0xFF9DBED1),
                          )),
                            onPressed: () {
                              alarmsProvider.value = BuiltList<Alarm>(_alarms.criticals);
                              Navigator.of(context).pushNamed('/alert_settings');
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],),
                        ...criticalsDisplay.map((it) {
                          final alertSettings = alertsSettings?.alertSettingsByAlarm(it, systemMode: systemMode) ?? it.alertSettings;

                        return alertSettings.isNotEmpty ? ListTile(
                          dense: true,
                          title: Row(children: <Widget>[
                          Expanded(child: Text("${it.displayName}", style: Theme.of(context).accentTextTheme.subhead, overflow: TextOverflow.ellipsis,)),
                          (or(() => alertSettings.emailEnabled) ?? false) ? SvgPicture.asset('assets/ic_mail.svg') : Container(),
                          (or(() => alertSettings.smsEnabled) ?? false) ? SvgPicture.asset('assets/ic_message2.svg') : Container(),
                          (or(() => alertSettings.pushEnabled) ?? false) ? SvgPicture.asset('assets/ic_notification.svg') : Container(),
                          (or(() => alertSettings.callEnabled) ?? false) ? SvgPicture.asset('assets/ic_phone.svg') : Container(),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_ios, color: floBlue2, size: 16),
                        ],),
                          onTap: () {
                            final extraAlarm = or(() => _alarms.criticals.firstWhere((alarm) => alarm.id == it.triggersAlarm?.id));
                            alarmsProvider.value = BuiltList<Alarm>(extraAlarm != null ? [it, extraAlarm] : [it]);
                            Fimber.d("alarmsProvider.value: ${alarmsProvider.value}");
                            Fimber.d("alarm: ${it.rebuild((b) => b..deliveryMedium = null..actions=null..supportOptions=null)}");
                            if (extraAlarm != null) {
                              Fimber.d("extraAlarm alarm: ${extraAlarm.rebuild((b) => b..deliveryMedium = null..actions=null..supportOptions=null)}");
                            }
                            Navigator.of(context).pushNamed('/alert_settings');
                          },
                        ) : Container(); },
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  )))) : Container(),
                warningsDisplay.isNotEmpty ?
    Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
    margin: EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    child: Column(
      children: <Widget>[
        SizedBox(height: 10),
        Row(children: <Widget>[
          SizedBox(width: 20),
          // linear-gradient(180deg, #5BE9F9 0%, #12C3EA 100%)
          Pill2(size: const Size(10, 10), color: floAmber,),
          SizedBox(width: 20),
          Expanded(child: Text(ReCase(S.of(context).warning_alerts).titleCase, style: Theme.of(context).accentTextTheme.title, textScaleFactor: 0.89)),
          FlatButton(child: Text(S.of(context).edit_all, style: Theme.of(context).accentTextTheme.subhead.copyWith(
            color: Color(0xFF9DBED1),
          )),
            onPressed: () {
              alarmsProvider.value = BuiltList<Alarm>(_alarms.warnings);
              Navigator.of(context).pushNamed('/alert_settings');
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],),
        ...warningsDisplay.map((it) {
          final alertSettings = alertsSettings?.alertSettingsByAlarm(it, systemMode: systemMode) ?? it.alertSettings;
          return alertSettings.isNotEmpty ? ListTile(
            dense: true,
            title: Row(children: <Widget>[
              Expanded(child: Text("${it.displayName}", style: Theme.of(context).accentTextTheme.subhead, overflow: TextOverflow.ellipsis,)),
              (or(() => alertSettings.emailEnabled) ?? false) ? SvgPicture.asset('assets/ic_mail.svg') : Container(),
              (or(() => alertSettings.smsEnabled) ?? false) ? SvgPicture.asset('assets/ic_message2.svg') : Container(),
              (or(() => alertSettings.pushEnabled) ?? false) ? SvgPicture.asset('assets/ic_notification.svg') : Container(),
              (or(() => alertSettings.callEnabled) ?? false) ? SvgPicture.asset('assets/ic_phone.svg') : Container(),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios, color: floBlue2, size: 16),
            ],),
            //trailing: Icon(Icons.arrow_forward_ios, color: floBlue2, size: 16),
            onTap: () {
              alarmsProvider.value = BuiltList<Alarm>([it]);
              Fimber.d("alarmsProvider.value: ${alarmsProvider.value}");
              Fimber.d("alarm: ${it}");
              Navigator.of(context).pushNamed('/alert_settings');
            },
          ) : Container(); },
        ),
        /*
                        Row(children: <Widget>[
                          ListTile(),
                          Spacer(),
                          SvgPicture.asset('assets/ic_mail.svg'),
                          SvgPicture.asset('assets/ic_message2.svg'),
                          SvgPicture.asset('assets/ic_notification.svg'),
                          SvgPicture.asset('assets/ic_phone.svg'),
                          Icon(Icons.arrow_forward_ios, color: floBlue2,),
                        ],)
                        )
                        */
      ],
    crossAxisAlignment: CrossAxisAlignment.start,
    ),
    )))) : Container(),
    infosDisplay.isNotEmpty ?
    Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
    margin: EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    child: Column(
      children: <Widget>[
        SizedBox(height: 10),
        Row(children: <Widget>[
          SizedBox(width: 20),
          // linear-gradient(180deg, #5BE9F9 0%, #12C3EA 100%)
          Pill2(size: const Size(10, 10), color: Color(0xFF12C3EA),),
          SizedBox(width: 20),
          Expanded(child: Text(ReCase(S.of(context).informative_alerts).titleCase, style: Theme.of(context).accentTextTheme.title, textScaleFactor: 0.89,)),
          FlatButton(child: Text(S.of(context).edit_all, style: Theme.of(context).accentTextTheme.subhead.copyWith(
            color: Color(0xFF9DBED1),
          )),
            onPressed: () {
              alarmsProvider.value = BuiltList<Alarm>(_alarms.infos);
              Navigator.of(context).pushNamed('/alert_settings');
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],),
        ...infosDisplay.map((it) {
          final alertSettings = alertsSettings?.alertSettingsByAlarm(it, systemMode: systemMode) ?? it.alertSettings;

          return alertSettings.isNotEmpty ? ListTile(
            dense: true,
            title: Row(children: <Widget>[
              Expanded(child: Text("${it.displayName}", style: Theme.of(context).accentTextTheme.subhead, overflow: TextOverflow.ellipsis,)),
              (or(() => alertSettings.emailEnabled) ?? false) ? SvgPicture.asset('assets/ic_mail.svg') : Container(),
              (or(() => alertSettings.smsEnabled) ?? false) ? SvgPicture.asset('assets/ic_message2.svg') : Container(),
              (or(() => alertSettings.pushEnabled) ?? false) ? SvgPicture.asset('assets/ic_notification.svg') : Container(),
              (or(() => alertSettings.callEnabled) ?? false) ? SvgPicture.asset('assets/ic_phone.svg') : Container(),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios, color: floBlue2, size: 16),
            ],),
            //trailing: Icon(Icons.arrow_forward_ios, color: floBlue2, size: 16),
            onTap: () {
              alarmsProvider.value = BuiltList<Alarm>([it]);
              Fimber.d("alarmsProvider.value: ${alarmsProvider.value}");
              Fimber.d("alarm: ${it}");
              Navigator.of(context).pushNamed('/alert_settings');
            },
          ) : Container(); },
        ),
        /*
                        Row(children: <Widget>[
                          ListTile(),
                          Spacer(),
                          SvgPicture.asset('assets/ic_mail.svg'),
                          SvgPicture.asset('assets/ic_message2.svg'),
                          SvgPicture.asset('assets/ic_notification.svg'),
                          SvgPicture.asset('assets/ic_phone.svg'),
                          Icon(Icons.arrow_forward_ios, color: floBlue2,),
                        ],)
                        )
                        */
      ],
    crossAxisAlignment: CrossAxisAlignment.start,
    ),
    )))) : Container(),
                ],
              )))
            ]))  : AlertsSettingsPlaceholder()),
        ])),
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class SimpleRoundedRectSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  /// Create a slider track that draws two rectangles with rounded outer edges.
  const SimpleRoundedRectSliderTrackShape();

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        @required RenderBox parentBox,
        @required SliderThemeData sliderTheme,
        @required Animation<double> enableAnimation,
        @required TextDirection textDirection,
        @required Offset thumbCenter,
        bool isDiscrete = false,
        bool isEnabled = false,
      }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    // If the slider track height is less than or equal to 0, then it makes no
    // difference whether the track is painted or not, therefore the painting
    // can be a no-op.
    if (sliderTheme.trackHeight <= 0) {
      return;
    }

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final ColorTween activeTrackColorTween = ColorTween(begin: sliderTheme.disabledActiveTrackColor, end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(begin: sliderTheme.disabledInactiveTrackColor, end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation);
    Paint leftTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        break;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Size thumbSize = sliderTheme.thumbShape.getPreferredSize(isEnabled, isDiscrete);
    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx - thumbSize.width / 2, trackRect.bottom);
    context.canvas.drawRRect(RRect.fromRectAndRadius(leftTrackSegment, Radius.circular(8.0)), leftTrackPaint);
  }
}

