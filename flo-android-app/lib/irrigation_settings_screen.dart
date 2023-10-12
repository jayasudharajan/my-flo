
import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:provider/provider.dart';

import 'generated/i18n.dart';
import 'model/device.dart';
import 'model/item.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';


class IrrigationSettingsScreen extends StatefulWidget {
  IrrigationSettingsScreen({Key key}) : super(key: key);

  State<IrrigationSettingsScreen> createState() => _IrrigationSettingsScreenState();
}

class _IrrigationSettingsScreenState extends State<IrrigationSettingsScreen> with AfterLayoutMixin<IrrigationSettingsScreen> {

  @override
  void initState() {
    super.initState();
  }

  Device _device;

  @override
  void afterFirstLayout(BuildContext context) {
    final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
    _device = deviceProvider.value;
  }

  @override
  Widget build(BuildContext context) {
    final BuiltList<Item> items = as<BuiltList<Item>>(ModalRoute.of(context).settings.arguments);
    final deviceProvider = Provider.of<DeviceNotifier>(context);
    final device = deviceProvider.value;
    return WillPopScope(
        onWillPop: () async {
          putDevice(context, last: _device);
          Navigator.of(context).pop();
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(S.of(context).irrigation),
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                elevation: 0.0,
                centerTitle: true
            ),
            resizeToAvoidBottomPadding: true,
            body: Stack(children: <Widget>[
                FloGradientBackground(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Column(children: <Widget>[
              Text(device.displayNameOf(context), style: Theme.of(context).textTheme.subhead),
              SizedBox(height: 20,),
              Text(S.of(context).installation_on_irrigation_line_q(device.displayNameOf(context))),
              SizedBox(height: 20,),
              Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items.map((item) =>
                          Padding(padding: EdgeInsets.symmetric(vertical: 0), child: RadioListTile(title: Text(item.longDisplay), value: item.key, groupValue: deviceProvider.value.irrigationType, onChanged: (value) {
                            deviceProvider.value = deviceProvider.value.rebuild((b) => b..irrigationType = value);
                            deviceProvider.invalidate();
                          })
                          )).toList()
                  ))))),
            ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            ),
            ])),
        );
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
      ..irrigationType = deviceProvider.value.irrigationType
    ), authorization: oauthConsumer.value.authorization);
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
  } catch (e) {
    Fimber.e("putDevice", ex: e);
  }
}
