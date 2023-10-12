import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:provider/provider.dart';
import 'home_settings_page.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';

class GoalsScreen extends StatefulWidget {
  GoalsScreen({Key key}) : super(key: key);

  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with AfterLayoutMixin<GoalsScreen> {

  @override
  void initState() {
    super.initState();
  }

  FocusNode focus1 = FocusNode();
  FocusNode focus2 = FocusNode();
  TextEditingController textController1 = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  int _volumePerPersonPerDayGoal = 1;
  int _volumePerDayGoal = 1;
  Location _location;

  static const MAX_GOAL = 99999; // NOTICE you should see also maxLength

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    _location = locationProvider.value;

    locationProvider.value = locationProvider.value.rebuild((b) => b..occupants = max((b.occupants ?? 1), 1));
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    final isMetricKpa = userProvider.value.unitSystem == UnitSystem.metricKpa;
    setState(() {
      _volumePerDayGoal = isMetricKpa ? toLiters(locationProvider.value.gallonsPerDayGoal).round() : locationProvider.value.gallonsPerDayGoal.round();
      _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationProvider.value.occupants;
      textController1.text = "${_volumePerPersonPerDayGoal}";
      textController2.text = "${_volumePerDayGoal}";
    });
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final userConsumer = Provider.of<UserNotifier>(context);
    final isMetricKpa = userConsumer.value.unitSystem == UnitSystem.metricKpa;

    final child = 
      WillPopScope(
      onWillPop: () async {
        final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
        Fimber.d("put gallonsPerDayGoal: ${locationProvider.value.gallonsPerDayGoal}");
        await putLocation(context, last: _location);
        Navigator.of(context).pop();
        return false;
      }, child: GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          centerTitle: true,
          elevation: 0.0,
          title: Text(S.of(context).goals),
        ),
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
          SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Column(children: <Widget>[
        SizedBox(width: double.infinity, child: Text(S.of(context).per_person,
          style: Theme.of(context).textTheme.subhead,
        )),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: Builder(builder: (context) => Stack(children: [
          OutlineTextFormField(
          focusNode: focus1,
          controller: textController1,
          initialValue: "${_volumePerPersonPerDayGoal}",
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          maxLength: 5,
          onUnfocus: (text) async {
            _volumePerDayGoal = max(min(int.tryParse(text) ?? 0, MAX_GOAL), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationProvider.value.occupants;
            locationProvider.value = locationProvider.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            Fimber.d("onUnfocus: $_volumePerPersonPerDayGoal");
            locationProvider.invalidate();
          },
          onFieldSubmitted: (text) {
            Fimber.d("onFieldSubmitted: _volumePerPersonPerDayGoal");
            FocusScope.of(context).requestFocus(focus2);
          },
          onChanged: (text) {
            if (!focus1.hasFocus) return;
            Fimber.d("onChanged: _volumePerPersonPerDayGoal");
            _volumePerDayGoal = max(min((int.tryParse(text) ?? 0) * locationProvider.value.occupants, MAX_GOAL), 1).round();
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationProvider.value.occupants;
            locationProvider.value = locationProvider.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            if (!focus2.hasFocus) {
              textController2.text = "${_volumePerDayGoal}";
            }
          },
          hintText: isMetricKpa ? S.of(context).liters_per_day : S.of(context).gal_per_day,
        ),
        Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                   child: Padding(
                     padding: EdgeInsets.only(right: 20, bottom: 20),
                     child: Text(isMetricKpa ? S.of(context).liters_per_day : S.of(context).gal_per_day, style: Theme.of(context).textTheme.body2.copyWith(color: floBlue)))
                     )
        ),
        ],
        )
        )),
        SizedBox(height: 15),
        SizedBox(height: 15),
        Row(children: <Widget>[
          Text(S.of(context).total,
            style: Theme.of(context).textTheme.subhead,
          ),
        SizedBox(width: 15),
          Text("(${locationProvider.value.occupants} ${S.of(context).people})",
            style: Theme.of(context).textTheme.body1,
          ),
        ]),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: Builder(builder: (context) => Stack(children: [
          OutlineTextFormField(
          focusNode: focus2,
          initialValue: "${_volumePerDayGoal}",
          controller: textController2,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          maxLength: 5,
          onUnfocus: (text) async {
            _volumePerDayGoal = max(min(int.tryParse(text) ?? 0, MAX_GOAL), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationProvider.value.occupants;
            Fimber.d("onUnfocus: $_volumePerDayGoal");
            locationProvider.value = locationProvider.value.rebuild((b) => b
            ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            locationProvider.invalidate();
          },
          onFieldSubmitted: (text) {},
          hintText: isMetricKpa ? S.of(context).liters_per_day: S.of(context).gal_per_day,
          onChanged: (text) {
            if (!focus2.hasFocus) return;
            Fimber.d("onChanged: _volumePerDayGoal");
            _volumePerDayGoal = max(min(int.tryParse(text) ?? 0, MAX_GOAL), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationProvider.value.occupants;
            locationProvider.value = locationProvider.value.rebuild((b) => b
            ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            if (!focus1.hasFocus) {
              textController1.text = "${_volumePerPersonPerDayGoal ?? ""}";
            }
          },
        ),
        Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                   child: Padding(
                     padding: EdgeInsets.only(right: 20, bottom: 20),
                     child: Text(isMetricKpa ? S.of(context).liters_per_day : S.of(context).gal_per_day, style: Theme.of(context).textTheme.body2.copyWith(color: floBlue)))
                     )
        ),
        ]),
        )
        ),
        SizedBox(height: 15),
          SizedBox(height: 20,),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
        ))
      )
        ])),
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
