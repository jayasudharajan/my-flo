import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'add_flo_device_screen.dart';
import 'flo_device_service.dart';
import 'flo_stream_service.dart';
import 'model/app_info.dart';
import 'model/certificates.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'model/id.dart';
import 'model/wifi_station.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';

class ChangeDeviceWifiScreen extends StatefulWidget {
  ChangeDeviceWifiScreen({Key key}) : super(key: key);

  State<ChangeDeviceWifiScreen> createState() => _ChangeDeviceWifiScreenState();
}

class _ChangeDeviceWifiScreenState extends State<ChangeDeviceWifiScreen> with AfterLayoutMixin<ChangeDeviceWifiScreen> {

  @override
  void afterFirstLayout(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceProvider = Provider.of<DeviceNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final authorization = Provider.of<OauthTokenNotifier>(context).value.authorization;
    bool nextEnabled = true;
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    Future(() async {
      try {
        final certificate = await flo.getCertificateByDevice(deviceProvider.value.id, authorization: authorization);
        deviceProvider.value = deviceProvider.value.mergeCertificate(certificate);
        Fimber.d("cert1: ${deviceProvider.value.certificate}");
        addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b..certificate = deviceProvider.value?.certificate?.toBuilder() ?? b.certificate);
        Fimber.d("cert: ${addFloDeviceConsumer.value.certificate}");
        addFloDeviceConsumer.invalidate();
      } catch (e) {
        if (addFloDeviceConsumer.value.certificate == null) {
          showDialog(
              context: context,
              builder: (context2) =>
                  AlertDialog(
                    title: Text("Flo Error 008"),
                    content: Text(S.of(context).something_went_wrong_please_retry),
                    actions: <Widget>[
                      FlatButton(
                        child: Text(S.of(context).ok),
                        onPressed: () async {
                          Navigator.of(context2).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _page = 0;
    _pageController = PageController(initialPage: _page);
    _pages = <Widget>[
      PushToConnectPage(pageController: _pageController,),
      LoadingWifiListPage(pageController: _pageController,),
      DeviceWifiListPage(pageController: _pageController,),
      OnlinePage2(pageController: _pageController,),
    ];
    _nextText = "Next";
  }

  PageController _pageController;
  int _page;
  List<Widget> _pages;
  String _nextText;

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final device = Provider.of<DeviceNotifier>(context).value;
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<UserNotifier>(context);
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    bool nextEnabled = true;

    if (_page == 0) {
      //nextEnabled = deviceConsumer.value.prvInstallation != null;
    } else if (_page == 1) {
      //nextEnabled = deviceConsumer.value.irrigationType != null;
      nextEnabled = false;
    } else if (_page == 2) {
      nextEnabled = false;
    }

    final child = 
    WillPopScope(
      onWillPop: () async {
        if (hasPreviousPage(_pageController)) {
          _pageController.previousPage(
            duration: Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
          );
          return false;
        }
        WiFiForIoTPlugin.forceWifiUsage(false);
        return true;
      },
      child: Theme(
      data: floLightThemeData,
      child:
      Builder(builder: (context) =>
      Scaffold(
        //backgroundColor: Colors.transparent,
        //appBar: AppBar(
        //  brightness: Brightness.light,
        //  //leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios), color: floBlue2,),
        //  automaticallyImplyLeading: false,
        //  backgroundColor: Colors.transparent,
        //  elevation: 0.0,
        //  //title: Text(S.of(context).goals),
        //  //centerTitle: true,
        //),
        resizeToAvoidBottomPadding: false,
        body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                brightness: Brightness.light,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios), color: floBlue2,),
                elevation: 0.0,
              ),
            ],
          body: PageView.builder(
          controller: _pageController,
          //physics: AlwaysScrollableScrollPhysics(),
          //itemBuilder: (context, i) => ConstrainedBox(constraints: const BoxConstraints.expand(), child: _pages[i % _pages.length]),
          itemBuilder: (context, i) => _pages[i % _pages.length],
          itemCount: _pages.length,
          onPageChanged: (i) {
            if (!hasNextPage(_pageController, _pages.length)) {
              _nextText = S.of(context).done;
            } else {
              _nextText = S.of(context).next;
            }
            setState(() {
              _page = i;
            });
          },
        )),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40), child:
               _page == 3 && addFloDeviceConsumer.value.error == null ? SizedBox(height: 100) :
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DotsIndicator(
                controller: _pageController,
                itemCount: _pages.length,
                color: floDotColor,
                selectedColor: floBlue2,
                maxZoom: 1.7,
                onPageSelected: (page) {
                  setState(() {
                    _page = page;
                  });
                  _pageController.animateToPage(
                    page,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                  );
                },
              ),
              SizedBox(height: 20),
              Enabled(enabled: nextEnabled, child: SizedBox(width: double.infinity, child: FlatButton(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                color: floBlue2,
                child: Text(addFloDeviceConsumer.value.error == true ? S.of(context).retry : _nextText, style: TextStyle(
                  color: Colors.white,
                  ),
                  textScaleFactor: 1.6,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                onPressed: () { // FIXME: add progress bar
                  if (addFloDeviceConsumer.value.error == true) {
                    addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b..error = null);
                    _pageController.animateToPage(0,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                    );
                  } else {
                  if (!hasNextPage(_pageController, _pages.length)) {
                    Navigator.of(context).pop();
                  } else {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                    );
                  }
                  }
                },
              ))),
              SizedBox(height: 20),
            ],)),
          ),
          //resizeToAvoidBottomPadding: true,
        ))));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class OnlinePage2 extends StatefulWidget {
  final PageController pageController;

  OnlinePage2({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<OnlinePage2> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage2> with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController _fadeInController;
  AnimationController _fadeOutController;
  AnimationController _slideRightController;
  AnimationController _warningScaleUpController;
  AnimationController _successScaleUpController;
  Animation<double> _fadeInAnimation;
  Animation<double> _fadeOutAnimation;
  Animation<Offset> _slideRightAnimation;
  //Animation<Offset> _scaleUpAnimation;
  Animation<double> _warningScaleUpAnimation;
  Animation<double> _successScaleUpAnimation;

/*
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
      }
      break;
      case AppLifecycleState.resumed: {
        onResume();
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
*/

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _fadeOutController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _slideRightController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _warningScaleUpController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _successScaleUpController = AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _fadeInAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeInController, curve: Curves.fastOutSlowIn));
    _fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _fadeOutController, curve: Curves.fastOutSlowIn));
    _slideRightAnimation = Tween(begin: const Offset(-0.1, 0.0),
        end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _slideRightController, curve: Curves.fastOutSlowIn));
    _warningScaleUpAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _warningScaleUpController, curve: Curves.fastOutSlowIn));
    _successScaleUpAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successScaleUpController, curve: Curves.fastOutSlowIn));

    _started = false;

    _failed = false;
    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
      ..error = null
    );

    widget.pageController.addListener(() {
      // TODO
      final page = widget.pageController.page;
      print(widget.pageController.page.round());
      if (widget.pageController.page.round() != _page) {
        _page = widget.pageController.page.round();
        if (_page == 3) {
          onResume(context);
        }
      }
    });
    _pairing = false;
  }

  int _page;
  void onResume(context) {
    Fimber.d("onResume");
    _fadeInController.reverse();
    _fadeOutController.reverse();
    _slideRightController.reverse();
    _successScaleUpController.reverse();
    _warningScaleUpController.reverse();
    setState(() {
      _failed = false;
      _pairing = true;
    });
    Future.delayed(Duration.zero, () async {
      final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
      addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
        ..error = null
      );
    });
    Future.delayed(Duration.zero, () async {
      final floStreamServiceConsumer = Provider.of<FloStreamServiceNotifier>(context);
      //final FloStreamService floStreamService = FloStreamServiceMocked();
      final FloStreamService floStreamService = floStreamServiceConsumer.value;
      final floDeviceServiceProvider = Provider.of<FloDeviceServiceNotifier>(context, listen: false);
      final FloDeviceService floDeviceService = floDeviceServiceProvider.value;
      final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
      try {
        final floConsumer = Provider.of<FloNotifier>(context);
        final flo = floConsumer.value;
        final isDemo = flo is FloMocked;
        final floDeviceServiceProvider = Provider.of<FloDeviceServiceNotifier>(context, listen: false);
        floDeviceServiceProvider.value = (!isDemo ? FloDeviceServiceOk() : FloDeviceServiceMocked());
        floDeviceServiceProvider.invalidate();
        await retry(() async {
        if (!isDemo) {
          await ensureFloDeviceService2(floDeviceServiceProvider.value,
              ssid: addFloDeviceConsumer.value.certificate.apName,
              loginToken: addFloDeviceConsumer.value.certificate.loginToken,
              websocketCert: addFloDeviceConsumer.value.certificate.websocketCert
          );
        }
        await floDeviceService.setCertificates(Certificates((b) => b
          ..encodedCaCert = addFloDeviceConsumer.value.certificate.serverCert
          ..encodedClientCert = addFloDeviceConsumer.value.certificate.clientCert
          ..encodedClientKey = addFloDeviceConsumer.value.certificate.clientKey
        ));
        await floDeviceService.setWifiStationConfig(WifiStation((b) => b
          ..wifiStaSsid = addFloDeviceConsumer.value.wifi.ssid
          ..wifiStaPassword = addFloDeviceConsumer.value.password
          ..wifiStaEncryption = addFloDeviceConsumer.value.wifi.encryption
        ));
        await WiFiForIoTPlugin.disconnect();
        WiFiForIoTPlugin.forceWifiUsage(false);
        await WiFiForIoTPlugin.setEnabled(true);
        Fimber.d("Previous ssid: ${addFloDeviceConsumer.value.ssid}");
        if (addFloDeviceConsumer.value.ssid != null) {
          await retry(() =>
              WiFiForIoTPlugin.connect(addFloDeviceConsumer.value.ssid),
              onRetry: (e) {
                WiFiForIoTPlugin.forceWifiUsage(false);
                Fimber.d("retry: $e", ex: e);
              }
          );
        } else {
          Fimber.d("No previous ssid: ${addFloDeviceConsumer.value.wifi.ssid} : ${addFloDeviceConsumer.value.password}");
          await retry(() =>
              WiFiForIoTPlugin.connect(
                  addFloDeviceConsumer.value.wifi.ssid,
                  password: addFloDeviceConsumer.value.password),
              onRetry: (e) {
                WiFiForIoTPlugin.forceWifiUsage(false);
                Fimber.d("retry: $e", ex: e);
              }
          );
        }
        return true;
        }, maxAttempts: 3).timeout(Duration(seconds: 60));
        await Future.delayed(Duration(seconds: 3));

        final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
        final locationConsumer = Provider.of<CurrentLocationNotifier>(context, listen: false);
        Fimber.d("${locationConsumer.value}");
        Fimber.d("${Id((b) => b..id = locationConsumer.value.id).toBuilder()}");
        final platform = await PackageInfo.fromPlatform();
        await flo.presence(AppInfo((b) => b
          ..appName = "flo-android-app2"
          ..appVersion = platform.version
        ), authorization: oauthConsumer.value.authorization);
        final firestoreToken = await flo.getFirestoreToken(authorization: oauthConsumer.value.authorization);
        await floStreamService.login(firestoreToken.body.token);
        /// It should return 404 here becuase the device doesn't exist yet,
        /// but it will create an empty device document on firestore
        /// that's what we need

        await floStreamService.awaitOnline(addFloDeviceConsumer.value.certificate.deviceId).timeout(Duration(seconds: 40));

        _fadeInController.forward();
        _fadeOutController.forward();
        _slideRightController.forward();
        _warningScaleUpController.reverse();
        _successScaleUpController.forward();
        final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
        addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
          ..error = false
        );
        addFloDeviceProvider.invalidate();
        setState(() {
          _begin = 1.0;
          _pairing = false;
        });
      } catch (e) {
        Fimber.e("$e", ex: e);
        _fadeInController.reverse();
        _fadeOutController.reverse();
        _slideRightController.reverse();
        _successScaleUpController.reverse();
        _warningScaleUpController.forward();
        final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
        addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
          ..error = true
        );
        addFloDeviceProvider.invalidate();
        setState(() {
          _failed = true;
          _pairing = false;
        });
        WiFiForIoTPlugin.forceWifiUsage(false);
        await WiFiForIoTPlugin.setEnabled(true);
        if (addFloDeviceConsumer.value.ssid != null) {
           or(() => WiFiForIoTPlugin.connect(addFloDeviceConsumer.value.ssid));
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeInController?.dispose();
    _fadeOutController?.dispose();
    _slideRightController?.dispose();
    super.dispose();
  }

  Widget floRaisedButton(String ssid) {
    return FlatButton(
        padding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [0.0, 1.0],
                colors: [
                  Color(0xFF0C679C),
                  Color(0xFF073F62),
                ],
              ),
              boxShadow: [
                BoxShadow(color: floBlue.withOpacity(0.3), offset: Offset(0, 8), blurRadius: 10)
              ],
              borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
            ),
            child: Row(children: [
              SizedBox(width: 10,),
              Icon(Icons.wifi, color: Colors.white,),
              SizedBox(width: 15,),
              Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ssid, style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white)),
                    //Text("tp-link"),
                  ]),
              Spacer(),
              Text(S.of(context).connected, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5))),
              SizedBox(width: 10,),
            ])),
        onPressed: () {
          print("pressed");
        });
  }

  double _begin = 0.5;
  bool _failed = false;
  bool _started = false;
  bool _pairing = false;

  @override
  Widget build(BuildContext context) {
    Fimber.d("build");
    if (!_started) {
      _started = true;
      onResume(context);
    }
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Spacer(),
          !_failed ? SizedBox(width: double.infinity, child: Stack(children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child:
            FadeTransition(opacity: _fadeOutAnimation, child: Animator(
                repeats: 0,
                tween: Tween(begin: 0.0, end: 3.0),
                duration: Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                builder: (anim) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Row(children: <Widget>[
                      //Text("${S.of(context).initial_pairing} ", style: Theme.of(context).textTheme.title,),
                      Text(S.of(context).initial_pairing_, style: Theme.of(context).textTheme.title,),
                      Opacity(opacity: min(anim.value, 1.0), child: Text(".", style: Theme.of(context).textTheme.title,)),
                      Opacity(opacity: anim.value >= 1.0 ? min(anim.value - 1, 1.0) : 0, child: Text(".", style: Theme.of(context).textTheme.title,)),
                      Opacity(opacity: anim.value >= 2.0 ? min(anim.value - 2, 1.0) : 0, child: Text(".", style: Theme.of(context).textTheme.title,)),
                    ],),
                      SizedBox(height: 15),
                      Text(S.of(context).please_wait_a_few_minutes, style: Theme.of(context).textTheme.body1,),
                    ])))
            ),
            SlideTransition(position: _slideRightAnimation, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child:
            FadeTransition(opacity: _fadeInAnimation, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).pairing_complete, style: Theme.of(context).textTheme.title,),
                  SizedBox(height: 15),
                  floRaisedButton(addFloDeviceConsumer.value?.wifi?.ssid ?? ""),
                ])),
            )),
          ])) : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).pairing_failed, style: Theme.of(context).textTheme.title,),),
                SizedBox(height: 15),
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).please_reenter_wifi_credentials, style: Theme.of(context).textTheme.body1,),)
              ]),
          Spacer(),
          Stack(children: [
            Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FloDeviceImage(width: 90, height: 90,),
                SizedBox(width: 5),
                Expanded(child:
                SpinKitBounce(
                  size: 5,
                  color: Color(0xFF0A537F).withOpacity(0.25),
                  begin: _begin,
                ),
                ),
                SizedBox(width: 5),
                //Icon(Icons.wifi, color: floBlue2, size: 50),
                SvgPicture.asset('assets/ic_wifi_white_normal.svg', color: floBlue2, width: 60, height: 60,)
              ],))),
            Center(child:
            ScaleTransition(scale: _warningScaleUpAnimation, child: IconWarning(height: 60))
            ),
            Center(child:
            ScaleTransition(scale: _successScaleUpAnimation, child: IconChecked(height: 60))
            ),
          ]),
          Spacer(),
          SizedBox(width: 40),
        ]);
  }
}

