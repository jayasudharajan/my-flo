import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aws/flutter_aws.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_embrace/flutter_embrace.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superpower/superpower.dart';
import 'package:version/version.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:zendesk/zendesk.dart';

import 'activity.dart';
import 'alerts_page.dart';
import 'dashboard_page.dart';
import 'flo_stream_service.dart';
import 'generated/i18n.dart';
import 'help_page.dart';
import 'model/alert1.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/flo_config.dart';
import 'model/location.dart';
import 'model/login_state.dart';
import 'model/oauth_token.dart';
import 'model/push_notification.dart';
import 'model/push_notification_token.dart';
import 'model/user.dart';
import 'providers.dart';
import 'settings_page.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:collection/collection.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key,
    this.index = 0
  }) : super(key: key);
  final int index;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, AfterLayoutMixin<HomePage> {

  int _bottomSelectedIndex;
  PageController pageController;
  BuildContext _context;
  BuildContext get activeContext => _context ?? navigator.of()?.context ?? context;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    Embrace.startAppStartup();

    final activity = Activity();
    activity.stream
    // FIXME: Type-safety it maybe not Map
    .distinct((it, that) => MapEquality().equals(it, that))
        .listen((intent) {
      Fimber.d("onNewIntent: $intent");
      final floAlarmNotificaation = Maps.get(intent, 'FloAlarmNotification');
      final alert1 = let(floAlarmNotificaation, (it) => Alert1.from(it));
      if (Maps.get(intent, 'action') == "com.flotechnologies.intent.action.INCIDENT" || alert1 != null) {
        Future.delayed(Duration.zero, () async {
          final alert = await alert1?.toAlert(navigator.of()?.context);
          Fimber.d("onNewIntent: Alert: $alert");
          if (!(alert?.isEmpty ?? true)) {
            Fimber.d("going to /alert");
            navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoutes.not('/alert'), arguments: alert);
            //navigator.of()?.pushNamed("/alert", arguments: alert);
          }
        });
      }
    }, onError: (err) {
      Fimber.e("", ex: err);
    });

    Future.delayed(Duration.zero, () async {
      await Aws.initialize();
    });
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.configure(
      //onBackgroundMessage: backgroundMessageHandler, // top
      onMessage: (Map<String, dynamic> message) async {
        ///  {notification: {title: test2, body: test2}, data: {}}
        Fimber.d("firebaseMessaging: onMessage: $message");
        Fimber.d("firebaseMessaging: data: ${Maps.get(message, 'data')}");
        Fimber.d("firebaseMessaging: notification: ${Maps.get(message, 'notification')}");
        final pushNotification = PushNotification.fromMap2(message);
        try {
          final pushNotification = PushNotification.fromMap2(message);
          Fimber.d("pushNotification: $pushNotification");
          if (pushNotification?.data?.url != null) {
            Fimber.d("firebaseMessaging: onMessage: url: ${pushNotification?.data?.url}");
            if (ModalRoute.of(activeContext).settings.name == '/home') {
              navigator.of()?.pushNamedAndRemoveUntil("/${Uri.tryParse(pushNotification.data.url).host}", ModalRoutes.not("/${Uri.tryParse(pushNotification.data.url).host}"), arguments: pushNotification.data.data);
            } else {
              Flushbar(
                titleText: Text(pushNotification?.notification?.title ?? "", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                messageText: Text(pushNotification?.notification?.body ?? "", style: TextStyle(color: Colors.black87)),
                duration: Duration(seconds: 10),
                backgroundColor: Colors.white,
                flushbarStyle: FlushbarStyle.FLOATING,
                animationDuration: Duration(milliseconds: 500),
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(14),
                borderRadius: floCardRadiusDimen,
                flushbarPosition: FlushbarPosition.TOP,
                onTap: (bar) {
                  navigator.of()?.pushNamedAndRemoveUntil("/${Uri.tryParse(pushNotification.data.url).host}", ModalRoutes.not("/${Uri.tryParse(pushNotification.data.url).host}"), arguments: pushNotification.data.data);
                },
              )..show(activeContext);
            }
          } else {
            final data = Maps.get(message, 'data');
            final floAlarmNotificaation = Maps.get(data, 'FloAlarmNotification');
            Fimber.d("firebaseMessaging: onMessage: type: ${floAlarmNotificaation?.runtimeType}");
            final alert1 = let(floAlarmNotificaation, (it) => Alert1.from(it));
            Fimber.d("firebaseMessaging: onMessage: alert1: ${alert1}");
            if (pushNotification?.notification?.clickAction == "com.flotechnologies.intent.action.INCIDENT" || alert1 != null) {
              Fimber.d("firebaseMessaging: onMessage: push data: ${pushNotification?.data?.data}");
              if (pushNotification?.data?.data == null) {
                // Here is no providers yet
                final alert = await alert1?.toAlert(navigator.of()?.context);
                Fimber.d("firebaseMessaging: onMessage: $alert");
                Fimber.d("firebaseMessaging: onMessage: notification.title: ${pushNotification?.notification?.title}");
                if (!(alert?.isEmpty ?? true)) {
                  Flushbar(
                    titleText: Text(pushNotification?.notification?.title ?? "", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    messageText: Text(pushNotification?.notification?.body ?? "", style: TextStyle(color: Colors.black87)),
                    duration: Duration(seconds: 10),
                    backgroundColor: Colors.white,
                    flushbarStyle: FlushbarStyle.FLOATING,
                    animationDuration: Duration(milliseconds: 500),
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(14),
                    borderRadius: floCardRadiusDimen,
                    flushbarPosition: FlushbarPosition.TOP,
                    onTap: (bar) {
                      navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoutes.not('/alert'), arguments: alert);
                    },
                  )..show(activeContext);
                }
              } else {
                //navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoute.withName('/home'), arguments: pushNotification?.data?.data);
              }
            }
            Fimber.d("");
          }
        } catch (err) {
          Fimber.e("", ex: err);
        }
        await Aws.onMessage(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        Fimber.d("firebaseMessaging: onLaunch: $message");
        //_navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        Fimber.d("firebaseMessaging: onResume: $message");
        try {
          final pushNotification = PushNotification.fromMap2(message);
          Fimber.d("pushNotification: $pushNotification");
          if (pushNotification?.data?.url != null) {
            Fimber.d("firebaseMessaging: onResume: url: ${pushNotification?.data?.url}");
            navigator.of()?.pushNamed("/${Uri.tryParse(pushNotification.data.url).host}", arguments: pushNotification.data.data);
          } else {
            final data = Maps.get(message, 'data');
            final floAlarmNotificaation = Maps.get(data, 'FloAlarmNotification');
            Fimber.d("firebaseMessaging: onResume: type: ${floAlarmNotificaation?.runtimeType}");
            final alert1 = let(floAlarmNotificaation, (it) => Alert1.from(it));
            Fimber.d("firebaseMessaging: onResume: alert1: ${alert1}");
            if (pushNotification?.notification?.clickAction == "com.flotechnologies.intent.action.INCIDENT" || alert1 != null) {
              Fimber.d("firebaseMessaging: onResume: going to /alert");
              Fimber.d("firebaseMessaging: onResume: push data: ${pushNotification?.data?.data}");
              if (pushNotification?.data?.data == null) {
                // Here is no providers yet
                final alert = await alert1?.toAlert(navigator.of()?.context);
                Fimber.d("firebaseMessaging: onResume: $alert");
                if (!(alert?.isEmpty ?? true)) {
                  navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoutes.not('/alert'), arguments: alert);
                }
              } else {
                //navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoute.withName('/home'), arguments: pushNotification?.data?.data);
              }
            }
            Fimber.d("");
          }
        } catch (err) {
          Fimber.e("", ex: err);
        }
        //_navigateToItemDetail(message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      Fimber.d("firebaseMessaging: Settings registered: $settings");
    });
    _firebaseMessaging.onTokenRefresh
        .listen((String token) {
      Fimber.d("firebaseMessaging: Settings registered: $token");
      Aws.onNewToken(token);
      putPushNotificationToken(context, token: token, awsEndpointId: Aws.endpointId);
    });

    _firebaseMessaging.getToken().then((String token) {
      Fimber.d("firebaseMessaging getToken: $token");
    });


    onInvalidate(context);

    super.initState();

    Future.delayed(Duration.zero, () async {
      await initZendesk(context);
      try {
        // ref. https://aws-amplify.github.io/docs/android/analytics#registering-endpoints-in-your-application
        final putPushRes = await putPushNotificationToken(context);
        Fimber.d("${putPushRes}");
        final prefs = await SharedPreferences.getInstance();
        final hasIntroducedV2 = or(() => prefs.getBool(HAS_INTRODUCED_V2)) ?? false;
        if (!hasIntroducedV2) {
          prefs.setBool(HAS_INTRODUCED_V2, true);
        showDialog(
            context: context,
            builder: (context2) =>
              ThemeBuilder(
                  data: floLightThemeData,
                  builder: (context) => AlertDialog(
                  title: Text(S.of(context).has_an_updated_features, style: Theme.of(context).textTheme.title.copyWith(color: floBlue)),
                  content: Column(children: <Widget>[
                    Expanded(child: SingleChildScrollView(child: Column(children: <Widget>[
                    Image.asset('assets/ic_flo_device_circle.png', height: 150),
                    SizedBox(height: 20),
                    RichText(
                        text: TextSpan(
                            children: <TextSpan>[
                              SimpleTextSpan(
                                context,
                                text: "We’ve simplified the interface, and your app now supports multiple locations and devices all within one account.\n\nHave multiple accounts and want to merge into one? Simply reach out to us at ", // FIXME: translatable
                              ),
                              SimpleTextSpan(
                                context,
                                text: S.of(context).support_email,
                                url: "mailto:${S.of(context).support_email}",
                              ),
                              SimpleTextSpan(
                                context,
                                text: ".\n\nNeed help using the app? Check out our ", // FIXME: translatable
                              ),
                              SimpleTextSpan(
                                context,
                                text: "app overview video by clicking here", // FIXME: translatable
                                url: "https://youtu.be/f35gctshj1I",
                              ),
                            ])
                    ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                  ))),
                    SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: FloLightBlueGradientButton(FlatButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(floButtonRadius)),
                        child: Text(S.of(context).check_it_out, style: TextStyle(color: Colors.white), textScaleFactor: 1.2),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }))),
                  ]),
              )
            ));
        }
      } catch (err) {
        Fimber.e("", ex: err);
      }
    });

    _locations = [];
    _drawerScrollController = ScrollController();
    _loading = false;
    _refreshController = RefreshController(initialRefresh: true);
    _bottomSelectedIndex = widget.index;
    pageController = PageController(
      initialPage: _bottomSelectedIndex,
      keepPage: true,
    );
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    if (oldWidget.index != widget.index) {
      _bottomSelectedIndex = widget.index;
      Fimber.d("HomePage index ${widget.index}");
      final SimpleFancyBottomNavigationState fState =
          bottomNavigationKey.currentState;
      fState.setPage(_bottomSelectedIndex);
      pageController.jumpToPage(_bottomSelectedIndex);
    }
    return super.didUpdateWidget(oldWidget);
  }

  ScrollController _scrollController;
  ScrollController _drawerScrollController;
  bool _loading = false;
  RefreshController _refreshController;

  onInvalidate(BuildContext context) {
    Fimber.d("onReume: loading: $_loading");
    if (_loading) return;
    _loading = true;
    Future.delayed(Duration.zero, () async {
      final prefsConsumer = Provider.of<PrefsNotifier>(context);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefsConsumer.value = prefs;

      WiFiForIoTPlugin.forceWifiUsage(false);
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      final userConsumer = Provider.of<UserNotifier>(context);
      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
      final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
      final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
      //deviceProvider.value.
      final floConsumer = Provider.of<FloNotifier>(context);
      final flo = floConsumer.value;
      final floStreamServiceNotifier = Provider.of<FloStreamServiceNotifier>(context);
      //final floStreamService = floStreamServiceNotifier.value;
      //floStreamServiceNotifier.value = await FloMqtt.of(context,
      // 'ssl://mqtt.flosecurecloud.com:8001',
      //  authorization: oauthConsumer.value.authorization);
      Fimber.d("current location: ${locationProvider.value}");
      locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
      locationProvider.invalidate();

      try {
        final userRes = await flo.getUser(oauthConsumer.value.userId, authorization: oauthConsumer.value.authorization).timeout(Duration(seconds: 30));
        Fimber.d("fetched user: ${userRes.body}");
        userProvider.value = userRes.body;
        userProvider.invalidate();

        final lastLocationId = prefs.getString(LAST_LOCATION_ID);
        Fimber.d("lastLocationId: ${lastLocationId}");
        if (userConsumer.value.locations.isNotEmpty) {
          Fimber.d("locations: ${userConsumer.value.locations}");
          //_refreshController.requestRefresh();
          //setState(() {
          //  _loading = true;
          //});
          Observable.fromIterable(userConsumer.value.locations)
          //.doOnData((it) {
          //  Fimber.d("onData location id: $it");
          //})
              .flatMap((location) {
            return Observable.fromFuture(flo.getLocation(location.id, authorization: oauthConsumer.value.authorization))
                //.onErrorResumeNext(Stream.empty())
                .map((res) => res.body)
                .doOnData((it) {
              Fimber.d("onData location: $it");
            })
                .where((it) => it != Location.EMPTY)
                .where((it) => it?.address?.isNotEmpty ?? false)
                .map((it) => it.rebuild((b) => b..id = b.id ?? location.id));
          })
              .flatMap((location) {
            Fimber.d("fetch devices for ${location.displayName}");

            return Observable.fromIterable(location.devices ?? [])
                .flatMap((device) {
              Fimber.d("fetch device for ${device.id}");
              return Observable.fromFuture(flo.getDevice(device.id, authorization: oauthConsumer.value.authorization))
                  .onErrorResumeNext(Stream.empty())
                  .map((res) => res.body);
            })
                .where((it) => it != Device.EMPTY)
                .doOnData((it) {
              Fimber.d("fetched device for ${it.displayName}");
              /*
                  if (it.id == deviceProvider.value)
                  deviceProvider.value = it;
                  */
            })
                .toList()
                .asObservable()
                .map((devices) => location.rebuild((b) => b..devices = ListBuilder<Device>($(devices).whereNotNull().sortedBy((it) => it.nickname ?? ""))))
                .doOnData((location) {
              Fimber.d("fetched devices for ${location.displayName}");

              Fimber.d("update location if selected ${location.displayName}");
              if (locationProvider.value.id == location.id) {
                locationProvider.value = location;
              }
            });
          })
          //.where((it) => it != null)
          //.doOnData((it) {
          //  Fimber.d("onData location: $it");
          //})
              .toList()
              .then((locations) {
            Fimber.d("fetched locations ${or(() => locations.map((it) => it.displayName))}, and sorting and selecting first location");
            //locationsConsumer.current = locationsConsumer.current.rebuild((b) => b..
            //);
            locationsProvider.value = BuiltList<Location>(or(() => $(locations).sortedBy((it) => it.nickname ?? "")) ?? const []);
            /*
            Future.delayed(Duration(microseconds: 100), () async {
              locationsConsumer.invalidate();
            });
            */
            Fimber.d("selecting ${or(() => locations.map((it) => it.displayName))}");
            if (locationProvider.value.isEmpty ||
                or(() => $(locations).firstOrNullWhere((it) => it.id == locationProvider.value.id) == null)) { // selected not found
              locationProvider.value = or(() => $(locations).firstOrNullWhere((it) => it.id == lastLocationId)) ?? or(() => locations.first) ?? Location.EMPTY;
              Fimber.d("selected ${locationProvider.value.displayName} ${locationProvider.value.id}");
            } else {
              Fimber.d("No selected");
            }
            return locations;
          })
              .then((locations) {
            Fimber.d("invalidate locations ${or(() => locations.map((it) => it.displayName))}");
            locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
            _loading = false;
            //locationsProvider.invalidate();
            locationProvider.invalidate();
            final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
            appProvider.value = appProvider.value.rebuild((b) => b..error = false);
            appProvider.invalidate();
            //_refreshController.refreshCompleted();
            //setState(() {
            //  _loading = false;
            //});
          })
              .catchError((err) {
            Fimber.e("", ex: err);
            final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
            appProvider.value = appProvider.value.rebuild((b) => b..error = true);
            appProvider.invalidate();
            locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
            _loading = false;
            //locationsProvider.invalidate();
            //locationsProvider.invalidate();
            locationProvider.invalidate();
          });
        }
      } catch (err) {
        Fimber.e("", ex: err);
        final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
        appProvider.value = appProvider.value.rebuild((b) => b..error = true);
        appProvider.invalidate();

        locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = false);
        _loading = false;
        //locationsProvider.invalidate();
        //locationsProvider.invalidate();
        locationProvider.invalidate();
      }
      /*
      final appProvider = Provider.of<AppStateNotifier>(context, listen: false);
      Observable.range(0, 10).interval(Duration(seconds: 5)).listen((_) {
        appProvider.value = appProvider.value.rebuild((b) => b..error = true);
        appProvider.invalidate();
      });
      */
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
        Fimber.d("AppLifecycleState.inactive");
        //Embrace.startAppStartup();
      }
      break;
      case AppLifecycleState.resumed: {
        //onResume(context);
        Fimber.d("AppLifecycleState.resumed");

        Future.delayed(Duration.zero, () async {
          try {
            final FloConfig floConfig = FloConfig.of();
            final configRes = await floConfig.get();
            final config = configRes.body;
            final minVersion = config.androidApp.minVersioned;
            final platform = await PackageInfo.fromPlatform();
            final version = Version.parse(platform.version);
            Fimber.d("version: $version");
            Fimber.d("minVersion: $minVersion");
            if (version < minVersion) {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context2) {
                    return Theme(
                        data: floLightThemeData,
                        child: AlertDialog(
                          title: Text(S.of(context).new_version_available),
                          content: Text(S.of(context).a_new_app_update_is_available_please_update_your_app),
                          actions: <Widget>[
                            FlatButton(
                                child: Text(S.of(context).update_now),
                                onPressed: () async {
                                  await launch(
                                    // https://play.google.com/store/apps/details?id=com.flotechnologies
                                    "https://play.google.com/store/apps/details?id=${platform.packageName}",
                                    option: CustomTabsOption(
                                      toolbarColor: Theme.of(context).primaryColor,
                                      enableDefaultShare: true,
                                      enableUrlBarHiding: true,
                                      showPageTitle: true,
                                      //animation: CustomTabsAnimation.slideIn()
                                    ),
                                  );
                                }
                            )
                          ],
                        ));
                  }
              );
            }
          } catch (err) {
            Fimber.e('', ex: err);
          }
        });
      }
      break;
      case AppLifecycleState.paused: {
        Fimber.d("AppLifecycleState.paused");
        //Embrace.endAppStartup();
      }
      break;
      case AppLifecycleState.suspending: {
        Fimber.d("AppLifecycleState.suspending");
        //Embrace.endAppStartup();
      }
      break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  GlobalKey bottomNavigationKey = GlobalKey();
  List<Location> _locations = [];

  @override
  Widget build(BuildContext context) {
    _context = context;
    Fimber.d("");
    /*
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: floBlue.withOpacity(0.5),
        //systemNavigationBarColor: floBlue,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
    ));
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
      SystemChrome.restoreSystemUIOverlays();
    */
    /*
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.restoreSystemUIOverlays();
    */
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final locationConumser = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final prefsConsumer = Provider.of<PrefsNotifier>(context);

    Fimber.d("build, location.dirty ${locationConumser.value.dirty}");
    Fimber.d("build, userConsumer.dirty ${userConsumer.value.dirty}");
    if (
    (locationConumser.value?.dirty ?? false) ||
        (userConsumer.value?.dirty ?? false)
    ) {
      onInvalidate(context);
    }

    _locations = locationsConsumer.value.toList();
    if (locationConumser.value == Location.empty) {
      locationConumser.value = or(() => _locations.first) ?? Location.empty;
    }
    _locations = moveInFirst(_locations, locationConumser.value, where: (it) => it.id);
    Fimber.d("ordered location: ${_locations}");
    Fimber.d("moveInFirst: ${$(_locations).map((it) => it.nickname)}");
    final Widget locationsWidget = (_locations?.isNotEmpty ?? false) ? CustomScrollView(slivers: <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          if (i < _locations.length) {
            final location = _locations[i];
            if (i == 0) {
              //return Padding(padding: EdgeInsets.symmetric(vertical: 5), child: LocationCard(location: location.rebuild((b) => b..
              //address = "2298 SE MARKET St")));
              return Padding(padding: EdgeInsets.symmetric(vertical: 5), child: LocationCard(
                location: location,
                onTap: () {
                  final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                  locationProvider.value = location;
                  locationProvider.invalidate();
                  Navigator.of(context).pop();
                },
              ));
            } else {
              return Padding(padding: EdgeInsets.symmetric(vertical: 5), child: NormalLocationCard(
                location: location,
                onTap: () {
                  Navigator.of(context).pop();
                  final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                  locationProvider.value = location;
                  locationProvider.invalidate();
                },
              ));
            }
          }
          if (i == _locations.length) {
            return AddAHome();
          }
          return Container();
        }, childCount: _locations.length + 1),
      ),
      /*
                        SliverToBoxAdapter(child: DrawerMenu(
                          controller: _drawerScrollController,
                        )),
                        */
    ],) : EmptyLocations();

    final child = Scaffold(
      drawer: SafeArea(
        bottom: false,
        child: Padding(padding: EdgeInsets.only(top: 15), child: ClipRRect(
          borderRadius: BorderRadius.only(topRight: Radius.circular(32.0), bottomRight: Radius.circular(32.0)),
          child: Drawer(
              child: Opacity(opacity: 0.9,
                  child: Container(
                      color: Colors.white,
                      child:
                      Column(children: <Widget>[
                        Expanded(child: NestedScrollView(
                          controller: _drawerScrollController,
                          headerSliverBuilder: (context, innerBoxIsScrolled) =>
                          <Widget>[
                            DrawerBar(
                                minHeight: 120,
                                maxHeight: 120,
                                child: Container(
                                  color: Colors.white.withOpacity(0.9),
                                  child: Theme(data: floLightThemeData, child: Builder(builder: (context) =>
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: Column(children: <Widget>[
                                        SizedBox(height: 10),
                                        Row(
                                            children: [
                                              Image.asset('assets/ic_flo_logo_light.png',
                                                  height: 50),
                                              Spacer(),
                                              /* EditProfile Button
                                SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(floButtonRadius),
                                    boxShadow: [
                                      BoxShadow(color: Colors.grey.withOpacity(0.3), offset: Offset(0, 10), blurRadius: 15)
                                    ],
                                  ),
                                  child: FlatButton(
                                    padding: EdgeInsets.symmetric(horizontal: 30),
                                    color: Colors.grey[100],
                                  child: Text(S.of(context).edit_profile,
                                    style: TextStyle(
                                      color: Color(0xFF0A537F),
                                    )),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(floButtonRadius),
                                    side: BorderSide(color: Color(0xFFEBEFF5), style: BorderStyle.solid, width: 1),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/edit_profile');
                                  },
                                )),
                                */
                                            ]),
                                        SizedBox(height: 15),
                                        Builder(builder: (context) {
                                          final user = Provider.of<UserNotifier>(context).value;
                                          return Text("${user.firstName} ${user.lastName}", style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.grey[850]));
                                        }),
                                      ],
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                      ))
                                  )),
                                )),
                          ],
                          body: locationsWidget,
                        )),
                        DrawerMenu(
                          controller: _drawerScrollController,
                          elevation: (_locations?.isEmpty ?? true) ? 0 : 8.0,
                          child: (_locations?.isEmpty ?? true) ? AddAHome() : Container(),
                        ),
                      ],)
                  ))
          ),
        )),
      ),
      /*
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.home), onPressed: null, elevation: 0),
      */
      bottomNavigationBar: SimpleFancyBottomNavigation(
        initialSelection: _bottomSelectedIndex,
        key: bottomNavigationKey,
        circleGradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 1.0],
          colors: [
            Color(0xFF3EBBE2),
            Color(0xFF2790BE),
          ],
        ),
        circleColor: Color(0xFF2790BE),
        barBackgroundColor: Theme.of(context).primaryColorDark,
        //inactiveIconColor: Colors.white.withOpacity(0.3),
        activeIconColor: Colors.white,
        textColor: Colors.white,
        tabs: [
          TabData(
              icon: 'assets/ic_home.svg',
              iconData: Icons.home,
              title: "",
              onclick: () {
                final SimpleFancyBottomNavigationState fState =
                    bottomNavigationKey.currentState;
                fState.setPage(0);
              }
          ),
          TabData(
              icon: 'assets/ic_alert.svg',
              iconData: Icons.notifications, title: "",
              onclick: () {
                final SimpleFancyBottomNavigationState fState =
                    bottomNavigationKey.currentState;
                fState.setPage(1);
              }
          ),
          TabData(
              icon: 'assets/ic_message.svg',
              iconData: Icons.message, title: "",
              onclick: () {
                final SimpleFancyBottomNavigationState fState =
                    bottomNavigationKey.currentState;
                fState.setPage(2);
              }
          ),
          TabData(iconData: Icons.settings, title: "",
              onclick: () {
                final SimpleFancyBottomNavigationState fState =
                    bottomNavigationKey.currentState;
                fState.setPage(3);
              }
          )
          //TabData(iconData: Icons.home, title: S.of(context).dashboard),
          //TabData(iconData: Icons.notifications, title: S.of(context).alerts),
          //TabData(iconData: Icons.message, title: S.of(context).alerts),
          //TabData(iconData: Icons.settings, title: S.of(context).settings)
        ],
        onTabChangedListener: (i) {
          Fimber.d("$i");
          setState(() {
            _bottomSelectedIndex = i;
          });
          pageController.animateToPage(i,
              duration: Duration(milliseconds: 250), curve: Curves.ease);
        },
      ),
/*
      BottomNavigationBar(
          currentIndex: _bottomSelectedIndex,
          onTap: (i) {
            setState(() {
              _bottomSelectedIndex = i;
              pageController.animateToPage(i,
                  duration: Duration(milliseconds: 500), curve: Curves.ease);
            });
          },
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.home),
                 title: Text('Home')),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              title: Text('Alerts'),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                 title: Text('Settings'))
          ]),
*/
      /*
      BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            //Opacity(opacity: 0.0, child: IconButton(icon: Icon(Icons.home), onPressed: null,)),
            SizedBox(width: 20.0),
            IconButton(icon: Icon(Icons.notifications), onPressed: () {},),
            IconButton(icon: Icon(Icons.message), onPressed: () {},),
            IconButton(icon: Icon(Icons.settings), onPressed: () {},),
          ],
        ),
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
      ),
      */
      /*
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
      appBar:
      */
      body:
      Stack(children: <Widget>[
        FloGradientBackground(),
        Material(color: Colors.transparent, child:
        NestedScrollView(
          //controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) =>
          <Widget>[],
          body:
          /*
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              return list[i];
            },
            childCount: list.length,
          ),
        ),
        */
          PageView(
              controller: pageController,
              onPageChanged: (index) {
                Fimber.d("onPageChanged");
                final SimpleFancyBottomNavigationState fState = bottomNavigationKey.currentState;
                fState.setPageSliently(index);
                //setState(() {
                //  _bottomSelectedIndex = index;
                //});
              },
              children: <Widget>[
                DashboardPage(key: PageStorageKey('dashboard'), pageController: pageController),
                AlertsPage(key: PageStorageKey('alerts')),
                HelpPage(key: PageStorageKey('help')),
                //HomeSettingsPage(key: PageStorageKey('home_settings'), pageController: pageController),
                SettingsPage(key: PageStorageKey('settings'), pageController: pageController),
              ]),
        ),
        ),
        ZendeskWidget(),
      ]
      ),
      /*
      ListView.builder(itemBuilder: (context, i) {
          return YoureSecure();
        }, itemCount: 10),
      */
    );
    return flo is FloMocked ? Banner(
        message: "          DEMO",
        location: BannerLocation.topEnd,
        child: child) : child;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.restoreSystemUIOverlays();
  }


  Future<void> initZendesk(BuildContext context) async {
    //if (!mounted) return;
    try {
      /*
    <string name="flo_oauth_client_id" translatable="false">3baec26f-0e8b-4e1d-84b0-e178f05ea0a5</string>
    <string name="flo_zendesk_app_id" translatable="false">0fe78e8f35578950e1bb77cbb2bf4d6603b6bc7503886c00</string>
    <string name="flo_zendesk_client_id" translatable="false">mobile_sdk_client_b85943e42693853258f5</string>
    <string name="flo_zendesk_account_key" translatable="false">49xQ8TjmnmOyykHkx9Zs4iotnT8kyBXW</string>
      */
      final Zendesk zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
      await zendesk.initSupport(
        appId: '0fe78e8f35578950e1bb77cbb2bf4d6603b6bc7503886c00',
        clientId: 'mobile_sdk_client_b85943e42693853258f5',
        url: 'https://meetflo.zendesk.com',
      );
      await zendesk.init('49xQ8TjmnmOyykHkx9Zs4iotnT8kyBXW');
      Fimber.d('init finished');
    } catch (err) {
      Fimber.e('failed with error', ex: err);
    }
  }
}

class DrawerBar extends StatefulWidget {
  const DrawerBar({Key key,
    @required this.minHeight,
    @required this.maxHeight,
    this.elevation = 4.0,
    this.child,
  }) : super(key: key);

  final double elevation;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  State<DrawerBar> createState() => DrawerBarState();
}

class DrawerBarState extends State<DrawerBar> with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration _snapConfiguration;

  void _updateSnapConfiguration() {
    _snapConfiguration = FloatingHeaderSnapConfiguration(
      vsync: this,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateSnapConfiguration();
  }

  @override
  void didUpdateWidget(DrawerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    //if (widget.snap != oldWidget.snap || widget.floating != oldWidget.floating)
    _updateSnapConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
        pinned: true,
        delegate: DrawerHeader(
          maxHeight: widget.maxHeight,
          minHeight: widget.minHeight,
          child: widget.child,
          elevation: widget.elevation,
          snapConfiguration: _snapConfiguration,
        ));
  }
}

class DrawerHeader extends SliverPersistentHeaderDelegate {
  DrawerHeader({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
    this.elevation,
    this.snapConfiguration,
  });

  final double elevation;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  final FloatingHeaderSnapConfiguration snapConfiguration;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new SizedBox.expand(child: Material(color: Colors.transparent, elevation: shrinkOffset > (maxExtent - minExtent) ? elevation ?? 4.0 : 0.0, child: child));
  }

  @override
  bool shouldRebuild(DrawerHeader oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class SliverFooter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that fills the remaining space in the viewport.
  const SliverFooter({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverFooter createRenderObject(BuildContext context) => RenderSliverFooter();
}

class RenderSliverFooter extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox] which is sized to fit
  /// the remaining space in the viewport.
  RenderSliverFooter({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    final extent = constraints.remainingPaintExtent - min(constraints.overlap, 0.0);
    var childGrowthSize = .0; // added
    if (child != null) {
      // changed maxExtent from 'extent' to double.infinity
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: double.infinity), parentUsesSize: true);
      childGrowthSize = constraints.axis == Axis.vertical ? child.size.height : child.size.width; // added
    }
    final paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      // used to be this : scrollExtent: constraints.viewportMainAxisExtent,
      scrollExtent: max(extent, childGrowthSize),
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null) {
      setChildParentData(child, constraints, geometry);
    }
  }
}

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({Key key,
    @required
    this.controller,
    this.elevation = 8.0,
    this.child,
    //this.forceElevated = false,
  }) : super(key: key);
  final ScrollController controller;
  //final bool forceElevated;
  final double elevation;
  final Widget child;

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  double _elevation = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (widget.controller.position.extentAfter == 0) {
        if (_elevation != 0) {
          if (mounted) {
            setState(() {
              _elevation = 0;
            });
          }
        }
      } else {
        if (_elevation == 0) {
          if (mounted) {
            setState(() {
              _elevation = widget.elevation;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final locationConumser = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final prefs = Provider.of<PrefsNotifier>(context).value;

    return Material(color: Colors.white,
        elevation: _elevation,
        child: Column(children: <Widget>[
          widget.child ?? Container(),
          ListTile(
            dense: true,
            contentPadding:
            EdgeInsets.only(left: 50, right: 20, top: 0, bottom: 0),
            title: Text(S.of(context).legal,
                textScaleFactor: 1.3,
                style: TextStyle(
                  color: floMenuItemColor,
                )),
            onTap: () async {
              //Navigator.of(context).pushNamed("/terms");
              Navigator.of(context).pushNamed("/legal");
              /*
                              await launch(
                                'https://user.meetflo.com/mobile/support/android/legal',
                                option: CustomTabsOption(
                                  toolbarColor: Theme.of(context).primaryColor,
                                  enableDefaultShare: true,
                                  enableUrlBarHiding: true,
                                  showPageTitle: true,
                                  //animation: CustomTabsAnimation.slideIn()
                                ),
                              );
                              */
            },
          ),
          ListTile(
            dense: true,
            contentPadding:
            EdgeInsets.only(left: 50, right: 20, top: 0, bottom: 0),
            title: Text(flo is FloMocked ? S.of(context).exit_demo_mode : S.of(context).log_out,
                textScaleFactor: 1.3,
                style: TextStyle(
                  color: floMenuItemColor,
                )),
            onTap: () {
              showDialog(
                context: context,
                builder: (context2) {
                  return Theme(
                      data: floLightThemeData,
                      child: AlertDialog(
                        title: Text(flo is FloMocked ? S.of(context).exit_demo_mode : S.of(context).log_out),
                        content: Text(S.of(context).are_you_sure_you_want_to_logout_of_flo_q),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(S.of(context).ok),
                            onPressed: () async {
                              try {
                                SharedPreferencesUtils.clearOauth(prefs);
                                if (floConsumer.value is FloMocked) {
                                  floConsumer.value = Flo.of(context);
                                }
                                floConsumer.invalidate();
                                final floStreamServiceProvider = Provider.of<FloStreamServiceNotifier>(context, listen: false);
                                floStreamServiceProvider.value = FloFirestoreService();
                                final loginProvider = Provider.of<LoginStateNotifier>(context, listen: false);
                                final userProvider = Provider.of<UserNotifier>(context, listen: false);
                                final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
                                userProvider.value = User.empty;
                                userProvider.invalidate();
                                locationProvider.value = Location.empty;
                                locationsProvider.value = BuiltList<Location>();
                                locationsProvider.invalidate();
                                loginProvider.value = LoginState.empty;
                                loginProvider.invalidate();
                                final res = await flo.logoutByContext(context, authorization: oauthConsumer.value.authorization);
                                Fimber.d("$res");
                              } catch (err) {
                                Fimber.e("", ex: err);
                                /*
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Theme(
                                                    data: floLightThemeData,
                                                    child: AlertDialog(
                                                      content: Text(S.of(context).something_wront_please_retry),
                                                      actions: <Widget>[
                                                        FlatButton(
                                                          child: Text(S.of(context).ok),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                      ],
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                                    )
                                                  );
                                                },
                                              );
                                              */
                              }
                              oauthConsumer.value = OauthToken.empty;
                              Navigator.of(context2).pushNamedAndRemoveUntil('/splash', ModalRoute.withName('/'));
                            },
                          ),
                          FlatButton(
                            child: Text(S.of(context).cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                      )
                  );
                },
              );
            },
          ),
          SizedBox(height: 20,),
        ]
        ));
  }
}

const HAS_INTRODUCED_V2 = 'has_introduced_v2';

/*
Flushbar showPushFlushbar(BuildContext context, PushNotification pushNotification) {
  return Flushbar(
    titleText: Text(pushNotification?.notification?.title ?? "", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    messageText: Text(pushNotification?.notification?.body ?? "", style: TextStyle(color: Colors.black)),
    duration: Duration(seconds: 10),
    backgroundColor: Colors.white,
    flushbarStyle: FlushbarStyle.FLOATING,
    margin: EdgeInsets.all(8),
    padding: EdgeInsets.all(8),
    borderRadius: floCardRadiusDimen,
    flushbarPosition: FlushbarPosition.TOP,
    mainButton: FlatButton(
      onPressed: () {
        navigator.of()?.pushNamedAndRemoveUntil("/alert", ModalRoutes.not('/alert'), arguments: alert);
      },
      child: Text(
          S.of(context).open,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
      ),
    ),
  )..show(context);
}
*/

// Should integrate with DI
Future<PushNotificationToken> putPushNotificationToken(BuildContext context, {
  token,
  FutureOr<String> awsEndpointId,
  String deviceId,
  Flo flo,
  OauthToken oauth,
}) async {
  deviceId ??= await Devices.id(context);
  flo ??= Provider.of<FloNotifier>(context).value;
  oauth ??= Provider.of<OauthTokenNotifier>(context).value;
  awsEndpointId ??= Aws.endpointId;
  token ??= await FirebaseMessaging().getToken();

  final awsEndpointIdRes = await awsEndpointId;
  return (await flo.putPushNotificationToken(PushNotificationToken((b) => b
    ..token = token
    ..mobileDeviceId = deviceId
    ..awsEndpointId = awsEndpointIdRes
  ), authorization: oauth.authorization)).body;
}
