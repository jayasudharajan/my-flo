import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:shimmer/shimmer.dart';
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'add_location_screen.dart';
import 'home_settings_page.dart';
import 'model/amenity.dart';
import 'model/flo.dart';
import 'model/item.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/locales.dart';
import 'model/location.dart';
import 'model/location_size.dart';
import 'model/location_type.dart';
import 'model/plumbing_type.dart';
import 'model/preference_category.dart';
import 'model/residence_type.dart';
import 'model/timezone.dart';
import 'model/unit_system.dart';
import 'model/water_source.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';

class LocationProfileScreen extends StatefulWidget {
  LocationProfileScreen({Key key}) : super(key: key);

  State<LocationProfileScreen> createState() => _LocationProfileScreenState();
}

class _LocationProfileScreenState extends State<LocationProfileScreen> with AfterLayoutMixin<LocationProfileScreen> {

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    _location = locationProvider.value;
  }

  Location _location;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final floConsumer = Provider.of<FloNotifier>(context);
      final flo = floConsumer.value;
      final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
      final oauth = oauthConsumer.value;
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
        flo.countries().then((it) {
          localesConsumer.value = Locales((b) => b..locales = ListBuilder(it));
          print(localesConsumer.value);
          localesConsumer.invalidate();
        }).catchError((err) => Fimber.e("", ex: err));
        if (locationConsumer.value.country?.isNotEmpty ?? false) {
          try {
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
          } catch (err) {
          }
          try {
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
          } catch (err) {
          }
        }
      locationConsumer.value = locationConsumer.value.rebuild((b) => b
        ..country = b.country ?? Localizations.localeOf(context).countryCode
        ..timezone = b.timezone ?? timeZoneIds[DateTime.now().timeZoneName]
        );

      _preferenceCategoryFuture = or(() => flo.preferenceCategory(authorization: oauth.authorization)) ?? Future.value(null);
      setState(() { });
    });
  }

  Future<PreferenceCategory> _preferenceCategoryFuture = Future.value(null);
  List<Item> _states = [];
  List<TimeZone> _timeZones = [];
  FocusNode focus1 = FocusNode();
  FocusNode focus2 = FocusNode();
  FocusNode focus3 = FocusNode();
  FocusNode focus4 = FocusNode();
  FocusNode focus5 = FocusNode();
  FocusNode focus6 = FocusNode();
  FocusNode focus7 = FocusNode();

  void trim(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    locationProvider.value = locationProvider.value.rebuild((b) => b
      ..address = b.address?.trim() ?? ""
      ..country = b.country?.trim() ?? ""
      ..city = b.city?.trim() ?? ""
      ..postalCode = b.postalCode?.trim() ?? ""
      ..timezone = b.timezone?.trim() ?? ""
    );
  }

  Future<bool> onWillPop(BuildContext context) async {
        trim(context);
        final locationConsumer = Provider.of<CurrentLocationNotifier>(context, listen: false);
        bool valid =
                (locationConsumer.value.address?.isNotEmpty ?? false) &&
                (locationConsumer.value.country?.isNotEmpty ?? false) &&
                (locationConsumer.value.city?.isNotEmpty ?? false) &&
                (locationConsumer.value.postalCode?.isNotEmpty ?? false) &&
                or(() => isPostalCode(locationConsumer.value.postalCode, locationConsumer.value.country.toUpperCase())) ?? true &&
                (locationConsumer.value.timezone?.isNotEmpty ?? false) &&
                (locationConsumer.value.occupants != null && locationConsumer.value.occupants > 0) &&
                locationConsumer.value.locationSize != null &&
                (locationConsumer.value.stories != null) &&
                (locationConsumer.value.showerBathCount != null) &&
                (locationConsumer.value.toiletCount != null) &&
                locationConsumer.value.plumbingType != null &&
                locationConsumer.value.waterShutoffKnown != null &&
                (locationConsumer.value.waterSource != null);
                //locationConsumer.value.locationType != null &&
                //locationConsumer.value.residenceType != null &&
                //(locationConsumer.value.nickname?.isNotEmpty ?? false) &&
                //(locationConsumer.value.gallonsPerDayGoal != null && locationConsumer.value.gallonsPerDayGoal > 0);

                if (!(locationConsumer.value.address?.isNotEmpty ?? false)) {
                  Fimber.d("!address");
                }

                if (!(locationConsumer.value.country?.isNotEmpty ?? false)) {
                  Fimber.d("!country");
                }

                if (!(locationConsumer.value.city?.isNotEmpty ?? false)) {
                  Fimber.d("!city");
                }

                if (!(locationConsumer.value.postalCode?.isNotEmpty ?? false)) {
                  Fimber.d("!postalCode");
                }

                if (!(or(() {
                  final b = isPostalCode(locationConsumer.value.postalCode, locationConsumer.value.country.toUpperCase());
                  Fimber.d("postalCode: \"${locationConsumer.value.postalCode}\"");
                  Fimber.d("isPostalCode: ${b}");
                  return b;
                } ) ?? true)) {
                locationConsumer.invalidate();
                return true;
                /*
                  Fimber.d("postalCode: \"${locationConsumer.value.postalCode}\"");
                  Fimber.d("country: \"${locationConsumer.value.country.toUpperCase()}\"");
                  Fimber.d("!isPostalCode: ");
                  showDialog(
                    context: context,
                    builder: (context) =>
                      Theme(data: floLightThemeData, child: Builder(builder: (context2) => AlertDialog(
                        title: Text(S.of(context).invalid),
                        content: Text("Invalid ${S.of(context).zip_code}"),
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
                  return false;
                */
                }
 
                if (!(locationConsumer.value.timezone?.isNotEmpty ?? false)) {
                  Fimber.d("!timezone");
                }

                if (!(locationConsumer.value.occupants != null)) {
                  Fimber.d("!occupants");
                }
                if (!(locationConsumer.value.locationSize != null)) {
                  Fimber.d("!locationSize");
                }

                if (!(locationConsumer.value.stories != null)) {
                  Fimber.d("!stories");
                }

                if (!(locationConsumer.value.showerBathCount != null)) {
                  Fimber.d("!showerBathCount");
                }

                if (!(locationConsumer.value.toiletCount != null)) {
                  Fimber.d("!toiletCount");
                }

                if (!(locationConsumer.value.plumbingType != null)) {
                  Fimber.d("!plumbingType");
                }

                if (!(locationConsumer.value.waterShutoffKnown != null)) {
                  Fimber.d("!waterShutoffKnown");
                }

                if (!(locationConsumer.value.waterSource != null)) {
                  Fimber.d("!waterSource");
                }
        if (!valid) {
          return true;
        }
        await putLocation(context, last: _location);
        return true;
  }

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context).value;
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final localesConsumer = Provider.of<LocalesNotifier>(context);

    //Fimber.d("timezone: ${DateTime.now().timeZoneName}");
    /*
    flo.getStateprovinces(locationConsumer.value.country).then((res) {
      setState(() {
        _states = res.body.toList() ?? [];
      });
    }).catchError((err) => Fimber.e("", ex: err));
    */

    final localTimeZoneId = timeZoneIds[DateTime.now().timeZoneName];
    if (localTimeZoneId != null) {
      locationConsumer.value = locationConsumer.value.rebuild((b) => b
        ..timezone = b.timezone ?? _timeZones.firstWhere((timezone) => timezone.tz == localTimeZoneId, orElse: () => TimeZone.empty).tz
      );
    }
    locationConsumer.value = locationConsumer.value.rebuild((b) => b ..occupants = b.occupants ?? 3);
    // For test unitSystem by country
    userConsumer.value = userConsumer.value.rebuild((b) => b..unitSystem = b.unitSystem ?? (locationConsumer.value.country.toLowerCase() == "us" ? UnitSystem.imperialUs : UnitSystem.metricBar));
    //locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = b.locationSize ?? LocationSize.gt_700_ft_lte_1000_ft);
    locationConsumer.value = locationConsumer.value.rebuild((b) => b
    //..stories = b.stories ?? 1
    ..showerBathCount = b.showerBathCount ?? 1
    ..toiletCount = b.toiletCount ?? 1
    );

    final double bathrooms = getSimpleBathrooms(locationConsumer.value.showerBathCount, locationConsumer.value.toiletCount);

    final feetUnit = userConsumer.value.unitSystem == UnitSystem.imperialUs;
    final unit = userConsumer.value.unitSystem == UnitSystem.imperialUs ? S.of(context).square_feet : S.of(context).square_meters;
    locationConsumer.value = locationConsumer.value.rebuild((b) => b
    ..indoorAmenities = b.indoorAmenities ?? []
    ..outdoorAmenities = b.outdoorAmenities ?? []
    ..plumbingAppliances = b.plumbingAppliances ?? []
    );

    final child =
      WillPopScope(
      onWillPop: () async {
        return await onWillPop(context);
      }, child: GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
          SafeArea(child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                floating: true,
                title: Text(ReCase(S.of(context).location_profile).titleCase),
                centerTitle: true,
              ),
            SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
          Text(deviceConsumer.value.displayName, style: Theme.of(context).textTheme.title,),
          SizedBox(height: 20,),
        Text(S.of(context).home_address, style: Theme.of(context).textTheme.title, ),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: OutlineTextFormField(
          hintText: S.of(context).address,
          labelText: S.of(context).address,
          initialValue: locationConsumer.value.address,
          focusNode: focus1,
          textInputAction: TextInputAction.next,
          maxLength: 256,
          counterText: "",
          autovalidate: true,
          onFieldSubmitted: (text) {
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..address = text);
            //locationConsumer.invalidate();
            FocusScope.of(context).requestFocus(focus2);
          },
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).address_empty;
            }
            return null;
          },
          onChanged: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..address = text.trim());
          },
          onUnfocus: (text) {
            locationConsumer.invalidate();
          },
        )),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: OutlineTextFormField(hintText: S.of(context).unit_apt_suite,
          initialValue: locationConsumer.value.address2,
          focusNode: focus2,
          //textInputAction: TextInputAction.unspecified,
          maxLength: 256,
          counterText: "",
          onFieldSubmitted: (text) {
            //FocusScope.of(context).requestFocus(focus4);
            locationConsumer.invalidate();
          },
          onChanged: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..address2 = text.trim());
          },
          onUnfocus: (text) {
            locationConsumer.invalidate();
          },
        )),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: Theme(data: floLightThemeData, child: SimplePickerDropdown<FloLocale.Locale>(
                initialValue: FloLocale.Locale((b) => b // FIXME
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
              )),
        ),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: OutlineTextFormField(hintText: S.of(context).city,
          initialValue: locationConsumer.value.city,
          focusNode: focus4,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (text) {
            FocusScope.of(context).requestFocus(_states.isNotEmpty ? focus5 : focus6);
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..city = text.trim());
            //locationConsumer.invalidate();
          },
          autovalidate: true,
          validator: (text) {
            if (text.isEmpty) {
              return S.of(context).should_not_be_empty;
            }
            return null;
          },
          onChanged: (text) {
            print("${text}");
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..city = text.trim());
            locationConsumer.invalidate();
          },
        )),
        SizedBox(height: 15),
        _states.isNotEmpty ? Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: Theme(data: floLightThemeData, child: SimplePickerDropdown<Item>(
                initialValue: Item((b) => b
                //..key = locationConsumer.value.state ?? ""
                ..key = locationConsumer.value?.state?.toLowerCase() ?? ""
                ..shortDisplay = ""
                ..longDisplay = ""
                ),
                //selection: (it) => it.key,
                selection: (it) => it.key.toLowerCase(),
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
              )),
        ) :
        Theme(data: floLightThemeData, child: OutlineTextFormField(hintText: S.of(context).state,
          initialValue: locationConsumer.value.state,
          focusNode: focus5,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (text) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..state = text.trim());
            locationConsumer.invalidate();
            FocusScope.of(context).requestFocus(focus6);
          },
          onChanged: (text) {
          },
        )),
        SizedBox(height: 15),
        Theme(data: floLightThemeData, child: OutlineTextFormField(hintText: S.of(context).zip_code,
          initialValue: locationConsumer.value.postalCode,
          focusNode: focus6,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (text) {
            FocusScope.of(context).requestFocus(focus7);
            //locationConsumer.value = locationConsumer.value.rebuild((b) => b..postalCode = text.trim());
            //locationConsumer.invalidate();
          },
          autovalidate: true,
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
        )),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: floLightBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: Colors.white,
            shape: BoxShape.rectangle,
          ),
          child: Theme(data: floLightThemeData, child: SimplePickerDropdown<TimeZone>(
                //initialValue: _timeZones.firstWhere((timeZone) => timeZone.tz == locationConsumer.value.timezone),
                initialValue: _timeZones.firstWhere((timeZone) {
                  //Fimber.d("init: $timeZone");
                  //Fimber.d("for: ${locationConsumer.value.timezone}");
                  return timeZone.tz == locationConsumer.value.timezone;
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
              )),
        ),
        SizedBox(height: 20),
        Text(S.of(context).more_info, style: Theme.of(context).textTheme.title, ),
        SizedBox(height: 20),
        Text(S.of(context).how_many_residents_live_in_your_home, style: Theme.of(context).textTheme.subhead, ),
        SizedBox(height: 10),
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
        SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                    Text(S.of(context).what_kind_of_home_is_this_q, style: Theme.of(context).textTheme.subhead,),
                    SizedBox(height: 20,),
                    Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                RadioListTile<LocationType>(
                                    value: LocationType.singleFamilyHouse,
                                    groupValue: locationConsumer.value.locationType,
                                    title: Text(S.of(context).single_family_house), onChanged: (value) {
                                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                    ..locationType = value
                                  );
                                  locationConsumer.invalidate();
                                }),
                                RadioListTile<LocationType>(
                                    value: LocationType.condo,
                                    groupValue: locationConsumer.value.locationType,
                                    title: Text(S.of(context).condo), onChanged: (value) {
                                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                    ..locationType = value
                                  );
                                  locationConsumer.invalidate();
                                }),
                                RadioListTile<LocationType>(
                                    value: LocationType.apartment,
                                    groupValue: locationConsumer.value.locationType,
                                    title: Text(S.of(context).apartment), onChanged: (value) {
                                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                    ..locationType = value
                                  );
                                  locationConsumer.invalidate();
                                }),
                                RadioListTile<LocationType>(
                                    value: LocationType.other,
                                    groupValue: locationConsumer.value.locationType,
                                    title: Text(S.of(context).other_), onChanged: (value) {
                                  locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                    ..locationType = value
                                  );
                                  locationConsumer.invalidate();
                                }),
                              ],
                            )
                        ))))),
                    SizedBox(height: 20),
                  ],),
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
                          return Column(children: <Widget>[
                            Text(S.of(context).how_do_you_use_this_home_q, style: Theme.of(context).textTheme.subhead,),
                            SizedBox(height: 20,),
                            Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: snapshot.data.residenceType.map((item) =>
                                            RadioListTile<String>(title: Text(item.longDisplay), value: item.key, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
                                              locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
                                              locationConsumer.invalidate();
                                            }),
                                        ).toList()
                                    )
                                ))))),
                          ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          );
                        } else {
                          return Container();
                        }
                      }
                  ),
          /*
          RadioListTile<String>(title: Text(S.of(context).my_primary_residence), value: ResidenceType.PRIMARY, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
            locationConsumer.invalidate();
          }),
          //RadioButton(label: S.of(context).i_rent_it, value: ResidenceType.rental, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
          RadioListTile<String>(title: Text(S.of(context).i_rent_it_out), value: ResidenceType.RENTAL, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
            locationConsumer.invalidate();
          }),
          RadioListTile<String>(title: Text(S.of(context).its_my_vacation_home), value: ResidenceType.VACATION, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
            locationConsumer.invalidate();
          }),
          RadioListTile<String>(title: Text(S.of(context).other_), value: ResidenceType.OTHER, groupValue: locationConsumer.value.residenceType, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b..residenceType = value);
            locationConsumer.invalidate();
          }),
          */
                  SizedBox(height: 20,),

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
                        return Column(children: <Widget>[
                          Text(S.of(context).how_big_is_this_home_q, style: Theme.of(context).textTheme.subhead,),
                          SizedBox(height: 20,),
                          Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              ),
                              child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: snapshot.data.locationSize.map((item) =>
                                          RadioListTile<String>(title: Text(item.longDisplay), value: item.key, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
                                            locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
                                            locationConsumer.invalidate();
                                          }),
                                      ).toList()
                                  )
                              ))))),
                        ],
                          crossAxisAlignment: CrossAxisAlignment.start,
                        );
                      } else {
                        // TODO: implement retry snackbar
                        return Container();
                      }
                    },
                  ),
        /*
        Text(S.of(context).how_big_is_this_home_q, style: Theme.of(context).textTheme.subhead, ),
          SizedBox(height: 20,),
      Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
        RadioListTile<String>(title: Text("${feetUnit ? S.of(context).less_than_700 : S.of(context).less_than_70} ${unit}"),
          value: LocationSize.LTE_700, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        RadioListTile<String>(title: Text("${feetUnit ? S.of(context).s_700_to_1000 : S.of(context).s_70_to_100} ${unit}"),
         value: LocationSize.GT_700_FT_LTE_1000_FT, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        RadioListTile<String>(title: Text("${feetUnit ? S.of(context).s_1001_to_2000 : S.of(context).s_101_to_200} ${unit}"),
         value: LocationSize.GT_1000_FT_LTE_2000_FT, groupValue: locationConsumer.value.locationSize , onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        RadioListTile<String>(title: Text("${feetUnit ? S.of(context).s_2001_to_4000 : S.of(context).s_201_to_400} ${unit}"),
         value: LocationSize.GT_2000_FT_LTE_4000_FT, groupValue: locationConsumer.value.locationSize , onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        }),
        RadioListTile<String>(title: Text("${feetUnit ? S.of(context).more_than_4000 : S.of(context).more_than_400} ${unit}"),
          value: LocationSize.GT_4000_FT, groupValue: locationConsumer.value.locationSize, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..locationSize = value);
          locationConsumer.invalidate();
        },),
            ])))))),
         */
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_many_floors_are_there_q,
         style: Theme.of(context).textTheme.subhead,)),
        SizedBox(height: 20),
      Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          RadioListTile(title: Text(S.of(context).s_1), value: 1, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioListTile(title: Text(S.of(context).s_2), value: 2, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioListTile(title: Text(S.of(context).s_3), value: 3, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
          RadioListTile(title: Text(S.of(context).s_4_plus), value: 4, groupValue: locationConsumer.value.stories, onChanged: (value) {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b ..stories = value);
            locationConsumer.invalidate();
          }),
            ])))))),
        SizedBox(height: 20),
        SizedBox(width: double.infinity, child: Text(S.of(context).how_many_bathrooms_does_this_home_have_q, style: Theme.of(context).textTheme.subhead,)),
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
        /*
        AlwaysSlider2(
          min: 0.0,
          max: 10.0,
          divisions: 20,
          value: bathrooms,
          title: Text((value) {
            Fimber.d("label");
            return '${NumberFormat("#.#").format(value)} bathrooms';
            },
          onChangedEnd: (value) async {
            Fimber.d("onChangedEnd");
            Future.delayed(Duration(seconds: 1), () {
            locationConsumer.value = locationConsumer.value.rebuild((b) => b
            ..showerBathCount = value.floor()
            ..toiletCount = value.round()
            );
            locationConsumer.invalidate();
            });
          },
          semanticFormatterCallback: (double newValue) {
            Fimber.d("semanticFormatterCallback");
              return '${newValue} bathrooms';
          },
        ),
        */
        SizedBox(height: 10),
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
                          return Column(children: <Widget>[
                            SizedBox(width: double.infinity, child: Text(S.of(context).what_type_of_plumbing_do_you_have_q, style: Theme.of(context).textTheme.subhead,)),
                            SizedBox(height: 20),
                            Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: snapshot.data.pipeType.map((item) =>
                                            RadioListTile<String>(title: Text(item.longDisplay), value: item.key, groupValue: locationConsumer.value.plumbingType, onChanged: (value) {
                                              locationConsumer.value = locationConsumer.value.rebuild((b) => b..plumbingType = value);
                                              locationConsumer.invalidate();
                                            }),
                                        ).toList()
                                    )
                                ))))),
                            SizedBox(height: 30),
                          ],);
                        } else {
                          return Container();
                        }
                      }
                  ),

/*
        SizedBox(width: double.infinity, child: Text(S.of(context).do_you_know_from_where_to_shutoff_the_water_to_your_home_q, style: Theme.of(context).textTheme.subhead,)),
        SizedBox(height: 30),
      Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        RadioListTile(title: Text(S.of(context).yes), value: Answer.yes, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
        RadioListTile(title: Text(S.of(context).no), value: Answer.no, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
        RadioListTile(title: Text(S.of(context).not_sure), value: Answer.unsure, groupValue: locationConsumer.value.waterShutoffKnown, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterShutoffKnown = value);
          locationConsumer.invalidate();
        }),
            ])))))),
        SizedBox(height: 15),
*/

        SizedBox(width: double.infinity, child: Text(S.of(context).what_is_the_source_of_your_water_q, style: Theme.of(context).textTheme.subhead,)),
        SizedBox(height: 15),
      Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        RadioListTile<String>(title: Text(S.of(context).city_water), value: WaterSource.UTILITY, groupValue: locationConsumer.value.waterSource, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterSource = value);
          locationConsumer.invalidate();
        }),
        RadioListTile<String>(title: Text(S.of(context).well), value: WaterSource.WELL, groupValue: locationConsumer.value.waterSource, onChanged: (value) {
          locationConsumer.value = locationConsumer.value.rebuild((b) => b..waterSource = value);
          locationConsumer.invalidate();
        }),
            ])))))),
        SizedBox(height: 35),
                  SizedBox(width: double.infinity, child: Text(S.of(context).appliances_amenities,
                    style: Theme.of(context).textTheme.title,)),
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
                        } else if (snapshot.connectionState == ConnectionState.done && (snapshot?.data?.fixtureIndoor?.isNotEmpty ?? false)) {
                          return
                            Column(children: <Widget>[
                              SizedBox(width: double.infinity, child: Text(S.of(context).indoors,
                                style: Theme.of(context).textTheme.subhead,)),
                              SizedBox(height: 20),
                              Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(floCardRadiusDimen),
                                  ),
                                  margin: EdgeInsets.all(0),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: snapshot.data.fixtureIndoor.map((item) =>
                                          SimpleCheckboxListTile(
                                            title: Text(item.longDisplay),
                                            controlAffinity: ListTileControlAffinity.leading,
                                            value: locationConsumer.value.indoorAmenities.contains(item.key),
                                            onChanged: (checked) {
                                              locationConsumer.value = locationConsumer.value.rebuild((b) {
                                                b.indoorAmenities.add(item.key);
                                                b..indoorAmenities = ListBuilder(b.indoorAmenities.build().toSet().toList());
                                              });
                                              locationConsumer.invalidate();
                                            },
                                          ),
                                        ).toList()
                                    )
                                ))))),
                            SizedBox(height: 30),
                          ],);
                        } else {
                          return Container();
                        }
                      }
                  ),
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
                          return
                            Column(children: <Widget>[
                              SizedBox(width: double.infinity, child: Text(S.of(context).outdoors,
                                style: Theme.of(context).textTheme.subhead,)),
                              SizedBox(height: 20),
                              Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(floCardRadiusDimen),
                                  ),
                                  margin: EdgeInsets.all(0),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: snapshot.data.fixtureOutdoor.map((item) =>
                                              SimpleCheckboxListTile(
                                                title: Text(item.longDisplay),
                                                controlAffinity: ListTileControlAffinity.leading,
                                                value: locationConsumer.value.outdoorAmenities.contains(item.key),
                                                onChanged: (checked) {
                                                  locationConsumer.value = locationConsumer.value.rebuild((b) {
                                                    b.outdoorAmenities.add(item.key);
                                                    b..outdoorAmenities = ListBuilder(b.outdoorAmenities.build().toSet().toList());
                                                  });
                                                  locationConsumer.invalidate();
                                                },
                                              ),
                                          ).toList()
                                      )
                                  ))))),
                              SizedBox(height: 30),
                            ],);
                        } else {
                          return Container();
                        }
                      }
                  ),
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
                          return
                            Column(children: <Widget>[
                              SizedBox(width: double.infinity, child: Text(S.of(context).plumbing_appliances,
                                style: Theme.of(context).textTheme.subhead,)),
                              SizedBox(height: 20),
                              Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(floCardRadiusDimen),
                                  ),
                                  margin: EdgeInsets.all(0),
                                  child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: snapshot.data.homeAppliance.map((item) =>
                                              SimpleCheckboxListTile(
                                                title: Text(item.longDisplay),
                                                controlAffinity: ListTileControlAffinity.leading,
                                                value: locationConsumer.value.plumbingAppliances.contains(item.key),
                                                onChanged: (checked) {
                                                  locationConsumer.value = locationConsumer.value.rebuild((b) {
                                                    b.plumbingAppliances.add(item.key);
                                                    b..plumbingAppliances = ListBuilder(b.plumbingAppliances.build().toSet().toList());
                                                  });
                                                  locationConsumer.invalidate();
                                                },
                                              ),
                                          ).toList()
                                      )
                                  ))))),
                              SizedBox(height: 30),
                            ],);
                        } else {
                          return Container();
                        }
                      }
                  ),
          SizedBox(height: 20,),
        ]))),
      ]))]))
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}
