
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'alerts_page.dart';
import 'widgets.dart';


class AlertsScreen extends StatefulWidget {
  AlertsScreen({Key key}) : super(key: key);

  State<AlertsScreen> createState() => _AlertsState();
}

class _AlertsState extends State<AlertsScreen> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: true,
        body:
        Stack(children: <Widget>[
          FloGradientBackground(),
          AlertsPage(filterEnabled: false)
        ]));
  }
}
