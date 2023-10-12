import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tinycolor/tinycolor.dart';
import 'model/device.dart';
import 'model/firmware_properties.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/item.dart';
import 'model/items.dart';
import 'model/pending_system_mode.dart';
import 'model/preference_category.dart';
import 'model/system_mode.dart';
import 'model/unit_system.dart';
import 'model/user.dart';
import 'providers.dart';
import 'signup_screen.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:flutter_range_slider/flutter_range_slider.dart';

class DeviceSettingsScreen extends StatefulWidget {
  DeviceSettingsScreen({Key key}) : super(key: key);

  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> with AfterLayoutMixin<DeviceSettingsScreen> {

  @override
  void initState() {
    _developer = false;
    super.initState();
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  void afterFirstLayout(BuildContext context) {
    final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
    _device = deviceProvider.value;
  }

  Device _device;
  bool _developer = false;

  String validateName(BuildContext context, String text) {
    final device = Provider.of<DeviceNotifier>(context, listen: false).value;
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
    if (text.isEmpty) {
      return S.of(context).nickname_not_empty;
    }
    if (location.devices?.where((it) => it.id != device.id)?.any((it) => it.nickname == text) ?? false) {
      return S.of(context).nickname_already_in_use;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    if (deviceConsumer.value == Device.empty) {
      Fimber.d("Current device is Device.empty");
      Navigator.of(context).pop();
    }
    if (userConsumer.value.enabledFeatures?.contains(User.DEVELOPER_MENU) ?? false) {
      _developer = true;
    }
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    /*
        if (deviceConsumer.value == Device.empty) {
          Fimber.d("Current device is Device.empty");
          Navigator.of(context).pop();
        }
    */
    final device = deviceConsumer.value;
    final installed = device?.installStatus?.isInstalled ?? false;
    final bool isMetric = (userConsumer.value.unitSystem == UnitSystem.metricKpa) ?? false;

    Fimber.d("0 playerAction: ${deviceConsumer.value?.firmwareProperties?.playerAction}");
    Fimber.d("0 isPlayerConstant: ${deviceConsumer.value?.firmwareProperties?.isPlayerConstant}");
    Fimber.d("0 isPlayerDescending: ${deviceConsumer.value?.firmwareProperties?.isPlayerPressureDescending}");
    final child =
      WillPopScope(
          onWillPop: () async {
            await putDevice(context, last: _device);
            Navigator.of(context).pop();
            return false;
          },
          child: GestureDetector(
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Scaffold(
        resizeToAvoidBottomPadding: true,
          body: Stack(children: <Widget>[
            FloGradientBackground(),
            Material(color: Colors.transparent, child: SafeArea(child: CustomScrollView(
            slivers: <Widget>[
                SliverAppBar(
                  brightness: Brightness.dark,
                  leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                  floating: true,
                  title: Text(ReCase(S.of(context).device_settings).titleCase),
                  centerTitle: true,
                ),
                SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), sliver: SliverList(delegate: SliverChildListDelegate(<Widget>[
                  Text(ReCase(S.of(context).device_nickname).titleCase, style: Theme.of(context).textTheme.subhead),
                  SizedBox(height: 20,),
                  Theme(data: floLightThemeData, child:
                  OutlineTextFormField(
                    initialValue: deviceConsumer.value.displayNameOf(context),
                    hintText: S.of(context).device_nickname,
                    maxLength: 24,
                    counterText: '',
                    autovalidate: true,
                    validator: (text) {
                      return validateName(context, text);
                    },
                    onUnfocus: (text) async {
                      if (validateName(context, text) == null) {
                        await putDevice(context, last: _device);
                        final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                        deviceProvider.value = deviceProvider.value.rebuild((b) => b
                          ..nickname = text.trim()
                        );
                        deviceProvider.invalidate();
                      }
                    },
                  ),
                  ),
                  SizedBox(height: 20,),
                  Text(ReCase(S.of(context).network_settings).titleCase, style: Theme.of(context).textTheme.subhead),
                  SizedBox(height: 20,),
                  TextFieldButton(
                    leading: WifiIcon(device: deviceConsumer.value),
                    text: deviceConsumer.value?.firmwareProperties?.wifiStaSsid ?? "Wi-Fi",
                    endText: S.of(context).change,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/change_device_wifi');
                    },
                  ),
                  SizedBox(height: 20,),
                  Text(ReCase(S.of(context).alert_settings).titleCase, style: Theme.of(context).textTheme.subhead),
                  SizedBox(height: 20,),
                  TextFieldButton(
                      leading: Image.asset('assets/ic_alerts.png', width: 18,),
                    text: S.of(context).alert_settings,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/alerts_settings');
                    },
                  ),
                  SizedBox(height: 20,),
                  Visibility(visible: installed, child: Column(children: <Widget>[
                    /*
                    Text(S.of(context).pressure_reducing_valve_q(S.of(context).device), style: Theme.of(context).textTheme.subhead),
                    SizedBox(height: 20,),
                    Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        child: Padding( padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        child: KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
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
                                  Padding(padding: EdgeInsets.symmetric(vertical: 0), child: RadioListTile(title: Text(item.longDisplay), value: item.key, groupValue: deviceConsumer.value.prvInstallation, onChanged: (value) {
                                    deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..prvInstallation = value);
                                    deviceConsumer.invalidate();
                                  })
                              )).toList()
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                        ))))),
                    SizedBox(height: 20,),
                    */
                    Text(ReCase("Device Setup").titleCase, style: Theme.of(context).textTheme.subhead),
                    SizedBox(height: 20,),
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
                          } else  if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.irrigationType?.isNotEmpty ?? false)) {
                            return TextFieldButton(
                              text: S.of(context).irrigation,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/irrigation_settings', arguments: snapshot.data.irrigationType);
                              },
                            );
                          } else {
                            return Container();
                          }
                        }),
                    SizedBox(height: 10,),
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
                          } else  if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.prv?.isNotEmpty ?? false)) {
                            return TextFieldButton(
                              text: ReCase(S.of(context).pressure_reducing_valve).titleCase,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/prv_settings', arguments: snapshot.data.prv);
                              },
                            );
                          } else {
                            return Container();
                          }
                        }),
                    /*
                    Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      child:
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        child:
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
                                      RadioListTile(title: Text(item.longDisplay), value: item.key, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                                        deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                                        deviceConsumer.invalidate();
                                      },
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
                              RadioListTile(title: Text(S.of(context).sprinklers), value: Device.SPRINKLERS, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                                deviceConsumer.invalidate();
                              },
                              ),
                              RadioListTile(title: Text(ReCase(S.of(context).drip_irrigation).titleCase), value: Device.DRIP, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                                deviceConsumer.invalidate();
                              },
                              ),
                              RadioListTile(title: Text(S.of(context).flo_not_plumbed_on_irrigation), value: Device.NONE, groupValue: deviceConsumer.value.irrigationType, onChanged: (value) {
                                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..irrigationType = value);
                                deviceConsumer.invalidate();
                              },
                              ),
                            ]),
                        */
                      ),
                    )))),
                    */
                    SizedBox(height: 20,),
                  ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  )
                  ),
                  Text(ReCase(S.of(context).device_info).titleCase, style: Theme.of(context).textTheme.subhead),
                  SizedBox(height: 20,),
                  Theme(data: floLightThemeData, child: Builder(builder: (context) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      OutlineTextFormField(
                        enabled: false,
                      ),
                      Row(children: [
                        SizedBox(width: 20,),
                        Text(ReCase(S.of(context).serial_number).titleCase,
                          style: Theme.of(context).textTheme.subhead.copyWith(color: Color(0xFF839FB0)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Text(deviceConsumer.value?.serialNumber ?? S.of(context).not_available,
                          style: Theme.of(context).textTheme.subhead.copyWith(),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(width: 20,),
                      ]),
                    ],))),
                  SizedBox(height: 10,),
                  Theme(data: floLightThemeData, child: Builder(builder: (context) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      OutlineTextFormField(
                        enabled: false,
                      ),
                      Row(children: [
                        SizedBox(width: 20,),
                        Text(S.of(context).device_id,
                          style: Theme.of(context).textTheme.subhead.copyWith(color: Color(0xFF839FB0)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Text(deviceConsumer.value?.macAddress ?? S.of(context).not_available,
                          style: Theme.of(context).textTheme.subhead.copyWith(),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(width: 20,),
                      ]),
                    ],))),
                  SizedBox(height: 10,),
                  GestureDetector(child: Theme(data: floLightThemeData, child: Builder(builder: (context) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      OutlineTextFormField(
                        enabled: false,
                      ),
                      Row(children: [
                        SizedBox(width: 20,),
                        Text(S.of(context).firmware,
                          style: Theme.of(context).textTheme.subhead.copyWith(color: Color(0xFF839FB0)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Text(deviceConsumer.value?.firmwareVersion ?? S.of(context).not_available,
                          style: Theme.of(context).textTheme.subhead.copyWith(),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(width: 20,),
                      ]),
                    ],))),
                    onDoubleTap: () async {
                      /*
                      setState(() {
                        _developer = true;
                      });
                      */
                    },
                  ),
                  SizedBox(height: 20,),
                  ExpandedSection(expand: _developer, child: Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    child: Column(children: <Widget>[
                      SizedBox(height: 20,),
                      Text(S.of(context).developer_options, style: Theme.of(context).textTheme.subhead),
                      SizedBox(height: 10,),
                      SimpleSwitchListTile(
                        title: Text(S.of(context).device_locked),
                        value: (device?.systemMode?.isLocked ?? true),
                        onChanged: (checked) async {
                          try {
                            deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                              ..systemMode = deviceConsumer.value?.systemMode?.rebuild((b) => b..isLocked = checked)?.toBuilder()
                                ?? PendingSystemMode((b) => b..isLocked = checked
                                  ..target = SystemMode.SLEEP)
                            );
                            //deviceConsumer.invalidate();
                            if (checked) {
                              await flo.forceSleep2(device.id, authorization: oauthConsumer.value.authorization);
                            } else {
                              await flo.unforceSleep2(device.id, authorization: oauthConsumer.value.authorization);
                            }
                          } catch (e) {
                            Fimber.e("", ex: e);
                            showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                          }
                        },
                      ),
                      /*
                      Enabled(enabled: !(device?.installStatus?.isInstalled ?? false), child: SimpleSwitchListTile(
                        title: Text(S.of(context).device_installed),
                        value: (device?.installStatus?.isInstalled ?? false),
                        onChanged: (checked) async {
                          if (checked) {
                            showDialog(
                              context: context,
                              builder: (context2) =>
                                  Theme(data: floLightThemeData, child: AlertDialog(
                                    title: Text(S.of(context).device_installed_q),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text(S.of(context).cancel),
                                        onPressed: () {
                                          Navigator.of(context2).pop();
                                        },
                                      ),
                                      FlatButton(
                                        child:  Text(S.of(context).installed),
                                        onPressed: () async {
                                          Navigator.of(context2).pop();
                                          try {
                                            flo.installDeviceEvent(device.id, device.macAddress, authorization: oauthConsumer.value.authorization);
                                          } catch (e) {
                                            Fimber.e("", ex: e);
                                            showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                                          }
                                          deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                              ..installStatus = deviceConsumer.value.installStatus?.rebuild((b) =>b
                                                  ..isInstalled = true
                                              )?.toBuilder() ?? deviceConsumer.value.installStatus
                                          );
                                          deviceConsumer.invalidate();
                                        },
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                  )),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context2) =>
                                  Theme(data: floLightThemeData, child: AlertDialog(
                                    title: Text(S.of(context).cannot_uninstall),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text(S.of(context).ok),
                                        onPressed: () {
                                          Navigator.of(context2).pop();
                                        },
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                  )),
                            );
                            return false;
                          }
                          return true;
                        },
                      )),
                      */
                      SimpleSwitchListTile(
                        title: Text(S.of(context).custom_telemetry),
                        //value: (deviceConsumer.value?.firmwareProperties?.isPlayerConstant ?? false),
                        value: !(deviceConsumer.value?.firmwareProperties?.isPlayerDisabled ?? true),
                        onChanged: (checked) async {
                          try {
                            deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                              ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CONSTANT : FirmwareProperties.PLAYER_ACTION_DISABLED).toBuilder()
                            );
                            deviceConsumer.invalidate();
                            await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                              ..playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CONSTANT : FirmwareProperties.PLAYER_ACTION_DISABLED
                            ), authorization: oauthConsumer.value.authorization);
                          } catch (e) {
                            Fimber.e("", ex: e);
                            showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                          }
                        },
                      ),
                      SizedBox(height: 20,),
                      //Enabled(enabled: (device?.firmwareProperties?.isPlayerConstant ?? false), child: Column(children: <Widget>[
                      Enabled(enabled: !(deviceConsumer.value?.firmwareProperties?.isPlayerDisabled ?? true), child: Column(children: <Widget>[
                      ListTile(
                        dense: true,
                        //leading: Icon(Icons.toys),
                        title: Text(ReCase(S.of(context).flow_rate).titleCase),
                        subtitle: SimpleSlider(
                          semanticFormatterCallback: !isMetric ? (value) => "${NumberFormat("#.#").format(value)} gpm"
                              : (value) => "${NumberFormat("#.#").format(toLiters((value)))} ${S.of(context).liters}",
                          label: !isMetric ? (value) => "${NumberFormat("#.#").format(value)}"
                              : (value) => "${NumberFormat("#.#").format(toLiters((value)))}",
                          value: (device.firmwareProperties?.playerFlow ?? 0),
                          min: 0.0, max: 25,
                          divisions: 25,
                          onChangeEnd: (value) async {
                            try {
                              Fimber.d("flow: $value");
                              deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                  ..playerFlow = value
                                ).toBuilder()
                              );
                              //deviceConsumer.invalidate();
                              await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                ..playerFlow = deviceConsumer.value.firmwareProperties.playerFlow
                                ..playerAction = deviceConsumer.value.firmwareProperties.playerAction
                              ), authorization: oauthConsumer.value.authorization);
                            } catch (e) {
                              Fimber.e("", ex: e);
                              showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                            }
                          },
                        ),
                      ),
                      ListTile(
                        dense: true,
                        //leading: Icon(Icons.wb_sunny),
                        title: Text(S.of(context).temperature),
                        subtitle: SimpleSlider(
                          semanticFormatterCallback: !isMetric ? (value) => "${NumberFormat("#.#").format(value)} °F"
                              : (value) => "${NumberFormat("#.#").format(toCelsius((value)))} °C",
                          label: !isMetric ? (value) => "${NumberFormat("#.#").format(value)}"
                              : (value) => "${NumberFormat("#.#").format(toCelsius((value)))}",
                          value: (device.firmwareProperties?.playerTemperature ?? 0),
                          min: 0.0, max: 100,
                          divisions: 100,
                          onChangeEnd: (value) async {
                            try {
                              deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                  ..playerTemperature = value
                                ).toBuilder()
                              );
                              //deviceConsumer.invalidate();
                              await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                ..playerTemperature = deviceConsumer.value.firmwareProperties.playerTemperature
                                ..playerAction = deviceConsumer.value.firmwareProperties.playerAction
                              ), authorization: oauthConsumer.value.authorization);
                            } catch (e) {
                              Fimber.e("", ex: e);
                              showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                            }
                          },
                        ),
                      ),
                      ListTile(
                        dense: true,
                        //leading: Icon(Icons.power_input),
                        title: Text(S.of(context).pressure),
                        subtitle: !(device.firmwareProperties?.isPlayerPressureDescending ?? false) ? SimpleSlider(
                          semanticFormatterCallback: !isMetric ? (value) => "${NumberFormat("#.#").format(value)} PSI"
                              : (value) => "${NumberFormat("#.#").format(toKpa((value)))} kPa",
                          label: !isMetric ? (value) => "${NumberFormat("#.#").format(value)}"
                              : (value) => "${NumberFormat("#.#").format(toKpa((value)))}",
                          value: (device.firmwareProperties?.playerPressure ?? 40),
                          min: 0.0, max: 160,
                          divisions: 160,
                          onChangeEnd: (value) async {
                            try {
                              deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                  ..playerPressure = value
                                ).toBuilder()
                              );
                              deviceConsumer.invalidate();
                              await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                ..playerPressure = value
                                ..playerAction = deviceConsumer.value.firmwareProperties.playerAction
                              ), authorization: oauthConsumer.value.authorization);
                            } catch (e) {
                              Fimber.e("", ex: e);
                              showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                            }
                          },
                        ) :
                        SimpleRangeSlider(
                          semanticFormatterCallback: !isMetric ? (value) => "${NumberFormat("#.#").format(value)} PSI"
                              : (value) => "${NumberFormat("#.#").format(toKpa((value)))} kPa",
                          valueIndicatorFormatter: !isMetric ? (i, value) => "${NumberFormat("#.#").format(value)}"
                              : (i, value) => "${NumberFormat("#.#").format(toKpa((value)))}",
                            showValueIndicator: true,
                            min: 0.0, max: 160,
                            divisions: 160,
                            lowerValue: device.firmwareProperties?.playerMinPressure ?? 0,
                            upperValue: max(device.firmwareProperties?.playerMinPressure ?? 0, device.firmwareProperties?.playerPressure ?? 40),
                            onChangeEnd: (lower, upper) async {
                              try {
                                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                  ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                    ..playerMinPressure = lower
                                    ..playerPressure = upper
                                  ).toBuilder()
                                );
                                deviceConsumer.invalidate();
                                await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                  ..playerMinPressure = lower
                                  ..playerPressure = upper
                                  ..playerAction = deviceConsumer.value.firmwareProperties.playerAction
                                ), authorization: oauthConsumer.value.authorization);
                              } catch (e) {
                                Fimber.e("", ex: e);
                                showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                              }
                            },
                          ),
                      ),
                      SizedBox(height: 10,),
                      Row(children: <Widget>[
                        //Icon(Icons.trending_down),
                        Spacer(),
                      Wrap(children: <Widget>[
                          ToggleButton(
                              label: "Cat1 Drip",
                              textScaleFactor: 0.7,
                              selected: deviceConsumer.value?.firmwareProperties?.isPlayerCat1 ?? false,
                              inactiveColor: floLightBackground,
                              onTap: (checked) async {
                                final playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT1 : FirmwareProperties.PLAYER_ACTION_CONSTANT;
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                      ..playerPressure = 100
                                      ..playerMinPressure = 20
                                      ..playerAction = playerAction).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerPressure = 100
                                    ..playerMinPressure = 20
                                    ..playerAction = playerAction
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                                }
                              }),
                          ToggleButton(
                              label: "Cat2 Drip",
                              inactiveColor: floLightBackground,
                              textScaleFactor: 0.7,
                              selected: deviceConsumer.value?.firmwareProperties?.isPlayerCat2 ?? false,
                              onTap: (checked) async {
                                final playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT2 : FirmwareProperties.PLAYER_ACTION_CONSTANT;
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                      ..playerPressure = 100
                                      ..playerMinPressure = 20
                                      ..playerAction = playerAction).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerPressure = 100
                                    ..playerMinPressure = 20
                                    ..playerAction = playerAction
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                                }
                              }),
                          ToggleButton(
                              label: "Cat3 Drip",
                              inactiveColor: floLightBackground,
                              textScaleFactor: 0.7,
                              selected: deviceConsumer.value?.firmwareProperties?.isPlayerCat3 ?? false,
                              onTap: (checked) async {
                                final playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT3 : FirmwareProperties.PLAYER_ACTION_CONSTANT;
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                      ..playerPressure = 100
                                      ..playerMinPressure = 20
                                      ..playerAction = playerAction
                                    ).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerPressure = 100
                                    ..playerMinPressure = 20
                                    ..playerAction = playerAction
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                                }
                              }),
                          ToggleButton(
                              label: "Cat4 Drip",
                              inactiveColor: floLightBackground,
                              textScaleFactor: 0.7,
                              selected: deviceConsumer.value?.firmwareProperties?.isPlayerCat4 ?? false,
                              onTap: (checked) async {
                                final playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT4 : FirmwareProperties.PLAYER_ACTION_CONSTANT;
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                      ..playerPressure = 100
                                      ..playerMinPressure = 20
                                      ..playerAction = playerAction).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerPressure = 100
                                    ..playerMinPressure = 20
                                    ..playerAction = playerAction
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(error: e));
                                }
                              }),
                      ],
                      spacing: 10,
                      ),
                        Spacer(),
                      ],),
                      SizedBox(height: 20,),
                      ],
                        mainAxisAlignment: MainAxisAlignment.start,
                      )),
                      /*
                      SimpleSwitchListTile(
                        title: Text("Health Test Failure Telemetry"),
                        value: (device?.firmwareProperties?.isPlayerDescending ?? false),
                        onChanged: (checked) async {
                          try {
                            deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                              ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT1 : FirmwareProperties.PLAYER_ACTION_DISABLED).toBuilder()
                            );
                            deviceConsumer.invalidate();
                            await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                              ..playerAction = checked ? FirmwareProperties.PLAYER_ACTION_CAT1 : FirmwareProperties.PLAYER_ACTION_DISABLED
                            ), authorization: oauthConsumer.value.authorization);
                          } catch (e) {
                            Fimber.e("", ex: e);
                            showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                          }
                        },
                      ),
                      Enabled(enabled: (device?.firmwareProperties?.isPlayerDescending ?? false), child: Column(children: <Widget>[
                          RadioListTile(
                              title: Text("Largest Drip (Cat1)"),
                              value: FirmwareProperties.PLAYER_ACTION_CAT1, groupValue: device?.firmwareProperties?.playerAction ?? "",
                              onChanged: (value) async {
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = value).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerAction = value
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                                }
                              }),
                          RadioListTile(
                              title: Text("Large Drip (Cat2)"),
                              value: FirmwareProperties.PLAYER_ACTION_CAT2, groupValue: device?.firmwareProperties?.playerAction ?? "",
                              onChanged: (value) async {
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = value).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerAction = value
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                                }
                              }),
                          RadioListTile(
                              title: Text("Medium Drip (Cat3)"),
                              value: FirmwareProperties.PLAYER_ACTION_CAT3, groupValue: device?.firmwareProperties?.playerAction ?? "",
                              onChanged: (value) async {
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = value).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerAction = value
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                                }
                              }),
                          RadioListTile(
                              title: Text("Small Drip (Cat4)"),
                              value: FirmwareProperties.PLAYER_ACTION_CAT4, groupValue: device?.firmwareProperties?.playerAction ?? "",
                              onChanged: (value) async {
                                try {
                                  deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                    ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b..playerAction = value).toBuilder()
                                  );
                                  deviceConsumer.invalidate();
                                  await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                    ..playerAction = value
                                  ), authorization: oauthConsumer.value.authorization);
                                } catch (e) {
                                  Fimber.e("", ex: e);
                                  showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                                }
                              }),
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.trending_down),
                          title: Text("Descending Pressure Range"),
                          subtitle: SimpleRangeSlider(
                            showValueIndicator: true,
                            min: 0, max: 100,
                            lowerValue: device.firmwareProperties?.playerMinPressure ?? 0,
                            upperValue: device.firmwareProperties?.playerPressure ?? 40,
                            onChangeEnd: (lower, upper) async {
                              try {
                                deviceConsumer.value = deviceConsumer.value.rebuild((b) => b
                                  ..firmwareProperties = deviceConsumer.value.firmwareProperties.rebuild((b) => b
                                    ..playerMinPressure = lower
                                    ..playerPressure = upper
                                  ).toBuilder()
                                );
                                deviceConsumer.invalidate();
                                await flo.putFirmwareProperties(device.id, FirmwareProperties((b) => b
                                  ..playerMinPressure = lower
                                  ..playerPressure = upper
                                ), authorization: oauthConsumer.value.authorization);
                              } catch (e) {
                                Fimber.e("", ex: e);
                                showDialog(context: context, builder: (context2) => FloErrorDialog(e: e));
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 10,),
                      ],
                        mainAxisAlignment: MainAxisAlignment.start,
                      )),
                      */
                    ]),
                  ))))),
                  SizedBox(height: 20,),
                  SizedBox(width: double.infinity,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: FlatButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context2) =>
                                    Theme(data: floLightThemeData, child: AlertDialog(
                                      title: Text(S.of(context).restart_device_q),
                                      content: Text(S.of(context).restart_device_description),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).cancel),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child:  Text(S.of(context).restart_device),
                                          onPressed: () async {
                                            try {
                                              await flo.restartDevice(deviceConsumer.value.id, authorization: oauthConsumer.value.authorization);
                                            } catch (e) {
                                              // TODO: Implement Error Dialog
                                              Fimber.e("", ex: e);
                                            }
                                            Navigator.of(context2).pop();
                                            //Navigator.of(context2).pushNamed('/404'); // should work now
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    )),
                              );
                            },
                            child: Text(S.of(context).restart_device, textScaleFactor: 1.4,),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(25.0)),
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ))),
                  //SizedBox(height: 20,),
                  //Text("Device Installe", style: Theme.of(context).textTheme.subhead), // FIXME
                  SizedBox(height: 20,),
                  SizedBox(width: double.infinity,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: FlatButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context2) =>
                                    Theme(data: floLightThemeData, child: AlertDialog(
                                      title: Text(S.of(context).unlink_device_q),
                                      content: Text(S.of(context).unlink_device_description),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(S.of(context).cancel),
                                          onPressed: () {
                                            Navigator.of(context2).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child:  Text(ReCase(S.of(context).unlink_device).titleCase),
                                          onPressed: () async {
                                            try {
                                              await flo.unlinkDevice2(deviceConsumer.value.id, authorization: oauthConsumer.value.authorization);
                                              final userProvider = Provider.of<UserNotifier>(context, listen: false);
                                              userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
                                              final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
                                              deviceProvider.value = Device.empty;
                                              deviceProvider.invalidate();
                                              //userProvider.invalidate();
                                              Navigator.of(context2).pushNamedAndRemoveUntil('/home', ModalRoute.withName('/home'));
                                            } catch (e) {
                                              Fimber.e("Unlink failure", ex: e);
                                              Navigator.of(context2).pop();
                                            }
                                          },
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    )),
                              );
                            },
                            child: Text(ReCase(S.of(context).unlink_device).titleCase, textScaleFactor: 1.4,),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(25.0)),
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ))),
                  SizedBox(height: 20,),
                ],
                )))
              ],
          )
          ))]))
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

Future<void> putDevice(BuildContext context, {Device last}) async {
  final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
  if (last == deviceProvider.value) {
    return;
  }
  final floConsumer = Provider.of<FloNotifier>(context, listen: false);
  final flo = floConsumer.value;
  final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
    try {
    await flo.putDevice(Device((b) => b
    ..id = deviceProvider.value.id
    ..nickname = deviceProvider.value.nickname
    ..prvInstallation = deviceProvider.value.prvInstallation
    ..irrigationType = deviceProvider.value.irrigationType
    ), authorization: oauthConsumer.value.authorization);
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
    } catch (e) {
      Fimber.e("putDevice", ex: e);
    }
}
