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
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:tinycolor/tinycolor.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';

class HomeSettingsPage extends StatefulWidget {
  HomeSettingsPage({Key key,
    @required
    this.pageController,
  }) : super(key: key);
  final PageController pageController;

  State<HomeSettingsPage> createState() => _HomeSettingsPageState();
}

class _HomeSettingsPageState extends State<HomeSettingsPage> with AfterLayoutMixin<HomeSettingsPage> {

  @override
  void initState() {
    super.initState();
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
    final user = userConsumer.value;
    final bool isMetricKpa = userConsumer.value.unitSystem == UnitSystem.metricKpa;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    Fimber.d("Goals: ${locationConsumer.value.gallonsPerDayGoal}");

    final child = 
      WillPopScope(
      onWillPop: () async {
        if (locationConsumer.value.nickname?.isEmpty ?? true) {
          showDialog(
            context: context,
            builder: (context) =>
              Theme(data: floLightThemeData, child: Builder(builder: (context2) => AlertDialog(
                title: Text(S.of(context).invalid),
                content: Text(S.of(context).should_not_be_empty),
                actions: <Widget>[
                  FlatButton(
                    child: Text(S.of(context).ok),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
              ))),
          );
        }
        putLocation(context, last: _location);
        //Navigator.of(context).pop();
        return true;
      }, child: GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Stack(children: <Widget>[
      Scaffold(
        backgroundColor: Colors.transparent,
        /*
        appBar: AppBar(
          brightness: Brightness.dark,
          /*
          leading: IconButton(icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            }
          ),
          centerTitle: true,
          */
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          title: Text("Home Settings", textScaleFactor: 1.2,), // FIXME
        ),
        */
        resizeToAvoidBottomPadding: true,
        body: SafeArea(child: CustomScrollView(
          slivers:
          locationConsumer.value == Location.empty
              ? <Widget>[SliverFillRemaining(child: EmptyHome())]
              : <Widget>[
            SliverAppBar(
              brightness: Brightness.dark,
              automaticallyImplyLeading: false,
              title: Text(ReCase(S.of(context).home_settings).titleCase, textScaleFactor: 1.2,),
              floating: true,
              actions: <Widget>[
                FlatButton(child:
                  Row(children: <Widget>[
                      Text(ReCase(S.of(context).my_profile).titleCase, style: Theme.of(context).textTheme.subtitle.copyWith(color: Colors.white.withOpacity(0.5)),),
                      SizedBox(width: 5,),
                      Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white.withOpacity(0.5)),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/edit_profile');
                  },
                )
              ],
            ),
          /*
          locationConsumer.value == Location.empty
           ? SliverToBoxAdapter(child: EmptyHome())
           : CustomScrollView(
          slivers: <Widget>[
          */
            SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
          <Widget>[
            SizedBox(width: 10),
            Row(children: [
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                  Text(locationConsumer.value.nickname ?? "", style: Theme.of(context).textTheme.title),
                  SizedBox(height: 10,),
                  Text(locationConsumer.value.address ?? "",
                   style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5)),
                   textScaleFactor: 1.2,
                   overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 20,),
                ],)),
                (locationConsumer.value.subscription?.isActive ?? false) ? FloProtectOn() : FloProtectOff(),
            ]),
          Text(S.of(context).nickname, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 10,),
          Theme(data: floLightThemeData, child: OutlineTextFormField(
            initialValue: locationConsumer.value.nickname ?? "",
            //labelText: "Nickname",
            hintText: S.of(context).enter_a_nickname_for_your_home,
            maxLength: 24,
            counterText: '',
            autovalidate: true,
            onFieldSubmitted: (text) {
              final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
              locationProvider.invalidate();
            },
            validator: (text) {
              if (text.isEmpty) {
                return S.of(context).nickname_not_empty;
              }
              if (locationsConsumer.value
              .where((it) => it.id != locationConsumer.value.id)
                  .any((location) => location.nickname == text)) {
                return S.of(context).nickname_already_in_use;
              }
              return null;
            },
            onUnfocus: (text) async {
              if (text.isNotEmpty) {
                await putLocation(context, last: _location);
                final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                locationsProvider.value = locationsProvider.value.map((it) => it.id == _location.id ? _location : it);
                locationProvider.invalidate();
                locationsProvider.invalidate();
              }
            },
            onChanged: (text) {
              if (text.isNotEmpty) {
                final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                locationProvider.value = locationProvider.value.rebuild((b) => b
                ..nickname = text.trim()
                );
              }
            },
          )),
          SizedBox(height: 20,),
          Text(ReCase(S.of(context).location_profile).titleCase, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 10,),
          TextFieldButton(text: S.of(context).edit,
           endText: "",
           onPressed: () {
            Navigator.of(context).pushNamed('/location_profile');
           },
          ),
          SizedBox(height: 20,),
          Text(S.of(context).goals, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 10,),
          TextFieldButton(text: ReCase(S.of(context).daily_water_usage).titleCase,
           ///endText: "${((locationConsumer.value.gallonsPerDayGoal ?? 1) * (isMetricKpa ? LITER_FACTOR : 1.0)).round()} ${(isMetricKpa ? "liters" : "gal.")}",
            endText: user.unitSystemOr().volumeText(context, locationConsumer.value.gallonsPerDayGoal ?? 1),
           onPressed: () {
            Navigator.of(context).pushNamed('/goals');
           },
          ),
          SizedBox(height: 20,),
          Text(S.of(context).devices, style: Theme.of(context).textTheme.subhead), // FIXME
        ],
        ))
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, i)  {
            //(locationConsumer.value?.devices?.isNotEmpty ?? false ) ?  {
            final device = locationConsumer.value?.devices[i];
            return Padding(padding: EdgeInsets.symmetric(vertical: 5), child: TextFieldButton(text: device.displayNameOf(context),
            endText: device.installationPoint ?? "",
            onPressed: () {
              deviceConsumer.value = device;
              Navigator.of(context).pushNamed('/device_settings');
            },
            ));
          },
          childCount: locationConsumer.value?.devices?.length ?? 0,
          ))),
            SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      Container(child: EmptyDeviceCardHorizontal()),
                    ]))),
          SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
            SizedBox(width: double.infinity,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: FlatButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context2) =>
                              Theme(data: floLightThemeData, child:
                                  (locationConsumer.value?.devices?.isNotEmpty ?? false) ? AlertDialog(
                                //content: Text("You still have devices linked to this location. Please unlink all your devices first."),
                                    content: Text(S.of(context).devices_linked_to_this_location),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text(S.of(context).ok),
                                    onPressed: () { Navigator.of(context).pop(); },
                                  ),
                                ],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              ) :
                              AlertDialog(
                                title: Text(S.of(context).delete_location_q),
                                //content: Text( "This operation cannot be undone. Are you sure you want to continue?"),
                                content: Text(S.of(context).confirm_remove_home),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text(S.of(context).cancel),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child:  Text(S.of(context).delete_location),
                                    onPressed: () async {
                                      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
                                      try {
                                        await flo.removeLocation(locationConsumer.value.id, authorization: oauthConsumer.value.authorization);
                                      } catch (e) {
                                        // TODO: Implement Error Dialog
                                        Fimber.e("", ex: e);
                                      }
                                      Navigator.of(context2).pop();
                                      final userProvider = Provider.of<UserNotifier>(context, listen: false);
                                      userProvider.value = userProvider.value.rebuild((b) => b
                                          ..dirty = true
                                      );
                                      userProvider.invalidate();
                                      widget.pageController.animateToPage(0,
                                        duration: Duration(milliseconds: 250),
                                          curve: Curves.ease);
                                      //Navigator.of(context2).pushNamed('/404'); // should work now
                                    },
                                  ),
                                ],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              )),
                        );
                      },
                      child: Text(S.of(context).delete_location, textScaleFactor: 1.4,),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ))),
                    ]))),
          SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 10),
          ),
        ])
      )
      ),
    ],
    )));

    return child;
  }
}

