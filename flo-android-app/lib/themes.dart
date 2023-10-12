import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:tinycolor/tinycolor.dart';

final floBlue = const Color(0xFF073F62);
final floBlue2 = const Color(0xFF0A537F);
final floLightBlue = const Color(0xFFE0E9F2);
//final floLightButton = const Color(0xFF0B5D8D).withOpacity(0.5);
//final floLightButtonBackground = const Color(0xFF0B5D8D).withOpacity(0.1);
final floLightButton = const Color(0xFF073F63).withOpacity(0.5);
final floLightButtonBackground = const Color(0xFF073F63).withOpacity(0.1);
final floBackground = const Color(0xFFEDF0F3);
final floDotColor = const Color(0xFFD7DDEA);
final floPrimaryColor = floBlue;
final floMenuItemColor = const Color(0xFF5781A8);
final floMenuItemBgColor = const Color(0xFFEDF0F3);
final floLightBackground = const Color(0xFFEDF0F3);
final floSecondaryButtonColor = const Color(0xFF70D549);
final floGreenButtonColor = const Color(0xFF70D549);
final floButtonRadius = 25.0;
final floBadgeRadius = 4.0;
final floCardRadiusDimen = 8.0;
final floCardRadius = Radius.circular(floCardRadiusDimen);
final floToggleButtonRadius = 10.0;
final floBody1TextColor = floBlue.withOpacity(0.5);
final floRed = const Color(0xFFD75839);
final floAmber = const Color(0xFFEB9A3A);
final floWarningRed = const Color(0xFFFF967C);
final floBlueGradientTop = const Color(0xFF0C679C);
final floBlueGradientBottom = floBlue;
final floBlueBottomNavBar = const Color(0xFF105077);
// linear-gradient(180deg, #5BE9F9 0%, #12C3EA 100%)
final floLightCyan = floCyan;
final floCyan = const Color(0xFF12C3EA);


final lightTheme = ThemeData.light();
final floLightThemeData = ThemeData(
        appBarTheme: lightTheme.appBarTheme.copyWith(
          brightness: Brightness.light,
        ),
        iconTheme: lightTheme.iconTheme.copyWith(
          color: floBlue2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          errorStyle: TextStyle(
            fontSize: 13,
          )
        ),
        errorColor: floAmber,
        fontFamily: 'Questrial',
        primaryColor: floPrimaryColor,
        primaryColorDark: floPrimaryColor,
        //accentColor: floPrimaryColor,
        toggleableActiveColor: floBlue2,
        unselectedWidgetColor: floBlue2, // checkbox border
        scaffoldBackgroundColor: floLightBackground,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: floPrimaryColor,
          primaryVariant: floPrimaryColor,
        ),
        //accentColor: Colors.black,
        accentTextTheme: Typography.dense2018.copyWith(
          //title: TextStyle(fontSize: 21, color: Colors.white),
          //subtitle: TextStyle(fontSize: 19, color: Colors.white),
          ////headline: TextStyle(fontSize: 20, color: Colors.white),
          //subhead: TextStyle(fontSize: 17, color: Colors.white),
          ////button: TextStyle(fontSize: 14, color: Colors.white),
          //body2: TextStyle(fontSize: 15, color: Colors.white),
          //body1: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
          display4  : TextStyle(debugLabel: 'dense display4 2018',  fontSize: 96.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic, color: Colors.black),
          display3  : TextStyle(debugLabel: 'dense display3 2018',  fontSize: 60.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic, color: Colors.black),
          display2  : TextStyle(debugLabel: 'dense display2 2018',  fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
          display1  : TextStyle(debugLabel: 'dense display1 2018',  fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
          headline  : TextStyle(debugLabel: 'dense headline 2018',  fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
          title     : TextStyle(debugLabel: 'dense title 2018',     fontSize: 21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic, color: Colors.black),
          subhead   : TextStyle(debugLabel: 'dense subhead 2018',   fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black.withOpacity(0.8)),
          body2     : TextStyle(debugLabel: 'dense body2 2018',     fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
          body1     : TextStyle(debugLabel: 'dense body1 2018',     fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
          caption   : TextStyle(debugLabel: 'dense caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black.withOpacity(0.8)),
          button    : TextStyle(debugLabel: 'dense button 2018',    fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic, color: Colors.black),
          subtitle  : TextStyle(debugLabel: 'dense subtitle 2018',  fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic, color: Colors.black),
          overline  : TextStyle(debugLabel: 'dense overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.black),
        ),
        textTheme: Typography.dense2018.copyWith(
          //title: TextStyle(fontSize: 21, color: Colors.white),
          //subtitle: TextStyle(fontSize: 19, color: Colors.white),
          ////headline: TextStyle(fontSize: 20, color: Colors.white),
          //subhead: TextStyle(fontSize: 17, color: Colors.white),
          ////button: TextStyle(fontSize: 14, color: Colors.white),
          //body2: TextStyle(fontSize: 15, color: Colors.white),
          //body1: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
          display4  : TextStyle(debugLabel: 'dense display4 2018',  fontSize: 96.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
          display3  : TextStyle(debugLabel: 'dense display3 2018',  fontSize: 60.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
          display2  : TextStyle(debugLabel: 'dense display2 2018',  fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          display1  : TextStyle(debugLabel: 'dense display1 2018',  fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          headline  : TextStyle(debugLabel: 'dense headline 2018',  fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          title     : TextStyle(debugLabel: 'dense title 2018',     fontSize: 21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic, color: floPrimaryColor),
          subhead   : TextStyle(debugLabel: 'dense subhead 2018',   fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: floPrimaryColor.withOpacity(0.8)),
          body2     : TextStyle(debugLabel: 'dense body2 2018',     fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: floPrimaryColor),
          body1     : TextStyle(debugLabel: 'dense body1 2018',     fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          caption   : TextStyle(debugLabel: 'dense caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: floPrimaryColor.withOpacity(0.8)),
          button    : TextStyle(debugLabel: 'dense button 2018',    fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
          subtitle  : TextStyle(debugLabel: 'dense subtitle 2018',  fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
          overline  : TextStyle(debugLabel: 'dense overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
        ),
        sliderTheme: lightTheme.sliderTheme.copyWith(
          showValueIndicator: ShowValueIndicator.always,
          valueIndicatorColor: floBlue2,
          activeTrackColor: floBlue2,
          activeTickMarkColor: floBlue2,
          thumbColor: floBlue2,
          overlayColor: floBlue2,
        ),
        /*
        sliderTheme: lightTheme.sliderTheme.copyWith(
          //activeTrackColor: floPrimaryColor,
          //activeTrackColor: Colors.green,
          //trackShape: RectangularSliderTrackShape(),
          //trackShape: RoundedRectSliderTrackShape(),
          //tickMarkShape: RoundedRectSliderTrackShape(),
          activeTrackColor: Colors.white,
          inactiveTrackColor: floPrimaryColor.withOpacity(0.5),
          activeTickMarkColor: floPrimaryColor,
          inactiveTickMarkColor: Color(0xFF0C679C),
          trackHeight: 20,
        ),
        */
        buttonColor: floBlue2,
        buttonTheme: lightTheme.buttonTheme.copyWith(
          buttonColor: floBlue2,
          textTheme: ButtonTextTheme.normal,
        ),
        hintColor: Color.fromARGB(40, 7, 63, 98),
        dialogTheme: lightTheme.dialogTheme.copyWith(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
        cardTheme: lightTheme.cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(floCardRadius),
          ),
        ),
      );
final dartTheme = ThemeData.dark();
final floThemeData = ThemeData(
        fontFamily: 'Questrial',
        primarySwatch: Colors.blue,
        //backgroundColor: Colors.black,
        brightness: Brightness.dark,
        //primaryColor: floPrimaryColor,
        primaryColor: TinyColor(floBlueGradientTop).darken(1).color,
        primaryColorDark: floBlueBottomNavBar,
        //accentColor: Colors.cyan[600],
        //accentColor: floPrimaryColor,
        //toggleableActiveColor: floPrimaryColor,
        textTheme: Typography.dense2018.copyWith(
          display4  : TextStyle(debugLabel: 'dense display4 2018',  fontSize: 96.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
          display3  : TextStyle(debugLabel: 'dense display3 2018',  fontSize: 60.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
          display2  : TextStyle(debugLabel: 'dense display2 2018',  fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          display1  : TextStyle(debugLabel: 'dense display1 2018',  fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          headline  : TextStyle(debugLabel: 'dense headline 2018',  fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          title     : TextStyle(debugLabel: 'dense title 2018',     fontSize: 21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
          subhead   : TextStyle(debugLabel: 'dense subhead 2018',   fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          body2     : TextStyle(debugLabel: 'dense body2 2018',     fontSize: 16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          body1     : TextStyle(debugLabel: 'dense body1 2018',     fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
          caption   : TextStyle(debugLabel: 'dense caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic, color: Colors.white.withOpacity(0.8)),
          button    : TextStyle(debugLabel: 'dense button 2018',    fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
          subtitle  : TextStyle(debugLabel: 'dense subtitle 2018',  fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic, color: Colors.white.withOpacity(0.8)),
          overline  : TextStyle(debugLabel: 'dense overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
        ),
        sliderTheme: lightTheme.sliderTheme.copyWith(
          showValueIndicator: ShowValueIndicator.always,
          valueIndicatorColor: Colors.white,
          activeTrackColor: Colors.white,
          activeTickMarkColor: Colors.white,
          inactiveTrackColor: Colors.grey,
          inactiveTickMarkColor: Colors.grey,
          //thumbColor: floBlue2,
          thumbColor: Colors.white,
          overlayColor: Colors.white,
          valueIndicatorTextStyle: TextStyle(color: floBlue),
        ),
          /*
          buttonColor: floPrimaryColor,
      buttonTheme: ButtonThemeData(
        buttonColor: floPrimaryColor,
        textTheme: ButtonTextTheme.normal,
      ),
      textSelectionColor: floPrimaryColor,
          */
        //canvasColor: Colors.white,
        //splashColor: Color(0x40CCCCCC),
        splashColor: Color(0x66C8C8C8),
        //splashColor: TinyColor(floBlue2).lighten(40).color.withOpacity(0.5),
        dialogTheme: lightTheme.dialogTheme.copyWith(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        ),
        cardTheme: lightTheme.cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
      );

