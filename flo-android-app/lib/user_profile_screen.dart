import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/model/unit_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:phone_number/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor/tinycolor.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/user.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';

class UserProfileScreen extends StatefulWidget {
  UserProfileScreen({Key key}) : super(key: key);

  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with AfterLayoutMixin<UserProfileScreen> {

  TextEditingController phoneNumberController;
  bool _phoneNumberAutovalidate = false;
  String _phoneNumberErrorText = null;
  bool _isMetricUnitSystem = false;

  @override
  void initState() {
    super.initState();
    phoneNumberController = TextEditingController();
    _isMetricUnitSystem = false;
    _countryCode = "us"; // FIXME

    Future.delayed(Duration.zero, () async {
      final userProvider = Provider.of<UserNotifier>(context, listen: false);
      //userProvider.value = userProvider.value.rebuild((b) => b
      //    ..locale = b.locale ?? Localizations.localeOf(context).toString()
      //);
      //Fimber.d("locale: ${userProvider.value.locale}");
      Fimber.d("phone: ${userProvider.value.phoneMobile}");
      _countryCode = Localizations.localeOf(context).countryCode;
      Fimber.d("default _phoneCode: ${_countryCode}");
      //String phoneMobile = "+5491158898021"; // testing
      String phoneMobile = userProvider.value.phoneMobile?.trim() ?? "";
      Fimber.d("trimed phone: ${phoneMobile}");
      // FIXME parse country from original phone number
      //phoneNumber = await PhoneNumber.parse(phoneMobile, region: userProvider.value.locale);
      var phoneNumber = await futureOr(() async => await PhoneNumber.parse(phoneMobile, region: Localizations.localeOf(context).countryCode));
      Fimber.d("parsed phoneNumber with ${Localizations.localeOf(context).countryCode}: $phoneNumber");
      phoneNumber ??= await futureOr(() async => await PhoneNumber.parse(phoneMobile));
      Fimber.d("parsed phoneNumber without region: $phoneNumber");
      phoneMobile = phoneNumber['international'] ?? phoneMobile;
      Fimber.d("format phone: ${phoneMobile}");
      Fimber.d("phone country: ${phoneNumber['country_code']} ?? 1");
      phoneMobile = phoneMobile.replaceFirst(RegExp(r'\+\d+ '), '');
      Fimber.d("removed country phone: ${phoneMobile}");
      phoneMobile = phoneMobile.trim();
      Fimber.d("trimed again phone: ${phoneMobile}");
      setState(() {
        _countryCode = or(() => dialNumberToCountry(phoneNumber['country_code'])) ?? _countryCode;
        phoneNumberController.text = phoneMobile;
      });
    });
  }

  User _user;
  String _countryCode;

  @override
  void afterFirstLayout(BuildContext context) {
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final userConsumer = Provider.of<UserNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    _isMetricUnitSystem = userConsumer.value.isMetric;

    final child = 
      WillPopScope(
      onWillPop: () async {
        await putUser(context, last: _user);
        Navigator.of(context).pop();
        return false;
      }, child: GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        /*
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(S.of(context).edit_profile, textScaleFactor: 1.2,),
        ),
        */
        resizeToAvoidBottomPadding: true,
        body: Stack(children: <Widget>[
            FloGradientBackground(),
        SafeArea(child: CustomScrollView(
            slivers: <Widget>[
                 SliverAppBar(
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                floating: true,
                title: Text(S.of(context).edit_profile, textScaleFactor: 1.2,),
                centerTitle: true,
              ),
        SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), sliver:
        SliverList(delegate: SliverChildListDelegate(
          <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Column(
                 // mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.of(context).first_name, style: Theme.of(context).textTheme.subhead),
                    SizedBox(height: 10,),
                    Theme(data: floLightThemeData, child: OutlineTextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      initialValue: userConsumer.value.firstName,
                      onUnfocus: (text) {
                        userConsumer.value = userConsumer.value.rebuild((b) => b..firstName = text.trim() ?? "");
                      },
                    )),
                ],)),
                SizedBox(width: 10),
                Flexible(child: Column(
                  //mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.of(context).last_name, style: Theme.of(context).textTheme.subhead),
                    SizedBox(height: 10,),
                    Theme(data: floLightThemeData, child: OutlineTextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      initialValue: userConsumer.value.lastName,
                      onUnfocus: (text) {
                        userConsumer.value = userConsumer.value.rebuild((b) => b..lastName = text.trim() ?? "");
                      },
                    )),
                ],)),
          ]),
          SizedBox(height: 20,),
          Text(S.of(context).phone_number, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 10,),
          Theme(data: floLightThemeData, child: 
          Stack(
            children: <Widget>[
            OutlineTextFormField(
              onUnfocus: (text) async {
                setState(() {
                  _phoneNumberAutovalidate = true;
                });
                try {
                  final phoneNumber = await PhoneNumber.parse(phoneNumberController.text.trim(), region: _countryCode); // FIXME parse country from original phone number
                  Fimber.d("last _phoneCode: ${_countryCode}");
                  _countryCode = or(() => dialNumberToCountry(phoneNumber['country_code'])) ?? _countryCode;
                  Fimber.d("_phoneCode: ${_countryCode}");
                  userConsumer.value = userConsumer.value.rebuild((b) => b
                    ..phoneMobile = phoneNumber['international'] ?? ""
                  );
                  //userConsumer.invalidate();
                  setState(() {
                    _phoneNumberErrorText = null;
                  });
                } catch (err) {
                  Fimber.d("", ex: err);
                  setState(() => _phoneNumberErrorText = S.of(context).invalid_phone_number);
                }
              },
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autovalidate: _phoneNumberAutovalidate,
            validator: (text) {
              if (text.trim().isEmpty) {
                return S.of(context).should_not_be_empty;
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: S.of(context).phone_number,
              errorText: _phoneNumberErrorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              //contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 18.0),
              contentPadding: EdgeInsets.only(left: 70, top: 18, bottom: 18, right: 10),
            ),
          ),
          Padding(padding: EdgeInsets.only(left: 0, top: 2), child: SimpleCountryCodePicker(
                  onChanged: (country) {
                    _countryCode = country.code;
                  },
                  textStyle: Theme.of(context).textTheme.button.copyWith(fontSize: 18, color: floBlue),
                  // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                  //initialSelection: loginConsumer.current.phoneCountry.isNotEmpty ? loginConsumer.current.phoneCountry : loginConsumer.current.country.toUpperCase(),
                  initialSelection: _countryCode.toUpperCase(),
                  favorite: [_countryCode.toUpperCase()],
                  // optional. Shows only country name and flag
                  showCountryOnly: false,
                  // optional. Shows only country name and flag when popup is closed.
                  //showOnlyCountryCodeWhenClosed: false,
                  // optional. aligns the flag and the Text left
                  //alignLeft: false,
                )),
          ])),
          SizedBox(height: 20,),
          Text(S.of(context).email, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 20,),
          Theme(data: floLightThemeData, child: OutlineTextFormField(
            style: TextStyle(color: floBlue.withOpacity(0.5)),
            enabled: false,
            initialValue: userConsumer.value.email,
            onChanged: (text) {
              userConsumer.value = userConsumer.value.rebuild((b) => b..email = text.trim());
            },
          )),
          SizedBox(height: 20,),
          Text(S.of(context).others, style: Theme.of(context).textTheme.subhead),
          SizedBox(height: 15,),
          TextFieldButton(text: S.of(context).change_password,
           endText: "",
           onPressed: () {
             Navigator.of(context).pushNamed('/change_password');
           },
          ),
          SizedBox(height: 20,),
        ],
        )))
      ])),
        ])),
    ));

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }
}

class SimpleDropdownButton<T> extends StatefulWidget {
  SimpleDropdownButton({Key key,
    @required this.items,
    //@required this.itemBuilder,
    this.value,
    this.hint,
    this.disabledHint,
    @required this.onChanged,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
  }) : super(key: key);

  State<SimpleDropdownButton<T>> createState() => _SimpleDropdownButtonState<T>();

  /// The list of items the user can select.
  ///
  /// If the [onChanged] callback is null or the list of items is null
  /// then the dropdown button will be disabled, i.e. its arrow will be
  /// displayed in grey and it will not respond to input. A disabled button
  /// will display the [disabledHint] widget if it is non-null.
  final List<DropdownMenuItem<T>> items;

  /// The value of the currently selected [DropdownMenuItem], or null if no
  /// item has been selected. If `value` is null then the menu is popped up as
  /// if the first item were selected.
  final T value;

  /// Displayed if [value] is null.
  final Widget hint;

  /// A message to show when the dropdown is disabled.
  ///
  /// Displayed if [items] or [onChanged] is null.
  final Widget disabledHint;

  /// Called when the user selects an item.
  ///
  /// If the [onChanged] callback is null or the list of [items] is null
  /// then the dropdown button will be disabled, i.e. its arrow will be
  /// displayed in grey and it will not respond to input. A disabled button
  /// will display the [disabledHint] widget if it is non-null.
  final ValueChanged<T> onChanged;

  /// The z-coordinate at which to place the menu when open.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12,
  /// 16, and 24. See [kElevationToShadow].
  ///
  /// Defaults to 8, the appropriate elevation for dropdown buttons.
  final int elevation;

  /// The text style to use for text in the dropdown button and the dropdown
  /// menu that appears when you tap the button.
  ///
  /// Defaults to the [TextTheme.subhead] value of the current
  /// [ThemeData.textTheme] of the current [Theme].
  final TextStyle style;

  /// The widget to use for drawing the drop-down button's underline.
  ///
  /// Defaults to a 0.0 width bottom border with color 0xFFBDBDBD.
  final Widget underline;

  /// The widget to use for the drop-down button's icon.
  ///
  /// Defaults to an [Icon] with the [Icons.arrow_drop_down] glyph.
  final Widget icon;

  /// The color of any [Icon] descendant of [icon] if this button is disabled,
  /// i.e. if [onChanged] is null.
  ///
  /// Defaults to [Colors.grey.shade400] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white10] when it is [Brightness.dark]
  final Color iconDisabledColor;

  /// The color of any [Icon] descendant of [icon] if this button is enabled,
  /// i.e. if [onChanged] is defined.
  ///
  /// Defaults to [Colors.grey.shade700] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white70] when it is [Brightness.dark]
  final Color iconEnabledColor;

  /// The size to use for the drop-down button's down arrow icon button.
  ///
  /// Defaults to 24.0.
  final double iconSize;

  /// Reduce the button's height.
  ///
  /// By default this button's height is the same as its menu items' heights.
  /// If isDense is true, the button's height is reduced by about half. This
  /// can be useful when the button is embedded in a container that adds
  /// its own decorations, like [InputDecorator].
  final bool isDense;

  /// Set the dropdown's inner contents to horizontally fill its parent.
  ///
  /// By default this button's inner width is the minimum size of its contents.
  /// If [isExpanded] is true, the inner width is expanded to fill its
  /// surrounding container.
  final bool isExpanded;

  //final ItemBuilder<T> itemBuilder;
}

class _SimpleDropdownButtonState<T> extends State<SimpleDropdownButton<T>> {

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
    if (or(() => widget.items.firstWhere((DropdownMenuItem<T> item) => item.value ==  _selected)) == null) {
      Fimber.e("${widget.value} not found");
      _selected = null;
    }
  }

  T _selected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(child: DropdownButton<T>(
      value: _selected,
      items: widget.items ?? [],
      onChanged: (value) {
        setState(() {
          _selected = value;
        });
        widget.onChanged(value);
      },
      hint: widget.hint,
      disabledHint: widget.disabledHint,
      elevation: widget.elevation,
      style: widget.style,
      underline: widget.underline,
      icon: widget.icon,
      iconDisabledColor: widget.iconDisabledColor,
      iconEnabledColor: widget.iconEnabledColor,
      iconSize: widget.iconSize,
      isDense: widget.isDense,
      isExpanded: widget.isExpanded,
    ));
  }
}

const locales = {
  "en": "English",
  "en-US": "English (United States)",
  "en-UK": "English (United Kingdom)",
  "es": "Spanish",
  "es-AR": "Spanish (Argentina)",
  "zh": "Chinese",
  "zh-TW": "Chinese (Taiwan)",
  "zh-CN": "Chinese (China)",
  "zh-HK": "Chinese (Hong Kong)",
};

Future<void> putUser(BuildContext context, {User last}) async {
  final userProvider = Provider.of<UserNotifier>(context, listen: false);
  if (last == userProvider.value) {
    return;
  }
  final floConsumer = Provider.of<FloNotifier>(context, listen: false);
  final flo = floConsumer.value;
  final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
  final user = userProvider.value;
  try {
    await flo.putUser(user, authorization: oauthConsumer.value.authorization);
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
  } catch (e) {
    Fimber.e("putUser", ex: e);
  }
}
