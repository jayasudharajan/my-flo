import 'package:after_layout/after_layout.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'flo_stream_service.dart';
import 'generated/i18n.dart';
import 'model/flo.dart';
import 'package:fimber/fimber.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes.dart';
import 'providers.dart';
import 'package:transparent_image/transparent_image.dart';

import 'utils.dart';
import 'widgets.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    Fimber.d("");
    SystemChrome.setEnabledSystemUIOverlays([]);
    WiFiForIoTPlugin.forceWifiUsage(false);

    super.initState();

    Future.delayed(Duration.zero, () async {
      final floProvider = Provider.of<FloNotifier>(context, listen: false);
      if (floProvider.value is FloMocked) {
        floProvider.value = Flo.of(context);
      }
      final flo = floProvider.value;
      final loginNotifier = Provider.of<LoginStateNotifier>(context, listen: false);
      loginNotifier.value = loginNotifier.value.rebuild((b) => b
        ..country = Localizations.localeOf(context).countryCode.toLowerCase()
        //..phoneCountry = Localizations.localeOf(context).countryCode.toLowerCase()
      );

      final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
      Fimber.d("oauth: ${oauthConsumer.value}");
      if (oauthConsumer.value.accessToken?.isNotEmpty ?? false) {
        Navigator.of(context).pushReplacementNamed('/home');
        return true;
      }

      Fimber.d("flo.refreshed: ${flo.refreshed}");
      if (flo.refreshed) {
        Navigator.of(context).pushReplacementNamed('/login');
        return true;
      }

      try {
        final prefsProvider = Provider.of<PrefsNotifier>(context, listen: false);
        final floStreamServiceProvider = Provider.of<FloStreamServiceNotifier>(context, listen: false);
        floStreamServiceProvider.value = FloFirestoreService();
        //floStreamServiceProvider.invalidate();
        final floStreamService = floStreamServiceProvider.value;
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefsProvider.value = prefs;
        oauthConsumer.value = oauthConsumer.value.rebuild((b) => b
          ..accessToken =  prefs.getString('access_token') ?? b.accessToken
          ..refreshToken = prefs.getString('refresh_token') ?? b.refreshToken
          ..expiresIn =    prefs.getInt('expires_in') ?? b.expiresIn
          ..userId =       prefs.getString('user_id') ?? b.userId
          ..expiresAt =    prefs.getString('expires_at') ?? b.expiresAt
          ..issuedAt =     prefs.getString('issued_at') ?? b.issuedAt
          ..tokenType =    prefs.getString('token_type') ?? b.tokenType
        );
        Fimber.d("oauth: ${oauthConsumer.value}");
        Fimber.d("oauth.isExpired: ${oauthConsumer.value.isExpired}");
        if (oauthConsumer.value.isExpired) {
          final unauthFlo = Flo.of(context, authenticated: false);
          oauthConsumer.value = await unauthFlo.refreshTokenBy(oauthConsumer.value);
          flo.refreshed = true;
          flo.oauth = oauthConsumer.value;
          SharedPreferencesUtils.putOauth(prefs, oauthConsumer.value);
          Fimber.d("refreshed: oauth: ${oauthConsumer.value}");
        }
        if (oauthConsumer.value.accessToken?.isNotEmpty ?? false) {
          final firestoreToken = await flo.getFirestoreToken(authorization: oauthConsumer.value.authorization);
          final firebaseUser = await floStreamService.login(firestoreToken.body.token);
          Fimber.d("user: ${firebaseUser}");
          Navigator.of(context).pushReplacementNamed('/home');
          return true;
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
          return true;
        }
        /*
        if (oauthConsumer.current.accessToken != "") {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        */
      } catch (err) {
        Fimber.e("${as<Response>(err)?.body}", ex: err);
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return true;
    });
  }

  //double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    Fimber.d(Localizations.localeOf(context).toString());
  return FutureBuilder(
  future: Future.delayed(Duration.zero),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return Material(
        type: MaterialType.transparency,
          child: Container(padding: EdgeInsets.only(left: 60), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                Text(S.of(context).secure_your_home, style: TextStyle(fontSize: 20, color: Colors.white)),
                Text(S.of(context).conserve_your_water, style: TextStyle(fontSize: 20, color: Colors.white)),
              ])));
      /*
      return Theme(data: ThemeData(backgroundColor: Colors.transparent), child:
        Scaffold(
            resizeToAvoidBottomPadding: false,
            body: Builder(builder: (context) => Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 30),
                  Text(S.of(context).secure_your_home, textScaleFactor: 1.6, style: TextStyle(color: Colors.white)),
                  Text(S.of(context).conserve_your_water, textScaleFactor: 1.6, style: TextStyle(color: Colors.white)),
                ])
              ))));
      */
    }
    return Container(color: Colors.transparent);
  }
  );
  }
}

class Waves extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                      Transform.scale(scale: 1.0,
                       child: Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave0.png',
                        fit: BoxFit.fitWidth,
                      )),
                      Transform.scale(scale: 1.0,
                       child: Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave1.png',
                        fit: BoxFit.fitWidth,
                      )),
                      Transform.scale(scale: 1.0,
                       child: Image.asset('android/app/src/main/res/drawable-xhdpi/bg_splash_wave2.png',
                        fit: BoxFit.fitWidth,
                      )),
                    ],));
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      return Theme(data: floLightThemeData, child: Stack(children: <Widget>[
        Scaffold(
            resizeToAvoidBottomPadding: false,
            body: Builder(builder: (context) => InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.75,
                      colors: [
                        const Color(0xFF8BC5E9),
                        const Color(0xFF0A537F),
                      ],
                      stops: [0.0, 1.0]
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                    Spacer(flex: 2),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                    Image.asset(
                      'android/app/src/main/res/drawable-xhdpi/ic_flo_logo_cutout.png', width: 100,
                      ),
                    SizedBox(height: 30),
                    Text(S.of(context).secure_your_home, textScaleFactor: 1.6, style: TextStyle(color: Colors.white)),
                    Text(S.of(context).conserve_your_water, textScaleFactor: 1.6, style: TextStyle(color: Colors.white)),
                    ])),
                    Spacer(flex: 1),
                    Waves(),
                  ],
                  )
                )
              )
            ),
          ),
        ]));
  }
}
