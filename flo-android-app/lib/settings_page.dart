import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:phone_number/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:tinycolor/tinycolor.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'model/user.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key,
    @required
    this.pageController,
  }) : super(key: key);
  final PageController pageController;

  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AfterLayoutMixin<SettingsPage> {

  bool _phoneNumberAutovalidate = false;
  String _phoneNumberErrorText = null;
  bool _isMetricUnitSystem = false;
  User _user;
  String _version;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isMetricUnitSystem = false;

    Future.delayed(Duration.zero, () async {
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      userProvider.value = userProvider.value.rebuild((b) => b
        ..locale = b.locale ?? Localizations.localeOf(context).toString()
      );
      final platform =  await PackageInfo.fromPlatform();
      setState(() {
        _isMetricUnitSystem = userProvider.value.isMetric;
        _version = platform.version;
      });
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    _location = locationProvider.value;
  }

  Location _location;

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final bool isMetricKpa = userConsumer.value.isMetric;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    Fimber.d("Goals: ${locationConsumer.value.gallonsPerDayGoal}");
    _user = userConsumer.value;

    final child = 
      WillPopScope(
      onWillPop: () async {
        _putUser(context, last: _user);
        return true;
      }, child: GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Stack(children: <Widget>[SafeArea(child: CustomScrollView(
        controller: _scrollController,
          slivers: <Widget>[
            SliverAppBar(
              //leading: SimpleDrawerButton(icon: SvgPicture.asset('assets/ic_fancy_menu.svg')),
              leading: SimpleDrawerButton(icon: Container()),
              brightness: Brightness.dark,
              title: Text(ReCase(S.of(context).settings).titleCase, textScaleFactor: 1.2,), // FIXME
              floating: true,
              centerTitle: true,
            ),
            SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      Text(S.of(context).user_profile, style: Theme.of(context).textTheme.subhead),
                      SizedBox(height: 15,),
                      TextFieldButton(text: "${userConsumer.value.firstName} ${userConsumer.value.lastName}",
                        endText: S.of(context).edit,
                        trailing: null,
                        onPressed: () {
                          Navigator.of(context).pushNamed('/edit_profile');
                        },
                      ),
                      SizedBox(height: 20,),
                      Text(S.of(context).locations, style: Theme.of(context).textTheme.subhead),
                    ]))),
            SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i)  {
                      final location = locationsConsumer.value[i];
                      return Padding(padding: EdgeInsets.symmetric(vertical: 5), child: TextFieldButton(text: location.nickname ?? S.of(context).nickname,
                        onPressed: () {
                          locationConsumer.value = location;
                          Navigator.of(context).pushNamed('/home_settings');
                        },
                      ));
                    },
                      childCount: locationsConsumer.value.length ?? 0,
                    ))),
            SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      Container(child: EmptyLocationCardHorizontal()),
                    ]))),
            SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), sliver:
            SliverList(delegate: SliverChildListDelegate(
              <Widget>[
                Text(S.of(context).units, style: Theme.of(context).textTheme.subhead),
                SizedBox(height: 15,),
                TextFieldButton(text: S.of(context).imperial,
                  endText: S.of(context).gallon_fahrenheit_psi,
                  trailing: !_isMetricUnitSystem ? Icon(Icons.check, size: 18) : Icon(Icons.check, color: Colors.transparent, size: 18),
                  onPressed: () {
                    userConsumer.value = userConsumer.value.rebuild((b) => b..unitSystem = UnitSystem.imperialUs);
                    setState(() {
                      _isMetricUnitSystem = !_isMetricUnitSystem;
                    });
                    _putUser(context, last: _user);
                  },
                ),
                SizedBox(height: 10,),
                TextFieldButton(text: S.of(context).metric,
                  endText: S.of(context).liter_celsius_kpa,
                  trailing: _isMetricUnitSystem ? Icon(Icons.check, size: 18) : Icon(Icons.check, color: Colors.transparent, size: 18),
                  onPressed: () {
                    userConsumer.value = userConsumer.value.rebuild((b) => b..unitSystem = UnitSystem.metricKpa);
                    setState(() {
                      _isMetricUnitSystem = !_isMetricUnitSystem;
                    });
                    _putUser(context, last: _user);
                  },
                ),
                SizedBox(height: 20,),
                Text(S.of(context).other_, style: Theme.of(context).textTheme.subhead),
                SizedBox(height: 15,),
                /*
                Stack(children: [
                  TextFieldButton(text: S.of(context).language,
                    endText: "", // FIXME
                    //endText: "ENG", // FIXME
                    onPressed: () {
                      //Navigator.of(context).pushNamed('/404');
                    },
                  ),
                  Theme(data: floLightThemeData, child: Opacity(opacity: 0.5, child: Padding(padding: EdgeInsets.only(top: 3, left: 40, right: 20), child: Align(
                      alignment: Alignment.centerRight,
                      child: SimpleDropdownButton<String>( // en-US, zh-TW
                        //icon: Icon(Icons.arrow_forward_ios),
                        isExpanded: true,
                        iconSize: 0,
                        value: userConsumer.value?.locale ?? "en",
                        items: <String>["en", "es", "zh"].map((value) {
                          return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(padding: EdgeInsets.only(left: 30, right: 40), child: Align(alignment: Alignment.centerRight, child: Text(locales[value] ?? value, style: TextStyle(color: floBlue), textAlign: TextAlign.end,)),
                              ));
                        }).toList(),
                        onChanged: (value) {
                          userConsumer.value = userConsumer.value.rebuild((b) => b..locale = value);
                        },
                      ))))),
                ]),
                SizedBox(height: 10,),
                */
                TextFieldButton(text: S.of(context).app_version,
                  endText: _version ?? S.of(context).unknown,
                  onPressed: null,
                  trailing: null,
                ),
                SizedBox(height: 20,),
              ],
            )),
            ),
          SliverPadding( padding: EdgeInsets.symmetric(vertical: 10), ),
        ])
      ),
    ],
    )));

    return child;
  }
}

Future<void> _putUser(BuildContext context, {User last}) async {
  final userProvider = Provider.of<UserNotifier>(context, listen: false);
  if (last == userProvider.value) {
    return;
  }
  final floConsumer = Provider.of<FloNotifier>(context, listen: false);
  final flo = floConsumer.value;
  final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
  final user = userProvider.value;
  try {
    await flo.putUser(user, authorization: oauthConsumer.value.authorization);
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    //userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
  } catch (e) {
    Fimber.e("putUser", ex: e);
  }
}
