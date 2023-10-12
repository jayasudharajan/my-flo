import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:superpower/superpower.dart';
import 'model/answer.dart';
import 'model/flo.dart';
import 'model/item.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/locales.dart';
import 'model/location.dart';
import 'model/location_type.dart';
import 'model/past_water_damage_claim_amount.dart';
import 'model/preference_category.dart';
import 'model/timezone.dart';
import 'model/unit_system.dart';
import 'model/water_source.dart';
import 'providers.dart';
import 'themes.dart';
import 'validations.dart';
import 'widgets.dart';
import 'package:recase/recase.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:progress_dialog/progress_dialog.dart';


class AddLocationScreen extends StatefulWidget {
  AddLocationScreen({Key key}) : super(key: key);

  State<AddLocationScreen> createState() => _AddLocationState();
}

class _AddLocationState extends State<AddLocationScreen> {
  PageController _pageController = PageController();
  List<Widget> _pages;
  int _page = 0;
  bool _loading = false;
  ScrollController _scrollController;
  ScrollDirection _scrollDirection = ScrollDirection.idle;
  bool _isVisible = true;
  double _elevation = 0;
  double getElevation() => _scrollController.position.extentAfter > 0.0 ? 8.0 : 0.0;

  void invalidateElevation() {
    final elevation = _page == 0 || _page == 2 || _page == 5 || _page == 6 ? getElevation() : 0.0;
    if (_elevation != elevation) {
      setState(() {
        _elevation = elevation;
      });
    }
  }

  @override
  void initState() {
    _pageController = PageController();
    _pages = <Widget>[
      WhatKindOfHomePage(pageController: _pageController,),
      HomeNicknamePage(pageController: _pageController,),
      EnterYourHomeAddressPage(pageController: _pageController,),
      HowBigIsThisHomePage(pageController: _pageController,),
      HowManyFloorsPage(pageController: _pageController,),
      WhatTypeOfPlumbingPage(pageController: _pageController,),
      AppliancesAndAmenitiesPage(pageController: _pageController,),
      HowManyPeoplePage(pageController: _pageController,),
      SetWaterComsumptionGoalPage(pageController: _pageController,),
      HomeownerInsurancePage(pageController: _pageController,),
      WaterUtilityPage(pageController: _pageController,),
    ];
    _loading = false;
    _elevation = 0;

    super.initState();
    _isVisible = true;
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
    Future.delayed(Duration(microseconds: 1500), () {
      invalidateElevation();
    });
    Future.delayed(Duration.zero, () async {
    final locationProvider = Provider.of<LocationNotifier>(context, listen: false);
    //locationProvider.value = locationProvider.value.rebuild((b) => b
    //..locationType = LocationType.singleFamilyHouse
    //..stories = 2
    //..showerBathCount = 2
    //..toiletCount = 3
    //..residenceType = ResidenceType.primary
    //);
    final userConsumer = Provider.of<UserNotifier>(context);
    locationProvider.value = Location.empty.rebuild((b) => b
    ..account = userConsumer.value.account.toBuilder()
    );
    locationProvider.invalidate();
      _nexText = S.of(context).next;
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        //statusBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        //statusBarColor: Colors.white.withOpacity(0.5), 
    ));

    //_pageController.addListener(listener);
    _pageController.addListener(() {
      currentPage(_pageController);
      final int page = currentPage(_pageController);
      if (_page != page) {
        _page = page;
        _scrollController.animateTo(0, duration: Duration(microseconds: 250), curve: Curves.fastOutSlowIn);
        _isVisible = true;
        _nexText = hasNextPage(_pageController, _pages.length) ? S.of(context).next : S.of(context).finish;
        invalidateElevation();
        print("${_page}");
        setState(() {
          print("${_page} : ${_valid}");
        });
      }
    });

  }

  String _nexText = "Next";

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
      Navigator.of(context).pop();
    }
    return false;
  }

  bool _valid = true;
  Widget navBar(BuildContext context) {
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final currentLocationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final floConsumer = Provider.of<FloNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    final flo = floConsumer.value;
    Fimber.d("${locationConsumer.value}");
    switch (_page) {
      case 0:
        _valid = locationConsumer.value.locationType != null &&
            locationConsumer.value.residenceType != null;
        break;
      case 1:
        _valid = locationConsumer.value.nickname?.isNotEmpty ?? false;
        break;
      case 2:
        _valid = (locationConsumer.value.address?.isNotEmpty ?? false) &&
            (locationConsumer.value.country?.isNotEmpty ?? false) &&
            (locationConsumer.value.city?.isNotEmpty ?? false) &&
            (locationConsumer.value.postalCode?.isNotEmpty ?? false) &&
            (or(() => isPostalCode(locationConsumer.value.postalCode, locationConsumer.value.country.toUpperCase())) ?? true) &&
            (locationConsumer.value.timezone?.isNotEmpty ?? false);
        break;
      case 3:
        _valid = locationConsumer.value.locationSize != null;
        break;
      case 4:
        _valid = (locationConsumer.value.stories != null) &&
            (locationConsumer.value.showerBathCount != null) &&
            (locationConsumer.value.toiletCount != null);
        break;
      case 5:
        _valid = (locationConsumer.value.waterShutoffKnown != null) &&
            (locationConsumer.value.waterSource != null);
        break;
      case 7:
        _valid = locationConsumer.value.occupants != null &&
            locationConsumer.value.occupants > 0;
        break;
      case 8:
        _valid = locationConsumer.value.gallonsPerDayGoal != null &&
            locationConsumer.value.gallonsPerDayGoal > 0;
        break;
      case 9:
      //_valid = locationConsumer.value.hasPastWaterDamage != null;
        break;
      default:
        _valid = true;
    }
    return Stack(
        children: <Widget>[
          Container(
            color: floLightBackground,
            height: 140,
            padding: EdgeInsets.only(bottom: 20),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                          await onWillPop();
                        },
                        icon: Icon(Icons.arrow_back_ios, color: floPrimaryColor, size: 16, ),
                        shape: CircleBorder(),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                          child: IgnorePointer(ignoring: !_valid, child: Opacity(opacity: _valid ? 1.0 : 0.3, child: TextButton(
                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                            color: floBlue2,
                            label: Text(_nexText, style: TextStyle(
                              color: Colors.white,
                            ),
                              textScaleFactor: 1.6,
                            ),
                            onPressed: () async {
                              if (hasNextPage(_pageController, _pages.length)) {
                                nextPage(_pageController);
                              } else {
                                final progressDialog = ProgressDialog(context, type: ProgressDialogType.Normal);

                                progressDialog.show();
                                flo.addLocation(locationConsumer.value.rebuild((b) => b
                                  ..account = userConsumer.value.account.toBuilder()
                                  ..isProfileComplete = true
                                ), authorization: oauthConsumer.value.authorization).then((res) {
                                  Fimber.d("${res.body}");
                                  currentLocationProvider.value = currentLocationProvider.value.rebuild((b) => b..dirty = true);
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context2) =>
                                        Theme(data: floLightThemeData, child: AlertDialog(
                                          title: Text(ReCase(S.of(context).home_added).titleCase),
                                          content: Text(S.of(context).your_home_was_added_successfully),
                                          actions: <Widget>[
                                            FlatButton(
                                              child: Text(S.of(context).continue_),
                                              onPressed: () {
                                                progressDialog.hide();
                                                Navigator.of(context2).pop();
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                        ),
                                        ),
                                  );
                                  currentLocationProvider.invalidate();
                                }).catchError((err) {
                                  Fimber.e("", ex: err);
                                  progressDialog.hide();
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context2) =>
                                          FloErrorDialog(
                                            error: let<chopper.Response, Error>(err, (it) => HttpError(it.base)) ?? err,
                                          )
                                  );
                                });
                              }
                            },
                            suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16, )),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                          )))),
                      SizedBox(width: 40),
                    ],),
                ]),
          )]);
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final child = Theme(
      data: floLightThemeData,
      child: Builder(builder: (context) => WillPopScope(
          onWillPop: onWillPop,
          child: Scaffold(
            appBar: EmptyAppBar(),
            /*
            appBar: AppBar(
            brightness: Brightness.light,
            leading: IconButton(icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (hasPreviousPage(_pageController)) {
                  previousPage(_pageController);
                } else {
                  Navigator.of(context).pop();
                }
              }
            ),
            iconTheme: IconThemeData(
              color: floBlue2,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true
          ),
          bottomNavigationBar: ExpandedSection(
            expand: _isVisible, axisAlignment: 0.0, child: BottomAppBar(child: navBar(context),
            elevation: 0,
          )),
            */
          bottomNavigationBar: BottomAppBar(child: navBar(context),
            elevation: _elevation,
          ),
          resizeToAvoidBottomPadding: true,
          body: GestureDetector(onTap: () => FocusScope.of(context).requestFocus(FocusNode()), child: SafeArea(child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return <Widget>[
                  SliverAppBar(
                    brightness: Brightness.light,
                    leading: SimpleCloseButton(icon: Icon(Icons.close),
                        onPressed: () async {
                          final res = await onCancel();
                          if (res) {
                            Navigator.of(context).pop();
                          }
                          return true;
                        }
                    ),
                    iconTheme: IconThemeData(
                      color: floBlue2,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    centerTitle: true,
                    //expandedHeight: 1.0,
                    //flexibleSpace: Container(),
                    floating: true,
                    snap: true,
                    pinned: false,
                  ),
              ];
            },
            body: Column(children: <Widget>[
              Expanded(child: PageView.builder(
                //physics: AlwaysScrollableScrollPhysics(),
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index % _pages.length];
                },
              )),
                ],
              ),
            )))
          )
      ,
    )));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class WhatKindOfHomePage extends StatefulWidget {
  final PageController pageController;

  WhatKindOfHomePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<WhatKindOfHomePage> createState() => _WhatKindOfHomePageState();
}

class _WhatKindOfHomePageState extends State<WhatKindOfHomePage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  Widget build(BuildContext context) {
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    //locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationType = b.locationType ?? LocationType.singleFamilyHouse);
    //locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = b.residenceType ?? ResidenceType.primary);
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).what_kind_of_home_is_this_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconRadio<LocationType>(
              size: wp(33),
              value: LocationType.singleFamilyHouse,
              groupValue: locationConsumer.value.locationType,
              label: S.of(context).single_family_house, iconData: Icons.home, onChanged: (value) {
                locationConsumer.value = locationConsumer.value.rebuild((b) => b
                ..locationType = value
                //..stories = 2
                ..showerBathCount = 2
                ..toiletCount = 3
                );
                locationConsumer.invalidate();
            }),
            IconRadio<LocationType>(icon: SvgPicture.asset('assets/ic_condo.svg', color: locationConsumer.value.locationType == LocationType.condo ? Colors.white : floLightButton,),
                size: wp(33),
              value: LocationType.condo,
              groupValue: locationConsumer.value.locationType,
              label: S.of(context).condo, onChanged: (value) {
                locationConsumer.value = locationConsumer.value.rebuild((b) => b
                ..locationType = value
                //..stories = 1
                ..showerBathCount = 1
                ..toiletCount = 1
                );
                locationConsumer.invalidate();
              }),
        ],),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconRadio<LocationType>(
                size: wp(33),
              value: LocationType.apartment,
              groupValue: locationConsumer.value.locationType,
              icon: SvgPicture.asset('assets/ic_apartment.svg', color: locationConsumer.value.locationType == LocationType.apartment ? Colors.white : floLightButton,),
               label: S.of(context).apartment, onChanged: (value) {
                locationConsumer.value = locationConsumer.value.rebuild((b) => b
                ..locationType = value
                //..stories = 1
                ..showerBathCount = 1
                ..toiletCount = 1
                );
                locationConsumer.invalidate();
            }),
            IconRadio<LocationType>(
                size: wp(33),
              value: LocationType.other,
              groupValue: locationConsumer.value.locationType,
              iconData: Icons.home, label: S.of(context).other_, onChanged: (value) {
                locationConsumer.value = locationConsumer.value.rebuild((b) => b
                ..locationType = value
                //..stories = 1
                ..showerBathCount = 1
                ..toiletCount = 1
                );
                locationConsumer.invalidate();
            }),
        ],),
        SizedBox(height: 30),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_do_you_use_this_home_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 30),
        KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                  baseColor: Colors.grey[300].withOpacity(0.3),
                  highlightColor: Colors.grey[100].withOpacity(0.3),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ));
            } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.residenceType?.isNotEmpty ?? false)) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data.residenceType.map((item) =>
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: RadioButton<String>(label: item.longDisplay, value: item.key, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
                        locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
                        locationConsumer.invalidate();
                      })),
                  ).toList()
              );
            } else {
              return Container();
            }
          },
          wantKeepAlive: true,
        ),
        /*
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RadioButton<String>(label: S.of(context).my_primary_residence, value: ResidenceType.PRIMARY, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
              locationConsumer.invalidate();
            }),
            SizedBox(height: 15),
            //RadioButton(label: S.of(context).i_rent_it, value: ResidenceType.rental, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
            RadioButton<String>(label: S.of(context).i_rent_it_out, value: ResidenceType.RENTAL, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
              locationConsumer.invalidate();
            }),
            SizedBox(height: 15),
            RadioButton<String>(label: S.of(context).its_my_vacation_home, value: ResidenceType.VACATION, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
              locationConsumer.invalidate();
            }),
            SizedBox(height: 15),
            RadioButton<String>(label: S.of(context).other_, value: ResidenceType.OTHER, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
              locationConsumer.invalidate();
            }),
          ],
        ),
         */
        SizedBox(height: 25),
      ],)
    ));
  }
}

class HowBigIsThisHomePage extends StatefulWidget {
  final PageController pageController;

  HowBigIsThisHomePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<HowBigIsThisHomePage> createState() => _HowBigIsThisHomePageState();
}

class _HowBigIsThisHomePageState extends State<HowBigIsThisHomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    // For test unitSystem by country
    userConsumer.value = userConsumer.value.rebuild((b) => b..unitSystem = b.unitSystem ?? (locationConsumer.value.country.toLowerCase() == "us" ? UnitSystem.imperialUs : UnitSystem.metricBar));
    //locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = b.locationSize ?? LocationSize.gt_700_ft_lte_1000_ft);

    final isMetric = userConsumer.value.unitSystem != UnitSystem.imperialUs;
    final unit = !isMetric ? S.of(context).square_feet : S.of(context).square_meters;
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_big_is_this_home_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 30),
        KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                  baseColor: Colors.grey[300].withOpacity(0.3),
                  highlightColor: Colors.grey[100].withOpacity(0.3),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ));
            } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.locationSize?.isNotEmpty ?? false)) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data.locationSize.map((item) =>
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                      //RadioButton<String>(label: "${item.longDisplay} ${unit}",
                      RadioButton<String>(label: "${item.longDisplay} ${S.of(context).square_feet}",
                          value: item.key, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
                            locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
                            locationConsumer.invalidate();
                          }),
                      ),
                  ).toList()
              );
            } else {
              // TODO: implement retry snackbar
              return Container();
            }
          },
        ),
        SizedBox(height: 15),
        /*
        RadioButton<String>(label: "${feetUnit ? S.of(context).less_than_700 : S.of(context).less_than_70} ${LocationSize.LTE_700 == locationConsumer.value.locationSize ? unit : ""}",
          value: LocationSize.LTE_700, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton<String>(label: "${feetUnit ? S.of(context).s_700_to_1000 : S.of(context).s_70_to_100} ${LocationSize.GT_700_FT_LTE_1000_FT == locationConsumer.value.locationSize ? unit : ""}",
         value: LocationSize.GT_700_FT_LTE_1000_FT, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton<String>(label: "${feetUnit ? S.of(context).s_1001_to_2000 : S.of(context).s_101_to_200} ${LocationSize.GT_1000_FT_LTE_2000_FT == locationConsumer.value.locationSize ? unit : ""}",
         value: LocationSize.GT_1000_FT_LTE_2000_FT, groupValue: locationConsumer.value.locationSize , onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton<String>(label: "${feetUnit ? S.of(context).s_2001_to_4000 : S.of(context).s_201_to_400} ${LocationSize.GT_2000_FT_LTE_4000_FT == locationConsumer.value.locationSize ? unit : ""}",
         value: LocationSize.GT_2000_FT_LTE_4000_FT, groupValue: locationConsumer.value.locationSize , onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton<String>(label: "${feetUnit ? S.of(context).more_than_4000 : S.of(context).more_than_400} ${LocationSize.GT_4000_FT == locationConsumer.value.locationSize ? unit : ""}",
          value: LocationSize.GT_4000_FT, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        },),
        SizedBox(height: 25),
        */
    ],)
    )
    );
  }
}

class WhatTypeOfPlumbingPage extends StatefulWidget {
  final PageController pageController;

  WhatTypeOfPlumbingPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<WhatTypeOfPlumbingPage> createState() => _WhatTypeOfPlumbingPageState();
}

class _WhatTypeOfPlumbingPageState extends State<WhatTypeOfPlumbingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final locationProvider = Provider.of<LocationNotifier>(context, listen: false);
    //locationProvider.value = locationProvider.value.rebuild((b) => b
    //..waterShutoffKnown = b.waterShutoffKnown ?? Answer.unsure
    //..waterSource = b.waterSource ?? WaterSource.utility
    //);
    //locationProvider.invalidate();

    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).what_type_of_plumbing_do_you_have_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 30),
        KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                    baseColor: Colors.grey[300].withOpacity(0.3),
                    highlightColor: Colors.grey[100].withOpacity(0.3),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ));
              } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.pipeType?.isNotEmpty ?? false)) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data.pipeType.map((item) =>
                        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                          RadioButton<String>(label: item.longDisplay, value: item.key, groupValue: locationConsumer.value.plumbingType, onChanged: (value) {
                              locationConsumer.value = locationConsumer.value.rebuild((b) => b..plumbingType = value);
                              locationConsumer.invalidate();
                            }),
                        ),
                    ).toList()
                );
              } else {
                return Container();
              }
            },
        ),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).do_you_know_from_where_to_shutoff_the_water_to_your_home_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 30),
        RadioButton(label: S.of(context).yes, value: Answer.yes, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).no, value: Answer.no, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).not_sure, value: Answer.unsure, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 30),
        SizedBox(width: double.infinity, child: Text(S.of(context).what_is_the_source_of_your_water_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 15),
        RadioButton<String>(label: S.of(context).city_water, value: WaterSource.UTILITY, groupValue: locationConsumer.value.waterSource, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterSource = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton<String>(label: S.of(context).well, value: WaterSource.WELL, groupValue: locationConsumer.value.waterSource, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterSource = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 25),
    ],))
    );
  }
}

class HomeownerInsurancePage extends StatefulWidget {
  final PageController pageController;

  HomeownerInsurancePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<HomeownerInsurancePage> createState() => _HomeownerInsurancePageState();
}

class _HomeownerInsurancePageState extends State<HomeownerInsurancePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    //locationConsumer.value = locationConsumer.value.rebuild((b) => b..hasPastWaterDamage = b.hasPastWaterDamage ?? false);
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(10)), child: Form(child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).homeowners_insurance,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).please_let_us_know_who_provides_your_homeowners_insurance_for,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        OutlineTextFormField(
          initialValue: locationConsumer.value.homeownersInsurance,
          textCapitalization: TextCapitalization.sentences,
          onUnfocus: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..homeownersInsurance = text.trim());
            locationConsumer.invalidate();
          },
          onFieldSubmitted: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..homeownersInsurance = text.trim());
            locationConsumer.invalidate();
          },
          labelText: S.of(context).insurance
        ),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Text(S.of(context).have_you_had_water_damage_in_the_past_q,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 25),
        RadioButton(label: S.of(context).yes_i_have, value: true, groupValue: locationConsumer.value.hasPastWaterDamage, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..hasPastWaterDamage = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).no_i_havent, value: false, groupValue: locationConsumer.value.hasPastWaterDamage, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..hasPastWaterDamage = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 25),
            ])),
        IgnorePointer(
          ignoring: locationConsumer.value.hasPastWaterDamage != null && !locationConsumer.value.hasPastWaterDamage && locationConsumer.value.country.toLowerCase() != "us",
          child: ExpandedSection(
            expand: locationConsumer.value.hasPastWaterDamage != null && locationConsumer.value.hasPastWaterDamage && locationConsumer.value.country.toLowerCase() == "us", child: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            opacity: locationConsumer.value.hasPastWaterDamage != null && locationConsumer.value.hasPastWaterDamage && locationConsumer.value.country.toLowerCase() == "us" ? 1.0 : 0.5, child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
        SizedBox(width: double.infinity, child: Text(S.of(context).how_much_was_the_claim_q,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 25),
        RadioButton(label: S.of(context).s_0_10000, value: PastWaterDamageClaimAmount.lte_10k_usd, groupValue: locationConsumer.value.pastWaterDamageClaimAmount, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..pastWaterDamageClaimAmount = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).s_10001_50000, value: PastWaterDamageClaimAmount.gt_10k_usd_lte_50k_usd, groupValue: locationConsumer.value.pastWaterDamageClaimAmount, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..pastWaterDamageClaimAmount = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).s_50000_100000, value: PastWaterDamageClaimAmount.gt_50k_usd_lte_100k_usd, groupValue: locationConsumer.value.pastWaterDamageClaimAmount, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..pastWaterDamageClaimAmount = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 15),
        RadioButton(label: S.of(context).s_100000_plus, value: PastWaterDamageClaimAmount.gt_100K_usd, groupValue: locationConsumer.value.pastWaterDamageClaimAmount, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..pastWaterDamageClaimAmount = value);
          locationConsumer.invalidate();
        }),
        SizedBox(height: 25),
            ]))),
        )),
    ],)))
    );
  }
}

class HomeNicknamePage extends StatefulWidget {
  final PageController pageController;

  HomeNicknamePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<HomeNicknamePage> createState() => _HomeNicknamePageState();
}

class _HomeNicknamePageState extends State<HomeNicknamePage> {
  TextEditingController textController1 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final locationConsumer = Provider.of<LocationNotifier>(context);
    textController1.text = locationConsumer.value.nickname;
    return Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).give_your_home_a_nickname,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).enter_a_nickname_for_this_location,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        OutlineTextFormField(
        //TextFormField(
          initialValue: locationConsumer.value.nickname,
          //controller: textController1,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 24,
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).nickname_not_empty;
            }
            if (locationsConsumer.value.any((location) => location.nickname == text)) {
              return S.of(context).nickname_already_in_use;
            }
            return null;
          },
          onChanged: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..nickname = text.trim());
          },
          onFieldSubmitted: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..nickname = text.trim());
            locationConsumer.invalidate();
          },
          labelText: S.of(context).nickname,
          hintText: S.of(context).ex_the_main_house,
        ),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).ex_the_main_house,
          style: Theme.of(context).textTheme.body1,
        )),
    ],)
    );
  }
}

class EnterYourHomeAddressPage extends StatefulWidget {
  final PageController pageController;

  EnterYourHomeAddressPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<EnterYourHomeAddressPage> createState() => _EnterYourHomeAddressPageState();
}

class _EnterYourHomeAddressPageState extends State<EnterYourHomeAddressPage> {
  FocusNode focus1 = FocusNode();
  FocusNode focus2 = FocusNode();
  FocusNode focus3 = FocusNode();
  FocusNode focus4 = FocusNode();
  FocusNode focus5 = FocusNode();
  FocusNode focus6 = FocusNode();
  FocusNode focus7 = FocusNode();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final floConsumer = Provider.of<FloNotifier>(context);
      final flo = floConsumer.value;
      final locationConsumer = Provider.of<LocationNotifier>(context);
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
      final localesConsumer = Provider.of<LocalesNotifier>(context);
      try {
        final userRes = await flo.getUser(oauthConsumer.value.userId, authorization: oauthConsumer.value.authorization);
        userProvider.value = userRes.body;
        //userProvider.invalidate();
      } catch (err) {
        Fimber.e("", ex: err);
      }
      /*
        flo.locales().then((res) {
          localesConsumer.value = res.body;
          print(localesConsumer.value);
          localesConsumer.invalidate();
        }).catchError((err) => Fimber.e("", ex: err));
      */
      try {
        final countries = (await flo.countries());
        localesConsumer.value = Locales((b) => b..locales = ListBuilder(countries));
        //Fimber.d("localesConsumer.value.locales: ${localesConsumer.value.locales}");
        final country = locationConsumer.value.country ?? Localizations.localeOf(context).countryCode;
        if (localesConsumer.value.locales.any((it) => it.locale == country.toLowerCase())) {
          locationConsumer.value = locationConsumer.value.rebuild(((b) => b..country = country.toLowerCase()));
        }
        if (locationConsumer.value.country?.isNotEmpty ?? false) {
            flo.regions(locationConsumer.value.country.toLowerCase()).then((res) {
              //Fimber.d("${res.body}");
              setState(() {
                _states = res.toList() ?? [];
              });
            }).catchError((err) {
              Fimber.e("$err", ex: err);
              setState(() {
                _states = [];
              });
            });
            flo.timezones(locationConsumer.value.country.toLowerCase()).then((timezones) {
              //FloLocale.Locale locale = res.body;
              setState(() {
                _timeZones = timezones.toList() ?? [];
              });
            }).catchError((err) {
              Fimber.e("$err", ex: err);
              setState(() {
                _timeZones = [];
              });
            });
        }
        localesConsumer.invalidate();
      } catch (err) {
        Fimber.e("", ex: err);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Item> _states = [];
  List<TimeZone> _timeZones = [];

  @override
  Widget build(BuildContext context) {
    Fimber.d("build");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final localesConsumer = Provider.of<LocalesNotifier>(context);
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;

    //Fimber.d("timezone: ${DateTime.now().timeZoneName}");
    /*
    flo.getStateprovinces(locationConsumer.value.country).then((res) {
      setState(() {
        _states = res.body.toList() ?? [];
      });
    }).catchError((err) => Fimber.e("", ex: err));
    */

    var timezone = locationConsumer.value.timezone;
    final localTimeZoneId = timeZoneIds[DateTime.now().timeZoneName];
    if ((timezone?.isEmpty ?? true) && localTimeZoneId != null) {
      //timezone = timezone ?? _timeZones.firstWhere((timezone) => timezone.tz == localTimeZoneId, orElse: () => TimeZone.empty).tz;
      locationConsumer.value = locationConsumer.value.rebuild((b) => b
        //..timezone = b.timezone ?? _timeZones.firstWhere((timezone) => timezone.tz == localTimeZoneId, orElse: () => TimeZone.empty).tz
        ..timezone = _timeZones.firstWhere((timezone) => timezone.tz == localTimeZoneId, orElse: () => TimeZone.empty).tz
      );
      timezone = locationConsumer.value.timezone;
    }
    final country = locationConsumer.value.country ?? Localizations.localeOf(context).countryCode;
    //Fimber.d("country: $country");
    if (localesConsumer.value.locales.any((it) => it.locale == country.toLowerCase())) {
      locationConsumer.value = locationConsumer.value.rebuild(((b) => b..country = country.toLowerCase()));
    }

    //Fimber.d("localTimeZoneId: ${localTimeZoneId}");
    //Fimber.d("_timeZones: ${_timeZones}");
    //Fimber.d("timezone: ${locationConsumer.value.timezone}");
    //Fimber.d("locales: ${localesConsumer.value.locales}");
    //Fimber.d("locationConsumer.value.country: ${locationConsumer.value.country}");

    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).enter_your_homes_address,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 25),
        OutlineTextFormField(labelText: S.of(context).address,
          initialValue: locationConsumer.value.address,
          textCapitalization: TextCapitalization.sentences,
          focusNode: focus1,
          textInputAction: TextInputAction.next,
          maxLength: 256,
          counterText: "",
          onFieldSubmitted: (text) {
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..address = text.trim());
            //locationConsumer.invalidate();
            FocusScope.of(context).requestFocus(focus2);
          },
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).address_empty;
            }
            return null;
          },
          onUnfocus: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..address = text.trim());
            locationConsumer.invalidate();
          },
          onChanged: (text) {
          },
        ),
        SizedBox(height: 15),
        OutlineTextFormField(labelText: S.of(context).unit_apt_suite,
          initialValue: locationConsumer.value.address2,
          textCapitalization: TextCapitalization.sentences,
          focusNode: focus2,
          //textInputAction: TextInputAction.unspecified,
          maxLength: 256,
          counterText: "",
          onUnfocus: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..address2 = text.trim());
            locationConsumer.invalidate();
          },
          onFieldSubmitted: (text) {
            //FocusScope.of(context).requestFocus(focus4);
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..address2 = text.trim());
            //locationConsumer.invalidate();
          },
          onChanged: (text) {
            Fimber.d("${text}");
          },
        ),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: SimplePickerDropdown<FloLocale.Locale>(
                initialValue: FloLocale.Locale((b) => b
                ..locale = locationConsumer.value.country.toLowerCase()
                ..name = ""),
                selection: (locale) => locale.locale.toLowerCase(),
                hint: Text(S.of(context).country, textAlign: TextAlign.center),
                items: sort(localesConsumer.value.locales.toList(), (a, b) => a.locale.compareTo(b.locale)),
                builder: (locale) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text("${locale.name}"),
                  );
                },
                onValuePicked: (locale) {
                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                  ..country = locale.locale
                  //..state = b.country == locale.locale ? b.state : null
                  ..state = null
                  //..timezone = b.country == locale.locale ? b.timezone : null
                  ..timezone = null
                  );
                  locationConsumer.invalidate();
                  //Fimber.d("$locale");
                  flo.regions(locationConsumer.value.country.toLowerCase()).then((res) {
                    //Fimber.d("${res.body}");
                    setState(() {
                      _states = res.toList() ?? [];
                    });
                  }).catchError((err) {
                    Fimber.e("$err", ex: err);
                    setState(() {
                      _states = [];
                    });
                  });
                  flo.timezones(locationConsumer.value.country.toLowerCase()).then((timezones) {
                    //FloLocale.Locale locale = res.body;
                    setState(() {
                      _timeZones = timezones.toList() ?? [];
                    });
                  }).catchError((err) {
                    Fimber.e("$err", ex: err);
                    setState(() {
                      _timeZones = [];
                    });
                  });
                  //FocusScope.of(context).requestFocus(focus4);
                },
              ),
        ),
        SizedBox(height: 15),
        OutlineTextFormField(labelText: S.of(context).city,
          initialValue: locationConsumer.value.city,
          textCapitalization: TextCapitalization.sentences,
          focusNode: focus4,
          textInputAction: TextInputAction.next,
          onUnfocus: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..city = text.trim());
            locationConsumer.invalidate();
          },
          onFieldSubmitted: (text) {
            FocusScope.of(context).requestFocus(_states.isNotEmpty ? focus5 : focus6);
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..city = text.trim());
            //locationConsumer.invalidate();
          },
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).should_not_be_empty;
            }
            return null;
          },
          onChanged: (text) {
            Fimber.d("${text}");
          },
        ),
        SizedBox(height: 15),
        _states.isNotEmpty ? Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: SimplePickerDropdown<Item>(
                initialValue: Item((b) => b
                ..key = locationConsumer.value.state ?? ""
                ..shortDisplay = ""
                ..longDisplay = ""
                ),
                selection: (it) => it.key,
                hint: Text(S.of(context).state, textAlign: TextAlign.center),
                items: $(_states).sortedBy((it) => it.longDisplay ?? ""),
                builder: (it) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text("${it.longDisplay}"),
                  );
                },
                onValuePicked: (it) {
                  locationConsumer.value = locationConsumer.value.rebuild((b) => b..state = it.key);
                  //Fimber.d("$state");
                  locationConsumer.invalidate();
                },
              ),
        ) :
        OutlineTextFormField(labelText: S.of(context).state,
          initialValue: locationConsumer.value.state,
          textCapitalization: TextCapitalization.sentences,
          focusNode: focus5,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..state = text.trim());
            locationConsumer.invalidate();
            FocusScope.of(context).requestFocus(focus6);
          },
          onChanged: (text) {
          },
        ),
        SizedBox(height: 15),
        OutlineTextFormField(labelText: S.of(context).zip_code,
          initialValue: locationConsumer.value.postalCode,
          focusNode: focus6,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (text) {
            FocusScope.of(context).requestFocus(focus7);
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..postalCode = text.trim());
            //locationConsumer.invalidate();
          },
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).should_not_be_empty;
            }
            if (!isPostalCode(text, locationConsumer.value.country.toUpperCase(), orElse: () => true)) {
              return S.of(context).invalid;
            }
            return null;
          },
          onChanged: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..postalCode = text.trim());
            locationConsumer.invalidate();
          },
        ),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: SimplePickerDropdown<TimeZone>(
                //initialValue: _timeZones.firstWhere((timeZone) => timeZone.tz == locationConsumer.value.timezone),
                initialValue: _timeZones.firstWhere((timeZone) {
                  //Fimber.d("init: $timeZone");
                  //Fimber.d("for: ${locationConsumer.value.timezone}");
                  return timeZone.tz == timezone;
                }, orElse: () => null),
                hint: Text(S.of(context).timezone, textAlign: TextAlign.center),
                selection: (timeZone) => timeZone.tz,
                items: _timeZones,
                builder: (timeZone) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text("${timeZone.display}"),
                  );
                },
                onValuePicked: (timeZone) {
                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                  ..timezone = timeZone?.tz
                  );
                  Fimber.d("onChanged: $timeZone");
                  locationConsumer.invalidate();
                },
              ),
        ),
        SizedBox(height: 25),
    ],))));
    });
  }
}

final timeZoneIds = {
      "EDT": "US/Eastern",
      "HDT": "US/Aleutian",
      "CDT": "US/Central",
      "MDT": "US/Mountain",
      "PDT": "US/Pacific",
      "AKDT": "US/Alaska",
      "MST": "US/Arizona",
      "HST": "US/Hawaii",
      "SST": "US/Samoa",
      "AST": "America/Puerto_Rico",
      "ChST": "Pacific/Guam",
    };

class HowManyFloorsPage extends StatefulWidget {
  final PageController pageController;

  HowManyFloorsPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<HowManyFloorsPage> createState() => _HowManyFloorsPageState();
}

class _HowManyFloorsPageState extends State<HowManyFloorsPage> {
  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    locationConsumer.value = locationConsumer.value.rebuild((b) => b
    //..stories = b.stories ?? 1
    ..showerBathCount = b.showerBathCount ?? 1
    ..toiletCount = b.toiletCount ?? 1
    );

    final double bathrooms = getSimpleBathrooms(locationConsumer.value.showerBathCount, locationConsumer.value.toiletCount);
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_many_floors_are_there_q,
         style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 30),
        Wrap(children: <Widget>[
          RadioButton(label: S.of(context).s_1, value: 1, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioButton(label: S.of(context).s_2, value: 2, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioButton(label: S.of(context).s_3, value: 3, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioButton(label: S.of(context).s_4_plus, value: 4, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          ],
          spacing: 10,
          runSpacing: 10,
        ),
        SizedBox(height: 30),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_many_bathrooms_does_this_home_have_q, style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 45),
        AlwaysSlider(
          min: 0.0,
          max: 10.0,
          divisions: 20,
          value: bathrooms,
          label: '${NumberFormat("#.#").format(bathrooms)} bathrooms',
          onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b
            ..showerBathCount = value.floor()
            ..toiletCount = value.round()
            );
            locationConsumer.invalidate();
          },
          semanticFormatterCallback: (double newValue) {
              return '${newValue} bathrooms';
          },
        ),
        SizedBox(height: 25),
    ],))));
    });
  }
}

class AppliancesAndAmenitiesPage extends StatefulWidget {
  final PageController pageController;

  AppliancesAndAmenitiesPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<AppliancesAndAmenitiesPage> createState() => _AppliancesAndAmenitiesPageState();
}

class _AppliancesAndAmenitiesPageState extends State<AppliancesAndAmenitiesPage> {

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context).value;
      final oauth = Provider.of<OauthTokenNotifier>(context).value;

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() {});
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    locationConsumer.value = locationConsumer.value.rebuild((b) => b
    ..indoorAmenities = b.indoorAmenities ?? []
    ..outdoorAmenities = b.outdoorAmenities ?? []
    ..plumbingAppliances = b.plumbingAppliances ?? []
    );
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).appliances_amenities,
          style: Theme.of(context).textTheme.title,)),
        SizedBox(height: 10),
        SizedBox(width: double.infinity, child: Text(S.of(context).which_do_you_have_in_this_home_q,
          style: Theme.of(context).textTheme.body1,)),
        SizedBox(height: 30),
        SizedBox(width: double.infinity, child: Text(S.of(context).indoors,
          style: Theme.of(context).textTheme.subtitle,)),
        SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(floCardRadiusDimen),
          ),
          margin: EdgeInsets.all(0),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child:
            KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                      baseColor: Colors.grey[300].withOpacity(0.3),
                      highlightColor: Colors.grey[100].withOpacity(0.3),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ));
                } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.fixtureIndoor?.isNotEmpty ?? false)) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data.fixtureIndoor.map((item) =>
                          SimpleCheckboxListTile(
                            title: Text(item.longDisplay),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: locationConsumer.value.indoorAmenities.contains(item.key),
                            onChanged: (checked) {
                              locationConsumer.value = locationConsumer.value.rebuild((b) {
                                b.indoorAmenities.add(item.key);
                                b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                                    .toSet().toList());
                              });
                              locationConsumer.invalidate();
                            },
                          ),
                      ).toList()
                  );
                } else {
                  return Container();
                }
              },
            ),
            /*
            Column(
              children: <Widget>[
                SimpleCheckboxListTile(
                  title: Text(S.of(context).bathtub),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.bathtub),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.bathtub.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).hot_tub),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.hottub),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.hottub.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).washer_dryer),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.washingMachine),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.washingMachine.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).dishwasher),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.dishwasher),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.dishwasher.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).refrigerator_with_ice_maker),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.iceMaker),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.iceMaker.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
              ],
            ),
            */
          ),
        ),
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).outdoors,
          style: Theme.of(context).textTheme.subtitle,)),
        SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(floCardRadiusDimen),
          ),
          margin: EdgeInsets.all(0),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child:
            KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                      baseColor: Colors.grey[300].withOpacity(0.3),
                      highlightColor: Colors.grey[100].withOpacity(0.3),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ));
                } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.fixtureOutdoor?.isNotEmpty ?? false)) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data.fixtureOutdoor.map((item) =>
                          SimpleCheckboxListTile(
                            title: Text(item.longDisplay),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: locationConsumer.value.outdoorAmenities.contains(item.key),
                            onChanged: (checked) {
                              locationConsumer.value = locationConsumer.value.rebuild((b) {
                                b.outdoorAmenities.add(item.key);
                                b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build()
                                    .toSet().toList());
                              });
                              locationConsumer.invalidate();
                            },
                          ),
                      ).toList()
                  );
                } else {
                  return Container();
                }
              },
              wantKeepAlive: true,
            ),
    /*
            Column(
              children: <Widget>[
                SimpleCheckboxListTile(
                  title: Text(S.of(context).swimming_pool_with_auto_pool_filler,
                    //style: true ? DefaultTextStyle.of(context).style : Theme.of(context).textTheme.subhead.copyWith(color: Colors.black.withOpacity(0.5)),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.outdoorAmenities.contains(Amenities.poolWithAutoPoolFilter),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.outdoorAmenities.add(Amenities.poolWithAutoPoolFilter.toString());
                      b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).regular_swimming_pool),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.outdoorAmenities.contains(Amenities.pool),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.outdoorAmenities.add(Amenities.pool.toString());
                      b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).hot_tub),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.outdoorAmenities.contains(Amenities.hottub),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.outdoorAmenities.add(Amenities.hottub.toString());
                      b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).fountain),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.indoorAmenities.contains(Amenities.fountain),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.indoorAmenities.add(Amenities.fountain.toString());
                      b..indoorAmenities = ListBuilder(b.indoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).pond),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.outdoorAmenities.contains(Amenities.pond),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.outdoorAmenities.add(Amenities.pond.toString());
                      b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
              ],
            ),
            */
          ),
        ),
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).plumbing_appliances,
          style: Theme.of(context).textTheme.subtitle,)),
        SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(floCardRadiusDimen),
          ),
          margin: EdgeInsets.all(0),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child:
            KeepAliveFutureBuilder<PreferenceCategory>(future: _preferenceCategoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                      baseColor: Colors.grey[300].withOpacity(0.3),
                      highlightColor: Colors.grey[100].withOpacity(0.3),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ));
                } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.homeAppliance?.isNotEmpty ?? false)) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data.homeAppliance.map((item) =>
                          SimpleCheckboxListTile(
                            title: Text(item.longDisplay),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: locationConsumer.value.plumbingAppliances.contains(item.key),
                            onChanged: (checked) {
                              locationConsumer.value = locationConsumer.value.rebuild((b) {
                                b.plumbingAppliances.add(item.key);
                                b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                                    .toSet().toList());
                              });
                              locationConsumer.invalidate();
                            },
                          ),
                      ).toList()
                  );
                } else {
                  return Container();
                }
              },
              wantKeepAlive: true,
            ),
                /*
            Column(
              children: <Widget>[
                SimpleCheckboxListTile(
                  title: Text(S.of(context).tankless_water_heater,
                    //style: true ? DefaultTextStyle.of(context).style : Theme.of(context).textTheme.subhead.copyWith(color: Colors.black.withOpacity(0.5)),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.tanklessWaterHeater),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.tanklessWaterHeater.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).expansion_tank),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.expansionTank),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.expansionTank.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).whole_home_filtration_system),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.wholeHomeFiltration),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.wholeHomeFiltration.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).whole_home_humidifer),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.wholeHomeHumidifer),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.wholeHomeHumidifer.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).recirculation_pump),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.recirculationPump),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.recirculationPump.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).reverse_osmosis),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.reverseOsmosis),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.reverseOsmosis.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).water_softener),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.waterSoftener),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.waterSoftener.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
                SimpleCheckboxListTile(
                  title: Text(S.of(context).pressure_reducing_valve),
                  controlAffinity: ListTileControlAffinity.leading,
                  value: locationConsumer.value.plumbingAppliances.contains(Amenities.pressureReducingValve),
                  onChanged: (checked) {
                    locationConsumer.value = locationConsumer.value.rebuild((b) {
                      b.plumbingAppliances.add(Amenities.pressureReducingValve.toString());
                      b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build()
                      .toSet().toList());
                    });
                    locationConsumer.invalidate();
                  },
                ),
              ],
            ),

                 */
          ),
        ),
        SizedBox(height: 25),
    ],))
    );
  }
}

class HowManyPeoplePage extends StatefulWidget {
  final PageController pageController;

  HowManyPeoplePage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<HowManyPeoplePage> createState() => _HowManyPeoplePageState();
}

class _HowManyPeoplePageState extends State<HowManyPeoplePage> {
  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);
    locationConsumer.value = locationConsumer.value.rebuild((b) => b ..occupants = b.occupants ?? 3);
    //locationConsumer.invalidate();
    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_many_people_live_in_this_home_q,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 20),
        Wrap(children: <Widget>[
          ToggleButton(label: S.of(context).minus, togglable: false,
            inactiveTextColor: floBlue,
            onTap: (_) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..occupants = max(b.occupants - 1, 1));
              locationConsumer.invalidate();
            },
          ),
          ToggleButton(label: "${locationConsumer.value.occupants}", togglable: false,
            inactiveTextColor: floBlue,
          ),
          ToggleButton(label: S.of(context).plus, togglable: false,
            inactiveTextColor: floBlue,
            onTap: (_) {
              locationConsumer.value = locationConsumer.value.rebuild((b) => b..occupants = min(b.occupants + 1, 20));
              locationConsumer.invalidate();
            },
          ),
          ],
          spacing: 10,
        ),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).please_enter_avg_monthly_occupants,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
    ],))));
    });
  }
}

class SetWaterComsumptionGoalPage extends StatefulWidget {
  final PageController pageController;

  SetWaterComsumptionGoalPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<SetWaterComsumptionGoalPage> createState() => _SetWaterComsumptionGoalPageState();
}

class _SetWaterComsumptionGoalPageState extends State<SetWaterComsumptionGoalPage> with AfterLayoutMixin<SetWaterComsumptionGoalPage> {
  FocusNode focus1 = FocusNode();
  FocusNode focus2 = FocusNode();
  TextEditingController textController1 = TextEditingController();
  TextEditingController textController2 = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    final locationConsumer = Provider.of<LocationNotifier>(context);
    final locationProvder = Provider.of<LocationNotifier>(context, listen: false);
    final userConsumer = Provider.of<UserNotifier>(context);
    final isMetricKpa = userConsumer.value.unitSystem == UnitSystem.metricKpa;
    locationConsumer.value = locationConsumer.value.rebuild((b) => b
    ..occupants = b.occupants ?? 1);
    _volumePerDayGoal = _volumePerPersonPerDayGoal * locationConsumer.value.occupants;

    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).set_water_consumption_goal,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(
          isMetricKpa ? "Set a target for daily water use. People use 300-400 liters per day on average"
                      : "Set a target for daily water use. People use 80-100 gallons per day on average", // FIXME
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        SizedBox(width: double.infinity, child: Text(S.of(context).per_person,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        OutlineTextFormField(
          focusNode: focus1,
          controller: textController1,
          initialValue: "${_volumePerPersonPerDayGoal}",
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          maxLength: 5,
          onUnfocus: (text) {
            _volumePerPersonPerDayGoal = int.tryParse(text);
            _volumePerDayGoal =  max(min(_volumePerPersonPerDayGoal * locationConsumer.value.occupants ?? 0, 99999), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationConsumer.value.occupants;
            locationProvder.value = locationProvder.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            setState(() {
              textController1.text = "${_volumePerPersonPerDayGoal ?? ""}";
              textController2.text = "${_volumePerDayGoal ?? ""}";
            });
            locationConsumer.invalidate();
          },
          onFieldSubmitted: (text) {
            FocusScope.of(context).requestFocus(focus2);
          },
          onChanged: (text) {
            _volumePerDayGoal = max(min((int.tryParse(text) ?? 0) * locationConsumer.value.occupants, 99999), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationConsumer.value.occupants;
            locationProvder.value = locationProvder.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );

            if (!focus2.hasFocus) {
              textController2.text = "${_volumePerDayGoal}";
            }
          },
          labelText: isMetricKpa ? S.of(context).liters_per_day: S.of(context).gal_per_day,
        ),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).or,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 15),
        Row(children: <Widget>[
          Text(S.of(context).total,
            style: Theme.of(context).textTheme.title,
          ),
        SizedBox(width: 15),
          Text("${locationConsumer.value.occupants} ${S.of(context).people}",
            style: Theme.of(context).textTheme.body1,
          ),
        ]),
        SizedBox(height: 15),
        OutlineTextFormField(
          focusNode: focus2,
          initialValue: "${_volumePerDayGoal}",
          controller: textController2,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          maxLength: 5,
          onFieldSubmitted: (text) {
            _volumePerDayGoal = max(min(int.tryParse(text) ?? 0, 99999), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationConsumer.value.occupants;
            locationProvder.value = locationProvder.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            setState(() {
              textController1.text = "${_volumePerPersonPerDayGoal ?? ""}";
              textController2.text = "${_volumePerDayGoal ?? ""}";
             });
            locationConsumer.invalidate();
          },
          labelText: isMetricKpa ? S.of(context).liters_per_day: S.of(context).gal_per_day,
          onChanged: (text) {
            _volumePerDayGoal = max(min(int.tryParse(text) ?? 0, 99999), 1);
            _volumePerPersonPerDayGoal = _volumePerDayGoal ~/ locationConsumer.value.occupants;
            locationProvder.value = locationProvder.value.rebuild((b) => b
              ..gallonsPerDayGoal = isMetricKpa ? toGallons(_volumePerDayGoal.toDouble()) : _volumePerDayGoal.toDouble()
            );
            if (!focus1.hasFocus) {
              textController1.text = "${_volumePerPersonPerDayGoal ?? ""}";
            }
          },
        ),
        SizedBox(height: 15),
        SizedBox(height: 25),
    ],))));
    });
  }

  int _volumePerPersonPerDayGoal = 0;
  int _volumePerDayGoal = 0;

  @override
  void afterFirstLayout(BuildContext context) {
    final locationConsumer = Provider.of<LocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final isMetricKpa = userConsumer.value.unitSystem == UnitSystem.metricKpa;
    //locationConsumer.invalidate();
    setState(() {
      _volumePerPersonPerDayGoal = isMetricKpa ? 350 : 80;
      _volumePerDayGoal = _volumePerPersonPerDayGoal * locationConsumer.value.occupants;
      textController1.text = "${_volumePerPersonPerDayGoal.toInt()}";
      textController2.text = "${_volumePerDayGoal.toInt()}";
    });
  }
}

class WaterUtilityPage extends StatefulWidget {
  final PageController pageController;

  WaterUtilityPage({
    Key key,
    @required
    this.pageController}) : super(key: key);

  State<WaterUtilityPage> createState() => _WaterUtilityPageState();
}

class _WaterUtilityPageState extends State<WaterUtilityPage> {
  @override
  Widget build(BuildContext context) {
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<LocationNotifier>(context);

    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints viewportConstraints) { return SingleChildScrollView(child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight,
          ), child: Padding(padding: EdgeInsets.symmetric(horizontal: wp(15)), child: Column(
                        mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).water_utility,
          style: Theme.of(context).textTheme.title,
        )),
        SizedBox(height: 15),
        SizedBox(width: double.infinity, child: Text(S.of(context).please_let_us_know_who_your_water_utility_is_for,
          style: Theme.of(context).textTheme.body1,
        )),
        SizedBox(height: 25),
        OutlineTextFormField(
          initialValue: locationConsumer.value.waterUtility?.toString() ?? "",
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          onUnfocus: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterUtility = text.isNotEmpty ? text : null);
          },
          onChanged: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterUtility = text.isNotEmpty ? text : null);
          },
          onFieldSubmitted: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterUtility = text.isNotEmpty ? text : null);
            locationConsumer.invalidate();
          },
          labelText: S.of(context).water_utility,
        ),
        SizedBox(height: 25),
    ],))));
    });
  }
}

double getSimpleBathrooms(int bathrooms, int toilets) {
  return (toilets > bathrooms) ? bathrooms + 0.5 : bathrooms.toDouble();
}
