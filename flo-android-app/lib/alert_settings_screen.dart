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
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'generated/i18n.dart';
import 'model/alarm.dart';
import 'model/alarms.dart';
import 'model/alert_settings.dart';
import 'model/device_alerts_settings.dart';
import 'model/alerts_settings.dart';
import 'model/flo.dart';

import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';

class AlertSettingsScreen extends StatefulWidget {
  AlertSettingsScreen({Key key}) : super(key: key);

  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> with AfterLayoutMixin<AlertSettingsScreen> {

  AlertSettings _notShutoffAlertSettings;
  AlertSettings _shutoffAlertSettings;

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
  }

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final alarms = Provider.of<AlarmsNotifier>(context).value;
    final notShutoffAlarms = $(alarms).where((it) => !it.isShutoff ?? true);
    final shutoffAlarms = $(alarms).where((it) => it.isShutoff ?? false);
    final user = Provider.of<UserNotifier>(context).value;
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;
    //Fimber.d("${user?.alertsSettings}");
    Fimber.d("device.id: ${device.id}");
    final alertsSettings = or(() => user?.alertsSettings?.firstWhere((it) => it.deviceId == device.id));
    final systemMode = Provider.of<AlertsSettingsStateNotifier>(context, listen: false).value.systemMode;
    Fimber.d("systemMode: ${systemMode}");
    /*
    final alertSettingsList = alertsSettings?.settings
        ?.where((it) => it.systemMode == systemMode)
        ?.where((it) => $(alarms).any((alarm) => alarm.id == it.alarmId));
    */
    Fimber.d("alarms: ${alarms}");
    if (alarms?.isEmpty ?? true) {
      return Container();
    }
    // optimized
    final alertSettingsList = alarms.map((it) => or(() => alertsSettings?.alertSettingsByAlarm(it, systemMode: systemMode)) ?? (systemMode != null ? it.alertSettingsBySystemMode(systemMode) : it.alertSettings))
        ?.where((it) => it != null);
    Fimber.d("alertSettingsList: ${alertSettingsList}");
    if (alertSettingsList?.isEmpty ?? true) {
      return Container();
    }
    final alertSettingsNotShutoffList = alertSettingsList
        ?.where((it) => $(notShutoffAlarms).any((alarm) => alarm.id == it.alarmId));
    final alertSettingsShutoffList = alertSettingsList
        ?.where((it) => $(shutoffAlarms).any((alarm) => alarm.id == it.alarmId));
    _notShutoffAlertSettings = or(() => alertSettingsNotShutoffList?.reduce((it, it2) =>
        it.rebuild((b) => b
          ..systemMode = systemMode
          ..smsEnabled   = it.smsEnabled   != null ? (it.smsEnabled   ?? false) || (it2.smsEnabled   ?? false) : null
          ..emailEnabled = it.emailEnabled != null ? (it.emailEnabled ?? false) || (it2.emailEnabled ?? false) : null
          ..pushEnabled  = it.pushEnabled  != null ? (it.pushEnabled  ?? false) || (it2.pushEnabled  ?? false) : null
          ..callEnabled  = it.callEnabled  != null ? (it.callEnabled  ?? false) || (it2.callEnabled  ?? false) : null
      )));
    _shutoffAlertSettings = or(() => alertSettingsShutoffList?.reduce((it, it2) =>
        it.rebuild((b) => b
          ..systemMode = systemMode
          ..smsEnabled   = it.smsEnabled   != null ? (it.smsEnabled   ?? false) || (it2.smsEnabled   ?? false) : null
          ..emailEnabled = it.emailEnabled != null ? (it.emailEnabled ?? false) || (it2.emailEnabled ?? false) : null
          ..pushEnabled  = it.pushEnabled  != null ? (it.pushEnabled  ?? false) || (it2.pushEnabled  ?? false) : null
          ..callEnabled  = it.callEnabled  != null ? (it.callEnabled  ?? false) || (it2.callEnabled  ?? false) : null
        )));
      //))) ?? AlertSettings.FALSE;
    final title = alarms.any((it) => it.severity == Alarm.CRITICAL) ? S.of(context).critical
    : alarms.any((it) => it.severity == Alarm.WARNING) ? S.of(context).warning
    : alarms.any((it) => it.severity == Alarm.INFO) ? S.of(context).informative : "";
    if (_shutoffAlertSettings?.isEmpty ?? true) {
      Fimber.d("shutoff alertSetting isEmpty: ${_shutoffAlertSettings} : $alertSettingsShutoffList");
    }
    if (_notShutoffAlertSettings?.isEmpty ?? true) {
      Fimber.d("not-shutoff alertSetting isEmpty: ${_notShutoffAlertSettings} : $alertSettingsNotShutoffList");
    }

    Future<void> putAlertsSettings(Iterable<AlertSettings> alertSettingsList, AlertSettings alertSettings) async {
      try {
        final alertsSettings = AlertsSettings((b) => b
              ..items = ListBuilder([DeviceAlertsSettings((b) => b
                ..deviceId = device.id
                ..settings = ListBuilder(
                  alertSettingsList.map((it) => alertSettings.rebuild((b) => b..alarmId = it.alarmId))
                )
              )]));
        Fimber.d("alertsSettings: ${alertsSettings}");
        final res = await flo.putAlertsSettings(user.id, alertsSettings, authorization: oauth.authorization);
        final userProvider = Provider.of<UserNotifier>(context, listen: false);
        userProvider.value = (await flo.getUser(oauth.userId, authorization: oauth.authorization)).body;
        userProvider.invalidate();
      } catch (e) {
        Fimber.e("", ex: e);
      }
    }

    final child = WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      }, child: GestureDetector(
      child: Scaffold(
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
        SafeArea(child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                floating: true,
                // FIXME
                title: Text((alarms?.length ?? 0) > 1 ? "Edit All ${title} Alerts" : "${alarms?.first?.displayName ?? S.of(context).alert_settings}", textScaleFactor: 1.1,),
                centerTitle: true,
              ),
              SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), sliver:
              SliverList(delegate: SliverChildListDelegate(
              (_notShutoffAlertSettings == null && _shutoffAlertSettings == null) ? <Widget>[Text(S.of(context).no_alerts_settings_available)] :
                <Widget>[
                  Text(S.of(context).alert_settings, style: Theme.of(context).textTheme.subhead),
                  SizedBox(height: 10),
                  Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    child: Column(
                      children: <Widget>[
                        _notShutoffAlertSettings.emailEnabled != null ? SimpleSwitchListTile(
                          value: _notShutoffAlertSettings.emailEnabled,
                          title: Text(S.of(context).email, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _notShutoffAlertSettings = _notShutoffAlertSettings.rebuild((b) => b
                                ..emailEnabled = checked
                            );
                            Fimber.d("alertSettingsNotShutoffList: ${alertSettingsNotShutoffList}");
                            Fimber.d("_notShutoffAlertSettings: ${_notShutoffAlertSettings}");
                            if (alertSettingsNotShutoffList != null && _notShutoffAlertSettings != null) {
                              putAlertsSettings(alertSettingsNotShutoffList, _notShutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                        _notShutoffAlertSettings.smsEnabled != null ? SimpleSwitchListTile(
                          value: _notShutoffAlertSettings.smsEnabled,
                          title: Text(S.of(context).text_message, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _notShutoffAlertSettings = _notShutoffAlertSettings.rebuild((b) => b
                              ..smsEnabled = checked
                            );
                            Fimber.d("alertSettingsNotShutoffList: ${alertSettingsNotShutoffList}");
                            Fimber.d("_notShutoffAlertSettings: ${_notShutoffAlertSettings}");
                            if (alertSettingsNotShutoffList != null && _notShutoffAlertSettings != null) {
                              putAlertsSettings(alertSettingsNotShutoffList, _notShutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                        _notShutoffAlertSettings.pushEnabled != null ? SimpleSwitchListTile(
                          value: _notShutoffAlertSettings.pushEnabled,
                          title: Text(S.of(context).push_notification, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _notShutoffAlertSettings = _notShutoffAlertSettings.rebuild((b) => b
                              ..pushEnabled = checked
                            );
                            Fimber.d("alertSettingsNotShutoffList: ${alertSettingsNotShutoffList}");
                            Fimber.d("_notShutoffAlertSettings: ${_notShutoffAlertSettings}");
                            if (alertSettingsNotShutoffList != null && _notShutoffAlertSettings != null) {
                              putAlertsSettings(alertSettingsNotShutoffList, _notShutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                        _notShutoffAlertSettings.callEnabled != null ? SimpleSwitchListTile(
                          value: _notShutoffAlertSettings.callEnabled,
                          title: Text(S.of(context).phone_call, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _notShutoffAlertSettings = _notShutoffAlertSettings.rebuild((b) => b
                              ..callEnabled = checked
                            );
                            Fimber.d("alertSettingsNotShutoffList: ${alertSettingsNotShutoffList}");
                            Fimber.d("_notShutoffAlertSettings: ${_notShutoffAlertSettings}");
                            if (alertSettingsNotShutoffList != null && _notShutoffAlertSettings != null) {
                              putAlertsSettings(alertSettingsNotShutoffList, _notShutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  )))),
                  SizedBox(height: 20,),
                  ((_shutoffAlertSettings?.isNotEmpty ?? false) && (alertSettingsShutoffList?.isNotEmpty ?? false)) ? Text(S.of(context).shutoff_notify_by, style: Theme.of(context).textTheme.subhead) : Container(),
                  SizedBox(height: 10),
                  ((_shutoffAlertSettings?.isNotEmpty ?? false) && (alertSettingsShutoffList?.isNotEmpty ?? false)) ? Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    child: Column(
                      children: <Widget>[
                        _shutoffAlertSettings?.emailEnabled != null ? SimpleSwitchListTile(
                          value: _shutoffAlertSettings.emailEnabled,
                          title: Text(S.of(context).email, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _shutoffAlertSettings = _shutoffAlertSettings?.rebuild((b) => b
                              ..emailEnabled = checked
                            );
                            if (_shutoffAlertSettings != null && alertSettingsShutoffList != null) {
                              putAlertsSettings(alertSettingsShutoffList, _shutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                        _shutoffAlertSettings?.smsEnabled != null ? SimpleSwitchListTile(
                          value: _shutoffAlertSettings?.smsEnabled,
                          title: Text(S.of(context).text_message, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _shutoffAlertSettings = _shutoffAlertSettings.rebuild((b) => b
                              ..smsEnabled = checked
                            );
                            if (_shutoffAlertSettings != null && alertSettingsShutoffList != null) {
                              putAlertsSettings(alertSettingsShutoffList, _shutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                        _shutoffAlertSettings?.pushEnabled != null ? SimpleSwitchListTile(
                          value: _shutoffAlertSettings?.pushEnabled,
                          title: Text(S.of(context).push_notification, style: Theme.of(context).textTheme.subhead),
                          onChanged: (checked) async {
                            _shutoffAlertSettings = _shutoffAlertSettings.rebuild((b) => b
                              ..pushEnabled = checked
                            );
                            if (_shutoffAlertSettings != null && alertSettingsShutoffList != null) {
                              putAlertsSettings(alertSettingsShutoffList, _shutoffAlertSettings);
                            }
                          },
                        ) : Container(),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  )))) : Container(),
                  SizedBox(height: 20,),
                ],
              )))
            ])),
        ]))
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
