import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'flodetect_widgets.dart';
import 'model/app_info.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/notifications.dart';
import 'model/system_mode.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';
import 'package:shimmer/shimmer.dart';


class DashboardPage extends StatefulWidget {
  DashboardPage({Key key,
    @required
    this.pageController,
  }) : super(key: key);
  final PageController pageController;

  State<DashboardPage> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardPage> with SingleTickerProviderStateMixin, AfterLayoutMixin<DashboardPage>, WidgetsBindingObserver, RouteAware {

  TabController tabController;

  RefreshController _refreshController;
  ScrollController _scrollController;
  StreamSubscription _ping;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
    _scrollController = ScrollController();
    //setState(() {
    //  _loading = true;
    //});
    /*
    Future.delayed(Duration(microseconds: 500), () {
      _refreshController.requestRefresh();
      //setState(() {
      //  _loading = false;
      //});
    });
    Future.delayed(Duration(microseconds: 5000), () {
      _refreshController.refreshCompleted();
      //setState(() {
      //  _loading = false;
      //});
    });
    */

    final baseColor = Colors.grey[300].withOpacity(0.3);
    final highlightColor = Colors.grey[100].withOpacity(0.3);
    _loadingList = [
      SizedBox(height: 10),
      Row(children: [Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: 200,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )), Spacer(),
            ]),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      SingleChildScrollView(child:
      Row(children: <Widget>[
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 180,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
        SizedBox(width: 10),
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 180,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
        SizedBox(width: 10),
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 180,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
      ],),
          scrollDirection: Axis.horizontal,
      ),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 30),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 30),
    ];
  }

  List<Widget> _loadingList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
        _ping?.cancel();
      }
      break;
      case AppLifecycleState.resumed: {
        Fimber.d("resumed");
        onResume(context);
      }
      break;
      case AppLifecycleState.paused: {
        _ping?.cancel();
      }
      break;
      case AppLifecycleState.suspending: {
        _ping?.cancel();
      }
      break;
    }
  }

  void onResume(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauthProvider = Provider.of<OauthTokenNotifier>(context, listen: false);
    _ping?.cancel();
    _ping = Observable.fromFuture(PackageInfo.fromPlatform())
        .flatMap((platform) => Observable.range(0, 1<<16)
        .interval(Duration(seconds: 40)).map((it) => platform))
        .asyncMap((platform) => flo.presence(AppInfo((b) => b
            ..appName = "flo-android-app2"
            ..appVersion = platform.version
          ), authorization: oauthProvider.value.authorization))
        .listen((_) {}, onError: (e) {
          Fimber.e("", ex: e);
    });
  }

  @override
  void dispose() {
    _ping?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    FirebaseAuth.instance.signOut();
    _ping?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("build0");
    final locationsConsumer = Provider.of<LocationsNotifier>(context, listen: false);
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final locationName = locationConsumer.value.nickname ?? locationConsumer.value.address;
    //final devicesConsumer = Provider.of<DevicesNotifier>(context);
    Fimber.d("${locationConsumer.value}");
    Fimber.d("$locationName");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    List<Widget> list = const [];

    final appProvider = Provider.of<AppStateNotifier>(context);
    if (appProvider.value.error ?? false) {
      Future.delayed(Duration(seconds: 1), () {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).something_went_wrong),
          duration: Duration(hours: 1),
          action: SnackBarAction(label: S.of(context).retry, onPressed: () async {
            final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
            final userProvider = Provider.of<UserNotifier>(context, listen: false);
            final userConsumer = Provider.of<UserNotifier>(context);
            final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
            final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
            final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
            final floConsumer = Provider.of<FloNotifier>(context);
            final flo = floConsumer.value;
            final floStreamServiceNotifier = Provider.of<FloStreamServiceNotifier>(context);
            Fimber.d("${locationProvider.value}");
            locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
            locationProvider.invalidate();

            try {
              final userRes = await flo.getUser(oauthConsumer.value.userId, authorization: oauthConsumer.value.authorization);
              Fimber.d("${userRes.body}");
              userProvider.value = userRes.body;
              userProvider.invalidate();
              if (userConsumer.value.locations.isNotEmpty) {
                Fimber.d("${userConsumer.value.locations}");
                Observable.fromIterable(userConsumer.value.locations)
                    .flatMap((location) {
                  return Observable.fromFuture(flo.getLocation(location.id, authorization: oauthConsumer.value.authorization))
                      .onErrorResumeNext(Stream.empty())
                      .map((res) => res.body)
                      .doOnData((it) {
                  })
                      .where((it) => it != Location.EMPTY)
                      .where((it) => it?.address?.isNotEmpty ?? false)
                      .map((it) => it.rebuild((b) => b..id = b.id ?? location.id));
                })
                    .flatMap((location) {
                  return Observable.fromIterable(location.devices ?? [])
                      .flatMap((device) {
                    return Observable.fromFuture(flo.getDevice(device.id, authorization: oauthConsumer.value.authorization))
                        .onErrorResumeNext(Stream.empty())
                        .map((res) => res.body);
                  })
                      .where((it) => it != Device.EMPTY)
                      .toList()
                      .asObservable()
                      .map((devices) => location.rebuild((b) => b..devices = ListBuilder($(devices).whereNotNull().sortedBy((it) => it.nickname ?? ""))))
                      .doOnData((location) {
                    if (locationProvider.value.id == location.id) {
                      locationProvider.value = location;
                    }
                  });
                })
                    .toList()
                    .then((locations) {
                  locationsProvider.value = BuiltList<Location>($(locations).sortedBy((it) => it.nickname ?? ""));
                  if (locationProvider.value == Location.empty ||
                      $(locations).firstOrNullWhere((it) => it.id == locationProvider.value.id) == null) {
                    locationProvider.value = locations.first;
                  }
                })
                    .then((locations) {
                  locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
                  locationProvider.invalidate();
                  final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
                  appProvider.value = appProvider.value.rebuild((b) => b..error = false);
                  appProvider.invalidate();
                })
                    .catchError((e) {
                  Fimber.e("", ex: e);
                  locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
                  locationProvider.invalidate();
                  final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
                  appProvider.value = appProvider.value.rebuild((b) => b..error = true);
                  appProvider.invalidate();
                });
              }
            } catch (e) {
              Fimber.e("", ex: e);
              locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
              locationProvider.invalidate();
              final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
              appProvider.value = appProvider.value.rebuild((b) => b..error = true);
              appProvider.invalidate();
            }
          }
          )
      ));
      });
      list = [SizedBox(height: hp(75), child: Container())];
    }
    else if ((locationsConsumer.value?.isEmpty) ?? true) {
      list = [SizedBox(height: hp(75), child: EmptyHome())];
    } else {
      final bool isSubscribed = (locationConsumer.value.subscription?.isActive ?? false);
      list = [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: <Widget>[
          Expanded(child: locationName != null ? Text(locationName, style: Theme.of(context).textTheme.title.copyWith(color: Colors.white, fontSize: 24), maxLines: 1, overflow: TextOverflow.ellipsis,) : Container()),
          SystemModeDropdown(),
        ])),
        SizedBox(height: 10),
        (locationConsumer.value?.devices?.isNotEmpty ?? false) ? NotificationCard( // Guard conditions for customers
          location: locationConsumer.value,
          notification: locationConsumer.value?.devices?.map((it) => it.notifications?.pending ?? Notifications())?.reduce((it, that) => it + that) ?? Notifications(),
          orElse: YoureSecure(),
          onPressed: () {
            final selectedDevicesProvider = Provider.of<SelectedDevicesNotifier>(context, listen: false);
            selectedDevicesProvider.value = locationConsumer.value?.devices;
            Fimber.d("selectedDevicesProvider.value: ${selectedDevicesProvider.value}");
            selectedDevicesProvider.invalidate();
            widget.pageController.animateToPage(1, duration: Duration(milliseconds: 150), curve: Curves.fastOutSlowIn);
          },
        ) : Container(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: DevicesCard(locationConsumer.value?.devices ?? <Device>[])),
        /*
        (locationConsumer.value?.devices?.isEmpty ?? true) ? Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(width: double.infinity, child: EmptyDeviceCard(width: double.infinity),)) : SizedBox(
            height: 140,
            child: ListView.builder(
              key: widget.key,
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, i) {
                final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
                final flo = Provider.of<FloNotifier>(context, listen: false).value;
                final oauthProvider = Provider.of<OauthTokenNotifier>(context, listen: false);
                if (i < locationConsumer.value?.devices?.length ?? 0) {
                  final device = locationConsumer.value?.devices[i];
                  return StreamBuilder<Device>(stream: Observable.fromFuture(flo.getFirestoreToken(authorization: oauthProvider.value.authorization)
                     .then((it) => floStreamService.login(it.body.token)))
                      .flatMap((it) => floStreamService.device(device.macAddress)
                      .map((it) => it.rebuild((b) => b
                      ..telemetries = null
                      ..estimateWaterUsage = null
                      )).distinct()
                  ), initialData: device, builder: (context, snapshot) {
                    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                    //final a = $(locationProvider.value.devices).map((it) => it.macAddress == snapshot.data.deviceId ? it.merge(snapshot.data) : it).distinctBy((it) => it.macAddress);
                    //Fimber.d("a: $a");
                    //locationProvider.value = locationProvider.value.rebuild((b) => b..
                    //    devices = ListBuilder($(b.devices.build()).map((it) => it.macAddress == snapshot.data.deviceId ? it.merge(snapshot.data) : it).distinctBy((it) => it.macAddress))
                    //);
                    //locationProvider.invalidate();
                    //Fimber.d("device: ${device.macAddress}: ${snapshot.data}");
                    Fimber.d("device: ${device.macAddress}");
                    // TODO: replace the device into CurrentLocations

                    final alertsStateProvider = Provider.of<AlertsStateNotifier>(context, listen: false);
                    Fimber.d("device.notifications.pending changed: ${device.notifications?.pending != snapshot.data?.notifications?.pending}");
                    alertsStateProvider.value = alertsStateProvider.value.rebuild((b) => b
                        ..dirty = (b.dirty ?? false) || device.notifications?.pending != snapshot.data?.notifications?.pending
                    );
                    Fimber.d("alertsStateProvider.value.dirty: ${alertsStateProvider.value.dirty}");
                    final newDevice = device.merge(snapshot.data);
                    final newDevices = locationConsumer.value?.devices?.toList();
                    newDevices[i] = newDevice;
                    locationConsumer.value = locationConsumer.value.rebuild((b) => b
                        ..devices = ListBuilder(newDevices)
                    );
                    alertsStateProvider.invalidate();
                    return DeviceCard(device: snapshot.hasData ? newDevice : device);
                  });
                }
                return EmptyDeviceCard();
              },
              scrollDirection: Axis.horizontal,
              itemCount: (locationConsumer.value.devices?.length ?? 0) + 1,
            )),
        */
          SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: WaterUsageCard(),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: FloDetectCollapsibleCard(key: widget.key, limit: !isSubscribed ? 3 : null),
        ),
        /*
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: FloDetectEventsCollapsibleCard(),
        ),
        */
        SizedBox(height: 20),
      ];
    }

    if ((locationConsumer.value.dirty ?? false)) {
      Fimber.d("loading");
      _refreshController.requestRefresh();
    } else {
      Fimber.d("loaded");
      _refreshController.refreshCompleted();
    }

    /*
    Widget body = ListView(
      //controller: _scrollController,
      children: list,
      //key: widget.key,
    );

    body =
        RefreshConfiguration(
          child: SmartRefresher(
        //key: widget.key,
        controller: _refreshController,
        //enableTwoLevel: true,
        onRefresh: () async {
          final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
          locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
          locationProvider.invalidate();
          //await Future.delayed(Duration(milliseconds: 500));
          //final scroller = PrimaryScrollController.of(context);
          //scroller.animateTo(scroller.position.minScrollExtent, duration: null, curve: null);
          //scroller.jumpTo(0);
          //_refreshController.refreshCompleted();
        },
        child: body
    ));
    */

    /*
    } else if ((locationsConsumer.value?.isEmpty) ?? true) {
      body = EmptyHome();
    } else {
      body = SmartRefresher(
          controller: _refreshController,
          //enableTwoLevel: true,
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
            _loading = false;
            _scrollController.animateTo(
                _scrollController.position.minScrollExtent, duration: null,
                curve: null);
            _refreshController.refreshCompleted();
          },
          child: ListView(
            controller: _scrollController,
            children: list, key: widget.key,
          ));
    }
    */

    return RefreshConfiguration(
          child: SmartRefresher(
        //key: widget.key,
        controller: _refreshController,
        //enableTwoLevel: true,
        onRefresh: () async {
          final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
          locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
          locationProvider.invalidate();
          await Future.delayed(Duration(milliseconds: 500));
          //final scroller = PrimaryScrollController.of(context);
          //scroller.animateTo(scroller.position.minScrollExtent, duration: null, curve: null);
          //scroller.jumpTo(0);
          //_refreshController.refreshCompleted();
        },
        child: CustomScrollView(
            controller: _scrollController,
          key: ObjectKey(locationConsumer.value),
            //key: UniqueKey(),
              slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                floating: true,
                pinned: true,
                leading: SimpleDrawerButton(icon: SvgPicture.asset('assets/ic_fancy_menu.svg')),
                //automaticallyImplyLeading: true,
                centerTitle: true,
                title: Image.asset('assets/ic_flo_logo_padding.png'),
               ),
              //SliverList(delegate: SliverChildListDelegate(list)),
              //AnimatedSwitcher(duration: Duration(milliseconds: 300), child:
                  (locationConsumer.value.dirty ?? false) && (locationsConsumer.value?.isEmpty ?? true)
                      ? SliverList(delegate: SliverChildBuilderDelegate((context, i) => Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _loadingList[i]), childCount: _loadingList.length))
                      : SliverList(delegate: SliverChildBuilderDelegate((context, i) => list[i], childCount: list.length))
              //),
              //SliverList(delegate: SliverChildBuilderDelegate((context, i) => (i % 2) == 0 ? WaterUsage() : Container(height: 10, color: (i % 2) == 0 ? Colors.red : Colors.green), childCount: 10)),
              ]))
    ,
    );
    }

  @override
  void afterFirstLayout(BuildContext context) {
    Fimber.d("");
    //final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    //_refreshController.requestRefresh();
    /*
    if ((locationProvider.value?.dirty ?? false)) {
      Fimber.d("");
      _refreshController.requestRefresh();
    } else {
      _refreshController.refreshCompleted();
    }
    */
    onResume(context);
  }
}

class SystemModeDropdown extends StatefulWidget {
  @override
  _SystemModeDropdownState createState() => _SystemModeDropdownState();
}

class _SystemModeDropdownState extends State<SystemModeDropdown> {
  String _systemMode = SystemMode.SLEEP;

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    _systemMode = locationConsumer.value?.systemMode?.target ?? SystemMode.SLEEP;
    return
      Container(
          padding: EdgeInsets.only(left: 15, right: 5, top: 5, bottom: 5),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: ThemeBuilder(data: floLightThemeData.copyWith(hintColor: Colors.white, canvasColor: Colors.white.withOpacity(0.95)),
              builder: (context) => SimpleDropdownButton(
                label: Padding(padding: EdgeInsets.only(left: 5, right: 5, top: 15), child: Text(S.of(context).system_mode, style: Theme.of(context).textTheme.subhead, textScaleFactor: 0.8)),
                factor: 2.0,
                isDense: true,
                value: _systemMode,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: SystemMode.HOME,
                      child: Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_home2.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).home),
                      ])
                  ),
                  DropdownMenuItem<String>(
                      value: SystemMode.AWAY,
                      child: Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_away.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).away),
                      ])
                  ),
                  DropdownMenuItem<String>(
                      value: SystemMode.SLEEP,
                      child: Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_sleep.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).sleep),
                      ])
                  ),
                ],
                selectedMenuItemBuilder: (value) {
                  switch (value) {
                    case SystemMode.SLEEP: {
                      return Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_sleep.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).sleep),
                        SizedBox(width: 5),
                        Icon(Icons.check, size: 18,),
                      ]);
                    } break;
                    case SystemMode.AWAY: {
                      return Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_away.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).away),
                        SizedBox(width: 5),
                        Icon(Icons.check, size: 18,),
                      ]);
                    } break;
                    case SystemMode.HOME: {
                      return Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_home2.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).home),
                        SizedBox(width: 5),
                        Icon(Icons.check, size: 18,),
                      ]);
                    } break;
                    default: {
                      return Row(children: <Widget>[
                        SvgPicture.asset('assets/ic_sleep.svg', color: Theme.of(context).textTheme.subhead.color),
                        SizedBox(width: 10),
                        Text(S.of(context).sleep),
                        SizedBox(width: 5),
                        Icon(Icons.check, size: 18,),
                      ]);
                    }
                  }
                },
                iconEnabledColor: Colors.white,
                selectedItemBuilder: (context) {
                  return <Widget>[
                    Row(children: <Widget>[
                      SvgPicture.asset('assets/ic_home2.svg', color: Colors.white, height: 16, width: 16,),
                      SizedBox(width: 5),
                    ]),
                    Row(children: <Widget>[
                      SvgPicture.asset('assets/ic_away.svg', color: Colors.white),
                      SizedBox(width: 5),
                    ]),
                    Row(children: <Widget>[
                      SvgPicture.asset('assets/ic_sleep.svg', color: Colors.white),
                      SizedBox(width: 5),
                    ]),
                  ].toList();
                },
                onChanged: (systemMode) async {
                  if (systemMode == SystemMode.SLEEP) {
                    await showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return Theme(
                            data: floLightThemeData,
                            child: WillPopScope(
                                onWillPop: () async {
                                  Navigator.of(context).pop();
                                  return false;
                                }, child: AlertDialog(
                              title: Text(ReCase(S.of(context).sleep_mode).titleCase),
                              content: Text("During Sleep Mode the Flo System will not send you any alerts for the specified period of time. Use this Mode when you expect temporary high water usage and don't want to be alerted"),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text(S.of(context).confirm),
                                  onPressed: () async {
                                    await showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context2) {
                                        return Theme(
                                            data: floLightThemeData,
                                            child: AlertDialog(
                                              title: Text(ReCase(S.of(context).sleep_mode).titleCase),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  FlatButton(
                                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                      child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_2h,
                                                        textAlign: TextAlign.left,
                                                      )), onPressed: () async {
                                                    try {
                                                      await flo.sleep(locationConsumer.value.id,
                                                        duration: Duration(hours: 2),
                                                        revertMode: _systemMode,
                                                        authorization: oauthConsumer.value.authorization,
                                                      );
                                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                      locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                    } catch (e) {
                                                      Fimber.e("", ex: e);
                                                    }
                                                    _systemMode = systemMode;
                                                    Navigator.of(context2).pop();
                                                  }),
                                                  FlatButton(
                                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                      child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_24h,
                                                        textAlign: TextAlign.left,
                                                      )), onPressed: () async {
                                                    try {
                                                      await flo.sleep(locationConsumer.value.id,
                                                        duration: Duration(hours: 24),
                                                        revertMode: _systemMode,
                                                        authorization: oauthConsumer.value.authorization,
                                                      );
                                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                      locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                    } catch (e) {
                                                      Fimber.e("", ex: e);
                                                    }
                                                    _systemMode = systemMode;
                                                    Navigator.of(context2).pop();
                                                  }),
                                                  FlatButton(
                                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                      child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_72h,
                                                        textAlign: TextAlign.left,
                                                      )), onPressed: () async {
                                                    try {
                                                      await flo.sleep(locationConsumer.value.id,
                                                        duration: Duration(hours: 72),
                                                        revertMode: _systemMode,
                                                        authorization: oauthConsumer.value.authorization,
                                                      );
                                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                      locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                    } catch (e) {
                                                      Fimber.e("", ex: e);
                                                    }
                                                    _systemMode = systemMode;
                                                    Navigator.of(context2).pop();
                                                  }),
                                                ],),
                                              actions: <Widget>[
                                                FlatButton(
                                                  child: Text(S.of(context).cancel),
                                                  onPressed: () {
                                                    Navigator.of(context2).pop();
                                                  },
                                                ),
                                              ],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                            )
                                        );
                                      },
                                    );
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            ))
                        );
                      },
                    );
                  } else if (systemMode == SystemMode.AWAY) {
                    await showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AwayModeIrrigation(
                          onChanged: () {
                            _systemMode = systemMode;
                          },
                            enabled: locationConsumer.value?.mergedIrrigationSchedule?.enabled ?? false
                        );
                      },
                    );
                  } else if (systemMode == SystemMode.HOME) {
                    try {
                      await flo.home(locationConsumer.value.id,
                        authorization: oauthConsumer.value.authorization,
                      );
                      locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.HOME);
                      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                      locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                    } catch (e) {
                      Fimber.e("", ex: e);
                    }
                    _systemMode = systemMode;
                  }
                  return _systemMode == systemMode;
                },
              )
          )
      );
  }
}

class FloLightCard2 extends StatelessWidget {
  FloLightCard2(this.child, {
    Key key
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(data: floLightThemeData.copyWith(dividerColor: Colors.transparent,  accentColor: Colors.black.withOpacity(0.8)), builder: (context) => Card(child: child));
    /*
    return ThemeBuilder(data: floLightThemeData.copyWith(dividerColor: Colors.transparent,  accentColor: Colors.black.withOpacity(0.8)), builder: (context) => Container(
        child: child,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(floCardRadius)
        )
    ));
    */
  }
}

//class EmptyDeviceCard extends StatelessWidget {
//}

class DevicesCard extends StatelessWidget {
  DevicesCard(
  this.devices, {
    key,
  }) : super(key: key);
  final Iterable<Device> devices;

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    if (devices.isEmpty) {
      return ThemeBuilder(data: floLightThemeData.copyWith(dividerColor: Colors.transparent, accentColor: Colors.black.withOpacity(0.8)), builder: (context) =>
          Card(child: SizedBox(width: double.infinity, child: FlatButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: floCardRadius,
                  bottomRight: floCardRadius,
                ),
                side: BorderSide(color: Colors.black.withOpacity(0.1))),
            child: Column(children: <Widget>[
              Image.asset('assets/ic_circle_blue_add.png', width: 28, height: 28),
              SizedBox(height: 10),
              Text(S.of(context).add_device,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.subhead,
              ),
            ],),
            onPressed: () {
              Navigator.of(context).pushNamed('/add_a_flo_device');
            },
          ),
          ))
      );
    }

    return FloLightCard2(
        ExpansionTile(
            key: key ?? PageStorageKey(S.of(context).my_devices),
            initiallyExpanded: true,
            title: Text(S.of(context).my_devices),
            children: <Widget>[
              ...ListTile.divideTiles(
                context: context,
                tiles: devices.map<Widget>((device) {
                  return StreamBuilder<Device>(stream: Observable.fromFuture(flo.getFirestoreToken(authorization: oauth.authorization)
                      .then((it) => floStreamService.login(it.body.token)))
                      .flatMap((it) => floStreamService.device(device.macAddress)
                      .map((it) => it.rebuild((b) => b
                    ..telemetries = null
                    ..estimateWaterUsage = null
                  )).distinct()
                  ), initialData: device, builder: (context, snapshot) {
                    if (!snapshot.hasError && snapshot.data != null) {
                      Fimber.d("device: ${device.macAddress}");
                      // TODO: replace the device into CurrentLocations

                      final alertsStateProvider = Provider.of<AlertsStateNotifier>(context, listen: false);
                      Fimber.d("device.notifications.pending changed: ${device.notifications?.pending != snapshot.data?.notifications?.pending}");
                      alertsStateProvider.value = alertsStateProvider.value.rebuild((b) => b
                        ..dirty = (b.dirty ?? false) || device.notifications?.pending != snapshot.data?.notifications?.pending
                      );
                      Fimber.d("alertsStateProvider.value.dirty: ${alertsStateProvider.value.dirty}");
                      final newDevice = device.merge(snapshot.data);
                      final devices = locationConsumer.value?.devices?.toList();
                      final i = devices.indexWhere((it) => it.id == newDevice.id);
                      if (i != -1) { devices[i] = newDevice; }
                      locationConsumer.value = locationConsumer.value.rebuild((b) => b
                        ..devices = ListBuilder(devices)
                      );
                      alertsStateProvider.invalidate();
                      return DeviceTile(snapshot.hasData ? newDevice : device);
                    } else {
                      return Container();
                    }
                  });
                }),
                color: Colors.grey[400],
              ),
              AddDevice(),
              //Container(
              //    width: double.infinity,
            //    child: AddDevice(),
            //    decoration: BoxDecoration(
            //        color: Color(0xFFE3ECF2),
            //        borderRadius: BorderRadius.only(
            //            bottomLeft: Radius.circular(4.0),
            //            bottomRight: Radius.circular(4.0)))
            //),
          ])
    );
  }
}

