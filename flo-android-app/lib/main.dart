
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/activity.dart';
import 'package:flotechnologies/device_settings_screen.dart';
import 'package:flotechnologies/health_test_screen.dart';
import 'package:flotechnologies/needs_install_screen.dart';
import 'package:flotechnologies/model/push_notification.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_aws/flutter_aws.dart';
import 'package:flutter_embrace/flutter_embrace.dart';
import 'dart:async';
import 'dart:io';
//import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:instabug_flutter/Instabug.dart';
import 'package:instabug_flutter/InstabugLog.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'add_flo_device_screen.dart';
import 'add_location_screen.dart';
import 'add_puck_screen.dart';
import 'alert_screen.dart';
import 'alert_settings_screen.dart';
import 'alerts_screen.dart';
import 'alerts_settings_screen.dart';
import 'change_device_wifi_screen.dart';
import 'change_password_screen.dart';
import 'device_screen.dart';
import 'fixtures_screen.dart';
import 'flo_device_service.dart';
import 'flo_stream_service.dart';
import 'floprotect_screen.dart';
import 'generated/i18n.dart';
import 'goals_screen.dart';
import 'health_test_interrupt_screen.dart';
import 'health_test_result_screens.dart';
import 'home_screen.dart';
import 'home_settings_screen.dart';
import 'instabug_http.dart';
import 'needs_install_details_screen.dart';
import 'irrigation_settings_screen.dart';
import 'legal_screen.dart';
import 'location_profile_screen.dart';
import 'model/add_flo_device_state.dart';
import 'model/add_puck_state.dart';
import 'model/alarm.dart';
import 'model/alert.dart';
import 'model/alert1.dart';
import 'model/alert_settings.dart';
import 'model/alerts_state.dart';
import 'model/app_state.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/locales.dart';
import 'model/location.dart';
import 'model/login_state.dart';
import 'package:flutter_stetho/flutter_stetho.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
//import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:fimber/fimber.dart';
import 'model/oauth_token.dart';
import 'model/system_mode.dart';
import 'model/ticket.dart';
import 'model/user.dart';
import 'login_screen.dart';
import 'prv_settings_screen.dart';
import 'resolved_alert_screen.dart';
import 'splash_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'terms_screen.dart';
import 'themes.dart';
import 'troubleshoot_screen.dart';
import 'user_profile_screen.dart';
import 'utils.dart';
import 'widgets.dart';
import 'providers.dart';
//import 'package:get_it/get_it.dart';
//GetIt getIt = GetIt();
import 'package:timeago/timeago.dart' as timeago;
import 'package:zendesk/zendesk.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';


class EnMessages2 implements timeago.LookupMessages {
  String prefixAgo() => '';
  String prefixFromNow() => '';
  String suffixAgo() => '';
  String suffixFromNow() => '';
  String lessThanOneMinute(int seconds) => 'a min.';
  String aboutAMinute(int minutes) => 'a min.';
  String minutes(int minutes) => '$minutes min.';
  String aboutAnHour(int minutes) => 'a hour';
  String hours(int hours) => '${hours} hours';
  String aDay(int hours) => 'Yesterday';
  String days(int days) => '$days days';
  String aboutAMonth(int days) => 'about a month';
  String months(int months) => '$months months';
  String aboutAYear(int year) => 'about a year';
  String years(int years) => '$years years';
  String wordSeparator() => ' ';
}

class EnDurationMessages implements timeago.LookupMessages {
  String prefixAgo() => '';
  String prefixFromNow() => '';
  String suffixAgo() => '';
  String suffixFromNow() => '';
  String lessThanOneMinute(int seconds) => '${seconds} seconds';
  String aboutAMinute(int minutes) => '1 minute';
  String minutes(int minutes) {
    final int inSeconds = (minutes * 60);
    final int seconds = inSeconds.remainder(60).round();
    return minutes < 5 ? (seconds != 0 ? '${minutes}min ${seconds}sec' : "${inSeconds} sec")
                       : '${minutes} min';
  }
  String aboutAnHour(int minutes) => '1h';
  String hours(int hours) {
    final int minutes = (hours * 60).remainder(60).round();
    return minutes > 0 ? '${hours}h ${minutes}' : '${hours}h';
  }
  String aDay(int hours) => '1 day';
  String days(int days) => '$days days';
  String aboutAMonth(int days) => 'about a month';
  String months(int months) => '$months months';
  String aboutAYear(int year) => 'about a year';
  String years(int years) => '$years years';
  String wordSeparator() => ' ';
}

class EnShortMessages2 implements timeago.LookupMessages {
  String prefixAgo() => '';
  String prefixFromNow() => '';
  String suffixAgo() => '';
  String suffixFromNow() => '';
  String lessThanOneMinute(int seconds) => '1 min';
  String aboutAMinute(int minutes) => '1 min';
  String minutes(int minutes) => '$minutes min';
  String aboutAnHour(int minutes) => '1h';
  String hours(int hours) => '${hours}h';
  String aDay(int hours) => '1 day';
  String days(int days) => '$days days';
  String aboutAMonth(int days) => 'about a month';
  String months(int months) => '$months months';
  String aboutAYear(int year) => 'about a year';
  String years(int years) => '$years years';
  String wordSeparator() => ' ';
}

GlobalKey<_FloAppState> appKey = new GlobalKey();

void main() async {
  timeago.setLocaleMessages('en', EnMessages2());
  timeago.setLocaleMessages('en_short', EnShortMessages2());
  timeago.setLocaleMessages('en_duration', EnDurationMessages());
  //timeago.setLocaleMessages('en_US', timeago.EnShortMessages());
  //timeago.setLocaleMessages('en-US', timeago.EnShortMessages());
  //timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  //timeago.setLocaleMessages('ja', timeago.JaMessages());
  //timeago.setLocaleMessages('km', timeago.KmMessages());
  //timeago.setLocaleMessages('km_short', timeago.KmShortMessages());
  //timeago.setLocaleMessages('id', timeago.IdMessages());
  //timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  //timeago.setLocaleMessages('pt_BR_short', timeago.PtBrShortMessages());
  //timeago.setLocaleMessages('zh_CN', timeago.ZhCnMessages());
  //timeago.setLocaleMessages('zh', timeago.ZhMessages());
  //timeago.setLocaleMessages('it', timeago.ItMessages());
  //timeago.setLocaleMessages('fa', timeago.FaMessages());
  //timeago.setLocaleMessages('ru', timeago.RuMessages());
  //timeago.setLocaleMessages('tr', timeago.TrMessages());
  //timeago.setLocaleMessages('pl', timeago.PlMessages());
  //timeago.setLocaleMessages('th', timeago.ThMessages());
  //timeago.setLocaleMessages('th_short', timeago.ThShortMessages());
  //timeago.setLocaleMessages('nb_NO', timeago.NbNoMessages());
  //timeago.setLocaleMessages('nb_NO_short', timeago.NbNoShortMessages());
  //timeago.setLocaleMessages('nn_NO', timeago.NnNoMessages());
  //timeago.setLocaleMessages('nn_NO_short', timeago.NnNoShortMessages());
  //timeago.setLocaleMessages('ku', timeago.KuMessages());
  //timeago.setLocaleMessages('ku_short', timeago.KuShortMessages());
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('ar_short', timeago.ArShortMessages());
  //timeago.setLocaleMessages('ko', timeago.KoMessages());
  //timeago.setLocaleMessages('vi', timeago.ViMessages());
  //timeago.setLocaleMessages('vi_short', timeago.ViShortMessages());
  //timeago.setLocaleMessages('ta', timeago.TaMessages());

  Fimber.plantTree(DebugTree()); // TODO: Debuggable
  //Fimber.plantTree(InstabugTree());
  //SystemChrome.setEnabledSystemUIOverlays([]);
  //ErrorWidget.builder = (FlutterErrorDetails details) {
  //  Fimber.e("", ex: details.exception);
  //  return ErrorWidget(details.exception);
  //};

  //final activity = Activity();
  //activity.configure(onNewIntent: (intent) {
  //  Fimber.d("intent: $intent");
  //});

  runApp(FloApp(key: appKey));
}

class FloApp extends StatefulWidget {
  FloApp({Key key}) : super(key: key);

  @override
  _FloAppState createState() => _FloAppState();

/*
  @override
  void performRebuild(BuildContext context) {
    try {
      var built = build(context);
      debugWidgetBuilderValue(widget, built);
    } catch (e, stack) {
      built = ErrorWidget.builder(_debugReportException('building $this', e, stack));
    }
  }
  */

}

Future<void> backgroundMessageHandler(Map<String, dynamic> message) async {
  ///  {notification: {title: test2, body: test2}, data: {}}
  Fimber.d("firebaseMessaging: onBackgroundMessage: $message");
  Fimber.d("firebaseMessaging: data: ${Maps.get(message, 'data')}");
  Fimber.d("firebaseMessaging: notification: ${Maps.get(message, 'notification')}");

  /*
  try {
    final pushNotification = PushNotification.fromMap2(message);
    Fimber.d("pushNotification: $pushNotification");
    if (pushNotification?.data?.url != null) {
      navigator.of()?.pushNamed("/${Uri.tryParse(pushNotification.data.url).host}", arguments: pushNotification.data.data);
    } else {
      //pushNotification.notification.clickAction
      Fimber.d("");
    }
  } catch (err) {
    Fimber.e("", ex: err);
  }
  await Aws.onMessage(message);
  */
}


class _FloAppState extends State<FloApp> with WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
      }
      break;
      case AppLifecycleState.resumed: {
        Future.delayed(Duration.zero, () async {
          //final action = await platform.invokeMethod("action");
          //final data = await platform.invokeMethod("data");
          //final type = await platform.invokeMethod("type");
          //Fimber.d("action: ${action}");
          //Fimber.d("data: ${data}");
          //switch (action) {
          //  case "com.flotechnologies.intent.action.INCIDENT": {
          //    //navigator.of()?.pushNamed("/alert", arguments: pushNotification.data.data);
          //  }
          //  break;
          //}
        });
      }
      break;
      case AppLifecycleState.paused: {
      }
      break;
      case AppLifecycleState.suspending: {
      }
      break;
    }
  }

  @override
  void initState() {
    super.initState();

    Stetho.initialize();

    HttpOverrides.global = InstabugHttpOverrides(current: HttpOverrides.current);
    //Embrace.initialize();

    //Provider.debugCheckInvalidValueType = null;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    });

    /*
    final activity = Activity();
    activity.configure(onNewIntent: (intent) {
      Fimber.d("onNewIntent: $intent");
      if (Maps.get(intent, 'action') == "com.flotechnologies.intent.action.INCIDENT") {
        Fimber.d("onNewIntent: Alert:going to /alert : ${Maps.get(intent, 'action')} : ${Maps.get(intent, 'data')}");

        final alert1 = let(Maps.get(intent, 'data'), (it) => Alert1.from(it));
        Future.delayed(Duration.zero, () async {
          final alert = await alert1?.toAlert(navigator.of()?.context);
          Fimber.d("onNewIntent: Alert: $alert");
          navigator.of()?.pushNamed("/alert", arguments: alert);
        });
      }
    });
    */
    getUriLinksStream().listen((Uri uri) {
      Fimber.d("FloAppState: applink: $uri");
    }, onError: (err) {
      Fimber.e("", ex: err);
    });

    /// ref. https://github.com/Instabug/Instabug-Flutter/issues/78
    if (Platform.isIOS) {
      Instabug.start('05d67f38bd1ad13fed750803dfb9e722',
          [InvocationEvent.shake, InvocationEvent.screenshot]);
    }
  }

  BuildContext _context;

  BuildContext get activeContext => _context ?? navigator.of()?.context ?? context;

  @override
  Widget build(BuildContext context) {
    _context = context;
    //final floLogo100 = Image.asset('android/app/src/main/res/drawable-xhdpi/ic_flo_logo_cutout.png', width: 100,);
    //precacheImage(Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave0.png').image, context);
    //precacheImage(Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave1.png').image, context);
    //precacheImage(Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave2.png').image, context);
    //precacheImage(floLogo100.image, context);
    /**
     * TODO: Adapt React Reducer or BLoc with Provider and optimize consumers
     * There is a lot of messy providers and consumers, they are tech-debt for finishing all of tickets asap
     */
    return MultiProvider(providers: [
      // TODO: validation on model
      ChangeNotifierProvider.value(value: LoginStateNotifier(LoginState.empty)),
      ChangeNotifierProvider.value(value: OauthTokenNotifier(OauthToken((b) => b
        ..accessToken = ""
        ..refreshToken = ""
        ..expiresIn = -1
        ..userId = ""
        ..expiresAt = ""
        ..issuedAt = ""
        ..tokenType = ""
      ))),
      ChangeNotifierProvider.value(value: LocalesNotifier(Locales((b) => b
        ..locales = ListBuilder()
      ))),
      ChangeNotifierProvider.value(value: LocationNotifier(Location.empty)),
      ChangeNotifierProvider.value(value: CurrentLocationNotifier(Location.empty)),
      ChangeNotifierProvider.value(value: DeviceNotifier(Device.empty)),
      ChangeNotifierProvider.value(value: LocationsNotifier(BuiltList<Location>())),
      ChangeNotifierProvider.value(value: UserNotifier(User.empty)),
      //ChangeNotifierProvider.value(value: FloNotifier(Flo.of(context))),
      ChangeNotifierProvider.value(value: FloNotifier(FloMocked())),
      ChangeNotifierProvider.value(value: FloStreamServiceNotifier(FloStreamServiceMocked())),
      ChangeNotifierProvider.value(value: FloDeviceServiceNotifier(FloDeviceServiceMocked())),
      ChangeNotifierProvider.value(value: PrefsNotifier(null)),
      ChangeNotifierProvider.value(value: AddFloDeviceNotifier(AddFloDeviceState((b) => b
        ..model = ""
        ..nickname = ""
        ..floDeviceWifiList = ListBuilder()
        ..wifiList = ListBuilder()
        ..ticket = Ticket.empty.toBuilder()
      ))),
      ChangeNotifierProvider.value(value: AddPuckNotifier(AddPuckState((b) => b
        ..model = ""
        ..nickname = ""
        ..floDeviceWifiList = ListBuilder()
        ..ticket = Ticket.empty.toBuilder()
      ))),
      ChangeNotifierProvider.value(value: DevicesNotifier(BuiltList<Device>())),
      ChangeNotifierProvider.value(value: AlarmsNotifier(BuiltList<Alarm>())),
      ChangeNotifierProvider.value(value: AlertsSettingsStateNotifier(AlertSettings((b) => b..systemMode = SystemMode.HOME))),
      ChangeNotifierProvider.value(value: AppStateNotifier(AppState())),
      ChangeNotifierProvider.value(value: SelectedDevicesNotifier(BuiltList<Device>())),
      ChangeNotifierProvider.value(value: AlertNotifier(Alert())),
      ChangeNotifierProvider.value(value: AlertsStateNotifier(AlertsState())),
      ChangeNotifierProvider.value(value: ZendeskNotifier(Zendesk())),
      //StreamProvider<ConnectionStatus>.value(
      //  stream: streamConnectivityService().connectivityController.stream,
      //),
      /*
      StreamProvider.value(stream: StateStream<LoginState>().subject, initialData: LoginState((b) => b
        ..autovalidate = false
        ..email = ""
        ..password = ""
        ..isEmailValid = false
        ..isPasswordValid = false
      )),
      StreamProvider<LoginState>(builder: (context) {
        StreamController()
        return LoginState();
      }, initialData: LoginState((b) => b
        ..autovalidate = false
        ..email = ""
        ..password = ""
        ..isEmailValid = false
        ..isPasswordValid = false
      ))
      */
    ], child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flo by moen',
      theme: floThemeData,
      darkTheme: ThemeData(
        fontFamily: 'Questrial',
        brightness: Brightness.dark,
        backgroundColor: Colors.black,
        primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        primaryColorDark: Colors.black,
      ),
      //theme: flolightthemedata,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: <Locale>[Locale("en", "")],
      //supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback:
          S.delegate.resolution(fallback: Locale("en", ""), withCountry: false),
      navigatorKey: navigator.key,
      navigatorObservers: [
        routeObserver,
        EmbraceRouteObserver(),
      ],
      //home: EmptyScreen(child: SimpleTimeSeriesChart.withSampleData()),
      //home: EmptyScreen(child: IrrigationScheduleChart.withSampleData()),
      //home: InstallingDeviceScreen(),
      //home: AlertsSettingsScreen(),
      home: SplashScreen(),
      //home: EmptyScreen(child: Builder(builder: (context) => KeepWaterRuningDialog())),
      //home: EmptyScreen(child: FloDetectCard()),
      //home: EmptyScreen(child: FloDetectEventsCard()),
      //home: EmptyScreen(child: FloDetectDonut()),
      //home: FloProtectScreen(),
      //home: AlertScreen(),
      //home: TroubleshootScreen(),
      //home: LegalScreen(),
      //home: AlertsPlaceholder(),
      //home: SimplePlaceholder(),
      //home: AlertsSettingsPlaceholder(),
      //home: EmptyScreen(child: WaterUsageBarChart.withSampleData()),
      //home: EmptyScreen(child: WaterUsageCard()),
      //home: EmptyScreen(child: WifiRssiExamples()),
      //home: ChangePasswordScreen(),
      //home: InstallingDeviceDetailsScreen(),
      //home: HealthTestInterruptScreen(),
      //home: HealthTestNoLeakResultScreen(),
      //home: HealthTestResultScreen(),
      //home: HealthTestScreen(),
      //home: LoginScreen(),
      //home: HomePage(),
      //home: Scaffold(body: Theme(data: floLightThemeData, child: SignUpPage2())),
      //home: SignUpScreen(),
      //home: TermsScreen(),
      //home: VerifyEmailScreen(),
      //home: ForgotPasswordScreen(),
      //home: AddLocationScreen(),
      //home: AddWhichOneFloDeviceScreen(),
      routes: <String, WidgetBuilder>{
        '/splash': (BuildContext context) => SplashScreen(),
        '/login': (BuildContext context) => LoginScreen(),
        '/signup': (BuildContext context) => SignUpScreen(),
        '/terms': (BuildContext context) => TermsScreen(),
        '/home': (BuildContext context) => HomePage(index: 0),
        //'/alerts': (BuildContext context) => HomePage(index: 1),
        '/alerts': (BuildContext context) => AlertsScreen(),
        '/settings': (BuildContext context) => HomePage(index: 2),
        '/control_panel': (BuildContext context) => HomePage(index: 0),
        '/verify_email': (BuildContext context) => VerifyEmailScreen(),
        '/forgot_password': (BuildContext context) => ForgotPasswordScreen(),
        '/edit_profile': (BuildContext context) => UserProfileScreen(),
        '/location_details': (BuildContext context) => EmptyScreen(title: S.of(context).location_details),
        '/add_a_home': (BuildContext context) => AddLocationScreen(),
        '/add_location': (BuildContext context) => AddLocationScreen(),
        '/add_a_flo_device': (BuildContext context) => AddWhichOneFloDeviceScreen(),
        '/add_the_device': (BuildContext context) => AddFloDeviceScreen(),
        '/flo_device': (BuildContext context) => DeviceScreen(),
        '/goto_wifi_settings': (BuildContext context) => GoToWifiSettingsScreen(),
        '/home_settings': (BuildContext context) => HomeSettingsScreen(),
        '/404': (BuildContext context) => EmptyScreen(title: "Not implemented"),
        '/device_settings': (BuildContext context) => DeviceSettingsScreen(),
        '/goals': (BuildContext context) => GoalsScreen(),
        '/location_profile': (BuildContext context) => LocationProfileScreen(),
        '/change_password': (BuildContext context) => ChangePasswordScreen(),
        '/needs_install': (BuildContext context) => NeedsInstallScreen(),
        '/needs_install_details': (BuildContext context) => NeedsInstallDetailsScreen(),
        '/health_test': (BuildContext context) => HealthTestScreen(),
        '/health_test_result': (BuildContext context) => HealthTestResultScreen(),
        '/health_test_no_leak_result': (BuildContext context) => HealthTestNoLeakResultScreen(),
        '/health_test_interrupt': (context) => HealthTestInterruptScreen(),
        '/change_device_wifi': (context) => ChangeDeviceWifiScreen(),
        '/alerts_settings': (context) => AlertsSettingsScreen(),
        '/alert_settings': (context) => AlertSettingsScreen(),
        '/legal': (context) => LegalScreen(),
        '/alert': (context) => AlertScreen(),
        '/resolved_alert': (context) => ResolvedAlertScreen(),
        '/troubleshoot': (context) => TroubleshootScreen(),
        '/floprotect': (context) => FloProtectScreen(),
        '/fixtures': (context) => FixturesScreen(),
        '/irrigation_settings': (context) => IrrigationSettingsScreen(),
        '/prv_settings': (context) => PrvSettingsScreen(),
        '/add_puck': (context) => AddPuckScreen(),
      },
      /*
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final Map<String, String> args = settings.arguments;
          final index = int.tryParse(or(() => args['index']) ?? "0") ?? 0;
          Fimber.d("HomeP index: ${index}");
          return MaterialPageRoute(
            builder: (context) => HomePage(index: index)
          );
        }
      },
      */
    ),
    );
  }
}

class EmptyScreen extends StatefulWidget {
  EmptyScreen({Key key,
   this.title = "",
   this.child,
   }) : super(key: key);

  final String title;
  final Widget child;

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  @override
  Widget build(BuildContext context) {
    return Theme(
        data: floLightThemeData,
        child: Builder(builder: (context) => Scaffold(
            appBar: AppBar(
              brightness: Brightness.light,
              title: Text(widget.title, style: TextStyle(color: floPrimaryColor)),
              automaticallyImplyLeading: true,
              leading: SimpleBackButton(),
              iconTheme: IconThemeData(
                color: floBlue2,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: true
            ),
            //body: widget.child != null ? SizedBox(height: double.infinity, child: SingleChildScrollView(child: SizedBox(height: double.infinity, child: widget.child))) : Container(child: Center(child: Text("Not Implemented  🤪", textScaleFactor: 1.8,)))
            body: widget.child ?? Container(child: Center(child: Text("Not Implemented  🤪", textScaleFactor: 1.8,)))
        )));
  }
}

/*
class _WebScreenState extends State<TermsScreen> {
  WebViewController _webViewController;

  _loadHtmlFromAssets() async {
    String fileText = await rootBundle.loadString('assets/help.html');
    _webViewController.loadUrl( Uri.dataFromString(
        fileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final loginConsumer = Provider.of<LoginStateNotifier>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      body: WebView(
        initialUrl: '',
        onWebViewCreated: (webViewController) {
          _webViewController = webViewController;
        },
      ),
    );
  }
}
*/

class EmptyPage extends StatefulWidget {
  EmptyPage({Key key, this.title}) : super(key: key);

  String title = "";

  @override
  State<EmptyPage> createState() => _EmptyPageState();
}

class _EmptyPageState extends State<EmptyPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
            //key: widget.key,
          slivers: <Widget>[
            SliverToBoxAdapter(child:
            Column(children: <Widget>[
              SizedBox(height: 300,),
              Container(child: Center(child: Text("Not Implemented  🤪", textScaleFactor: 1.8,))),
            ],),
            )
          ]);
  }
}

//class NavigationService {
//  final GlobalKey<NavigatorState> navigatorKey =
//      new GlobalKey<NavigatorState>();
//
//  Future<dynamic> navigateTo(String routeName) {
//    return navigatorKey.currentState.pushNamed(routeName);
//  }
//}

//void setupLocator() {
//  locator.registerLazySingleton(() => NavigationService());
//}


///InstabugLog.d("Message to log");
///InstabugLog.v("Message to log");
///InstabugLog.i("Message to log");
///InstabugLog.e("Message to log");
///InstabugLog.w("Message to log");
///InstabugLog.wtf("Message to log");
class InstabugTree extends LogTree {
  static const V = "V";
  static const D = "D";
  static const I = "I";
  static const W = "W";
  static const E = "E";
  static const List<String> DEFAULT = [V, D, I, W, E];
  List<String> logLevels;

  InstabugTree({this.logLevels = DEFAULT});

  @override
  log(String level, String msg,
      {String tag, dynamic ex, StackTrace stacktrace}) {
    var logTag = tag ?? LogTree.getTag();
    var _message = "";
    if (ex != null) {
      var tmpStacktrace =
          stacktrace?.toString()?.split('\n') ?? LogTree.getStacktrace();
      var stackTraceMessage =
      tmpStacktrace.map((stackLine) => "\t$stackLine").join("\n");
      _message = "$level\t$logTag:\t $msg \n${ex.toString()}\n$stackTraceMessage";
    } else {
      _message = "$level\t$logTag:\t $msg";
    }
    switch (level) {
      case V: {
        InstabugLog.logVerbose(_message);
        break;
      }
      case D: {
        InstabugLog.logDebug(_message);
        break;
      }
      case I: {
        InstabugLog.logInfo(_message);
        break;
      }
      case W: {
        InstabugLog.logWarn(_message);
        break;
      }
      case E: {
        InstabugLog.logError(_message);
        break;
      }
    }
  }

  @override
  List<String> getLevels() {
    return logLevels;
  }
}

class EmbraceLogTree extends LogTree {
  static const V = "V";
  static const D = "D";
  static const I = "I";
  static const W = "W";
  static const E = "E";
  static const List<String> DEFAULT = [V, D, I, W, E];
  List<String> logLevels;

  EmbraceLogTree({this.logLevels = DEFAULT});

  @override
  log(String level, String msg,
      {String tag, dynamic ex, StackTrace stacktrace}) {
    var logTag = tag ?? LogTree.getTag();
    var _message = "";
    if (ex != null) {
      var tmpStacktrace =
          stacktrace?.toString()?.split('\n') ?? LogTree.getStacktrace();
      var stackTraceMessage =
      tmpStacktrace.map((stackLine) => "\t$stackLine").join("\n");
      _message = "$level\t$logTag:\t $msg \n${ex.toString()}\n$stackTraceMessage";
    } else {
      _message = "$level\t$logTag:\t $msg";
    }
    switch (level) {
      case V: {
        Embrace.logInfo(_message);
        break;
      }
      case D: {
        Embrace.logInfo(_message);
        break;
      }
      case I: {
        Embrace.logInfo(_message);
        break;
      }
      case W: {
        Embrace.logWarning(_message);
        break;
      }
      case E: {
        Embrace.logError(_message);
        break;
      }
    }
  }

  @override
  List<String> getLevels() {
    return logLevels;
  }
}

class SimpleIoHttpClient implements HttpClient {

  final HttpClient client;

  SimpleIoHttpClient({HttpClient client}) : client = client ?? HttpClient();

  @override
  set autoUncompress(bool au) => client.autoUncompress = au;

  @override
  set connectionTimeout(Duration ct) => client.connectionTimeout = ct;

  @override
  set idleTimeout(Duration it) => client.idleTimeout = it;

  @override
  set maxConnectionsPerHost(int mcph) => client.maxConnectionsPerHost = mcph;

  @override
  set userAgent (String ua) => client.userAgent = ua;

  @override
  bool get autoUncompress => client.autoUncompress;

  @override
  Duration get connectionTimeout => client.connectionTimeout;

  @override
  Duration get idleTimeout => client.idleTimeout;

  @override
  int get maxConnectionsPerHost => client.maxConnectionsPerHost;

  @override
  String get userAgent => client.userAgent;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    client.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    client.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String realm) f) {
    client.authenticate = f;
  }

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String realm)
      f) {
    client.authenticateProxy = f;
  }

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port) callback) {
    client.badCertificateCallback = callback;
  }

  @override
  void close({bool force = false}) {
    client.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return client.delete(host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return client.deleteUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  set findProxy(String Function(Uri url) f) {
    client.findProxy = f;
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return client.get(host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return client.getUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return client.head(host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return client.headUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    return client.open(method, host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return client.openUrl(method, url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return client.patch(host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return client.patchUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return client.post(host, port, path).then((HttpClientRequest request) async {
      print(request.headers);
      return request;
    });
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return client.postUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return client.put(host, port, path).then((HttpClientRequest request) async {
      return request;
    });
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return client.putUrl(url).then((HttpClientRequest request) async {
      return request;
    });
  }
}

Alert1 getAlert1ByMessage(Map<String, dynamic> message) {
  final pushNotification = PushNotification.fromMap2(message);
  final data = Maps.get(message, 'data');
  final floAlarmNotificaation = Maps.get(data, 'FloAlarmNotification');
  Fimber.d("firebaseMessaging: onResume: type: ${floAlarmNotificaation?.runtimeType}");
  return let(floAlarmNotificaation, (it) => Alert1.from(it));
}
