import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:built_collection/built_collection.dart';
import 'package:faker/faker.dart';
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
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'flo_stream_service.dart';
import 'flodetect_widgets.dart';
import 'home_settings_page.dart';
import 'model/alarm.dart';
import 'model/alarm_action.dart';
import 'model/alert.dart';
import 'model/alert_action.dart';
import 'model/alert_feedback.dart';
import 'model/alert_feedback_option.dart';
import 'model/alert_feedback_step.dart';
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


class FixturesScreen extends StatefulWidget {
  FixturesScreen({Key key}) : super(key: key);

  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> with AfterLayoutMixin<FixturesScreen> {

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  void afterFirstLayout(BuildContext context) {
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
    final isSubscribed = Provider.of<CurrentLocationNotifier>(context).value.subscription?.isActive ?? false;

    final child = Scaffold(
          resizeToAvoidBottomPadding: true,
          body: Stack(children: <Widget>[
              FloGradientBackground(),
        SafeArea(child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  brightness: Brightness.dark,
                  leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                  floating: true,
                  title: Text(ReCase(S.of(context).fixtures).titleCase),
                  centerTitle: true,
                ),
                SliverPadding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), sliver: SliverList(delegate: SliverChildListDelegate(<Widget>[
                  FloDetectCard(key: widget.key, showLastUpdate: true),
                  SizedBox(height: 10),
                  Visibility(visible: isSubscribed, child: FloDetectEventsCard()),
                ],
                ),
                ),
                )])
            )]));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
