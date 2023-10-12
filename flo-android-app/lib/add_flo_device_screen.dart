import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:async/async.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/model/wifi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:rxdart/rxdart.dart';

import 'flo_stream_service.dart';
import 'generated/i18n.dart';
import 'model/app_info.dart';
import 'model/certificates.dart';
import 'model/device.dart';
import 'model/device_item.dart';
import 'model/flo.dart';
import 'model/id.dart';
import 'model/item.dart';
import 'model/link_device_payload.dart';
import 'model/ticket.dart';
import 'model/ticket2.dart';
import 'model/ticket_data.dart';
import 'model/wifi_station.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'flo_device_service.dart';
import 'package:flutter_spinkit/src/utils.dart';
import 'package:retry/retry.dart';
import 'package:validators/validators.dart';
import 'package:superpower/superpower.dart';
import 'package:chopper/chopper.dart' as chopper;


class AddFloDeviceScreen extends StatefulWidget {
  AddFloDeviceScreen({Key key}) : super(key: key);

  State<AddFloDeviceScreen> createState() => _AddFloDeviceScreenState();
}

class _AddFloDeviceScreenState extends State<AddFloDeviceScreen> {
  PageController _pageController = PageController();
  List<Widget> _pages;
  int _page = 0;
  bool _loading = false;
  ScrollController _scrollController;
  ScrollDirection _scrollDirection = ScrollDirection.idle;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      //keepPage: false,
      //viewportFraction: 0,
      );
    _pages = <Widget>[
      FloDeviceNicknamePage(pageController: _pageController,),
      ChargeFloDevicePage(pageController: _pageController,),
      PushToConnectPage(pageController: _pageController,),
      ScanQrCodePage(pageController: _pageController,),
      LoadingWifiListPage(pageController: _pageController,),
      DeviceWifiListPage(pageController: _pageController,),
      OnlinePage(pageController: _pageController,),
      //GoToWifiSettingsPage(pageCont roller: _pageController,),
      //OnlinePage(pageController: _pageController,),
      //LoadingWifiListPage(pageController: _pageController,),
      //DeviceWifiListPage(pageController: _pageController,),
    ];
    _loading = false;

    _valid = false;
    _elevation = 0;
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection != _scrollDirection) {
        _scrollDirection = _scrollController.position.userScrollDirection;
        if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          //setState(() => _isVisible = true);
        } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
          //setState(() => _isVisible = false);
        }
      }
      invalidateElevation();
    });

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
    );

    //_pageController.addListener(listener);
    _pageController.addListener(() {
      final int page = currentPage(_pageController);
      if (_page != page) {
        _page = page;
        _scrollController.animateTo(0, duration: Duration(microseconds: 250), curve: Curves.fastOutSlowIn);
        print("${_page}");
        final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
        addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b..error = null);
        invalidateElevation();
        setState(() {
          print("${_page} : ${_valid}");
        });
      }
    });

  }

  double _elevation = 0;
  double getElevation() => _scrollController.position.extentAfter > 0.0 ? 8.0 : 0.0;

  void invalidateElevation() {
    final elevation = _page == 1 ? getElevation() : 0.0;
    if (_elevation != elevation) {
      setState(() {
        _elevation = elevation;
      });
    }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
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
  final floConsumer = Provider.of<FloNotifier>(context);
  final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
  final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
  final flo = floConsumer.value;
  print(addFloDeviceConsumer.value);
  var hide = false;
  switch (_page) {
    case 0:
      _valid = addFloDeviceConsumer.value.nickname?.isNotEmpty ?? false;
      break;
    case 1:
      _valid = (addFloDeviceConsumer.value.pluggedPowerCord ?? false) &&
               (addFloDeviceConsumer.value.pluggedOutlet ?? false) &&
               (addFloDeviceConsumer.value.lightsOn ?? false);
      break;
    case 3:
      _valid = false;
      break;
    case 5:
      _valid = false;
      break;
    case 4:
      _valid = false;
      break;
    case 6:
      _valid = false;
      hide = true;
      break;
    default:
      _valid = true;
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
                          _pageController.jumpToPage(2);
                          //previousPage(_pageController);
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
    final child = Theme(
      data: floLightThemeData,
      child: WillPopScope(
          onWillPop: onWillPop,
          child: Scaffold(
          bottomNavigationBar: BottomAppBar(child: navBar(context),
            elevation: _elevation,
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
                  final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
                  if (i == 3) {
                    if ((addFloDeviceProvider.value?.ticket2?.data?.isNotEmpty ?? false) && addFloDeviceProvider.value.certificate != null) {
                      nextPage(_pageController);
                    }
                  }
                },
                //physics: AlwaysScrollableScrollPhysics(),
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index % _pages.length];
                },
              )),
              //navBar(context,)
                ],
              ),
              Center(child: _loading ? CircularProgressIndicator() : Container())
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

class AddWhichOneFloDeviceScreen extends StatefulWidget {
  AddWhichOneFloDeviceScreen({
    Key key,
  }) : super(key: key);

  State<AddWhichOneFloDeviceScreen> createState() => _AddWhichOneFloDeviceState();
}

class _AddWhichOneFloDeviceState extends State<AddWhichOneFloDeviceScreen> with AfterLayoutMixin<AddWhichOneFloDeviceScreen> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        //statusBarIconBrightness: Brightness.light,
                    //brightness: Brightness.dark,
        statusBarColor: Colors.white.withOpacity(0.5), 
    ));
  }


  Iterable<DeviceItem> _deviceModels = [];

  @override
  Widget build(BuildContext context) {
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    final location = locationConsumer.value;
    return Theme(data: floLightThemeData,
      isMaterialAppTheme: true,
      child: Scaffold(
      appBar: AppBar(
        brightness: Brightness.light,
        leading: SimpleCloseButton(),
        iconTheme: IconThemeData(
          color: floBlue2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Builder(builder: (context) => CustomScrollView(
      slivers: <Widget>[
         SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(
          horizontal: 40,
        ), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).add_a_device_to_your_home,
         style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 10),
        SizedBox(width: double.infinity, child: Text(location?.nickname ?? location?.address ?? "",
          style: Theme.of(context).textTheme.subhead,
          textScaleFactor: 0.9,
        )),
        SizedBox(height: 40),
        /*
        IconRaisedButton(label: S.of(context).s_3_4_flo_by_moen_device, onPressed: () {
          addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
          ..model = "flo_device_075_v2"
          ..modelDisplay = S.of(context).s_3_4_flo_by_moen_device
          ..deviceMake = "flo_device_v2"
          );
          Navigator.of(context).pushReplacementNamed("/add_the_device");
        }),
        SizedBox(height: 25),
        IconRaisedButton(icon: FloDeviceQuarterIcon(), label: S.of(context).s_1_14_flo_by_moen_device, onPressed: () {
          addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
          ..model = "flo_device_125_v2"
          ..modelDisplay = S.of(context).s_1_14_flo_by_moen_device
          ..deviceMake = "flo_device_v2"
          );
          Navigator.of(context).pushReplacementNamed("/add_the_device");
        }),
        */
        /*
        SizedBox(height: 25),
        IconRaisedButton(label: S.of(context).puck_leak_sensor, onPressed: () {
          addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b..model = "Puck Leak Sensor"); // FIXME
          Navigator.of(context).pushReplacementNamed("/add_the_device");
        }),
        SizedBox(height: 25),
        */
    ]))),
      SliverList(delegate: SliverChildBuilderDelegate((context, i) {
        final models = _deviceModels.toList();
        final model = models[i];

        Fimber.d("model: ${model}");
        return Padding(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: IconRaisedButton(icon: DeviceUtils.icon(models[i].key),
            label: models[i]?.longDisplay,
            onPressed: () {
              addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
              ..model = models[i]?.key
              ..modelDisplay = models[i]?.longDisplay
              ..deviceMake = models[i]?.type?.key ?? ""
              );
              if (Device.PUCK_V1 == addFloDeviceProvider.value.model) {
                Navigator.of(context).pushReplacementNamed("/add_puck");
              } else {
                Navigator.of(context).pushReplacementNamed("/add_the_device");
              }
            }));
      },
       childCount: _deviceModels.length)
      ),
    ],
    ))));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
    _deviceModels = [
      DeviceItem((b) => b
        ..type = Item((b) => b
          ..key = Device.FLO_DEVICE_V2
          ..shortDisplay = Device.FLO_DEVICE_V2
          ..longDisplay = Device.FLO_DEVICE_V2
        ).toBuilder()
        ..key = Device.FLO_DEVICE_075_V2
        ..shortDisplay = S.of(context).s_3_4_flo_by_moen_device
        ..longDisplay = S.of(context).s_3_4_flo_by_moen_device
      ),
      DeviceItem((b) => b
        ..type = Item((b) => b
          ..key = Device.FLO_DEVICE_V2
          ..shortDisplay = Device.FLO_DEVICE_V2
          ..longDisplay = Device.FLO_DEVICE_V2
        ).toBuilder()
        ..key = Device.FLO_DEVICE_125_V2
        ..shortDisplay = S.of(context).s_1_14_flo_by_moen_device
        ..longDisplay = S.of(context).s_1_14_flo_by_moen_device
      ),
    ];
    });
    Future.delayed(Duration.zero, () async {
      final floConsumer = Provider.of<FloNotifier>(context, listen: false);
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
      final flo = floConsumer.value;
      try {
        /*
        final deviceModels = await flo.floDeviceV2Models(authorization: oauthConsumer.value.authorization);
        */
        final deviceModels = await flo.deviceModelsWithType(authorization: oauthConsumer.value.authorization);
        setState(() {
          _deviceModels = deviceModels.where((it) => !it.key.contains("puck"));
        });
      } catch (e) {
        Fimber.e("", ex: e);
      }
    });
  }
}

class FloDeviceNicknamePage extends StatefulWidget {
  final PageController pageController;

  FloDeviceNicknamePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<FloDeviceNicknamePage> createState() => _FloDeviceNicknamePageState();
}

class _FloDeviceNicknamePageState extends State<FloDeviceNicknamePage> {
  TextEditingController textController1 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    Fimber.d("${locationConsumer.value}");
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FloDeviceIcon(),
        SizedBox(height: 40),
        // SizedBox(width: double.infinity, child: Text(S.of(context).give_your_a_nickname,
        SizedBox(width: double.infinity, child: Text(S.of(context).give_your_device_a_nickname(addFloDeviceConsumer.value.modelDisplay),
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
    ],))));
    });
  }
}

class ChargeFloDevicePage extends StatefulWidget {
  final PageController pageController;

  ChargeFloDevicePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<ChargeFloDevicePage> createState() => _ChargeFloDevicePageState();
}

class _ChargeFloDevicePageState extends State<ChargeFloDevicePage> {
  TextEditingController textController1 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            //minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(10)), child: Column(
                        //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: double.infinity, child: Text("${S.of(context).pair} ${addFloDeviceConsumer.value.nickname ?? ""}",
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).mark_the_steps_finished_to_continue_pairing,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Container(color: Colors.white, child: Image.asset('assets/bg_flo_charge.png'))),
        SizedBox(height: 15),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).firmly_pushed_the_power_cord, textScaleFactor: 1.3,),
                  subtitle: Text(S.of(context).note_twist_and_turn_cord, textScaleFactor: 1.3),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: addFloDeviceConsumer.value.pluggedPowerCord?? false,
                  onChanged: (checked) {
                    addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
                    ..pluggedPowerCord = checked
                    );
                    addFloDeviceProvider.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).plugged_the_power_supply_into_an_outlet, textScaleFactor: 1.3),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: addFloDeviceConsumer.value.pluggedOutlet?? false,
                  onChanged: (checked) {
                    addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
                    ..pluggedOutlet = checked
                    );
                    addFloDeviceProvider.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).both_lights_are_on_and_are_not_blinking, textScaleFactor: 1.3),
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
    ],))));
    });
  }
}

class PushToConnectPage extends StatefulWidget {
  final PageController pageController;

  PushToConnectPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<PushToConnectPage> createState() => _PushToConnectPageState();
}

class _PushToConnectPageState extends State<PushToConnectPage>
 with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animatable<Color> _animatedColor;
  @override
  void initState() {
    super.initState();
    _animatedColor = TweenSequence<Color>([
     TweenSequenceItem(weight: 1.0, tween: ColorTween(
        begin: Colors.white,
        end: Colors.black,
    ))]);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(10)), child: Column(
                        //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: double.infinity, child: Text(S.of(context).push_to_connect_to_wifi,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).press_and_hold_until_white_light_blinks_then_release,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Container(color: _animatedColor.evaluate(AlwaysStoppedAnimation(_animationController.value)), child: Image.asset('assets/bg_push_button_connect_hole.png')))),
        SizedBox(height: 25),
    ],))));
    });
  }
}

class ScanQrCodePage extends StatefulWidget {
  final PageController pageController;

  ScanQrCodePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<ScanQrCodePage> createState() => _ScanQrCodePageState();
}

class _ScanQrCodePageState extends State<ScanQrCodePage>
 with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animatable<Color> _animatedColor;

@override
  void dispose() {
    _animationController?.dispose();
    QrMobileVision.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animatedColor = TweenSequence<Color>([
     TweenSequenceItem(weight: 1.0, tween: ColorTween(
        begin: Colors.white,
        end: Colors.black,
    ))]);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
    
    Future.delayed(Duration.zero, () async {
    });
      _paused = false;
  }

  Timer _startCameraTimer;
  bool _paused = false;

  Future<bool> requestPermissions() async {
      Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([
        PermissionGroup.camera,
        PermissionGroup.locationWhenInUse,
      ]);
      final isNotGranted = permissions.values.any((it) => it != PermissionStatus.granted);
      if (permissions[PermissionGroup.camera] != PermissionStatus.granted) {
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text(S.of(context).camera_access_required_to_continue),
                content: Text(S.of(context).please_go_to_settings_and_allow_camera_access),
                actions: <Widget>[
                  FlatButton(
                    child: Text(S.of(context).app_settings),
                    onPressed: () async {
                      await PermissionHandler().openAppSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(S.of(context).cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
        );
        previousPage(widget.pageController);
      } else if (permissions[PermissionGroup.locationWhenInUse] != PermissionStatus.granted) {
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text(S.of(context).location_access_required_to_continue),
                content: Text(S.of(context).location_access_required_description),
                actions: <Widget>[
                  FlatButton(
                    child: Text(S.of(context).app_settings),
                    onPressed: () async {
                      await PermissionHandler().openAppSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(S.of(context).cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
        );
        previousPage(widget.pageController);
      }
    return !isNotGranted;
  }

  @override
  Widget build(BuildContext context) {
    WiFiForIoTPlugin.forceWifiUsage(false);
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final size = MediaQuery.of(context).size;
    final floConsumer = Provider.of<FloNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    final flo = floConsumer.value;
    final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    final isDemo = flo is FloMocked;
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            //minHeight: viewportConstraints.maxHeight,
          ), child: Column(
                        //mainAxisSize: MainAxisSize.min,
      //mainAxisAlignment: MainAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 5),
        Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: SvgPicture.asset('assets/ic_qr_code.svg', color: floBlue2, width: 30, height: 30,)),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("${S.of(context).pair_your} ${addFloDeviceConsumer.value.nickname}", // FIXME
          style: Theme.of(context).textTheme.title,
        ))),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).scan_qr_code_located_on_device,
          style: Theme.of(context).textTheme.body1,
        ))),
        SizedBox(height: 25),
        //CenterCrop(
        //CenterCrop2(
        //Container(width: size.width / 2, height: size.height / 2,
        /*
        Container(width: size.width, height: size.width * 1.3,
          child: CenterCrop3(child: QrReaderView(width: size.width, height: size.width * 1.3, callback: (controller) {
              print(controller);
              _qrController = controller;
              _startCameraTimer?.cancel();
              _startCameraTimer = Timer(Duration(milliseconds: 500) * timeDilation, () {
                _startCameraTimer = null;
                _qrController?.startCamera((qrCode, offsets) {
                  print(qrCode);
                  _qrController?.stopCamera();
                });
            });
          })),
        ),
        */
        Container(width: size.width, height: 250,
          child: Stack(children: <Widget>[
            Futures.of(requestPermissions(), initialData: false, then: (context, granted) =>
            granted ? RxBuilder((subject, context) => QrCamera(
              qrCodeCallback: (code) {
                  subject.add(code);
                }),
              onNext: (code) {
                if (_paused) return;
                _paused = true;
                Fimber.d("$code");
                final ticket = or(() => TicketData.fromJson(code));
                addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
                ..ticket = ticket != null ? Ticket((b) => b..data = ticket.toBuilder()).toBuilder() : null
                ..ticket2 = Ticket2((b) => b..data = code).toBuilder()
                ..certificate = null
                );
                addFloDeviceProvider.invalidate();
                nextPage(widget.pageController);
                _paused = false;
              },
            ) : Container(),
            ),
            Align(
              alignment: Alignment.center,
              child: Image.asset('assets/ic_focus_frame.png',
              width: 220,
              height: 220,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: isDemo ? Counter((context, t) => Text("$t", textScaleFactor: 3),
              begin: 4,
              end: 0,
              onCompleted: () {
                addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
                ..ticket = null
                ..ticket2 = Ticket2((b) => b..data = "").toBuilder()
                ..certificate = null
                );
                addFloDeviceProvider.invalidate();
                nextPage(widget.pageController);
              }) : Container(),
          ),
          ]),
        ),
        SizedBox(height: 25),
        Align(alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50),
            width: double.infinity,
            child: FlatViewSetupGuide()
          )
        ),
    ],)));
    });
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

class LoadingWifiListPage extends StatefulWidget {
  final PageController pageController;

  LoadingWifiListPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<LoadingWifiListPage> createState() => _LoadingWifiListPageState();
}

class _LoadingWifiListPageState extends State<LoadingWifiListPage> with WidgetsBindingObserver, AfterLayoutMixin<LoadingWifiListPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: {
        cancellable?.cancel();
      }
      break;
      case AppLifecycleState.resumed: {
        onResume(context);
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

  CancelableOperation cancellable;
  void onResume(BuildContext context) {
    Fimber.d("onResume");
    cancellable?.cancel();
    cancellable = CancelableOperation.fromFuture(Future.delayed(Duration(seconds: 1), () async {
      final floProvider = Provider.of<FloNotifier>(context, listen: false);
      final flo = floProvider.value;
      final isDemo = flo is FloMocked;
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
      final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context, listen: false);
      if (addFloDeviceConsumer.value.ticket2 == null &&
          addFloDeviceConsumer.value.ticket == null &&
          addFloDeviceConsumer.value.certificate == null) {
         //_process = false;
        Fimber.d("no any ticket and no certs: ${addFloDeviceConsumer.value.certificate}");
        previousPage(widget.pageController);
        return;
      }
      Fimber.d("WiFiForIoTPlugin.getSSID()");
      final ssid = await WiFiForIoTPlugin.getSSID();
      if (addFloDeviceConsumer.value.certificate == null) {
      if (addFloDeviceConsumer.value.ticket != null) {
        await flo.getCertificate(addFloDeviceConsumer.value.ticket, authorization: oauthConsumer.value.authorization)
            .then((res) => res.body)
            .then((cert) {
          addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
            ..certificate = cert.toBuilder()
            ..ssid = ssid ?? b.ssid
          );
        })
        //.whenComplete(() => paused = false)
            .catchError((e) {
          Fimber.e("${e}", ex: e);
          addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
            ..ticket = null
          );
          showDialog(
              context: context,
              builder: (context2) =>
                  FloErrorDialog(
                    title: as<chopper.Response>(e)?.statusCode == HttpStatus.conflict ? Text("Flo Error 004") : Text("Flo Error 008"),
                    error: let<chopper.Response, Error>(e, (it) => HttpError(it.base)) ?? e,
                    onPressed: () async {
                      Navigator.of(context2).pop();
                      previousPage(widget.pageController);
                    },
                  )
          );
        });
      } else {
      await flo.getCertificate2(addFloDeviceConsumer.value.ticket2, authorization: oauthConsumer.value.authorization)
        .then((res) => res.body)
        .then((cert) {
          addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
          ..certificate = cert.toBuilder()
          ..ssid = ssid ?? b.ssid
          );
        })
        //.whenComplete(() => paused = false)
        .catchError((e) {
          Fimber.e("", ex: e);
          Fimber.e("statusCode? ${as<chopper.Response>(e)?.statusCode}");
          Fimber.e("conflict? ${as<chopper.Response>(e)?.statusCode == HttpStatus.conflict}");

          addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
            ..ticket2 = null
          );
          showDialog(
              context: context,
              builder: (context2) =>
                  FloErrorDialog(
                    title: as<chopper.Response>(e)?.statusCode == HttpStatus.conflict ? Text("Flo Error 004") : Text("Flo Error 008"),
                    error: let<chopper.Response, Error>(e, (it) => HttpError(it.base)) ?? e,
                    onPressed: () async {
                      Navigator.of(context2).pop();
                      previousPage(widget.pageController);
                    },
                  )
          );
        });
      }
      }
      final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
      if (addFloDeviceProvider.value.certificate?.apName?.isEmpty ?? true) {
        /*
        showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: Text("Flo Error 008"),
                  content: Text(S.of(context).something_wront_please_retry),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).ok),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        previousPage(widget.pageController);
                      },
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                )
        );
        */
        Fimber.d("no cert or apName: ${addFloDeviceProvider.value.certificate}");
        previousPage(widget.pageController);
        return;
      }
      addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
        ..ssid = ssid ?? b.ssid
      );
      try {
        final floDeviceService = (!isDemo ? FloDeviceServiceOk() : FloDeviceServiceMocked());
        final floDeviceServiceProvider = Provider.of<FloDeviceServiceNotifier>(context, listen: false);
        floDeviceServiceProvider.value = floDeviceService;
        floDeviceServiceProvider.invalidate();
        await retry(() async {
          if (!isDemo) {
            // recursive build? after nav.push()
            //if (!await containsWifi(addFloDeviceConsumer.value.certificate.apName)) {
            //  throw WifiNotFoundException();
            //}
            Fimber.d("to apName: ${addFloDeviceProvider.value.certificate.apName}");
            await ensureFloDeviceService2(floDeviceServiceProvider.value,
              ssid: addFloDeviceProvider.value.certificate.apName,
              loginToken: addFloDeviceProvider.value.certificate.loginToken,
              websocketCert: addFloDeviceProvider.value.certificate.websocketCert
            );
          }
          //await Future.delayed(Duration(seconds: 2));
          //await Future.delayed(Duration(seconds: 10));
          final res = await floDeviceService.scanWifi();
          addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
          ..floDeviceWifiList = ListBuilder($(res.result)
            .distinctBy((it) => it.ssid)
            .sortedBy((it) => it.signal))
          );
          Fimber.d("scanned: ${addFloDeviceProvider.value.floDeviceWifiList}");
          return true;
        }, maxAttempts: 3).timeout(Duration(seconds: 90));
        //connect(wifiList.first, "password");
        nextPage(widget.pageController);
      } catch (e) {
        Fimber.e("${e}", ex: e);
        Navigator.of(context).pushNamed('/goto_wifi_settings');
        //Navigator.of(context).pushNamedAndRemoveUntil('/goto_wifi_settings', ModalRoute.withName('/goto_wifi_settings'));
        /*
        Navigator.of(context).pushNamedAndRemoveUntil('/goto_wifi_settings', (Route<dynamic> route) =>
        !route.willHandlePopInternally
            && route is ModalRoute
            && (route.settings.name == '/add_a_flo_device' || route.settings.name == '/change_device_wifi')
        );
        */
      }
    }),
      onCancel: () => Fimber.d('onCancel'),
    );
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("build");
    onResume(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 5),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).loading_wifi_list_,
          style: Theme.of(context).textTheme.title,
        ))),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text(S.of(context).this_may_take_up_to_1_minute,
          style: Theme.of(context).textTheme.body1,
        ))),
        SizedBox(height: 100),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 50),
    ],);
  }

  @override
  void afterFirstLayout(BuildContext context) {
  }
}

/*
class GoToWifiSettingsPage extends StatefulWidget {
  final PageController pageController;

  GoToWifiSettingsPage({
    Key key,
    this.pageController}) : super(key: key);

  State<GoToWifiSettingsPage> createState() => _GoToWifiSettingsPageState();
}

class _GoToWifiSettingsPageState extends State<GoToWifiSettingsPage> with AfterLayoutMixin<GoToWifiSettingsPage> {
  @override
  void initState() {
    super.initState();
    _wifi_enabled = false;
  }

  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    if (addFloDeviceConsumer.value.floDeviceWifiList?.isNotEmpty ?? false) {
      Navigator.of(context).pop();
    }

    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Column(
                        //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("Connect to Wi-Fi “Flo-35a”", // TODO
          style: Theme.of(context).textTheme.title,
        ))),
        SizedBox(height: 25),
        Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Container(
          padding: EdgeInsets.only(left: 25, right: 15, bottom: 15, top: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            color: Colors.white,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.2),
          ),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text(S.of(context).wifi,
               style: Theme.of(context).textTheme.subhead.copyWith())),
              Switch(
                value: _wifi_enabled,
                onChanged: (value) {
                  _wifi_enabled = value;
                  Fimber.d("${value}");
                },
              ),
            ],),
            SizedBox(height: 15),
            Row(children: <Widget>[
              Expanded(child: Text(addFloDeviceConsumer.value.certificate.apName, style: Theme.of(context).textTheme.subhead.copyWith(
              ))),
              Icon(Icons.lock, size: 16),
              SizedBox(width: 5),
              Icon(Icons.wifi, size: 16),
              SizedBox(width: 5),
              Icon(Icons.info_outline, size: 25, color: Colors.blue,),
            ],),
          ],),
        )),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
         child: Text(S.of(context).one_leave_app_go_to_settings,
          style: Theme.of(context).textTheme.subhead,
        ))),
        SizedBox(height: 25),
        Align(alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50),
            width: double.infinity,
            child: TextButton(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              color: floLightBlue,
              label: Text(S.of(context).open_settings, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.3,),
              onPressed: () async {
                await AppSettings.openWIFISettings();
              },
              suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: floPrimaryColor, size: 13, )),
            )
          )
        ),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(S.of(context).two_tap_on_wifi_and_select_the_network,
          style: Theme.of(context).textTheme.subhead,
        ))),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(S.of(context).three_return_to_app_to_continue,
          style: Theme.of(context).textTheme.subhead,
        ))),
    ],)));
    });
  }

  bool _wifi_enabled = true;

  @override
  void afterFirstLayout(BuildContext context) {
    Future(() async {
      setState(() async {
        _wifi_enabled = await WiFiForIoTPlugin.isEnabled();
      });
    });
  }
}
*/

/// loadWifiList(orElse: () => [])
/*
Future<List<WifiNetwork>> loadWifiList({List<WifiNetwork> orElse()}) async {
  try {
    return await WiFiForIoTPlugin.loadWifiList();
  } catch (e) {
    return orElse != null ? orElse() : throw e;
  }
}
*/
Future<List<WifiNetwork>> loadWifiList({List<WifiNetwork> orElse()}) async {
  return await futureOr(WiFiForIoTPlugin.loadWifiList(), orElse: orElse);
}

Future<T> futureOr<T>(Future<T> future, {T orElse()}) async {
  try {
    return await future;
  } catch (e) {
    return orElse != null ? orElse() : throw e;
  }
}

T orElse<T>(T func(), {T orElse}) {
  try {
    return func();
  } catch (e) {
    return orElse;
  }
}
/// none, psk-mixed, psk-mixed+aes, psk-mixed+ccmp, psk-mixed+tkip, psk-mixed+tkip+aes, psk-mixed+tkip+ccmp, psk, psk+aes, psk+ccmp, psk+tkip, psk+tkip+aes , psk+tkip+ccmp, psk2, psk2+aes, psk2+ccmp, psk2+tkip, psk2+tkip+aes, psk2+tkip+ccmp
Set<NetworkSecurity> networkSecurities(String capabilities) {
  return capabilities.split('\]')
      .map((cap) => cap.replaceAll(RegExp(r'[\[\]]'), ''))
      .map((cap) => cap.toUpperCase())
      .map<NetworkSecurity>((cap) {
        if (cap.contains('WPA')) {
          return NetworkSecurity.WPA;
        } else if (cap.contains('PSK')) {
          return NetworkSecurity.WEP;
        } else if (cap.contains('WEP')) {
          return NetworkSecurity.WEP;
        } else {
          return null;
        }
      })
      .where((value) => value != null)
      .toSet();
}

bool isNetworkLocked(String capabilities) => networkSecurities(capabilities).isNotEmpty;

/*
  WiFiForIoTPlugin.connect(
    ssid,
    password: password,
    joinOnce: true,
    security: NetworkSecurity.WPA);
*/
Future<bool> connect(WifiNetwork network, String password, {bool joinOnce}) async {
  final Set<NetworkSecurity> securities = networkSecurities(network.capabilities);
  return WiFiForIoTPlugin.connect(network.ssid,
   password: password,
   joinOnce: joinOnce,
   security: securities.contains(NetworkSecurity.WPA) ? NetworkSecurity.WPA :
             securities.contains(NetworkSecurity.WEP) ? NetworkSecurity.WEP :
             NetworkSecurity.NONE);
}

class DeviceWifiListPage extends StatefulWidget {
  final PageController pageController;

  DeviceWifiListPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<DeviceWifiListPage> createState() => _DeviceWifiListPageState();
}

class _DeviceWifiListPageState extends State<DeviceWifiListPage> {
  @override
  void initState() {
    super.initState();
  }

  wifiItem({
    String ssid = "",
    String password,
    int signal,
    bool locked = true,
    @required
    Changed3<String, String, bool> onChanged,
  }) {
    signal = signal != 100 ? signal : -70;
    final bool isLowSignal = signal <= -60;
    return Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: FlatButton(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            color: Colors.white,
            child: Row(children: [
              SizedBox(width: 10,),
              WifiSignalIcon(signal.toDouble(), width: 22, height: 22,),
              SizedBox(width: 15,),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${ssid}", style: Theme.of(context).textTheme.caption.copyWith(color: floBlue2), textScaleFactor: 1.1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  !locked ? Text("Not supported", style: Theme.of(context).textTheme.caption)
                         : isLowSignal ? Text(S.of(context).not_recommended_low_strength, style: Theme.of(context).textTheme.caption)
                                       : Container(),
                ]
              )),
              locked ? Icon(Icons.lock, color: floBlue2, size: 16) : Container(),
              SizedBox(width: 10,),
            ]
            ),
            onPressed: () async {
              if (locked) {
                if (password != null) {
                    onChanged(ssid, password, true);
                } else {
                showDialog(
                  context: context,
                  builder: (context) => WifiPasswordAlertDialog(
                    ssid: ssid,
                    password: password,
                    onPositive: (password, remembered) {
                    onChanged(ssid, password, remembered);
                  },)
                );
                }
              } else {
                onChanged(ssid, "", true);
              }
            },
          ));
  }

  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    //final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
    final floConsumer = Provider.of<FloNotifier>(context, listen: false);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
    final flo = floConsumer.value;
    final prefsConsumer = Provider.of<PrefsNotifier>(context, listen: false);
    final prefs = prefsConsumer.value;
    return Column(children: <Widget>[
            SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("Connect ${addFloDeviceConsumer.value.nickname} to your Home’s 2.4GHz Wi-Fi Network", // TODO
              style: Theme.of(context).textTheme.title,
            ))),
            SizedBox(height: 15),
        (addFloDeviceConsumer.value.floDeviceWifiList?.isEmpty ?? true) ? Container(height: 200, child: Center(child: Text(S.of(context).no_networks_scanned_please_rescan))) :
        Expanded(child: CustomScrollView(slivers: [SliverList(delegate: SliverChildBuilderDelegate(
          (context, i) {
            final wifi = addFloDeviceConsumer.value.floDeviceWifiList[i];
            return IgnorePointer(
              ignoring: !isNetworkLocked(wifi.encryption),
              child: Opacity(opacity: !isNetworkLocked(wifi.encryption) ? 0.5 : 1.0, child: Padding(padding: EdgeInsets.symmetric(vertical: 2.5), child: wifiItem(ssid: wifi.ssid,
              password: prefs?.getString("ssid_${wifi.ssid}"),
              signal: wifi.signal.toInt() ?? 100.0,
              locked: isNetworkLocked(wifi.encryption),
              onChanged: (ssid, password, remebered) {
                if (remebered) {
                  prefs?.setString("ssid_${ssid}", password);
                }
                addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
                ..wifi = wifi.toBuilder()
                ..password = password
                );
                addFloDeviceConsumer.invalidate();
                nextPage(widget.pageController);
              }))));
          },
          childCount: addFloDeviceConsumer.value.floDeviceWifiList?.length ?? 0,
        ))
        ]
        )),
        SizedBox(height: 10),
        Align(alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50),
            width: double.infinity,
            child: TextButton(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              color: floLightBlue,
              label: Text(S.of(context).rescan_networks, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.3,),
              onPressed: () async {
                final addFloDeviceProvider = Provider.of<AddFloDeviceNotifier>(context, listen: false);
                addFloDeviceProvider.value = addFloDeviceProvider.value.rebuild((b) => b
                ..floDeviceWifiList = null);
                previousPage(widget.pageController);
              },
            )
          )
        ),
        SizedBox(height: 15),
        Align(alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50),
            width: double.infinity,
            child: TextButton(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              color: floLightBlue,
              label: Text(S.of(context).enter_manually, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.3,),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => WifiSsidPasswordAlertDialog(
                    onPositive: (ssid, password, remembered) {
                      if (remembered) {
                        prefs.setString("ssid_${ssid}", password);
                      }
                      addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
                      ..wifi = Wifi((b) => b
                                ..ssid = ssid
                                ..encryption = Wifi.PSK2 // FIXME: the firmware doesn't support auto encryption, we choose the popular one as default
                                ..signal = 100.0 // FIXME: should keep null as well
                              ).toBuilder()
                      ..password = password
                      );
                      nextPage(widget.pageController);
                    },

                  )
                );
              },
            )
          )
        ),
        SizedBox(height: 15),
        Align(alignment: Alignment.center,
            child: TextButton(
              padding: EdgeInsets.symmetric(horizontal: 10),
              label: Text(S.of(context).network_not_listed_q, style: TextStyle(
                color: floPrimaryColor,
                decoration: TextDecoration.underline,
              ), textScaleFactor: 1.3,),
              onPressed: () async {
            showDialog(
              context: context,
              builder: (context) =>
                AlertDialog(
                  title: Text(S.of(context).wifi_not_listed),
                  content: Text(S.of(context).if_wifi_not_visible_contact_support),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).ok),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
            ));
              },
            )
        ),
    ]);
  }
}

class WifiPasswordAlertDialog extends StatefulWidget {
  WifiPasswordAlertDialog({Key key,
    this.ssid = "",
    this.password = "",
    this.onPositive,
    this.onNegative,
  }) : super(key: key);

  final Changed2<String, bool> onPositive;
  final Changed2<String, bool> onNegative;
  final String ssid;
  final String password;

  _WifiPasswordAlertDialogState createState() => _WifiPasswordAlertDialogState();
}

class _WifiPasswordAlertDialogState extends State<WifiPasswordAlertDialog> {
  TextEditingController _textController;
  bool _checked;

  @override
  void initState() { 
    super.initState();
    _textController = TextEditingController();
    _checked = false;
    _autovalidate = false;
    _textController.text = widget.password;
    _valid = false;
  }

  @override
  void dispose() {
    //_textController?.dispose();
    super.dispose();
  }

  bool _autovalidate = false;
  bool _valid = false;

  String validator(String text) {
    if (text.length < 8) {
      return S.of(context).min_8_characters;
    }
    if (!isAscii(text)) {
      return S.of(context).invalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
                  title: Text(S.of(context).enter_password),
                  //content: Text("Please go to your phone settings and allow \"Flo by Moen\" to access your camera so you can pair this device"),
                  content: SingleChildScrollView(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text("Connect to “${widget.ssid}”", style: Theme.of(context).textTheme.body1), // TODO
                    SizedBox(height: 25,),
                    PasswordField(
                      controller: _textController,
                      autofocus: true,
                      autovalidate: _autovalidate,
                      maxLength: 63,
                      validator: (text) {
                        validator(text);
                      },
                      onTextChanged: (text) {
                        final valid = validator(text) == null;
                        if (_valid != valid) {
                          setState(() {
                            _valid = valid;
                          });
                        }
                      },
                      onFieldSubmitted: (text) {
                        if (!_autovalidate) {
                          setState(() {
                            _autovalidate = true;
                          });
                        }
                        onPositive();
                      },
                    ),
                    SizedBox(height: 10,),
                    /*
                    SimpleCheckboxListTile(
                      dense: true,
                      title: Text(S.of(context).remember_wifi_password, textScaleFactor: 1.2,),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _checked,
                      onChanged: (checked) {
                        _checked = checked;
                      },
                    ),
                    */
                  ])),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).cancel),
                      onPressed: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          Navigator.of(context).pop();
                          if (widget.onNegative != null) {
                            widget.onNegative(_textController.text, _checked);
                          }
                      },
                    ),
                    FlatButton(
                      child: Text(S.of(context).connect, style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _valid ? () async {
                        onPositive();
                      } : null,
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                );
  }

  void onPositive() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_valid) {
      Navigator.of(context).pop();
      if (widget.onPositive != null) {
        widget.onPositive(_textController.text, _checked);
      }
    }
  }
}

class OnlinePage extends StatefulWidget {
  final PageController pageController;

  OnlinePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage> with TickerProviderStateMixin, WidgetsBindingObserver {
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
      // TODO
      final page = widget.pageController.page;
      print(widget.pageController.page.round());
      if (widget.pageController.page.round() != _page) {
        _page = widget.pageController.page.round();
        if (_page == 6) {
          onResume(context);
        }
      }
    });
    _pairing = false;
  }

  int _page;
  void onResume(context) {
    if (widget.pageController.page.round() != 6) {
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
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    final floStreamServiceConsumer = Provider.of<FloStreamServiceNotifier>(context, listen: false);
    //final FloStreamService floStreamService = FloStreamServiceMocked(); // Use firestore instead if it's ready for pairing
    final FloStreamService floStreamService = addFloDeviceConsumer.value.certificate.firestoreToken.token != null ? floStreamServiceConsumer.value : FloStreamServiceMocked();
    final floDeviceServiceProvider = Provider.of<FloDeviceServiceNotifier>(context, listen: false);
    final FloDeviceService floDeviceService = floDeviceServiceProvider.value;
    try {
      final floConsumer = Provider.of<FloNotifier>(context);
      final flo = floConsumer.value;
      final isDemo = flo is FloMocked;
      final floDeviceServiceProvider = Provider.of<FloDeviceServiceNotifier>(context, listen: false);
      floDeviceServiceProvider.value = (!isDemo ? FloDeviceServiceOk() : FloDeviceServiceMocked());
      floDeviceServiceProvider.invalidate();
      setState(() {
        _progressText = S.of(context).initial_pairing_;
      });
      await retry(() async {
        if (!isDemo) {
          await ensureFloDeviceService2(floDeviceServiceProvider.value,
              ssid: addFloDeviceConsumer.value.certificate.apName,
              loginToken: addFloDeviceConsumer.value.certificate.loginToken,
              websocketCert: addFloDeviceConsumer.value.certificate
                  .websocketCert
          ).timeout(Duration(seconds: 45));
        }
        setState(() {
          _progressText = S.of(context).uploading_certificates;
        });
        await floDeviceService.setCertificates(Certificates((b) => b
          ..encodedCaCert = addFloDeviceConsumer.value.certificate.serverCert
          ..encodedClientCert = addFloDeviceConsumer.value.certificate
              .clientCert
          ..encodedClientKey = addFloDeviceConsumer.value.certificate.clientKey
        ));
        setState(() {
          _progressText = S.of(context).updating_network_settings;
        });
        await floDeviceService.setWifiStationConfig(WifiStation((b) => b
          ..wifiStaSsid = addFloDeviceConsumer.value.wifi.ssid
          ..wifiStaPassword = addFloDeviceConsumer.value.password
          ..wifiStaEncryption = addFloDeviceConsumer.value.wifi.encryption
        ));
      }, maxAttempts: 5).timeout(Duration(seconds: 90));
      WiFiForIoTPlugin.forceWifiUsage(false);
      if (addFloDeviceConsumer.value.ssid != null) {
        Fimber.d("connect back to ${addFloDeviceConsumer.value.ssid}");
        await retry(() => WiFiForIoTPlugin.connect(addFloDeviceConsumer.value.ssid),
            onRetry: (e) {
              WiFiForIoTPlugin.forceWifiUsage(false);
              Fimber.e("retry: connect ${addFloDeviceConsumer.value.ssid}", ex: e);
            }
        );
        await WiFiForIoTPlugin.disconnect();
      } else {
        await WiFiForIoTPlugin.disconnect();
      }
      await Future.delayed(Duration(seconds: 8));

      final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
      final locationConsumer = Provider.of<CurrentLocationNotifier>(context, listen: false);
      //Fimber.d("location ${locationConsumer.value}");
      //Fimber.d("${Id((b) => b..id = locationConsumer.value.id)}");
      Observable.fromFuture(PackageInfo.fromPlatform())
          .flatMap((platform) => Stream.fromFuture(flo.presence(AppInfo((b) => b
              ..appName = "flo-android-app2"
              ..appVersion = platform.version
            ), authorization: oauthConsumer.value.authorization)).map((it) => platform))
          .flatMap((platform) => Observable.range(0, 10)
          .interval(Duration(seconds: 30)).map((it) => platform))
          .flatMap((platform) => Stream.fromFuture(flo.presence(AppInfo((b) => b
        ..appName = "flo-android-app2"
        ..appVersion = platform.version
      ), authorization: oauthConsumer.value.authorization)))
          .listen((_) {}, onError: (err) {
        Fimber.e("", ex: err);
      });
      //final firestoreToken = await flo.getFirestoreToken(authorization: oauthConsumer.value.authorization);
      //final location = (await flo.getLocation(locationConsumer.value.id, authorization: oauthConsumer.value.authorization)).body;
      //final simpleDevice = location.devices.firstWhere((it) => it.macAddress == addFloDeviceConsumer.value.certificate.deviceId);
      ///// It should return 404 here becuase the device doesn't exist yet,
      ///// but it will create an empty device document on firestore
      ///// that's what we need
      //await flo.getDevice(simpleDevice.id, authorization: oauthConsumer.value.authorization);

      Fimber.d("floStreamService: $floStreamService");
      Fimber.d("firestoreToken: ${addFloDeviceConsumer.value.certificate.firestoreToken.token}");
      await retry(() => floStreamService.login(addFloDeviceConsumer.value.certificate.firestoreToken.token).timeout(Duration(seconds: 5))).timeout(Duration(seconds: 15));
      Fimber.d("floStreamService.login");
      Fimber.d("floStreamService.awaitOnline");
      await retry(() => floStreamService.awaitOnline(addFloDeviceConsumer.value.certificate.deviceId)).timeout(Duration(seconds: 70));
      Fimber.d("online");

      final res = await retry(() => flo.linkDevice(LinkDevicePayload((b) => b
        ..nickname = addFloDeviceConsumer.value.nickname
        ..deviceModel = addFloDeviceConsumer.value.model
        ..deviceType = addFloDeviceConsumer.value.deviceMake
        ..location = Id((b) => b..id = locationConsumer.value.id).toBuilder()
        ..macAddress = addFloDeviceConsumer.value.certificate.deviceId,
      ), authorization: oauthConsumer.value.authorization),
        onRetry: (e) {
          WiFiForIoTPlugin.forceWifiUsage(false);
          Fimber.d("retry: link", ex: e);
        }
      ).timeout(Duration(seconds: 15));
      Fimber.d("linkDevice: ${res.body}");

      final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
      locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
      locationProvider.invalidate();
      addFloDeviceConsumer.value = addFloDeviceConsumer.value.rebuild((b) => b
      ..deviceId = res.body.id
      );
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

class SpinKitBounce extends StatefulWidget {
  SpinKitBounce({
    Key key,
    this.color,
    this.size = 10,
    this.begin = 0.5,
    this.end = 1.0,
    this.itemBuilder,
    this.duration = const Duration(milliseconds: 1400),
  })  : assert(
            !(itemBuilder is IndexedWidgetBuilder && color is Color) &&
                !(itemBuilder == null && color == null),
            'You should specify either a itemBuilder or a color'),
        assert(size != null),
        super(key: key);

  final Color color;
  final double size;
  final double begin;
  final double end;
  final IndexedWidgetBuilder itemBuilder;
  final Duration duration;

  @override
  _SpinKitBounceState createState() => _SpinKitBounceState();
}

class _SpinKitBounceState extends State<SpinKitBounce>
    with SingleTickerProviderStateMixin {
  AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _circle(0, .0),
            _circle(1, .1),
            _circle(2, .2),
            _circle(3, .3),
            _circle(5, .5),
            _circle(6, .6),
            _circle(7, .7),
            _circle(8, .8),
            //_circle(9, .9),
            //_circle(10, .10),
          ],
    );
  }

  Widget _circle(int index, double delay) {
    final _size = widget.size;
    return ScaleTransition(
      scale: DelayTween(begin: widget.begin, end: widget.end, delay: delay).animate(_scaleCtrl),
      child: SizedBox.fromSize(
        size: Size(_size * 3, _size),
        child: _itemBuilder(index),
      ),
    );
  }

  Widget _itemBuilder(int index) {
    return widget.itemBuilder != null
        ? widget.itemBuilder(context, index)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
  }
}

class IconWarning extends StatelessWidget {
  const IconWarning({
    Key key,
    this.width,
    this.height,
    }) : super(key: key);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: 5), child: Image.asset('assets/ic_warning2.png', width: width, height: height,));
  }
}

class IconChecked extends StatelessWidget {
  const IconChecked({
    Key key,
    this.width,
    this.height,
    }) : super(key: key);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: 5), child: Image.asset('assets/ic_checked.png', width: width, height: height,));
  }
}

class WifiSsidPasswordAlertDialog extends StatefulWidget {
  WifiSsidPasswordAlertDialog({Key key,
    this.onPositive,
    this.onNegative,
  }) : super(key: key);

  final Changed3<String, String, bool> onPositive;
  final Changed3<String, String, bool> onNegative;

  _WifiSsidPasswordAlertDialogState createState() => _WifiSsidPasswordAlertDialogState();
}

class _WifiSsidPasswordAlertDialogState extends State<WifiSsidPasswordAlertDialog> {
  TextEditingController _textController;
  TextEditingController _passwordController;
  bool _checked;
  FocusNode focus1;
  FocusNode focus2;

  @override
  void initState() { 
    _textController = TextEditingController();
    _passwordController = TextEditingController();
    _checked = false;
    _autovalidate1 = false;
    _autovalidate2 = false;
    focus1 = FocusNode();
    focus2 = FocusNode();
    _valid = false;
    _valid0 = false;
    super.initState();
  }

  @override
  void dispose() {
    //_textController?.dispose();
    //_passwordController?.dispose();
    super.dispose();
  }

  bool _autovalidate1 = false;
  bool _autovalidate2 = false;
  bool _valid = false;
  bool _valid0 = false;

  String validator(String text) {
    if (text.length < 8) {
      return S.of(context).min_8_characters;
    }
    if (!isAscii(text)) {
      return S.of(context).invalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
                  title: Text(S.of(context).enter_manually),
                  content: SingleChildScrollView(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    //Text("Connect to “Jake-Home”", style: Theme.of(context).textTheme.body1),
                    SizedBox(height: 4,),
                    OutlineTextFormField(
                      labelText: S.of(context).wifi_network,
                      controller: _textController,
                      focusNode: focus1,
                      autovalidate: _autovalidate1,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      validator: (text) {
                        String res;
                        if (text.isEmpty) {
                          res = S.of(context).empty_ssid;
                        }
                        return res;
                      },
                      onChanged: (text) {
                        final bool valid = text.isNotEmpty;
                        if (_valid0 != valid) {
                          setState(() {
                            _valid0 = valid;
                          });
                        }
                      },
                    onFieldSubmitted: (text) {
                      FocusScope.of(context).requestFocus(focus2);
                    }
                    ),
                    SizedBox(height: 15,),
                    PasswordField(
                      controller: _passwordController,
                      focusNode: focus2,
                      autovalidate: _autovalidate2,
                      textInputAction: TextInputAction.done,
                      validator: (text) {
                        validator(text);
                      },
                      onTextChanged: (text) {
                        final valid = validator(text) == null;
                        if (_valid != valid) {
                          setState(() {
                            _valid = valid;
                          });
                        }
                      },
                      onFieldSubmitted: (text) {
                        onPositive();
                      },
                    ),
                    SizedBox(height: 5,),
                    /*
                    SimpleCheckboxListTile(
                      dense: true,
                      title: Text(S.of(context).remember_wifi_password, textScaleFactor: 1.2,),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _checked,
                      onChanged: (checked) {
                        _checked = checked;
                      },
                    ),
                    */
                  ])),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).cancel),
                      onPressed: () async {
                        if (widget.onNegative != null) {
                          widget.onNegative(_textController.text, _passwordController.text, _checked);
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text(S.of(context).connect, style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _valid0 && _valid ? () async {
                        onPositive();
                      } : null,
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                );
  }

  void onPositive() {
    if (!_valid0 || !_valid) {
      if (!_autovalidate1 || !_autovalidate2) {
        setState(() {
          _autovalidate1 = true;
          _autovalidate2 = true;
        });
      }
    } else {
      if (widget.onPositive != null) {
        widget.onPositive(_textController.text, _passwordController.text, _checked);
      }
      Navigator.of(context).pop();
    }
  }
}

// TODO
// V:2$I:ffffffffffffffffffffffffffffffff$E:ffffffffffffffffffffffffffffffff$
//void isFloTicket2(String text) {
//  text.split('\$').map();
//}

typedef SubjectBuilder<T> = Widget Function(Subject<T>, BuildContext context);
typedef SubjectTransformer<T> = Subject<T> Function(Subject<T>);

class RxBuilder<T> extends StatefulWidget {
  RxBuilder(this.child, {
    Key key,
    this.subject,
    this.throttleTime = const Duration(milliseconds: 1000),
    this.onNext,
    this.transformer,
  }) : super(key: key);
  final SubjectBuilder child;
  final Subject<T> subject;
  final ValueChanged<T> onNext;
  //final SubjectTransformer<T> transformer;
  final StreamTransformer<T, T> transformer;
  final Duration throttleTime;

  _RxBuilderState<T> createState() => _RxBuilderState<T>();
}

class _RxBuilderState<T> extends State<RxBuilder> {
  Subject<T> _subject;
  ValueChanged<T> _onNext;

  @override
  void initState() { 
    super.initState();
    _subject = widget.subject ?? PublishSubject<T>();
    _onNext = widget.onNext ?? (_) {};
    _subject.asBroadcastStream()
      //.transform(widget.transformer)
      .throttleTime(widget.throttleTime)
      .take(1)
      //.debounce((_) => TimerStream(true, widget.debounce))
      //.distinct()
      .listen(_onNext);
  }

  @override
  void dispose() {
    _subject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child(_subject, context);
  }
}

class GoToWifiSettingsScreen extends StatefulWidget {
  final PageController pageController;

  GoToWifiSettingsScreen({
    Key key,
    this.pageController}) : super(key: key);

  State<GoToWifiSettingsScreen> createState() => _GoToWifiSettingsScreenState();
}

class _GoToWifiSettingsScreenState extends State<GoToWifiSettingsScreen> {
  @override
  void initState() {
    super.initState();
    _isWifiEnabled = false;
  }

  bool _isWifiEnabled = false;

  @override
  Widget build(BuildContext context) {
    final addFloDeviceConsumer = Provider.of<AddFloDeviceNotifier>(context);
    return Theme(data: floLightThemeData, child: Scaffold(
      appBar: AppBar(
        brightness: Brightness.light,
        leading: IconButton(icon: Icon(Icons.close),
          onPressed: () {
            /*
            if (hasPreviousPage(_pageController)) {
              previousPage(_pageController);
            } else {
              Navigator.of(context).pop();
            }
            */
            Navigator.of(context).pop();
          }
        ),
        iconTheme: IconThemeData(
          color: floBlue2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Builder(builder: (context) => Column(
                        //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("Connect to Wi-Fi “${addFloDeviceConsumer.value.certificate?.apName ?? addFloDeviceConsumer.value.deviceSsid}”", // TODO
          style: Theme.of(context).textTheme.title,
        ))),
        SizedBox(height: 25),
        Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Container(
          padding: EdgeInsets.only(left: 25, right: 15, bottom: 15, top: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            color: Colors.white,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.2),
          ),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text(S.of(context).wifi,
               style: Theme.of(context).textTheme.subhead.copyWith())),
              Futures.of(WiFiForIoTPlugin.isEnabled(), initialData: false, then: (context, value) {
                return Switch(
                  value: value,
                  onChanged: (value) async {
                    Fimber.d("${value}");
                    //await WiFiForIoTPlugin.setEnabled(value);
                    await AppSettings.openWIFISettings();
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],),
            SizedBox(height: 15),
            InkWell(onTap: () async {
              await AppSettings.openWIFISettings();
              Navigator.of(context).pop();
            }, child: Row(children: <Widget>[
              Expanded(child: Text(addFloDeviceConsumer.value.certificate?.apName ?? addFloDeviceConsumer.value?.deviceSsid ?? "Puck-xxxx", style: Theme.of(context).textTheme.subhead.copyWith(
              ))),
              Icon(Icons.lock, size: 16),
              SizedBox(width: 5),
              Icon(Icons.wifi, size: 16),
              SizedBox(width: 5),
              Icon(Icons.info_outline, size: 25, color: Colors.blue,),
            ],)),
          ],),
        )),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
         child: Text(S.of(context).one_leave_app_go_to_settings,
          style: Theme.of(context).textTheme.subhead,
        ))),
        SizedBox(height: 25),
        Align(alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 50),
            width: double.infinity,
            child: TextButton(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              color: floLightBlue,
              label: Text(S.of(context).open_settings, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.3,),
              onPressed: () async {
                await AppSettings.openWIFISettings();
                Navigator.of(context).pop();
              },
              suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: floPrimaryColor, size: 13, )),
            )
          )
        ),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(S.of(context).two_tap_on_wifi_and_select_the_network,
          style: Theme.of(context).textTheme.subhead,
        ))),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(S.of(context).three_return_to_app_to_continue,
          style: Theme.of(context).textTheme.subhead,
        ))),
    ],))
    ));
  }
}

Future<bool> connectOrThrow(String ssid, {String password, bool joinOnce}) async {
  if (!(await WiFiForIoTPlugin.isEnabled())) { await WiFiForIoTPlugin.setEnabled(true); }
  final connectedSsid = await WiFiForIoTPlugin.getSSID();
  Fimber.d("current ssid: ${connectedSsid}");
  Fimber.d("connect to ssid: ${ssid}");
  if (ssid == connectedSsid) return true;
  return await orThrow(WiFiForIoTPlugin.findAndConnect(ssid, password: password, joinOnce: joinOnce));
}

Future<bool> orThrow(Future<bool> future) async {
  final ok = await future;
  if (!ok) {
    throw Exception();
  }
  return ok; 
}

  Future<void> ensureFloDeviceService(FloDeviceService floDeviceService, {
    @required
    String ssid, 
    @required
    String loginToken,
    String websocketCert
    }) async {
      WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(Duration(seconds: 3));
      final connected = await retry(() =>
        connectOrThrow(ssid),
          onRetry: (e) {
            WiFiForIoTPlugin.forceWifiUsage(true);
            Fimber.d("retry: $e", ex: e);
          }
        );
      Fimber.d("connected: ${connected} : ${ssid}");
      List<InternetAddress> lookuped = [];
      try {
        lookuped = await retry(() => InternetAddress.lookup("flodevice"),
          onRetry: (e) async {
            WiFiForIoTPlugin.forceWifiUsage(true);
            final connected = await connectOrThrow(ssid);
            Fimber.d("retry: flodevice: ${e} : (${connected})");
          }
        );
        Fimber.d("lookuped: ${lookuped}");
      } catch (e) {
        Fimber.e("Cannot resove flodevice: ${e}", ex: e);
      }
      if ((lookuped?.isNotEmpty ?? false)) {
        await retry(() => floDeviceService.connect('wss://flodevice:8000', certificate: websocketCert),
            onRetry: (e) async {
              WiFiForIoTPlugin.forceWifiUsage(true);
              final connected = await connectOrThrow(ssid);
              Fimber.e("retry: connect flodevice service (${connected})", ex: e);
            }
        );
        Fimber.d("lookuped: ${lookuped}");
      } else {
        lookuped = await retry(() => InternetAddress.lookup("192.168.3.1"),
            onRetry: (e) async {
              WiFiForIoTPlugin.forceWifiUsage(true);
              final connected = await connectOrThrow(ssid);
              Fimber.d("retry: 192.168.3.1: ${e} : (${connected})");
            }
        );
        await retry(() => floDeviceService.connect('wss://192.168.3.1:8000', certificate: websocketCert),
            onRetry: (e) async {
              WiFiForIoTPlugin.forceWifiUsage(true);
              final connected = await connectOrThrow(ssid);
              Fimber.e("retry: connect flodevice service (${connected})", ex: e);
            }
        );
      }
      final res = await retry(() => floDeviceService.login(loginToken),
        onRetry: (e) async {
          WiFiForIoTPlugin.forceWifiUsage(true);
          final connected = await connectOrThrow(ssid);
          Fimber.e("retry: login flodevice service (${connected})", ex: e);
        }
      );
      Fimber.d("$res");
  }

Future<void> ensureFloDeviceService2(FloDeviceService floDeviceService, {
  @required
  String ssid,
  @required
  String loginToken,
  String websocketCert
}) async {
  if (ssid?.isEmpty ?? true) {
    throw ArgumentError.notNull(ssid);
  }
  Fimber.d("ensure: ${ssid}");
  await retry(() async {
    WiFiForIoTPlugin.forceWifiUsage(true);
    //await Future.delayed(Duration(seconds: 3));
    var connected = await retry(() =>
        connectOrThrow(ssid),
        onRetry: (e) {
          WiFiForIoTPlugin.forceWifiUsage(true);
          Fimber.d("retry: connect to $ssid", ex: e);
        }, maxAttempts: 6
    );
    Fimber.d("connected: ${connected} : ${ssid}");
    //WiFiForIoTPlugin.forceWifiUsage(true);
    //await Future.delayed(Duration(seconds: 3));
    connected = await retry(() =>
        connectOrThrow(ssid),
        onRetry: (e) {
          //WiFiForIoTPlugin.forceWifiUsage(true);
          Fimber.d("retry2: connect to $ssid", ex: e);
        }, maxAttempts: 3
    );
    Fimber.d("connected2: ${connected} : ${ssid}");
    //await Future.delayed(Duration(seconds: 10));
    final url = 'wss://192.168.3.1:8000';
    Fimber.d("connecting: wss://192.168.3.1:8000 : ${websocketCert}");
    await retry(() => floDeviceService.connect(url, certificate: websocketCert),
        onRetry: (e) async {
          //WiFiForIoTPlugin.forceWifiUsage(true);
          final connected = await connectOrThrow(ssid);
          Fimber.e("retry: connect to flodevice service (${connected})", ex: e);
        }, maxAttempts: 6
    );
    Fimber.d("wss connected: wss://192.168.3.1:8000");
    //await Future.delayed(Duration(seconds: 10));
    final res = await retry(() => floDeviceService.login(loginToken),
        onRetry: (e) async {
          //WiFiForIoTPlugin.forceWifiUsage(true);
          final connected = await connectOrThrow(ssid);
          Fimber.e("retry: login flodevice service (${connected})", ex: e);
        }, maxAttempts: 3
    );
    Fimber.d("wss login: $res");
    //await Future.delayed(Duration(seconds: 10));
  }, maxAttempts: 4, maxDelay: Duration(seconds: 5));
}


Future<bool> containsWifi(String ssid) async {
  final wifiList = await WiFiForIoTPlugin.loadWifiList();
  return or(() => wifiList.firstWhere((it) => it.ssid == ssid)) != null;
}
