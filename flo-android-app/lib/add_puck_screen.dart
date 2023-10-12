import 'dart:async';
import 'package:async/async.dart';
import 'dart:math';
import 'package:animator/animator.dart';
import 'package:flotechnologies/model/firmware_properties.dart';
import 'package:flotechnologies/model/puck_ticket.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'add_flo_device_screen.dart';
import 'generated/i18n.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/link_device_payload.dart';
import 'model/puck.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';


class AddPuckScreen extends StatefulWidget {
  AddPuckScreen({Key key}) : super(key: key);

  State<AddPuckScreen> createState() => _AddPuckScreenState();
}

class _AddPuckScreenState extends State<AddPuckScreen> {
  PageController _pageController = PageController();
  List<Widget> _pages;
  int _page = 0;
  bool _loading = false;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      );
    _pages = <Widget>[
      PuckNicknamePage(pageController: _pageController,),
      PuckChargePage(pageController: _pageController,),
      PuckLoadingWifiListPage(pageController: _pageController,),
      DeviceWifiListPage(pageController: _pageController,),
      PuckOnlinePage(pageController: _pageController,),
    ];
    _scrollController = ScrollController();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        //statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white.withOpacity(0.5), 
    ));

    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
      ..error = null
      ..certificate = null
      ..ticket = null
      ..ticket2 = null
      ..lightsOn = null
      ..pluggedOutlet = null
      ..pluggedPowerCord = null
      ..nickname = ""
      ..deviceSsid = null
    );
    _pageController.addListener(() {
      final int page = currentPage(_pageController);
      if (_page != page) {
        addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b..error = null);
        setState(() {
          _page = page;
        });
      }
    });
  }

  Future<bool> onCancel() async {
    bool consumed = false;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context2) =>
          Theme(data: floLightThemeData, child: AlertDialog(
            title: Text(S.of(context).are_you_sure_you_want_to_cancel_q),
            actions: <Widget>[
              FlatButton(
                child:  Text(S.of(context2).no),
                onPressed: () {
                  Navigator.of(context2).pop();
                },
              ),
              FlatButton(
                child:  Text(S.of(context2).yes),
                onPressed: () async {
                  consumed = true;
                  Navigator.of(context2).pop();
                },
              ),
            ],
          )),
    );
    return consumed;
  }

  Future<bool> onWillPop() async {
    if (hasPreviousPage(_pageController)) {
      previousPage(_pageController);
    } else {
      Navigator.of(context).pushReplacementNamed('/add_a_flo_device');
    }
    return false;
  }

  bool _valid = false;

  Widget navBar(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    var hide = false;
    switch (_page) {
      case 0:
        _valid = addFloDeviceConsumer.value.nickname?.isNotEmpty ?? false;
        break;
      case 1:
        _valid = (addFloDeviceConsumer.value.pluggedPowerCord ?? false) &&
            (addFloDeviceConsumer.value.lightsOn ?? false);
        Fimber.d("_valid: $_valid : ${addFloDeviceConsumer.value.pluggedPowerCord} ${addFloDeviceConsumer.value.lightsOn}");
        break;
      case 4:
        hide = true;
        break;
      default:
        _valid = false;
    }

    return hide && addFloDeviceConsumer.value.error == null ? Container(height: 160, color: floLightBackground) : Container(
      color: floLightBackground, // FIXME
      padding: EdgeInsets.only(bottom: 20),
      child:
      Stack(
          children: <Widget>[
            addFloDeviceConsumer.value.error == null ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 10),
                  SizedBox(height: 15,
                    child: DotsIndicator(
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
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(width: 30),
                      TextButton(
                        padding: EdgeInsets.symmetric(vertical: 25),
                        color: floLightBlue,
                        label: Text("", style: TextStyle(
                          color: floPrimaryColor,
                        ),
                        ),
                        onPressed: () async {
                          onWillPop();
                        },
                        icon: Icon(Icons.arrow_back_ios, color: floPrimaryColor, size: 16, ),
                        shape: CircleBorder(),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                          child: IgnorePointer(ignoring: !_valid, child: Opacity(opacity: _valid ? 1.0 : 0.3, child: TextButton(
                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                            color: floBlue2,
                            label: Text(S.of(context).next, style: TextStyle(
                              color: Colors.white,
                            ),
                              textScaleFactor: 1.6,
                            ),
                            onPressed: () async {
                              if (hasNextPage(_pageController, _pages.length)) {
                                nextPage(_pageController);
                              } else {
                              }
                            },
                            suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16, )),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                          )))),
                      SizedBox(width: 40),
                    ],),
                ]) :
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: TextButton(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        color: floBlue2,
                        label: Text(!(addFloDeviceConsumer.value.error ?? false) ? S.of(context).go_to_dashboard : S.of(context).retry_pairing, style: TextStyle(
                          color: Colors.white,
                        ),
                          textScaleFactor: 1.4,
                        ),
                        onPressed: () async {
                          if (addFloDeviceConsumer.value.error ?? false) {
                            _pageController.jumpToPage(1);
                          } else {
                            Navigator.of(context).pop();
                          }
                        })),
                    SizedBox(height: 20),
                  ],)),
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final child = ThemeBuilder(
      data: floLightThemeData,
      builder: (context) => WillPopScope(
          onWillPop: onWillPop,
          child: Scaffold(
          bottomNavigationBar: BottomAppBar(child: navBar(context),
            elevation: 0,
          ),
          resizeToAvoidBottomPadding: false,
          body: GestureDetector(onTap: () => FocusScope.of(context).requestFocus(FocusNode()), child: SafeArea(child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return <Widget>[
                  SliverAppBar(
                    brightness: Brightness.light,
                    leading: SimpleCloseButton(onPressed: () async {
                      final res = await onCancel();
                      if (res) {
                        Navigator.of(context).pop();
                      }
                    },),
                    iconTheme: IconThemeData(
                      color: floBlue2,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    centerTitle: true,
                    //expandedHeight: 1.0,
                    //flexibleSpace: Container(),
                    floating: true,
                    //snap: true,
                    pinned: false,
                  ),
              ];
            },
            body: Stack(children: <Widget>[Column(children: <Widget>[
              Expanded(child: PageView.builder(
                onPageChanged: (i) {
                },
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index % _pages.length];
                },
              )),
                ],
              ),
              ])
            )))
          )
      ),
    );

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class IconRaisedButton extends StatelessWidget {
  const IconRaisedButton ({
    Key key,
    this.icon,
    this.text,
    this.label,
    this.onPressed,
  }) : super(key: key);

  final Widget icon;
  final Widget text;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
        return RaisedButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          padding: EdgeInsets.all(10),
          color: Colors.white,
          child: Row(
            children: <Widget>[
            SizedBox(width: 70, height: 90, child: icon ?? PuckIcon()),
            SizedBox(width: 5),
            Flexible(child: Container(child: text ?? Text(label ?? Device.FLO_DEVICE_075_V2_DISPLAY,
              style: Theme.of(context).textTheme.subhead,
              overflow: TextOverflow.ellipsis,
            ))), // FIXME
            ]),
            onPressed: onPressed ?? () {},
         );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon ({
    Key key,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  final Widget icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment:  AlignmentDirectional.center,
      children: <Widget>[
    Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: floBlue2.withOpacity(0.2),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.7), offset: Offset(5, 5), blurRadius: 15)
        ],
      ),
      width: width ?? 54,
      height: height ?? 54,
    ),
    icon ?? Image.asset('assets/ic_flo_device_on.png',
      width: 60,
      height: 60)
    ],);
  }
}

class PuckIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleIcon(
      width: 54,
      height: 54,
      icon: Padding(padding: EdgeInsets.only(left: 5), child: Image.asset('assets/ic_flo_device_on.png',
            width: 75,
            height: 75))
    );
  }
}

class PuckNicknamePage extends StatefulWidget {
  final PageController pageController;

  PuckNicknamePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<PuckNicknamePage> createState() => _PuckNicknamePageState();
}

class _PuckNicknamePageState extends State<PuckNicknamePage> {
  @override
  Widget build(BuildContext context) {
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    Fimber.d("${locationConsumer.value}");
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);

    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        // SizedBox(width: double.infinity, child: Text(S.of(context).give_your_a_nickname,
        SizedBox(height: 20),
        Image.asset(DeviceUtils.iconPath(addFloDeviceConsumer.value.model), width: 80, height: 80),
        SizedBox(width: double.infinity, child: Text("Give your Puck a Nickname", // FIXME
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).this_helps_distinguish_devices_and_alerts,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        OutlineTextFormField(
          initialValue: addFloDeviceConsumer.value.nickname,
          //controller: textController1,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 24,
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).nickname_not_empty;
            }
            if (locationConsumer.value.devices?.any((it) => it.nickname == text) ?? false) {
              return S.of(context).nickname_already_in_use;
            }
            return null;
          },
          onChanged: (text) {
            addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b..nickname = text);
          },
          onFieldSubmitted: (text) {
            addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b..nickname = text);
            addFloDeviceConsumer.invalidate();
          },
          labelText: S.of(context).nickname,
        ),
        SizedBox(height: 25),
    ])));
  }
}

class PuckChargePage extends StatefulWidget {
  final PageController pageController;

  PuckChargePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<PuckChargePage> createState() => _PuckChargePageState();
}

class _PuckChargePageState extends State<PuckChargePage> {
  TextEditingController textController1 = TextEditingController();
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
        final floConsumer = Provider.of<FloNotifier>(context);
        final flo = floConsumer.value;
        final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
        final cert = (await flo.getCertificateByDeviceModel(Device((b) => b
          ..deviceType = addFloDeviceConsumer.value.deviceMake
          ..deviceModel = addFloDeviceConsumer.value.model
        ), authorization: oauth.authorization)).body;
        Fimber.d("cert: $cert");
        addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
            ..certificate = cert.toBuilder()
        );
      } catch (err) {
        Fimber.e("", ex: err);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Column(
                        //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: double.infinity, child: Text("${S.of(context).pair_your} ${addFloDeviceConsumer.value.nickname ?? ""}",
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).mark_the_steps_finished_to_continue_pairing,
        )),
        SizedBox(height: 25),
        Center(child: Stack(children: <Widget>[
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 300), child: Visibility(visible: addFloDeviceConsumer.value.pluggedPowerCord ?? false, child: Container(
            key: ValueKey("puck_check1_${addFloDeviceConsumer.value.pluggedPowerCord}"),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              //borderRadius: BorderRadius.all(Radius.circular(8.0)),
              border: DashPathBorder.all(
                borderSide: BorderSide(color: Color(0xFF0C679C), width: 1.0),
                dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
              ),
            ),
            width: 140,
            height: 140,
          ))),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 300), child: Visibility(visible: addFloDeviceConsumer.value.lightsOn ?? false, child: Container(
            key: ValueKey("puck_check2_${addFloDeviceConsumer.value.lightsOn}"),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              //borderRadius: BorderRadius.all(Radius.circular(8.0)),
              border: DashPathBorder.all(
                borderSide: BorderSide(color: Color(0xFF0C679C).withOpacity(0.6), width: 1.0),
                dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
              ),
            ),
            width: 200,
            height: 200,
          ))),
          SizedBox(
              width: 200,
              height: 200,
          ),
          Transform.translate(offset: Offset(8, 8), child: Image.asset(DeviceUtils.iconPath(addFloDeviceConsumer.value.model), width: 140, height: 140)),
        ],
          alignment: Alignment.center,
        )),
        SizedBox(height: 15),
        SimpleCheckboxListTile(
          title: Text("Pull tab or push button on your Leak & Freeze Sensor for 5 seconds.", textScaleFactor: 1.3,),
          subtitle: Text(S.of(context).note_twist_and_turn_cord, textScaleFactor: 1.3),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: addFloDeviceConsumer.value.pluggedPowerCord ?? false,
          onChanged: (checked) {
            addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
              ..pluggedPowerCord = checked
            );
            addFloDeviceProvider.invalidate();
          },
        ),
        SimpleCheckboxListTile(
          title: Text("Light is on and is blinking white.", textScaleFactor: 1.3),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: addFloDeviceConsumer.value.lightsOn ?? false,
          onChanged: (checked) {
            addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
              ..lightsOn = checked
            );
            addFloDeviceProvider.invalidate();
          },
        ),
        SizedBox(height: 25),
    ],)));
  }
}

class PuckLoadingWifiListPage extends StatefulWidget {
  final PageController pageController;

  PuckLoadingWifiListPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<PuckLoadingWifiListPage> createState() => _PuckLoadingWifiListPageState();
}

class _PuckLoadingWifiListPageState extends State<PuckLoadingWifiListPage> with WidgetsBindingObserver {
  Puck puck;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
        cancellable?.cancel();
      }
      break;
      case AppLifecycleState.resumed: {
        final int page = currentPage(widget.pageController);
        if (ModalRoute.of(context)?.settings?.name == '/add_puck' && page == 2) {
          onResume();
        }
      }
      break;
      case AppLifecycleState.paused: {
        cancellable?.cancel();
      }
      break;
      case AppLifecycleState.suspending: {
        cancellable?.cancel();
      }
      break;
    }
  }

  @override
  void initState() {
    super.initState();
    Fimber.d("");

    onResume();
  }

  CancelableOperation cancellable;

  void onResume() {
    Fimber.d("onResume");
    cancellable?.cancel();
    cancellable = CancelableOperation.fromFuture(Future.delayed(Duration(seconds: 1), () async {
      Fimber.d("");
      try {
        await reretry(() async {
          WiFiForIoTPlugin.forceWifiUsage(true);

          final puckWifi = await reretry(() async {
            List<WifiNetwork> wifiList = await WiFiForIoTPlugin.loadWifiList();
            //final wifi = or(() => wifiList.firstWhere((it) => it.ssid.toLowerCase().startsWith(Device.PUCK)));
            //if (wifi == null) {
            //  throw Exception("null");
            //}
            return wifiList.firstWhere((it) => it.ssid.toLowerCase().startsWith(Device.PUCK));
          },
            onRetry: (err) {
              Fimber.d("reretry: puck not found", ex: err);
            },
          );

          await reretry(() =>
              connectOrThrow(puckWifi.ssid),
              onRetry: (e) {
                Fimber.d("reretry: connect to ${puckWifi.ssid}", ex: e);
              }, maxAttempts: 3
          );
          puck = Puck.of();
          final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
          addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
            ..deviceSsid = puckWifi.ssid
          );
          await reretry(() async {
            final scanResult = (await puck.scanList()).body;
            final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
            addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
              ..floDeviceWifiList = scanResult.result.toBuilder()
            );
            addFloDeviceProvider.invalidate();
            nextPage(widget.pageController);
          },
              onRetry: (e) {
                Fimber.d("reretry: scanList()", ex: e);
              }, maxAttempts: 3
          );
        }).timeout(Duration(seconds: 60));
      } catch (err) {
        Navigator.of(context).pushNamed('/goto_wifi_settings');
        Fimber.e("", ex: err);
      }
    }));
  }

  @override
  dispose() {
    puck?.dispose();
    cancellable?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    Fimber.d("");
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 5),
        SizedBox(width: double.infinity,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S
                .of(context)
                .loading_wifi_list_,
              style: Theme
                  .of(context)
                  .textTheme
                  .title,
            ))),
        SizedBox(height: 15),
        SizedBox(width: double.infinity,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S
                .of(context)
                .this_may_take_up_to_1_minute,
              style: Theme
                  .of(context)
                  .textTheme
                  .body1,
            ))),
        SizedBox(height: 100),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 50),
      ],);
  }
}


class PuckOnlinePage extends StatefulWidget {
  final PageController pageController;

  PuckOnlinePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<PuckOnlinePage> createState() => _PuckOnlinePageState();
}

class _PuckOnlinePageState extends State<PuckOnlinePage> with TickerProviderStateMixin, WidgetsBindingObserver {
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

  String _progressText;

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
    _progressText = "";
    Future.delayed(Duration.zero, () async {
      _progressText = S.of(context).initial_pairing_;
    });

    widget.pageController.addListener(() {
      final page = widget.pageController.page;
      print(widget.pageController.page.round());
      if (widget.pageController.page.round() != _page) {
        _page = widget.pageController.page.round();
        if (_page == 4) {
          onResume(context);
        }
      }
    });
    _pairing = false;
  }

  int _page;
  void onResume(context) {
    if (widget.pageController.page.round() != 4) {
      return;
    }
    if (_pairing) {
      return;
    }
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
      try {
        final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
        final floConsumer = Provider.of<FloNotifier>(context);
        final flo = floConsumer.value;
        final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
        final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
        setState(() {
          _progressText = S.of(context).initial_pairing_;
        });
        await reretry(() async {
          final puck = Puck.of();
          await reretry(() async {
            WiFiForIoTPlugin.forceWifiUsage(true);
            await reretry(() =>
                connectOrThrow(addFloDeviceConsumer.value.deviceSsid),
                onRetry: (e) {
                  Fimber.d("reretry: connect to ${addFloDeviceConsumer.value.deviceSsid}", ex: e);
                }, maxAttempts: 6
            );
            await reretry(() async {
              await puck.pair(PuckTicket((b) => b
                ..apiAccessToken = addFloDeviceConsumer.value.certificate?.loginToken ?? oauth.accessToken
                ..wifiSsid = addFloDeviceConsumer.value.wifi?.ssid
                ..wifiPassword = addFloDeviceConsumer.value?.password
                ..wifiEncryption = addFloDeviceConsumer.value.wifi?.encryption
                ..locationId = locationProvider.value.id
                ..nickname = addFloDeviceConsumer.value.nickname
                ..installPoint = Device.UNKNOWN
                ..deviceModel = addFloDeviceConsumer.value.model
                ..deviceType = addFloDeviceConsumer.value.deviceMake
                ..cloudHostname = 'api-gw.meetflo.com'
              ));
            },
                onRetry: (e) {
                  Fimber.d("reretry: pair()", ex: e);
                }, maxAttempts: 3
            );
          });
          setState(() {
            _progressText = S.of(context).updating_network_settings;
          });
          await Future.delayed(Duration(seconds: 3));
          WiFiForIoTPlugin.disconnect();
          WiFiForIoTPlugin.forceWifiUsage(true);
          await reretry(() {
            connectOrThrow(addFloDeviceConsumer.value.deviceSsid);
          },
              onRetry: (e) {
                Fimber.d("reretry: connect to ${addFloDeviceConsumer.value.deviceSsid}", ex: e);
              },
              maxAttempts: 10
          );
          await reretry(() async {
            final properties = await reretry(() async {
              final puck = Puck.of();
              final props = (await puck.getProperties()).body;
              Fimber.d("getProperties: $props");
              if (props.result.pairingState != FirmwareProperties.PAIRED) {
                throw StateError(props.result.pairingState); // waiting for paired
              }
              return props.result;
            },
              onRetry: (e) async {
                await reretry(() =>
                    connectOrThrow(addFloDeviceConsumer.value.deviceSsid),
                    onRetry: (e) {
                      Fimber.d("reretry: connect to ${addFloDeviceConsumer.value.deviceSsid}", ex: e);
                    }, maxAttempts: 3
                );
                Fimber.d("reretry: getProperties()", ex: e);
              },
            );
            Fimber.d("properties: ${properties}");
          });
          await puck.disconnect();
          WiFiForIoTPlugin.forceWifiUsage(false);
          /*
          await flo.linkDevice(LinkDevicePayload((b) => b
            ..locationId = locationProvider.value.id
            ..nickname = addFloDeviceConsumer.value.nickname
            ..deviceType = addFloDeviceConsumer.value.deviceMake
          ), authorization: oauth.authorization);
          */
        }, maxAttempts: 5).timeout(Duration(seconds: 120));
        await Future.delayed(Duration(seconds: 4));

        locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
        locationProvider.invalidate();
        _fadeInController.forward();
        _fadeOutController.forward();
        _slideRightController.forward();
        _warningScaleUpController.reverse();
        _successScaleUpController.forward();
        addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
          ..error = false
        );
        addFloDeviceConsumer.invalidate();
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
                    Text(ssid, style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white), textScaleFactor: 1.1,),
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
                      Text(_progressText, style: Theme.of(context).textTheme.title, overflow: TextOverflow.ellipsis,),
                      Opacity(opacity: min(anim.value, 1.0), child: Text(".", style: Theme.of(context).textTheme.title,)),
                      Opacity(opacity: anim.value >= 1.0 ? min(anim.value - 1, 1.0) : 0, child: Text(".", style: Theme.of(context).textTheme.title,)),
                      Opacity(opacity: anim.value >= 2.0 ? min(anim.value - 2, 1.0) : 0, child: Text(".", style: Theme.of(context).textTheme.title,)),
                      Spacer(),
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
            Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                PuckV1Icon(),
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
              ],)),
            Center(child:
            Transform.translate(offset: Offset(15, 15), child: ScaleTransition(scale: _warningScaleUpAnimation, child: IconWarning(height: 60)))
            ),
            Center(child:
            Transform.translate(offset: Offset(15, 15), child: ScaleTransition(scale: _successScaleUpAnimation, child: IconChecked(height: 60)))
            ),
          ]),
          Spacer(),
          SizedBox(width: 40),
        ]);
  }
}


class CenterCrop extends StatelessWidget {
  const CenterCrop ({
    Key key,
    @required
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return OverflowBox(
      ////maxWidth: double.infinity,
      //maxWidth: double.infinity,
      //maxHeight: double.infinity,
      maxWidth: size.width / 2,
      maxHeight: size.height / 2,
      alignment: Alignment.center,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          UnconstrainedBox(
            constrainedAxis: Axis.vertical,
            child: child 
          ),
        ]
      )
    );
  }
}

class CenterCrop2 extends StatelessWidget {
  const CenterCrop2 ({
    Key key,
    @required
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return OverflowBox(
      //maxWidth: double.infinity,
      //maxHeight: double.infinity,
      maxWidth: size.width / 2,
      maxHeight: size.height / 2,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: Container(
          width: size.width / 2,
          height: size.height / 2,
          child: child
        )
      )
    );
  }
}

class CenterCrop3 extends StatelessWidget {
  const CenterCrop3 ({
    Key key,
    @required
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(children: <Widget>[
      Align(
        alignment: Alignment.center,
        child: child,
      ),
      Positioned(
        top: 70,
        left: 0,
        right: 0,
        child: Image.asset('assets/ic_focus_frame.png',
        width: 200,
        height: 200,
        ),
      ),
      Positioned(
        top: 0,
        child: Container(width: size.width, height: 40, color: floLightBackground,),
      ),
      Positioned(
        bottom: 0,
        child: Container(width: size.width, height: 250, color: floLightBackground,),
      ),
    ],
    );
  }
}

Future<bool> awaitFor() {
}
