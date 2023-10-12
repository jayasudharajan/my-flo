import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:after_layout/after_layout.dart';
import 'package:animator/animator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:built_collection/built_collection.dart';
import 'package:country_code_picker/country_code.dart';
import 'package:country_code_picker/country_codes.dart';
import 'package:country_code_picker/selection_dialog.dart';
import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:fimber/fimber.dart';
import 'package:flotechnologies/model/pending_system_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_range_slider/flutter_range_slider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:path_drawing/path_drawing.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:superpower/superpower.dart';
import 'package:tinycolor/tinycolor.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'package:zendesk/zendesk.dart';

import 'badge.dart';
import 'charts.dart';
import 'dropdown.dart';
import 'generated/i18n.dart';
import 'model/alarm.dart';
import 'model/alarm_action.dart';
import 'model/alert.dart';
import 'model/alert_action.dart';
import 'model/alert_feedback_flow_tags.dart';
import 'model/alert_feedback_option.dart';
import 'model/alert_feedback_step.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/health_test.dart';
import 'model/location.dart';
import 'model/notifications.dart';
import 'model/response_error.dart';
import 'model/schedule.dart';
import 'model/system_mode.dart';
import 'model/user.dart';
import 'model/water_usage.dart';
import 'model/water_usage_averages.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_range_slider/flutter_range_slider.dart' as frs;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;



class SingleClickTextButton extends StatefulWidget {
  SingleClickTextButton({
    Key key,
    this.onPressed,
    this.onHighlightChanged,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.padding,
    this.shape,
    this.materialTapTargetSize,
    this.icon,
    this.suffixIcon,
    this.label,
    this.enabled = true,
  }) : super(key: key);

  final VoidCallback onPressed;
  final ValueChanged<bool> onHighlightChanged;
  final ButtonTextTheme textTheme;
  final Color textColor;
  final Color disabledTextColor;
  final Color color;
  final Color disabledColor;
  final Color highlightColor;
  final Color splashColor;
  final Brightness colorBrightness;
  final EdgeInsetsGeometry padding;
  final ShapeBorder shape;
  final MaterialTapTargetSize materialTapTargetSize;
  final Widget icon;
  final Widget suffixIcon;
  final Widget label;
  final bool enabled;

  @override
  State<SingleClickTextButton> createState() => SingleClickTextButtonState();
}

class SingleClickTextButtonState extends State<SingleClickTextButton> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
  }

  @override
  void didUpdateWidget(SingleClickTextButton oldWidget) {
    _enabled = widget.enabled;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Enabled(enabled: _enabled, child: TextButton(
      key: widget.key,
      onPressed: () {
        if (widget.onPressed != null) {
          setState(() {
            _enabled = false;
          });
          widget.onPressed();
        }
      },
      onHighlightChanged: widget.onHighlightChanged,
      textTheme: widget.textTheme,
      textColor: widget.textColor,
      disabledTextColor: widget.disabledTextColor,
      color: widget.color,
      disabledColor: widget.disabledColor,
      highlightColor: widget.highlightColor,
      splashColor: widget.splashColor,
      colorBrightness: widget.colorBrightness,
      padding: widget.padding,
      shape: widget.shape,
      materialTapTargetSize: widget.materialTapTargetSize,
      icon: widget.icon,
      suffixIcon: widget.suffixIcon,
      label: widget.label,
    ));
  }

}

class TextButton extends FlatButton with MaterialButtonWithIconMixin {
  TextButton({
    Key key,
    VoidCallback onPressed,
    ValueChanged<bool> onHighlightChanged,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    MaterialTapTargetSize materialTapTargetSize,
    Widget icon,
    Widget suffixIcon,
    Widget label,
  }) : super(
        key: key,
        onPressed: onPressed ?? () {},
        onHighlightChanged: onHighlightChanged,
        textTheme: textTheme,
        textColor: textColor,
        disabledTextColor: disabledTextColor,
        color: color,
        disabledColor: disabledColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
        colorBrightness: colorBrightness,
        padding: padding,
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        materialTapTargetSize: materialTapTargetSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon ?? Container(),
            label ?? Container(),
            suffixIcon ?? Container(),
          ],
        ),
      );
}

int currentPage(PageController pageController) {
  return pageController?.page?.round() ?? pageController.initialPage;
}

/*
TODO: int hasNextPage(PageController pageController) {
}
*/

typedef ConsumeFunction<T, R> = R Function(T value);
typedef Callable<T> = void Function(T value);
typedef Runnable = void Function();

class PasswordField extends StatefulWidget {
  PasswordField({Key key,
    this.text,
    this.controller,
    this.autovalidate,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.validator,
    this.onTextChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.maxLength,
  }) : super(key: key);

  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;
  final bool autovalidate;
  final FocusNode focusNode;
  final String text;
  final String labelText;
  final FormFieldValidator<String> validator;
  //final Function2<String, String> onTextChanged;
  final Callable<String> onTextChanged;
  final bool autofocus;
  final controller;
  final int maxLength;
  final String hintText;

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  TextEditingController textController;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    textController = widget.controller ?? TextEditingController();
    _autovalidate = widget.autovalidate ?? false;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (_autovalidate) {
        return;
      }
      if (!_focusNode.hasFocus) {
        setState(() => _autovalidate = true);
      }
    });
    if (textController.text == null || textController.text.isEmpty) {
      textController.text = widget.text;
    }
  }

  @override
  void dispose() {
    textController?.dispose();
    super.dispose();
  }

  bool _obscureText = true;
  bool _autovalidate = false;

  @override
  Widget build(BuildContext context) {
    Fimber.d(textController.text);
    Fimber.d(widget.text);

    return TextFormField(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      maxLength: widget.maxLength,
      controller: addTextChangedListener(textController, (text) {
        if (widget.onTextChanged != null) {
          widget.onTextChanged(text);
        }
      }),
      obscureText: _obscureText,
      autovalidate: _autovalidate,
      validator: widget.validator != null ? widget.validator : (text) {
        if (!hasUpperCase(text)) {
          //loginConsumer.invalidate();
          return S.of(context).password_validation;
        } else if (!hasDigits(text)) {
          //loginConsumer.invalidate();
          return S.of(context).password_validation;
        } else if (!hasLowerCase(text)) {
          //loginConsumer.invalidate();
          return S.of(context).password_validation;
        } else if (text.isEmpty) {
          //loginConsumer.invalidate();
          return S.of(context).password_validation;
        } else if (text.length < 8) {
          //loginConsumer.invalidate();
          return S.of(context).password_validation;
        } else if (hasWhitespace(text)) {
          //loginConsumer.invalidate();
          return S.of(context).no_whitespace;
        }
        //loginConsumer.invalidate();
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: widget.hintText == null ? (widget.labelText ?? S.of(context).password) : null,
        hintText:  widget.hintText,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            )
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 18.0),
        suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            tooltip: _obscureText ? S.of(context).show_password : S.of(context).hide_password,
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
        ),
      ),
    );
  }
}

class SimpleNeverScrollableScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that does not let the user scroll.
  const SimpleNeverScrollableScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  SimpleNeverScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SimpleNeverScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;

  @override
  bool get allowImplicitScrolling => true;
}

class Page extends StatelessWidget {
  final page;
  final index;

  Page({
    @required this.page,
    @required this.index,
  });

  onTap() {
    Fimber.d("${this.index} selected.");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Card(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  this.page,
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: this.onTap),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

FocusNode addListener(FocusNode focusNode, Callable<FocusNode> listener) {
  focusNode.addListener(() {
    listener(focusNode);
  });
  return focusNode;
}

Widget getDefaultFlagImage(String countryCode) {
  return Image.asset(
    CountryPickerUtils.getFlagImageAssetPath(countryCode),
    height: 20.0,
    width: 30.0,
    fit: BoxFit.fill,
    package: "country_pickers",
  );
}

/// An indicator showing the currently selected page of a PageController
class DotsIndicator extends AnimatedWidget {
  DotsIndicator({
    this.controller,
    this.itemCount,
    this.onPageSelected,
    this.color: Colors.white,
    this.selectedColor: Colors.black,
    this.dotSize: 8.0,
    this.maxZoom: 2.0,
    this.interval: 25.0,
  }) : super(listenable: controller);

  /// The PageController that this DotsIndicator is representing.
  final PageController controller;

  /// The number of items managed by the PageController
  final int itemCount;

  /// Called when a dot is tapped
  final ValueChanged<int> onPageSelected;

  /// The color of the dots.
  final Color color;
  final Color selectedColor;

  // The base size of the dots
  final double dotSize;

  // The increase in the size of the selected dot
  final double maxZoom;

  // The distance between the center of each dot
  final double interval;

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    double zoom = 1.0 + (maxZoom - 1.0) * selectedness;
    Color _color = selectedness > 0.1 ? selectedColor : color;

    return Container(
      width: interval,
      child: Center(
        child: Material(
          color: _color,
          type: MaterialType.circle,
          child: Container(
            width: dotSize * zoom,
            height: dotSize * zoom,
            child: InkWell(
              onTap: () => onPageSelected(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, _buildDot),
    );
  }
}

class RevealProgressButton extends StatefulWidget {
  final bool animated;

  RevealProgressButton({Key key, this.animated}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RevealProgressButtonState();
}

class _RevealProgressButtonState extends State<RevealProgressButton>
    with TickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;
  double _fraction = 0.0;
  bool isAnimated = false;

  @override
  Widget build(BuildContext context) {
    if (widget.animated) {
      if (!isAnimated) {
        isAnimated = true;
        reveal();
      }
      return CustomPaint(
        painter: RevealProgressButtonPainter(_fraction, MediaQuery.of(context).size),
      );
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    _fraction = 0.0;
  }


  @override
  dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void reveal() {
    _controller = AnimationController(
        duration: Duration(milliseconds: 300), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: Curves.fastOutSlowIn))
      )
      ..addListener(() {
        setState(() {
          _fraction = _animation.value;
        });
      });

    _controller.forward();
  }

}

class RevealProgressButtonPainter extends CustomPainter {
  double _fraction = 0.0;
  Size _screenSize;

  RevealProgressButtonPainter(this._fraction, this._screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = floPrimaryColor
      ..style = PaintingStyle.fill;

    var finalRadius = sqrt(pow(_screenSize.width, 2) + pow(_screenSize.height, 2));
    var radius = finalRadius * _fraction;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(RevealProgressButtonPainter oldDelegate) {
    return oldDelegate._fraction != _fraction;
  }
}

typedef bool Predicate<T>(T value);
typedef Widget ItemBuilder<T>(T value);
typedef Widget ItemBuilder2<T, R>(T, R);
//bool acceptAllCountries(_) => true;

// = Text(S.of(context).country, textAlign: TextAlign.center)
class SimplePickerDropdown<T> extends StatefulWidget {
  SimplePickerDropdown({
    @required
    this.items,
    @required
    this.builder,
    this.selection,
    this.filter,
    this.initialValue,
    this.onValuePicked,
    this.onChanged,
    this.hint,
  });
  final Predicate<T> filter;
  final Text hint;
  final ItemBuilder builder;
  final T initialValue;
  //final String initialValue;
  final ConsumeFunction<dynamic, Comparable> selection;

  //final ValueChanged<T> onValuePicked; // (Locale) = Null is not a subtype of type '(dynamic) => void'
  final ValueChanged onValuePicked;
  final ValueChanged onChanged;
  final Iterable<T> items;

  @override
  _PickerDropdownState createState() => _PickerDropdownState<T>();
}

class _PickerDropdownState<T> extends State<SimplePickerDropdown> {
  Iterable<T> _items;
  T _selected;
  ValueChanged _onChanged;
  //ConsumeFunction<dynamic, Comparable> _selection;
  Iterable<DropdownMenuItem<T>> buildItems;
  bool _dirty = true;

  @override
  void initState() {
    super.initState();
    _onChanged = widget.onChanged ?? (_) {};
    _selected = widget.initialValue;
    _dirty = true;
    _items = widget.items ?? [];
  }

  @override
  void didUpdateWidget(SimplePickerDropdown oldWidget) {
    //Fimber.d("widget.initialValue: ${widget.initialValue}");
    //Fimber.d("oldWidget.initialValue: ${oldWidget.initialValue}");
    if (oldWidget.initialValue != widget.initialValue) {
      _selected = widget.initialValue;
      //_dirty = true;
    }
    //Fimber.d("_selected: ${_selected}");
    if (oldWidget.items != widget.items) {
      _selected = widget.initialValue;
      _items = widget.items ?? [];
      _dirty = true;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    try {
      _selected = _items.where((it) => it != null).firstWhere((item) {
        if (_selected == null) { return false; }
        if (item == _selected) { return true; }
        if (widget.selection != null) {
          //Fimber.d("!!! each ${item} =? ${widget.initialValue} : ${widget.selection(item)} == ${widget.selection(widget.initialValue)}");
          //Fimber.d("select: ${widget.selection(item)} : ${widget.selection(_selected)}");
          if (widget.selection(item) == widget.selection(_selected)) {
            return true;
          }
        }
        return false;
      },
      //orElse: () => _items.first
      );
    } catch (err) {
      _selected = null;
      //Fimber.e( "The initialValue provided is not a supported!", ex: err);
    }
    if (_selected == null && _items.length == 1) {
      _selected = _items.first;
    }

    if (_dirty) {
      buildItems = _items
          .map((item) => DropdownMenuItem<T>(
              value: item,
              child: widget.builder(item)))
          .toList();
      _dirty = false;
    }

    //Fimber.d("selected: $_selected");
    //Fimber.d("items: $_items");
    return DropdownButtonHideUnderline(
          child: Padding(padding: EdgeInsets.all(12), child: ButtonTheme(
             alignedDropdown: true,
          child: DropdownButton<T>(
            isDense: true,
            hint: widget.hint,
            isExpanded: true,
            onChanged: (T value) {
              if (_selected != value) {
                if (widget.onValuePicked != null) {
                  widget.onValuePicked(value);
                }
                setState(() {
                  _selected = value;
                });
              }
            },
            items: buildItems,
            value: _selected,
          )
        )),
    );
  }

/*
  Widget _buildDefaultMenuItem(T item) {
    return Row(
      children: <Widget>[
        CountryPickerUtils.getDefaultFlagImage(item),
        SizedBox(
          width: 8.0,
        ),
        Text("(${country.isoCode}) +${country.phoneCode}"),
      ],
    );
  }
*/
}
//final BuiltList<Country> countries =  ListBuilder<Country>(countryList);
/*
List.from()countryList
  countryList.add();
*/


Country getCountryByIsoCode(String isoCode) {
  // TODO: to be const
  final countriesBuilder = BuiltList<Country>(countryList).toBuilder();
  countriesBuilder.add(Country(
        isoCode: "UK",
        phoneCode: "44",
        name: "United Kingdom",
        iso3Code: "GBR",
    ));
  try {
    return countriesBuilder.build().firstWhere(
      (country) => country.isoCode.toLowerCase() == isoCode.toLowerCase(),
    );
  } catch (error) {
    throw Exception("The initialValue provided is not a supported iso code!");
  }
}

TextEditingController addTextChangedListener(TextEditingController controller, Function(String text) listener) {
  controller.addListener(() {
    listener(controller.text);
  });
  return controller;
}

TextEditingController addTextChangesListener(TextEditingController controller, Function listener) {
  controller.addListener(() {
    listener(controller);
  });
  return controller;
}
const double CIRCLE_SIZE = 60;
const double ARC_HEIGHT = 70;
const double ARC_WIDTH = 90;
const double CIRCLE_OUTLINE = 10;
const double SHADOW_ALLOWANCE = 20;
const double BAR_HEIGHT = 60;

class SimpleFancyBottomNavigation extends StatefulWidget {
  SimpleFancyBottomNavigation(
      {@required this.tabs,
      @required this.onTabChangedListener,
      this.key,
      this.initialSelection = 0,
      this.circleGradient,
      this.circleColor,
      this.activeIconColor,
      this.inactiveIconColor,
      this.textColor,
      this.barBackgroundColor})
      : assert(onTabChangedListener != null),
        assert(tabs != null),
        assert(tabs.length > 1 && tabs.length < 5);

  final Function(int position) onTabChangedListener;
  final Color circleColor;
  final LinearGradient circleGradient;
  final Color activeIconColor;
  final Color inactiveIconColor;
  final Color textColor;
  final Color barBackgroundColor;
  final List<TabData> tabs;
  final int initialSelection;

  final Key key;

  @override
  SimpleFancyBottomNavigationState createState() => SimpleFancyBottomNavigationState();
}

class SimpleFancyBottomNavigationState extends State<SimpleFancyBottomNavigation>
    with TickerProviderStateMixin, RouteAware {
  IconData nextIcon = Icons.search;
  IconData activeIcon = Icons.search;
  String nextIconAsset;
  String activeIconAsset;

  int currentSelected = 0;
  double _circleAlignX = 0;
  double _circleIconAlpha = 1;

  Color circleColor;
  LinearGradient circleGradient;
  Color activeIconColor;
  Color inactiveIconColor;
  Color barBackgroundColor;
  Color textColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    activeIcon = widget.tabs[currentSelected].iconData;
    activeIconAsset = widget.tabs[currentSelected].icon;

    circleColor = (widget.circleColor == null)
        ? (Theme.of(context).brightness == Brightness.dark)
            ? Colors.white
            : Theme.of(context).primaryColor
        : widget.circleColor;
    circleGradient = widget.circleGradient;

    activeIconColor = (widget.activeIconColor == null)
        ? (Theme.of(context).brightness == Brightness.dark)
            ? Colors.black54
            : Colors.white
        : widget.activeIconColor;

    barBackgroundColor = (widget.barBackgroundColor == null)
        ? (Theme.of(context).brightness == Brightness.dark)
            ? Color(0xFF212121)
            : Colors.white
        : widget.barBackgroundColor;
    textColor = (widget.textColor == null)
        ? (Theme.of(context).brightness == Brightness.dark)
            ? Colors.white
            : Colors.black54
        : widget.textColor;
    //inactiveIconColor = activeIconColor.withAlpha(100);
    inactiveIconColor = activeIconColor;
  }

  @override
  void initState() {
    super.initState();
    _setSelected(widget.tabs[widget.initialSelection].key);
  }

  _setSelected(UniqueKey key) {
    int selected = widget.tabs.indexWhere((tabData) => tabData.key == key);

        currentSelected = selected;
        _circleAlignX = -1 + (2 / (widget.tabs.length - 1) * selected);
        nextIcon = widget.tabs[selected].iconData;
        nextIconAsset = widget.tabs[selected].icon;
    if (mounted) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          height: BAR_HEIGHT,
          decoration: BoxDecoration(color: barBackgroundColor, boxShadow: [
            BoxShadow(
                color: Colors.black12, offset: Offset(0, -1), blurRadius: 8)
          ]),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widget.tabs
                .map((t) => SimpleTabItem(
                    uniqueKey: t.key,
                    selected: t.key == widget.tabs[currentSelected].key,
                    iconData: t.iconData,
                    icon: t.icon,
                    title: t.title,
                    iconColor: inactiveIconColor,
                    textColor: textColor,
                    callbackFunction: (uniqueKey) {
                      int selected = widget.tabs
                          .indexWhere((tabData) => tabData.key == uniqueKey);
                      widget.onTabChangedListener(selected);
                      _setSelected(uniqueKey);
                      _initAnimationAndStart(_circleAlignX, 1);
                    }))
                .toList(),
          ),
        ),
        Positioned.fill(
          top: -(CIRCLE_SIZE + CIRCLE_OUTLINE + SHADOW_ALLOWANCE) / 3,
          child: Container(
            child: AnimatedAlign(
              duration: Duration(milliseconds: ANIM_DURATION),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment(_circleAlignX, 1),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: FractionallySizedBox(
                  widthFactor: 1 / widget.tabs.length,
                  child: GestureDetector(
                    onTap: widget.tabs[currentSelected].onclick,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        /*
                        SizedBox(
                          height:
                              CIRCLE_SIZE + CIRCLE_OUTLINE + SHADOW_ALLOWANCE,
                          width:
                              CIRCLE_SIZE + CIRCLE_OUTLINE + SHADOW_ALLOWANCE,
                          child: ClipRect(
                              clipper: HalfClipper(),
                              child: Container(
                                child: Center(
                                  child: Container(
                                      width: CIRCLE_SIZE + CIRCLE_OUTLINE,
                                      height: CIRCLE_SIZE + CIRCLE_OUTLINE,
                                      decoration: BoxDecoration(
                                          color: barBackgroundColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: barBackgroundColor,
                                                blurRadius: 8)
                                          ])),
                                ),
                              )),
                        ),
                        SizedBox(
                            height: ARC_HEIGHT,
                            width: ARC_WIDTH,
                            child: CustomPaint(
                              painter: HalfPainter(barBackgroundColor),
                            )),
                            */
                        SizedBox(
                          height: CIRCLE_SIZE,
                          width: CIRCLE_SIZE,
                          child: Container(
                            decoration: circleGradient != null ?
                                BoxDecoration(gradient: circleGradient, shape: BoxShape.circle, color: circleColor) :
                                BoxDecoration(shape: BoxShape.circle, color: circleColor),
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: ANIM_DURATION ~/ 5),
                                opacity: _circleIconAlpha,
                                child: activeIconAsset != null ? Transform.scale(scale: 0.4, child: SvgPicture.asset(activeIconAsset, color: activeIconColor)) : Icon(
                                  activeIcon,
                                  color: activeIconColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  _initAnimationAndStart(double from, double to) {
    _circleIconAlpha = 0.7;

    Future.delayed(Duration(milliseconds: ANIM_DURATION ~/ 5), () {
      setState(() {
        activeIcon = nextIcon;
        activeIconAsset = nextIconAsset;
      });
    }).then((_) {
      Future.delayed(Duration(milliseconds: (ANIM_DURATION ~/ 5 * 3)), () {
        setState(() {
          _circleIconAlpha = 1;
        });
      });
    });
  }

  void setPage(int page) {
    widget.onTabChangedListener(page);
    _setSelected(widget.tabs[page].key);
    _initAnimationAndStart(_circleAlignX, 1);

    setState(() {
      currentSelected = page;
    });
  }

  void setPageSliently(int page) {
    //widget.onTabChangedListener(page);
    _setSelected(widget.tabs[page].key);
    _initAnimationAndStart(_circleAlignX, 1);

    setState(() {
      currentSelected = page;
    });
  }
}

class TabData {
  TabData({
    this.iconData,
    this.icon,
    @required this.title, this.onclick});

  IconData iconData;
  String icon;
  String title;
  Function onclick;
  final UniqueKey key = UniqueKey();
}

const double ICON_OFF = -3;
const double ICON_ON = 0;
const double TEXT_OFF = 3;
const double TEXT_ON = 1;
const double ALPHA_OFF = 1.0;
const double ALPHA_ON = 0.3;
const int ANIM_DURATION = 250;

class SimpleTabItem extends StatelessWidget {
  SimpleTabItem(
      {@required this.uniqueKey,
        @required this.selected,
        this.icon,
        this.iconData,
        @required this.title,
        @required this.callbackFunction,
        @required this.textColor,
        @required this.iconColor,
        });

  final UniqueKey uniqueKey;
  final String title;
  final IconData iconData;
  final String icon;
  final bool selected;
  final Function(UniqueKey uniqueKey) callbackFunction;
  final Color textColor;
  final Color iconColor;

  final double iconYAlign = ICON_ON;
  final double textYAlign = TEXT_OFF;
  final double iconAlpha = ALPHA_ON;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            child: AnimatedAlign(
                duration: Duration(milliseconds: ANIM_DURATION),
                alignment: Alignment(0, (selected) ? TEXT_ON : TEXT_OFF),
                child: title.isNotEmpty ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textColor),
                  ),
                ) : Container()),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            child: AnimatedAlign(
              duration: Duration(milliseconds: ANIM_DURATION),
              curve: Curves.easeIn,
              alignment: Alignment(0, (selected) ? ICON_OFF : ICON_ON),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: ANIM_DURATION),
                opacity: (selected) ? ALPHA_OFF : ALPHA_ON,
                child: IconButton(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  padding: EdgeInsets.all(0),
                  alignment: Alignment(0, 0),
                  icon: icon != null ? SvgPicture.asset(icon, color: iconColor, width: 24, height: 24) : Icon(
                    iconData,
                    color: iconColor,
                  ),
                  onPressed: () {
                    callbackFunction(uniqueKey);
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class EmptyDeviceCard extends StatelessWidget {
  EmptyDeviceCard({Key key,
    this.width = 140,
    this.height = 140
  }) : super(key: key);
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(6.0), child: InkWell(onTap: () {
      Navigator.of(context).pushNamed('/add_a_flo_device');
    }, child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          border: DashPathBorder.all(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                  dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
                ),
          color: Colors.white.withOpacity(0.1),
        ),
        width: width,
        height: height,
        child: Padding(padding: EdgeInsets.all(12.0), child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Transform.scale(scale: 0.8,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(Icons.add))),
            Spacer(),
            Text(S.of(context).connect_new_device, textScaleFactor: 1.1, textAlign: TextAlign.center,),
            Spacer(),
          ],
        )))));
  }
}

class DeviceCard extends StatelessWidget {

  DeviceCard({Key key, this.device}) : super(key: key);

  final Device device;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);

    Widget wifIcon;
    final isConnected = device?.isConnected ?? false;
    if (isConnected) {
      wifIcon = WifiSignalIcon(device?.connectivity?.rssi?.toDouble() ?? -40, color: Colors.white,
      height: 20,
      );
    } else {
      wifIcon = SvgPicture.asset('assets/ic_wifi_offline.svg', height: 20,);
    }
    Fimber.d("${device?.displayName}: device.notifications?.pending: ${device.notifications?.pending}");


    final installed = (device?.installStatus?.isInstalled ?? false);
    Widget alertIcon = Container();
    final isLearning = (device?.isLearning ?? false);
    if (!isConnected) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 5), child: Image.asset('assets/ic_warning2.png', width: 20, height: 20,));
    } else if (!installed) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 5), child: Image.asset('assets/ic_warning2.png', width: 20, height: 20,));
    } else if (isLearning) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 3), child: Image.asset('assets/ic_info_blue.png', width: 25, height: 25,));
    } else {
      if ((device.notifications?.pending?.criticalCount ?? 0) > 0) {
        alertIcon = Container(
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 4),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: floRed,
              /*
              boxShadow: [
                BoxShadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 1)
              ],
              */
              shape: BoxShape.circle,
            ),
            child: Text("${min((device.notifications?.pending?.criticalCount ?? 0), 99)}", textScaleFactor: 0.8, textAlign: TextAlign.center,)
        );
      } else if ((device.notifications?.pending?.warningCount ?? 0) > 0) {
        alertIcon = Container(
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 4),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: floAmber,
              /*
              boxShadow: [
                BoxShadow(color: Colors.black, offset: Offset(1, 1))
              ],
              */
              shape: BoxShape.circle,
            ),
            child: Text("${min((device.notifications?.pending?.warningCount ?? 0), 99)}", textScaleFactor: 0.8, textAlign: TextAlign.center,)
        );
      }
    }

    final runningHealthTest = (device?.healthTest?.status == HealthTest.RUNNING);
    Widget warningText = Container();
    if (!isConnected) {
      warningText = Text(S.of(context).offline, style: Theme.of(context).textTheme.caption.copyWith(color: floWarningRed), textAlign: TextAlign.end, softWrap: true,);
    } else if (!installed) {
      warningText = Text(S.of(context).needs_install, style: Theme.of(context).textTheme.caption.copyWith(color: floWarningRed), textAlign: TextAlign.end, softWrap: true);
    } else if (runningHealthTest) {
      warningText = Text(S.of(context).health_test__running, style: Theme.of(context).textTheme.caption.copyWith(color: floWarningRed), textAlign: TextAlign.end, softWrap: true);
    } else if (device?.valve?.closed ?? false) {
      warningText = Text(S.of(context).valve_closed, style: Theme.of(context).textTheme.caption.copyWith(color: floWarningRed), textAlign: TextAlign.end, softWrap: true);
    } else if (isLearning) {
      warningText = Text(S.of(context).learning, style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white), textAlign: TextAlign.end, softWrap: true);
    }
    return Padding(padding: EdgeInsets.all(6.0), child: InkWell(onTap: () {
      deviceProvider.value = device;
      deviceProvider.invalidate();
      Navigator.of(context).pushNamed('/flo_device');
    }, child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          color: Colors.white.withOpacity(0.2),
        ),
        width: 160,
        height: 140,
        child: Padding(padding: EdgeInsets.all(12.0), child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              (device?.valve?.open ?? true) ? Image.asset('assets/ic_flo_device.png', height: 60) : Image.asset('assets/ic_flo_device_off2.png', height: 60),
              Expanded(child: Column(
                children: <Widget>[
                Row(children: <Widget>[
                  Padding(padding: EdgeInsets.symmetric(vertical: 5), child: wifIcon),
                  alertIcon,
                ],
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                SizedBox(height: 0),
                Expanded(child: warningText),
              ],
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
              )),
              //Svg.asset('assets/ic_wifi_white_low.svg', width: 20, height: 20),
            ])),
            Text(device.displayNameOf(context)),
            //Opacity(opacity: 0.7, child: Text(device.installationPoint ?? "", textScaleFactor: 1.0)),
            SizedBox(height: 5),
          ],
        )))));
  }
}

class YoureSecure extends StatelessWidget {
  //final int index;
  //YoureSecure({Key key, this.index}) : super(key: key);
  YoureSecure({Key key,
    this.margin = const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
  }) : super(key: key);
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          color: Colors.white.withOpacity(0.2),
        ),
        height: 65,
        child: Row(
          children: <Widget>[
            SizedBox(width: 20,),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Color(0xFF42DCF4).withOpacity(0.3), offset: Offset(0, 5), blurRadius: 14)
              ],
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 1],
                colors: [
                  Color(0xFF5BE9F9),
                  Color(0xFF12C3EA)
                ],
              ),
              border: Border.all(color: Colors.white, width: 0.2),
            ),
            child: Icon(Icons.check, size: 20)),
            SizedBox(width: 20),
            Column(
              children: <Widget>[
                Text(
                  S.of(context).youre_secure_,
                  style: Theme.of(context).textTheme.title,
                  textScaleFactor: 0.9,
                ),
                SizedBox(height: 5),
                Text(S.of(context).no_alerts,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  textScaleFactor: 0.9,
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ],
        ));
  }
}

class OffBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Color(0xFFA4B6C0),
        ),
        child: Row(
          children: <Widget>[
            Center(
              child: Image.asset('assets/ic_protect.png', width: 15, height: 15),
            ),
            SizedBox(width: 5),
            Text(
              S.of(context).off,
              style: TextStyle(fontSize: 12.0, color: Colors.white),
            ),
          ],
        ));
  }
}

class OnBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Color(0xFF6DD04C),
        ),
        child: Row(
          children: <Widget>[
            Center(
              child: Image.asset('assets/ic_protect.png', width: 15, height: 15),
            ),
            SizedBox(width: 5),
            Text(
              S.of(context).on,
              style: TextStyle(fontSize: 12.0, color: Colors.white),
            ),
          ],
        ));
  }
}

class SleepBadge extends StatelessWidget {
  //AwayBadge({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Text(
              S.of(context).sleep,
              style: TextStyle(fontSize: 12.0, color: Color(0xFF084063)),
            ),
          ],
        ));
  }
}

class OfflineBadge extends StatelessWidget {
  OfflineBadge({Key key,
    this.opacity = 0.5,
  }): super(key: key);
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: opacity, child: TextBadge(ReCase(S.of(context).offline).titleCase));
  }
}

class LearningBadge extends StatelessWidget {
  LearningBadge({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TextBadge(S.of(context).learning);
  }
}

class TextBadge extends StatelessWidget {
  TextBadge(this.label, {
    Key key,
    this.dark = false,
  }): super(key: key);
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Text(
              label ?? S.of(context).learning,
              style: TextStyle(fontSize: 12.0, color: dark ? Color(0xFF084063) : Color(0xFF084063)),
            ),
          ],
        ));
  }
}

class HomeBadge extends StatelessWidget {
  //AwayBadge({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Text(
              S.of(context).home,
              style: TextStyle(fontSize: 12.0, color: Color(0xFF084063)),
            ),
          ],
        ));
  }
}

class AwayBadge extends StatelessWidget {
  //AwayBadge({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(floBadgeRadius)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            Text(
              S.of(context).away,
              style: TextStyle(fontSize: 12.0, color: Color(0xFF084063)),
            ),
          ],
        ));
  }
}

class LocationCard extends StatelessWidget {
  LocationCard({Key key,
   @required
   this.location,
   this.onTap,
   }) : super(key: key);

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Colors.transparent;
    bool showBadge = false;
    int count = 0;
    Fimber.d("subscription:: ${location.nickname} ${location.subscription}");
    Fimber.d("${location?.nickname}.notifications: ${location?.notifications}");
    if ((location?.notifications?.pending?.criticalCount ?? 0) > 1) {
      badgeColor = floRed;
      showBadge = true;
      count = location?.notifications?.pending?.criticalCount ?? 0;
    } else if ((location?.notifications?.pending?.warningCount ?? 0) > 1) {
      badgeColor = floAmber;
      showBadge = true;
      count = location?.notifications?.pending?.warningCount ?? 0;
    }
    return
    Padding(padding: EdgeInsets.only(top: 8, right: 16.0, left: 16.0), child: SimpleBadge(
      badgeColor: badgeColor,
      shape: BadgeShape.circle,
      //border: Border.all(color: Colors.white, width: 2),
      border: CircleBorder(
        side: BorderSide(color: Colors.white, width: 3),
      ),
      padding: const EdgeInsets.all(6),
      elevation: 0,
      toAnimate: true,
      showBadge: showBadge,
      animationType: BadgeAnimationType.scale,
      //badgeContent: SizedBox(height: 15, width: 15, child: Center(child: Text("${min(count, 99)}", style: TextStyle(color: Colors.white), textScaleFactor: 0.6, textAlign: TextAlign.center))),
      badgeContent: Center(child: Text("${min(count, 99)}", style: TextStyle(color: Colors.white), textScaleFactor: 0.8, textAlign: TextAlign.center)),
    child:
    Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          color: Color(0xFFF0F4F8),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.0, 1.0],
            colors: [
              Color(0xFF0C679C),
              floPrimaryColor,
            ],
          ),
          //border: Border.all(color: showBadge ? badgeColor : Colors.transparent, width: 1),
        ),
        child: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () {
            final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
            locationProvider.value = location;
            locationProvider.invalidate();
            if (onTap != null) {
              onTap();
            }
            //Navigator.of(context).pushNamed('/location_details');
          },
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Opacity(opacity: 0.5, child: SystemModeBadge(location: location)),
                  ],
                ),
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: (location.nickname != null)
                   ? Text("${location.nickname}", style: TextStyle(color: Colors.white, fontSize: 20))
                   : Text("${location.address}", style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text("${location.address}",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 10),
                (location.subscription?.isActive ?? false) ? FloProtectActiveButton() : FloProtectInactiveButton(),
                SizedBox(height: 20),
              ],
            ))))));
  }
}

class NormalLocationCard extends StatelessWidget {
  NormalLocationCard({Key key,
   @required this.location,
   this.onTap,
   }) : super(key: key);

  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Colors.transparent;
    bool showBadge = false;
    int count = 0;
    if ((location?.notifications?.pending?.criticalCount ?? 0) > 1) {
      badgeColor = floRed;
      showBadge = true;
      count = location?.notifications?.pending?.criticalCount ?? 0;
    } else if ((location?.notifications?.pending?.warningCount ?? 0) > 1) {
      badgeColor = floAmber;
      showBadge = true;
      count = location?.notifications?.pending?.warningCount ?? 0;
    } else {
    }
    return
    Padding(padding: EdgeInsets.only(top: 8, right: 16.0, left: 16.0), child: SimpleBadge(
      badgeColor: badgeColor,
      shape: BadgeShape.circle,
      //border: Border.all(color: Colors.white, width: 2),
      border: CircleBorder(
        side: BorderSide(color: Colors.white, width: 3),
      ),
      elevation: 0,
      toAnimate: true,
      showBadge: showBadge,
      animationType: BadgeAnimationType.scale,
      //badgeContent: SizedBox(height: 12, width: 12, child: Text("${min(count, 99)}", style: TextStyle(color: Colors.white), textScaleFactor: 0.8, textAlign: TextAlign.center)),
      padding: const EdgeInsets.all(6),
      badgeContent: Center(child: Text("${min(count, 99)}", style: TextStyle(color: Colors.white), textScaleFactor: 0.8, textAlign: TextAlign.center)),
    child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          color: Color(0xFFF0F4F8),
          border: Border.all(color: badgeColor, width: 1),
        ),
        child: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () {
            final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
            locationProvider.value = location;
            locationProvider.invalidate();
            if (onTap != null) {
              onTap();
            }
          },
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    SystemModeBadge(location: location),
                    SizedBox(width: 10),
                    OffBadge(),
                  ],
                ),
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: (location.nickname != null)
                   ? Text("${location.nickname}", style: TextStyle(color: Colors.black, fontSize: 20))
                   : Text("${location.address}", style: TextStyle(color: Colors.black, fontSize: 20)),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text("${location.address}",
                        style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ))))));
  }
}

class NormalLocationCard2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(right: 16.0, left: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          color: Color(0xFFF0F4F8),
        ),
        child: FlatButton(onPressed: () {
            Navigator.of(context).pushNamed('/location_details');
          },
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    AwayBadge(),
                    SizedBox(width: 10),
                    OffBadge(),
                  ],
                ),
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Address",
                      style: TextStyle(color: Colors.black, fontSize: 20)),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text("Manage by N People",
                        style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ))));
  }
}

class SimpleCountryCodePicker extends StatefulWidget {
  final ValueChanged<CountryCode> onChanged;
  final ValueChanged<CountryCode> onPicked;
  final String initialSelection;
  final List<String> favorite;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final bool showCountryOnly;

  SimpleCountryCodePicker({
    ValueChanged<CountryCode> onPicked,
    this.onChanged,
    this.initialSelection,
    this.favorite = const [],
    this.textStyle,
    this.padding = const EdgeInsets.all(0.0),
    this.showCountryOnly = false,
  }) : this.onPicked = onPicked ?? ((_) {});

  @override
  State<StatefulWidget> createState() {
    List<Map> jsonList = codes;

    List<CountryCode> elements = countryCodes.toList();

    return new _CountryCodePickerState(elements);
  }
}

class _CountryCodePickerState extends State<SimpleCountryCodePicker> {
  CountryCode selectedItem;
  List<CountryCode> elements = const [];
  Map<String, CountryCode> _elementsMap = const {};
  Map<String, CountryCode> _dialCodesMap = const {};
  List<CountryCode> favoriteElements = const [];

  _CountryCodePickerState(this.elements);

  @override
  void didUpdateWidget(SimpleCountryCodePicker oldWidget) {
    if (widget.initialSelection != oldWidget.initialSelection) {
      _updateSelection();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateSelection() {
    Fimber.d("selection: ${widget.initialSelection}");
    Fimber.d("last selected: ${selectedItem}");
    selectedItem = (widget.initialSelection != null ? _elementsMap[widget.initialSelection] ?? _dialCodesMap[widget.initialSelection] : elements.first)
        ?? selectedItem ?? elements.first;
    Fimber.d("selected: ${selectedItem}");
  }

  @override
  Widget build(BuildContext context) {
     return FlatButton(
        child: /*Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
              true ? Container() : Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Image.asset(
                  selectedItem.flagUri,
                  package: 'country_code_picker',
                  width: 32.0,
                ),
              ),
              Text(
                widget.showCountryOnly
                    ? selectedItem.toCountryStringOnly()
                    : selectedItem.toString(),
                style: widget.textStyle ?? Theme.of(context).textTheme.button,
              ),
          ],
        ),
              */
              Text(
                widget.showCountryOnly
                    ? selectedItem.toCountryStringOnly()
                    : selectedItem.toString(),
                style: widget.textStyle ?? Theme.of(context).textTheme.button,
              ),
        padding: widget.padding,
        onPressed: _showSelectionDialog,
      );
  }

  @override
  initState() {
    //Fimber.d("init: ${BuiltList<CountryCode>(elements)}");
    _elementsMap = Maps.fromIterable<CountryCode, String, CountryCode>(elements, key: (it) => it.code);
    _dialCodesMap = Maps.fromIterable<CountryCode, String, CountryCode>(elements, key: (it) => it.dialCode);
    _updateSelection();
    favoriteElements = elements
        .where((e) =>
            widget.favorite.firstWhere(
                (f) => e.code == f.toUpperCase() || e.dialCode == f.toString(),
                orElse: () => null) !=
            null)
        .toList();
    super.initState();

    if (mounted) {
      _publishSelection(selectedItem);
    }
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (_) => new SelectionDialog(elements, favoriteElements,
          showFlag: true,
          showCountryOnly: widget.showCountryOnly),
    ).then((it) {
      if (it != null) {
        setState(() {
          selectedItem = it;
        });

        widget.onPicked(it);
        _publishSelection(it);
      }
    });
  }

  void _publishSelection(CountryCode e) {
    if (widget.onChanged != null) {
      widget.onChanged(e);
    }
  }
}

bool get isDebuggable {
  bool _isDebuggable = false;
  assert(_isDebuggable = true);
  return _isDebuggable;
}


class AddDevice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(offset: Offset(0, 0), child: SizedBox(width: double.infinity, child: FlatButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(vertical: 12),
        color: Color(0xFFE3ECF2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: floCardRadius,
              bottomRight: floCardRadius,
            ),
            side: BorderSide(color: Colors.black.withOpacity(0.1))),
        child: Row(children: <Widget>[
          SizedBox(width: 20),
          Image.asset('assets/ic_circle_blue_add.png', width: 20, height: 20),
          SizedBox(width: 20),
          Expanded(child: Text(S.of(context).add_device,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.subhead,
              textScaleFactor: 0.83,
          )),
        ],),
      onPressed: () {
        Navigator.of(context).pushNamed('/add_a_flo_device');
      },
    )),
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/add_a_flo_device');
        },
        child: Row(children: <Widget>[
          SizedBox(width: 10),
          Image.asset('assets/ic_circle_blue_add.png', width: 24, height: 24),
          SizedBox(width: 20),
          Expanded(child: Text(S.of(context).add_device,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.subhead,
          )),
          SizedBox(width: 20),
        ],)
    ));
  }
}

class DeviceTile extends StatefulWidget {
  DeviceTile(this. device, {Key key}) : super(key: key);
  final Device device;

  @override
  _DeviceTileState createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile> {
  Notifications _notification;

  @override
  void initState() {
    invalidate();
    super.initState();
  }

  void invalidate() {
    _notification = widget.device.notifications?.pending;
    if (_notification == null) return;
    final hasSeverity = _notification.hasSeverity ?? false;
    try {
      Fimber.d("hasSeverity: ${hasSeverity}");
      if (!hasSeverity) {
        final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
        if (alarms.isEmpty) {
          Future.delayed(Duration.zero, () async {
            try {
              final flo = Provider .of<FloNotifier>(context) .value;
              final oauth = Provider .of<OauthTokenNotifier>(context) .value;
              final alarmProvider = Provider.of<AlarmsNotifier>(context, listen: false);
              alarmProvider.value = (await flo.getAlarms(authorization: oauth.authorization)).body.items;
              final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
              if (alarms?.isNotEmpty ?? false) {
                _notification = _notification.rebuild((b) => b
                  ..alarmCounts = ListBuilder(_notification?.alarmCounts?.map((alarm) => alarm.rebuild((b) => b
                    ..severity = Maps.get2<Alarm, int>(alarms, b.id).severity
                  ))  ?? <Alarm>[])
                );
              }
              Fimber.d("_notification: ${_notification}");
              setState(() {});
            } catch (err) {
              Fimber.d("", ex: err);
            }
          });
        } else {
          _notification = _notification.rebuild((b) => b
            ..alarmCounts = ListBuilder(_notification?.alarmCounts?.map((alarm) => alarm.rebuild((b) => b
              ..severity = Maps.get2<Alarm, int>(alarms, b.id).severity
            )) ?? <Alarm>[])
          );
          Fimber.d("_notification: ${_notification}");
        }
      }
    } catch (err) {
      Fimber.d("", ex: err);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget wifIcon;
    final isConnected = widget.device?.isConnected ?? false;
    if (isConnected) {
      wifIcon = WifiSignalIcon(widget.device?.connectivity?.rssi?.toDouble() ?? -40, color: floPrimaryColor,
        height: 20,
      );
    } else {
      wifIcon = SvgPicture.asset('assets/ic_wifi_offline.svg', height: 20, color: floPrimaryColor);
    }
    Fimber.d("${widget.device?.displayName}: device.notifications?.pending: ${widget.device.notifications?.pending}");
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;

    final installed = (widget.device?.installStatus?.isInstalled ?? false);
    Widget alertIcon = Container();
    final isLearning = (widget.device?.isLearning ?? false);
    if (!isConnected) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 5, left: 2, right: 2), child: Image.asset('assets/ic_warning2.png', width: 20, height: 20,));
    } else if (!installed) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 5, left: 2, right: 2), child: Image.asset('assets/ic_warning2.png', width: 20, height: 20,));
    } else if (isLearning) {
      alertIcon = Padding(padding: EdgeInsets.only(top: 3), child: Image.asset('assets/ic_info_blue.png', width: 25, height: 25,));
    } else {
      final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
      if (alarms.isNotEmpty) {
        _notification = _notification.rebuild((b) => b
          ..alarmCounts = ListBuilder(_notification.alarmCounts.map((alarm) => alarm.rebuild((b) => b
            ..severity = Maps.get2<Alarm, int>(alarms, b.id)?.severity
          )))
        );
      }
      if ((_notification?.criticalCount ?? 0) > 0) {
        alertIcon = Container(
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 4, right: 4),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: floRed,
              /*
              boxShadow: [
                BoxShadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 1)
              ],
              */
              shape: BoxShape.circle,
            ),
            child: Text("${min((_notification?.criticalCount ?? 0), 99)}", textScaleFactor: 0.8, textAlign: TextAlign.center, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),)
        );
      } else if ((_notification?.warningCount ?? 0) > 0) {
        alertIcon = Container(
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 4, right: 4),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: floAmber,
              /*
              boxShadow: [
                BoxShadow(color: Colors.black, offset: Offset(1, 1))
              ],
              */
              shape: BoxShape.circle,
            ),
            child: Text("${min((_notification?.warningCount ?? 0), 99)}", textScaleFactor: 0.8, textAlign: TextAlign.center, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),)
        );
      } else {
        if ((location?.devices?.length ?? 0) > 1) {
        alertIcon = Container(
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 4, right: 4),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFF5BE9F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 8, color: Colors.white)
        );
        }
      }
    }

    final runningHealthTest = (widget.device?.healthTest?.status == HealthTest.RUNNING);
    Widget warningText = Container();
    if (!isConnected) {
      warningText = Text(S.of(context).offline, style: Theme.of(context).textTheme.body1.copyWith(color: floRed), textAlign: TextAlign.end, softWrap: true,);
    } else if (!installed) {
      warningText = Text(S.of(context).needs_install, style: Theme.of(context).textTheme.body1.copyWith(color: floRed), textAlign: TextAlign.end, softWrap: true);
    } else if (runningHealthTest) {
      warningText = Text(S.of(context).health_test_running, style: Theme.of(context).textTheme.body1.copyWith(color: floRed), textAlign: TextAlign.end, softWrap: true);
    } else if (widget.device?.valve?.closed ?? false) {
      warningText = Text(S.of(context).valve_closed, style: Theme.of(context).textTheme.body1.copyWith(color: floRed), textAlign: TextAlign.end, softWrap: true);
    } else if (isLearning) {
      warningText = Text(S.of(context).learning, style: Theme.of(context).textTheme.body1.copyWith(color: Color(0xFF1B7AB2)), textAlign: TextAlign.end, softWrap: true);
    }

    return ListTile(
      title: Column(children: <Widget>[
        SizedBox(height: 8),
        Row(children: <Widget>[
          Transform.translate(offset: Offset(0, 0), child: Image.asset(DeviceUtils.iconPath(widget.device.deviceModel, open: widget.device.valve?.open ?? true), width: 40, height: 40)),
          SizedBox(width: 10),
          Expanded(child: Column(children: <Widget>[
            Text(widget.device.displayNameOf(context), style: Theme.of(context).textTheme.title, maxLines: 1, overflow: TextOverflow.ellipsis,),
            SizedBox(height: 3),
            warningText,
          ],
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
          )),
          wifIcon,
          SizedBox(width: 10),
          alertIcon,
          SizedBox(width: 10),
          Padding(padding: EdgeInsets.only(left: 0), child: Icon(Icons.arrow_forward_ios, color: Colors.black.withOpacity(0.3), size: 15, )),
        ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        SizedBox(height: 8),
      ],
      ),
      onTap: () {
        final deviceProvider = Provider.of<DeviceNotifier>(context, listen: false);
        deviceProvider.value = widget.device;
        deviceProvider.invalidate();
        Navigator.of(context).pushNamed('/flo_device');
      },
    );
  }
}

class AddAHome extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/add_a_home');
        },
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              border: Border.all(color: Color(0xFFD7DDEA), width: 1.0),
                              color: floMenuItemBgColor,
                            ),
                            child: Row(children: <Widget>[
                              SizedBox(width: 10),
                              /*
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: floMenuItemBgColor,
                                ),
                                child: Icon(Icons.plus_one)
                              ),
                              */
                              Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    stops: [0.22, 0.76],
                                    colors: [
                                      Color.fromARGB((255.0 * 0.4).round(), 7, 63, 98),
                                      Color.fromARGB((255.0 * 0.4).round(), 12, 103, 156),
                                    ],
                                  ),
                                  color: floMenuItemBgColor,
                                ),
                                child: Icon(Icons.add)),
                              SizedBox(width: 20),
                              Expanded(child: Text(ReCase(S.of(context).add_location).titleCase,
                                overflow: TextOverflow.ellipsis,
                                textScaleFactor: 1.2,
                                style: TextStyle(
                                  color: floBlue,
                                ),
                              )),
                              SizedBox(width: 20),
                            ],)
                          )));
  }
}

Future<void> previousPage(PageController pageController, {
    Duration duration,
    Curve curve: Curves.fastOutSlowIn,
}) {
  print("previousPage");
  return pageController.previousPage(
    duration: duration ?? Duration(milliseconds: 250),
    curve: curve,
  );
}

Future<void> nextPage(PageController pageController, {
    Duration duration,
    Curve curve: Curves.fastOutSlowIn,
}) {
  print("nextPage");
  return pageController.nextPage(
    duration: duration ?? Duration(milliseconds: 250),
    curve: curve,
  );
}

hasPreviousPage(PageController pageController) {
  return currentPage(pageController) > 0;
}

hasNextPage(PageController pageController, pageCount) {
  try {
    return currentPage(pageController) + 1 < pageCount;
  } catch (e) {
    Fimber.e("", ex: e);
    return true;
  }
}


class SystemModeAppBar2 extends StatefulWidget {
  SystemModeAppBar2({Key key,
    this.controller}) : super(key: key);

  final TabController controller;

  @override
  _SystemModeAppBar2State createState() => _SystemModeAppBar2State();
}

class _SystemModeAppBar2State extends State<SystemModeAppBar2> with SingleTickerProviderStateMixin {

  Map<int, String> modes = {
    0: SystemMode.SLEEP,
    1: SystemMode.AWAY,
    2: SystemMode.HOME,
  };

  TabController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    if (locationConsumer.value?.systemMode?.target == SystemMode.HOME) {
      _controller.animateTo(2, curve: Curves.fastOutSlowIn);
    } else if (locationConsumer.value?.systemMode?.target == SystemMode.AWAY) {
      _controller.animateTo(1, curve: Curves.fastOutSlowIn);
    } else if (locationConsumer.value?.systemMode?.target == SystemMode.SLEEP) {
      _controller.animateTo(0, curve: Curves.fastOutSlowIn);
    } else {
      _controller.animateTo(0, curve: Curves.fastOutSlowIn);
    }
    final isDevicesEmpty = (locationConsumer.value.devices?.isEmpty ?? true);
    final isLearning = locationConsumer.value.isLearning;
    Fimber.d("isLearning: ${locationConsumer.value.isLearning}");
    return Enabled(enabled: !isLearning && !isDevicesEmpty, child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 40, top: 10, right: 20, bottom: 10),
              child: Container(
                  height: 40,
                  padding: EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: TabBar(
                    onTap: (i) async {
                      if (modes[i] == SystemMode.SLEEP) {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return Theme(
                            data: floLightThemeData,
                            child: WillPopScope(
                                onWillPop: () async {
                                  _controller.animateTo(_controller.previousIndex, curve: Curves.fastOutSlowIn);
                                  Navigator.of(context).pop();
                                  return false;
                                }, child: AlertDialog(
                              title: Text(ReCase(S.of(context).sleep_mode).titleCase),
                              content: Text("During Sleep Mode the Flo System will not send you any alerts for the specified period of time. Use this Mode when you expect temporary high water usage and don't want to be alerted"),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    _controller.animateTo(_controller.previousIndex, curve: Curves.fastOutSlowIn);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text(S.of(context).confirm),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return Theme(
                                          data: floLightThemeData,
                                          child: AlertDialog(
                                            title: Text(ReCase(S.of(context).sleep_mode).titleCase),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                              FlatButton(
                                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_2h,
                                                textAlign: TextAlign.left,
                                              )), onPressed: () async {
                                                try {
                                                await flo.sleep(locationConsumer.value.id,
                                                  duration: Duration(hours: 2),
                                                  revertMode: modes[_controller.previousIndex],
                                                  authorization: oauthConsumer.value.authorization,
                                                );
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                locationConsumer.invalidate();
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b..dirty = true);
                                                final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                } catch (e) {
                                                Fimber.e("", ex: e);
                                                }
                                                Navigator.of(context).pop();
                                              }),
                                              FlatButton(
                                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_24h,
                                                textAlign: TextAlign.left,
                                              )), onPressed: () async {
                                                try {
                                                await flo.sleep(locationConsumer.value.id,
                                                  duration: Duration(hours: 24),
                                                  revertMode: modes[_controller.previousIndex],
                                                  authorization: oauthConsumer.value.authorization,
                                                );
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                locationConsumer.invalidate();
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b..dirty = true);
                                                final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                } catch (e) {
                                                Fimber.e("", ex: e);
                                                }
                                                Navigator.of(context).pop();
                                              }),
                                              FlatButton(
                                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                                child: SizedBox(width: double.infinity, child: Text(S.of(context).sleep_72h,
                                                textAlign: TextAlign.left,
                                              )), onPressed: () async {
                                                try {
                                                await flo.sleep(locationConsumer.value.id,
                                                  duration: Duration(hours: 72),
                                                  revertMode: modes[_controller.previousIndex],
                                                  authorization: oauthConsumer.value.authorization,
                                                );
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.SLEEP);
                                                locationConsumer.invalidate();
                                                locationConsumer.value = locationConsumer.value.rebuild((b) => b..dirty = true);
                                                final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                                locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                                } catch (e) {
                                                Fimber.e("", ex: e);
                                                }
                                                Navigator.of(context).pop();
                                              }),
                                            ],),
                                            actions: <Widget>[
                                              FlatButton(
                                                child: Text(S.of(context).cancel),
                                                onPressed: () {
                                                  _controller.animateTo(_controller.previousIndex, curve: Curves.fastOutSlowIn);
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
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            ))
                          );
                        },
                      );
                      } else if (modes[i] == SystemMode.AWAY) {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return AwayModeIrrigation(
                            controller: _controller,
                            enabled: locationConsumer.value?.mergedIrrigationSchedule?.enabled ?? false
                          );
                        },
                      );
                      } else if (modes[i] == SystemMode.HOME) {
                        try {
                        await flo.home(locationConsumer.value.id,
                          authorization: oauthConsumer.value.authorization,
                        );
                        locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.HOME);
                        locationConsumer.invalidate();
                        locationConsumer.value = locationConsumer.value.rebuild((b) => b..dirty = true);
                        final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                        locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                        } catch (e) {
                          Fimber.e("", ex: e);
                        }
                      }
                    },
                    labelColor: isLearning || isDevicesEmpty ? Colors.black.withOpacity(0.3) : Colors.black,
                    unselectedLabelColor: Colors.black.withOpacity(0.3),
                    labelPadding: EdgeInsets.symmetric(vertical: 10),
                    tabs: <Widget>[
                      Tab(
                        text: S.of(context).sleep,
                      ),
                      Tab(
                        text: S.of(context).away,
                      ),
                      Tab(
                        text: S.of(context).home,
                      ),
                    ],
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: isLearning || isDevicesEmpty ? Colors.transparent : Colors.white,
                      tabBarIndicatorSize: TabBarIndicatorSize.label,
                    ),
                    controller: _controller,
                  )
              ),
            ),
          ));
  }
}

class SystemModeAppBar extends StatelessWidget {
  SystemModeAppBar({Key key,
    this.controller}) : super(key: key);

  final TabController controller;

  Widget build(BuildContext context) {
        return SliverAppBar(
          backgroundColor: Colors.transparent,
          bottom: PreferredSize(
              child: SizedBox(height: 0),
              preferredSize: Size(double.infinity, 10)),
          title: SizedBox(height: 100),
          // pinned: true,
          snap: true,
          floating: true,
          expandedHeight: 60.0,
          // **Is it intended ?** flexibleSpace.title overlaps with tabs title.
          flexibleSpace: SystemModeAppBar2(controller: controller),
        );
  }
}

class Controller<T> {
  T _self;

  set self(T self) {
    this._self = self;
  }

  T get self => this._self;
}

class ToggleButton extends StatefulWidget {
  ToggleButton({Key key,
   this.text,
   this.selected = false,
   this.label = "Single-family house",
   this.onTap,
   this.controller,
   this.togglable = true,
   //this.activeTextColor = floLightButton,
   this.inactiveTextColor,
   this.activeTextColor,
   this.textScaleFactor = 1.2,
   this.height = 1.1,
   this.padding,
   this.inactiveColor = Colors.white,
   }) : super(key: key);

  final Widget text;
  final String label;
  final bool selected;
  final Callable<bool> onTap;
  Controller<ToggleButton> controller = Controller<ToggleButton>();
  final bool togglable;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final Color inactiveColor;
  final double textScaleFactor;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}


class _ToggleButtonState extends State<ToggleButton> {
  Widget flatButton(BuildContext context) {
    final button = FlatButton(
        padding: widget.padding ?? widget.textScaleFactor < 1 ? EdgeInsets.all(12 * widget.textScaleFactor) : null,
        child: widget.text ?? Text(widget.label,
         style: TextStyle(color: _selected ? widget.activeTextColor ?? Colors.white : widget.inactiveTextColor ?? floLightButton,
          height: widget.height
          ),
          textAlign: TextAlign.center,
           textScaleFactor: widget.textScaleFactor,),
        onPressed: null);
    return ButtonTheme.fromButtonThemeData(data: Theme.of(context).buttonTheme.copyWith(
        height: 48 * widget.textScaleFactor,
        minWidth: 0.0,
      ),
      child: widget.textScaleFactor < 1 ? SizedBox(height: 48 * widget.textScaleFactor, child: button) : button
      );
  }

  bool _selected;
  bool _dirty;
  //double _scale;

  @override
  void initState() {
    widget.controller?.self = widget;
    _selected = widget.selected;
    _dirty = false;

    super.initState();
  }

  void onTap () {
    if (widget.togglable) {
      _dirty = true;
      setState(() {
        _selected = !_selected;
      });
    }
    widget.onTap(_selected);
  }

  @override
  void didUpdateWidget(ToggleButton oldWidget) {
    if (oldWidget.selected != widget.selected) {
      //setState(() {
        _selected = widget.selected;
      //});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Animator(
        key: UniqueKey(),
        tickerMixin: TickerMixin.tickerProviderStateMixin,
        endAnimationListener: (anim) => _dirty = false,
      duration: Duration(milliseconds: _dirty ? 100 : 0),
      tween: _selected ? Tween<double>(begin: 1.0, end: 1.1) : Tween<double>(begin: 1.1, end: 1.0),
      curve: Curves.fastOutSlowIn,
      builder: (anim) => Transform.scale(scale: anim.value, child: Stack(children: [
      Container(
        decoration: _selected ? BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 1.0],
          colors: [
            Color(0xFF0C679C),
            Color(0xFF073F62),
          ],
        ),
        boxShadow: _selected ? [
          BoxShadow(color: floBlue.withOpacity(0.3), offset: Offset(0, 8), blurRadius: 10)
        ] : [],
        borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
      ) : BoxDecoration(
          color: widget.inactiveColor,
          borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: this.onTap, child: Container(
            //padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
            ),
            child: flatButton(context)),
      ))),
    ])));
  }
}

class RadioButton<T> extends StatefulWidget {
  RadioButton({Key key,
    this.icon,
    this.iconData,
    this.text,
    @required
    this.value,
    @required
    this.groupValue,
    this.size = 130.0,
    this.label = "",
    @required
    this.onChanged,
    this.width,
    this.textAlign,
    this.inactiveColor,
    this.activeColor,
  }) : super(key: key);

  final Widget icon;
  final double width;
  final TextAlign textAlign;
  final IconData iconData;
  final Widget text;
  final String label;
  final double size;
  final Color inactiveColor;
  final Color activeColor;
  final T value;
  final T groupValue;
  final ValueChanged onChanged;

  @override
  _RadioButtonState createState() => _RadioButtonState();
}

class _RadioButtonState<T> extends State<RadioButton<T>> {
  bool _selected;
  double _scale;

  @override
  void initState() {
    _selected = widget.value == widget.groupValue;
    _scale = _selected ? 1.1 : 1.0;

    super.initState();
  }

  void onTap() {
    print("onTap: ${widget.value}");
    widget.onChanged(widget.value);
  }

  Widget flatButton(BuildContext context) {
    return ButtonTheme.fromButtonThemeData(data: Theme.of(context).buttonTheme.copyWith(
        minWidth: 0.0,
      ),
      child: FlatButton(
        child: widget.text ?? SizedBox(width: widget.width, child: Text(widget.label,
         style: TextStyle(color: _selected ? (widget.activeColor ?? Colors.white) : (widget.inactiveColor ?? floLightButton),
          height: 1.1),
           textAlign: widget.textAlign ?? TextAlign.left, textScaleFactor: 1.2,)),
        onPressed: null,),
      );
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.value == widget.groupValue;
    //print("${widget.value} == ${widget.groupValue}: ${_selected}");
    return Animator(
        key: UniqueKey(),
        tickerMixin: TickerMixin.tickerProviderStateMixin,
        endAnimationListener: (anim) {
         _scale = anim.animation.value;
      },
      duration: Duration(milliseconds: 100),
      tween: _selected ? Tween<double>(begin: _scale, end: 1.1) : Tween<double>(begin: _scale, end: 1.0),
      curve: Curves.fastOutSlowIn,
      builder: (anim) => Transform.scale(scale: anim.value, child: Stack(children: [
      Container(
        decoration: _selected ? BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 1.0],
          colors: [
            Color(0xFF0C679C),
            Color(0xFF073F62),
          ],
        ),
        boxShadow: _selected ? [
          BoxShadow(color: floBlue.withOpacity(0.3), offset: Offset(0, 8), blurRadius: 10)
        ] : [],
        borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
      ) : BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: this.onTap, child: Container(
            //padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
            ),
            child: flatButton(context)),
      ))),
    ])));
  }
}

class IconRadio<T> extends StatefulWidget {
  IconRadio({Key key,
    this.icon,
    this.iconData,
    this.text,
    @required
    this.value,
    @required
    this.groupValue,
    this.size = 130.0,
    this.label = "",
    @required
    this.onChanged,
  }) : super(key: key);

  final Widget icon;
  final IconData iconData;
  final Widget text;
  final String label;
  final double size;
  final T value;
  final T groupValue;
  final ValueChanged onChanged;

  @override
  _IconRadioState createState() => _IconRadioState();
}

class _IconRadioState<T> extends State<IconRadio<T>> {
  bool _selected;
  double _scale;

  @override
  void initState() {
    _selected = widget.value == widget.groupValue;
    _scale = _selected ? 1.1 : 1.0;

    super.initState();
  }

  void onTap() {
    //print("${widget.value}");
    widget.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.value == widget.groupValue;
    //print("${widget.value}: ${_selected}");
    // responsive for smaller screen
    //widget.size = widget.size * MediaQuery.of(context).textScaleFactor;
    return Animator(
        key: UniqueKey(),
        tickerMixin: TickerMixin.tickerProviderStateMixin,
        //endAnimationListener: (anim) { _scale = anim.value; _dirty = false; },
      //endAnimationListener: (anim) => _dirty = false,
      endAnimationListener: (anim) {
         _scale = anim.animation.value;
      },
      duration: Duration(milliseconds: 150),
      tween: _selected ? Tween<double>(begin: _scale, end: 1.1) : Tween<double>(begin: _scale, end: 1.0),
      //tween: _selected ? Tween<double>(begin: 1.0, end: 1.1) : Tween<double>(begin: 1.1, end: 1.0),
      curve: Curves.fastOutSlowIn,
      builder: (anim) => Transform.scale(scale: anim.value, child:
      Container(
          width: widget.size,
          height: widget.size,
          decoration: _selected ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [0.2, 0.7],
              colors: [
                Color(0xFF0C679C),
                Color(0xFF073F62),
              ],
            ),
            boxShadow: _selected ? [
              BoxShadow(color: floBlue.withOpacity(0.3), offset: Offset(0, 8), blurRadius: 10)
            ] : [],
            borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
          ) : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            child: FlatButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.all(15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
              ),
              child: Column(children: <Widget>[
                SizedBox(height: 8),
              RawMaterialButton(
                onPressed: null,
                child: widget.icon ?? Icon(
                  widget.iconData ?? Icons.home,
                  color: _selected ? Colors.white : floLightButton,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 0,
                fillColor: _selected ? Colors.white.withOpacity(0.2) : floLightButtonBackground,
                padding: const EdgeInsets.all(10.0),
              ),
                SizedBox(height: 8),
              Expanded(child: Center(child: AutoSizeText(widget.label, style: Theme.of(context).textTheme.body2.copyWith(color: _selected ? Colors.white : floLightButton, height: 1.1), textAlign: TextAlign.center, maxLines: 2, minFontSize: 10, overflow: TextOverflow.ellipsis,))),
            ],
                //crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
             ),
              onPressed: onTap,
            ),
          )
      )
      )
    );
  }
}

class IconToggleButton extends StatefulWidget {
  IconToggleButton({Key key,
   this.icon,
   this.iconData,
   this.text,
   this.selected = false,
   this.size = 130.0,
   this.label = "",
   this.onTap,
   }) : super(key: key);

  Widget icon;
  IconData iconData;
  Widget text;
  String label;
  bool selected;
  double size;
  Callable<bool> onTap;
  Controller<IconToggleButton> controller = Controller<IconToggleButton>();

  @override
  _IconToggleButtonState createState() => _IconToggleButtonState();
}

class _IconToggleButtonState extends State<IconToggleButton> {
  bool _selected;
  bool _dirty;
  //double _scale;

  @override
  void initState() {
    widget.controller?.self = widget;
    _selected = widget.selected;
    //_scale = _selected ? 1.1 : 1.0;
    _dirty = false;

    super.initState();
  }

  void onTap() {
    _dirty = true;
    widget.onTap(_selected);
    setState(() {
      _selected = !_selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    // responsive for smaller screen
    //widget.size = widget.size * MediaQuery.of(context).textScaleFactor;
    return Animator(
        key: UniqueKey(),
        tickerMixin: TickerMixin.tickerProviderStateMixin,
        //endAnimationListener: (anim) { _scale = anim.value; _dirty = false; },
      endAnimationListener: (anim) => _dirty = false,
      duration: Duration(milliseconds: _dirty ? 150 : 0),
      //tween: _selected ? Tween<double>(begin: _scale, end: 1.1) : Tween<double>(begin: _scale, end: 1.0),
      tween: _selected ? Tween<double>(begin: 1.0, end: 1.1) : Tween<double>(begin: 1.1, end: 1.0),
      curve: Curves.fastOutSlowIn,
      builder: (anim) => Transform.scale(scale: anim.value, child: Stack(children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: _selected ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [0.2, 0.7],
              colors: [
                Color(0xFF0C679C),
                Color(0xFF073F62),
              ],
            ),
            boxShadow: widget.selected ? [
              BoxShadow(color: floBlue.withOpacity(0.3), offset: Offset(0, 8), blurRadius: 10)
            ] : [],
            borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
          ) : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(floToggleButtonRadius)),
          ),
          child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: Container(
            padding: EdgeInsets.all(20),
            child: Column(children: <Widget>[
            Spacer(),
            RawMaterialButton(
              onPressed: null,
              child: widget.icon ?? Icon(
                widget.iconData ?? Icons.home,
                color: widget.selected ? Colors.white : floLightButton,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 0,
              fillColor: widget.selected ? Colors.white.withOpacity(0.2) : floLightButtonBackground,
              padding: const EdgeInsets.all(10.0),
            ),
            Spacer(),
            widget.text ?? Text(widget.label, style: TextStyle(color: widget.selected ? Colors.white : floLightButton, height: 1.1), textAlign: TextAlign.center,),
            Spacer(),
          ],)
        ))
        )
        )
        ]
        )
      )
    );
  }
}

class OutlineTextFormField extends StatefulWidget {
  OutlineTextFormField({
    Key key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.autovalidate = false,
    this.maxLengthEnforced = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.enabled = true,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.buildCounter,
    this.labelText,
    this.counterText,
    this.hintText,
    this.onFocus,
    this.onUnfocus,
    this.onFocusChanged,
  }) : super(
    key: key,
  ) {
    this.decoration = decoration ?? InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      counterText: counterText,
      contentPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 18.0),
    );
    this.onChanged = onChanged ?? (_) {
    };
    this.onFieldSubmitted = onFieldSubmitted ?? (_) {
    };
  }

  final TextEditingController controller;
  ValueChanged<String> onChanged;
  final String initialValue;
  final FocusNode focusNode;
  InputDecoration decoration;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final TextStyle style;
  final StrutStyle strutStyle;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final String counterText;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool autovalidate;
  final bool maxLengthEnforced;
  final int maxLines;
  final int minLines;
  final bool expands;
  final int maxLength;
  final VoidCallback onEditingComplete;
  ValueChanged<String> onFieldSubmitted;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;
  final double cursorWidth;
  final Radius cursorRadius;
  final Color cursorColor;
  final Brightness keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final InputCounterWidgetBuilder buildCounter;
  final String labelText;
  final String hintText;
  final ValueChanged<String> onFocus;
  final ValueChanged<String> onUnfocus;
  final Changed2<bool, String> onFocusChanged;

  @override
  State<OutlineTextFormField> createState() => _OutlineTextFormFieldState();
}

class _OutlineTextFormFieldState extends State<OutlineTextFormField> {
  TextEditingController _controller;
  bool _autovalidate;
  ValueChanged<String> _onFieldSubmitted;
  FocusNode _focusNode;


  @override
  void initState() {
    super.initState();
    _autovalidate = widget.autovalidate ?? false;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.initialValue;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged(_focusNode.hasFocus, _controller.text);
      }
      if (_focusNode.hasFocus) {
        if (widget.onFocus != null) {
          widget.onFocus(_controller.text);
        }
      } else {
        if (widget.onUnfocus != null) {
          widget.onUnfocus(_controller.text);
        }
      }
    });
    _onFieldSubmitted = (text) {
      if (!_autovalidate) {
        setState(() {
          _autovalidate = true;
        });
      }
      widget.onFieldSubmitted(text);
    };

    _controller.addListener(() {
      widget.onChanged(_controller.text);
      if (!_autovalidate && _controller.text.isNotEmpty) {
        setState(() {
          _autovalidate = true;
        });
      }
    });
    Fimber.d("initState: initialValue: ${widget.initialValue}, text: ${_controller.text}");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OutlineTextFormField oldWidget) {
    if (widget.initialValue != oldWidget.initialValue) {
      if (_controller.text != widget.initialValue) {
        _controller.text = widget.initialValue;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
    key: widget.key,
    controller: _controller,
    //initialValue: widget.initialValue,
    focusNode: _focusNode,
    decoration: widget.decoration,
    keyboardType: widget.keyboardType,
    textCapitalization: widget.textCapitalization,
    textInputAction: widget.textInputAction,
    style: widget.style,
    strutStyle: widget.strutStyle,
    textDirection: widget.textDirection,
    textAlign: widget.textAlign,
    autofocus: widget.autofocus,
    obscureText: widget.obscureText,
    autocorrect: widget.autocorrect,
    autovalidate: _autovalidate,
    maxLengthEnforced: widget.maxLengthEnforced,
    maxLines: widget.maxLines,
    minLines: widget.minLines,
    expands: widget.expands,
    maxLength: widget.maxLength,
    onEditingComplete: widget.onEditingComplete,
    onFieldSubmitted: _onFieldSubmitted,
    onSaved: widget.onSaved,
    validator: widget.validator,
    inputFormatters: widget.inputFormatters,
    enabled: widget.enabled,
    cursorWidth: widget.cursorWidth,
    cursorRadius: widget.cursorRadius,
    cursorColor: widget.cursorColor,
    keyboardAppearance: widget.keyboardAppearance,
    scrollPadding: widget.scrollPadding,
    enableInteractiveSelection: widget.enableInteractiveSelection,
    buildCounter: widget.buildCounter,
    );
  }
}

class SimpleAnimatedContainer extends AnimatedContainer {
  SimpleAnimatedContainer({
    Key key,
    AlignmentGeometry alignment,
    EdgeInsetsGeometry padding,
    Color color,
    Decoration decoration,
    Decoration foregroundDecoration,
    double width,
    double height,
    BoxConstraints constraints,
    EdgeInsetsGeometry margin,
    Matrix4 transform,
    Widget child,
    Curve curve = Curves.fastOutSlowIn,
    Duration duration = const Duration(milliseconds: 250),
    //Duration reverseDuration,
  }) : super(
    key: key,
    alignment: alignment,
    padding: padding,
    color: color,
    decoration: decoration,
    foregroundDecoration: foregroundDecoration,
    width: width,
    height: height,
    constraints: constraints,
    margin: margin,
    transform: transform,
    child: child,
    curve: curve,
    duration: duration,
    //reverseDuration: reverseDuration,
  );
}

class ScaleAnimatedContainer extends StatefulWidget {
  ScaleAnimatedContainer({
    Key key,
    @required
    Widget child,
    this.duration,
    this.curve,
  }) : super(key: key);

  Widget child;
  Duration duration = const Duration(milliseconds: 250);
  Curve curve = Curves.fastOutSlowIn;

  _ScaleAnimatedContainerState createState() => _ScaleAnimatedContainerState();
}

class _ScaleAnimatedContainerState extends State<ScaleAnimatedContainer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    /*
    Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ),
    );
    */
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ),
      child: widget.child,
    );
  }
}

class SimpleCheckboxListTile extends StatefulWidget {
  SimpleCheckboxListTile({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.validator,
    this.controlAffinity = ListTileControlAffinity.platform,
}) : super(key: key);
  final bool value;
  final ValueChanged<bool> onChanged;
  final Predicate<bool> validator;
  final Color activeColor;
  final Widget title;
  final Widget subtitle;
  final Widget secondary;
  final bool isThreeLine;
  final bool dense;
  final bool selected;
  final ListTileControlAffinity controlAffinity;

  @override
  _SimpleCheckboxListTileState createState() => _SimpleCheckboxListTileState();
}

class _SimpleCheckboxListTileState extends State<SimpleCheckboxListTile> {
  bool _value;

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(SimpleCheckboxListTile oldWidget) {
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: widget.key,
      value: _value,
      onChanged: (value) {
        bool valid = true;
        if (widget.validator != null) {
          valid = widget.validator(value);
        }

        if (valid) {
          setState(() => _value = value);
          widget.onChanged(value);
        }
      },
      activeColor: widget.activeColor,
      title: widget.title,
      subtitle: widget.subtitle,
      isThreeLine: widget.isThreeLine,
      dense: widget.dense,
      secondary: widget.secondary,
      selected: widget.selected,
      controlAffinity: widget.controlAffinity,
    );
  }
}

/// ref. https://stackoverflow.com/a/54173729
class ExpandedSection extends StatefulWidget {

  final Widget child;
  final bool expand;
  final double axisAlignment;
  ExpandedSection({
    this.expand = false,
    this.axisAlignment = 1.0,
    this.child
  });

  @override
  _ExpandedSectionState createState() => _ExpandedSectionState();
}

class _ExpandedSectionState extends State<ExpandedSection> with SingleTickerProviderStateMixin, AfterLayoutMixin<ExpandedSection> {
  AnimationController expandController;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _child = widget.child;
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250)
    );
    Animation curve = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(curve)
      ..addListener(() {
        setState(() {

        });
      }
    );
  }

  @override
  void didUpdateWidget(ExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
    //return _child;
    return SizeTransition(
      axisAlignment: widget.axisAlignment,
      sizeFactor: animation,
      child: widget.child
    );
  }

  Widget _child;

  @override
  void afterFirstLayout(BuildContext context) {
    /*
    setState(() {
    _child = SizeTransition(
      axisAlignment: widget.axisAlignment,
      sizeFactor: animation,
      child: widget.child
    );
    });
    */
  }
}

class ScaleContainer extends StatefulWidget {

  final Widget child;
  final bool scaled;
  final double begin;
  final double end;
  ScaleContainer({
    this.scaled = false,
    this.begin = 0.0,
    this.end = 1.0,
    this.child});

  @override
  _ScaleContainerState createState() => _ScaleContainerState();
}

class _ScaleContainerState extends State<ScaleContainer> with SingleTickerProviderStateMixin {
  AnimationController expandController;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250)
    );
    Animation curve = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
    animation = Tween(begin: widget.begin, end: widget.end).animate(curve)
      ..addListener(() {
        setState(() {

        });
      }
    );
  }

  @override
  void didUpdateWidget(ScaleContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scaled) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: widget.child
    );
  }
}

List<T> sort<T>(List<T> list, [int compare(T a, T b)]) {
  list.sort(compare);
  return list;
}

E firstWhere<E>(List<E> list, bool test(E element), {E orElse()}) {
  try {
    return list.firstWhere(test);
  } catch (error) {
    Fimber.d("", ex: error);
  }
}

enum _SliderType { material, adaptive }

class AlwaysSlider2 extends StatefulWidget {
  AlwaysSlider2({Key key,
  this.min = 0,
  this.max = 1,
  this.divisions = 10,
  this.label,
  this.onChanged,
  this.value,
  this.semanticFormatterCallback,
  this.onChangedEnd,
  }) : super(key: key);

  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedEnd;
  final Consumers<double, String> label;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final SemanticFormatterCallback semanticFormatterCallback;

  _AlwaysSlider2 createState() => _AlwaysSlider2();
}

class _AlwaysSlider2 extends State<AlwaysSlider2> {
  String _label;
  double _value;

@override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return AlwaysSlider(
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      value: _value,
      label: _label,
      onChangeEnd: widget.onChangedEnd,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged(value);
        }
        if (widget.label != null) {
          setState(() {
            _value = value;
            _label = widget.label(value);
          });
        }
      },
      semanticFormatterCallback: widget.semanticFormatterCallback,
    );
  }
}

class AlwaysSlider extends StatefulWidget {
  /// Creates a Material Design slider.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of
  /// the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called while the user is selecting a new value for the
  ///   slider.
  /// * [onChangeStart] is called when the user starts to select a new value for
  ///   the slider.
  /// * [onChangeEnd] is called when the user is done selecting a new value for
  ///   the slider.
  ///
  /// You can override some of the colors with the [activeColor] and
  /// [inactiveColor] properties, although more fine-grained control of the
  /// appearance is achieved using a [SliderThemeData].
  const AlwaysSlider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.semanticFormatterCallback,
  }) : _sliderType = _SliderType.material,
       assert(value != null),
       assert(min != null),
       assert(max != null),
       assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0),
       super(key: key);

  /// Creates a [CupertinoSlider] if the target platform is iOS, creates a
  /// Material Design slider otherwise.
  ///
  /// If a [CupertinoSlider] is created, the following parameters are
  /// ignored: [label], [inactiveColor], [semanticFormatterCallback].
  ///
  /// The target platform is based on the current [Theme]: [ThemeData.platform].
  const AlwaysSlider.adaptive({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.semanticFormatterCallback,
  }) : _sliderType = _SliderType.adaptive,
       assert(value != null),
       assert(min != null),
       assert(max != null),
       assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0),
       super(key: key);

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// Called during a drag when the user is selecting a new value for the slider
  /// by dragging.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// Slider(
  ///   value: _duelCommandment.toDouble(),
  ///   min: 1.0,
  ///   max: 10.0,
  ///   divisions: 10,
  ///   label: '$_duelCommandment',
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _duelCommandment = newValue.round();
  ///     });
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [onChangeStart] for a callback that is called when the user starts
  ///    changing the value.
  ///  * [onChangeEnd] for a callback that is called when the user stops
  ///    changing the value.
  final ValueChanged<double> onChanged;

  /// Called when the user starts selecting a new value for the slider.
  ///
  /// This callback shouldn't be used to update the slider [value] (use
  /// [onChanged] for that), but rather to be notified when the user has started
  /// selecting a new value by starting a drag or with a tap.
  ///
  /// The value passed will be the last [value] that the slider had before the
  /// change began.
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// Slider(
  ///   value: _duelCommandment.toDouble(),
  ///   min: 1.0,
  ///   max: 10.0,
  ///   divisions: 10,
  ///   label: '$_duelCommandment',
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _duelCommandment = newValue.round();
  ///     });
  ///   },
  ///   onChangeStart: (double startValue) {
  ///     print('Started change at $startValue');
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [onChangeEnd] for a callback that is called when the value change is
  ///    complete.
  final ValueChanged<double> onChangeStart;

  /// Called when the user is done selecting a new value for the slider.
  ///
  /// This callback shouldn't be used to update the slider [value] (use
  /// [onChanged] for that), but rather to know when the user has completed
  /// selecting a new [value] by ending a drag or a click.
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// Slider(
  ///   value: _duelCommandment.toDouble(),
  ///   min: 1.0,
  ///   max: 10.0,
  ///   divisions: 10,
  ///   label: '$_duelCommandment',
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _duelCommandment = newValue.round();
  ///     });
  ///   },
  ///   onChangeEnd: (double newValue) {
  ///     print('Ended change on $newValue');
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [onChangeStart] for a callback that is called when a value change
  ///    begins.
  final ValueChanged<double> onChangeEnd;

  /// The minimum value the user can select.
  ///
  /// Defaults to 0.0. Must be less than or equal to [max].
  ///
  /// If the [max] is equal to the [min], then the slider is disabled.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0. Must be greater than or equal to [min].
  ///
  /// If the [max] is equal to the [min], then the slider is disabled.
  final double max;

  /// The number of discrete divisions.
  ///
  /// Typically used with [label] to show the current discrete value.
  ///
  /// If null, the slider is continuous.
  final int divisions;

  /// A label to show above the slider when the slider is active.
  ///
  /// It is used to display the value of a discrete slider, and it is displayed
  /// as part of the value indicator shape.
  ///
  /// The label is rendered using the active [ThemeData]'s
  /// [ThemeData.accentTextTheme.body2] text style.
  ///
  /// If null, then the value indicator will not be displayed.
  ///
  /// Ignored if this slider is created with [Slider.adaptive].
  ///
  /// See also:
  ///
  ///  * [SliderComponentShape] for how to create a custom value indicator
  ///    shape.
  final String label;

  /// The color to use for the portion of the slider track that is active.
  ///
  /// The "active" side of the slider is the side between the thumb and the
  /// minimum value.
  ///
  /// Defaults to [SliderTheme.activeTrackColor] of the current [SliderTheme].
  ///
  /// Using a [SliderTheme] gives much more fine-grained control over the
  /// appearance of various components of the slider.
  final Color activeColor;

  /// The color for the inactive portion of the slider track.
  ///
  /// The "inactive" side of the slider is the side between the thumb and the
  /// maximum value.
  ///
  /// Defaults to the [SliderTheme.inactiveTrackColor] of the current
  /// [SliderTheme].
  ///
  /// Using a [SliderTheme] gives much more fine-grained control over the
  /// appearance of various components of the slider.
  ///
  /// Ignored if this slider is created with [Slider.adaptive].
  final Color inactiveColor;

  /// The callback used to create a semantic value from a slider value.
  ///
  /// Defaults to formatting values as a percentage.
  ///
  /// This is used by accessibility frameworks like TalkBack on Android to
  /// inform users what the currently selected value is with more context.
  ///
  /// {@tool sample}
  ///
  /// In the example below, a slider for currency values is configured to
  /// announce a value with a currency label.
  ///
  /// ```dart
  /// Slider(
  ///   value: _dollars.toDouble(),
  ///   min: 20.0,
  ///   max: 330.0,
  ///   label: '$_dollars dollars',
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _dollars = newValue.round();
  ///     });
  ///   },
  ///   semanticFormatterCallback: (double newValue) {
  ///     return '${newValue.round()} dollars';
  ///   }
  ///  )
  /// ```
  /// {@end-tool}
  ///
  /// Ignored if this slider is created with [Slider.adaptive]
  final SemanticFormatterCallback semanticFormatterCallback;

  final _SliderType _sliderType ;

  @override
  _SliderState createState() => _SliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
    properties.add(DoubleProperty('min', min));
    properties.add(DoubleProperty('max', max));
  }
}

class _SliderState extends State<AlwaysSlider> with TickerProviderStateMixin {
  static const Duration enableAnimationDuration = Duration(milliseconds: 75);
  static const Duration valueIndicatorAnimationDuration = Duration(milliseconds: 100);

  // Animation controller that is run when the overlay (a.k.a radial reaction)
  // is shown in response to user interaction.
  AnimationController overlayController;
  // Animation controller that is run when the value indicator is being shown
  // or hidden.
  AnimationController valueIndicatorController;
  // Animation controller that is run when enabling/disabling the slider.
  AnimationController enableController;
  // Animation controller that is run when transitioning between one value
  // and the next on a discrete slider.
  AnimationController positionController;
  Timer interactionTimer;

  @override
  void initState() {
    super.initState();
    overlayController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    valueIndicatorController = AnimationController(
      duration: valueIndicatorAnimationDuration,
      vsync: this,
    );
    enableController = AnimationController(
      duration: enableAnimationDuration,
      vsync: this,
    );
    positionController = AnimationController(
      duration: Duration.zero,
      vsync: this,
    );
    enableController.value = widget.onChanged != null ? 1.0 : 0.0;
    positionController.value = _unlerp(widget.value);
  }

  @override
  void dispose() {
    interactionTimer?.cancel();
    overlayController.dispose();
    valueIndicatorController.dispose();
    enableController.dispose();
    positionController.dispose();
    super.dispose();
  }

  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      widget.onChanged(lerpValue);
    }
  }

  void _handleDragStart(double value) {
    assert(widget.onChangeStart != null);
    widget.onChangeStart(_lerp(value));
  }

  void _handleDragEnd(double value) {
    assert(widget.onChangeEnd != null);
    widget.onChangeEnd(_lerp(value));
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min ? (value - widget.min) / (widget.max - widget.min) : 0.0;
  }

  static const double _defaultTrackHeight = 2;
  static const SliderTrackShape _defaultTrackShape = RoundedRectSliderTrackShape();
  static const SliderTickMarkShape _defaultTickMarkShape = RoundSliderTickMarkShape();
  static const SliderComponentShape _defaultOverlayShape = RoundSliderOverlayShape();
  static const SliderComponentShape _defaultThumbShape = RoundSliderThumbShape();
  static const SliderComponentShape _defaultValueIndicatorShape = PaddleSliderValueIndicatorShape();
  static const ShowValueIndicator _defaultShowValueIndicator = ShowValueIndicator.onlyForDiscrete;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));

    switch (widget._sliderType) {
      case _SliderType.material:
        return _buildMaterialSlider(context);

      case _SliderType.adaptive: {
        final ThemeData theme = Theme.of(context);
        assert(theme.platform != null);
        switch (theme.platform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            return _buildMaterialSlider(context);
          case TargetPlatform.iOS:
            return _buildCupertinoSlider(context);
        }
      }
    }
    assert(false);
    return null;
  }

  Widget _buildMaterialSlider(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    SliderThemeData sliderTheme = SliderTheme.of(context);

    // If the widget has active or inactive colors specified, then we plug them
    // in to the slider theme as best we can. If the developer wants more
    // control than that, then they need to use a SliderTheme. The default
    // colors come from the ThemeData.colorScheme. These colors, along with
    // the default shapes and text styles are aligned to the Material
    // Guidelines.
    sliderTheme = sliderTheme.copyWith(
      trackHeight: sliderTheme.trackHeight ?? _defaultTrackHeight,
      activeTrackColor: widget.activeColor ?? sliderTheme.activeTrackColor ?? theme.colorScheme.primary,
      inactiveTrackColor: widget.inactiveColor ?? sliderTheme.inactiveTrackColor ?? theme.colorScheme.primary.withOpacity(0.24),
      disabledActiveTrackColor: sliderTheme.disabledActiveTrackColor ?? theme.colorScheme.onSurface.withOpacity(0.32),
      disabledInactiveTrackColor: sliderTheme.disabledInactiveTrackColor ?? theme.colorScheme.onSurface.withOpacity(0.12),
      activeTickMarkColor: widget.inactiveColor ?? sliderTheme.activeTickMarkColor ?? theme.colorScheme.onPrimary.withOpacity(0.54),
      inactiveTickMarkColor: widget.activeColor ?? sliderTheme.inactiveTickMarkColor ?? theme.colorScheme.primary.withOpacity(0.54),
      disabledActiveTickMarkColor: sliderTheme.disabledActiveTickMarkColor ?? theme.colorScheme.onPrimary.withOpacity(0.12),
      disabledInactiveTickMarkColor: sliderTheme.disabledInactiveTickMarkColor ?? theme.colorScheme.onSurface.withOpacity(0.12),
      thumbColor: widget.activeColor ?? sliderTheme.thumbColor ?? theme.colorScheme.primary,
      disabledThumbColor: sliderTheme.disabledThumbColor ?? theme.colorScheme.onSurface.withOpacity(0.38),
      overlayColor: widget.activeColor?.withOpacity(0.12) ?? sliderTheme.overlayColor ?? theme.colorScheme.primary.withOpacity(0.12),
      valueIndicatorColor: widget.activeColor ?? sliderTheme.valueIndicatorColor ?? theme.colorScheme.primary,
      trackShape: sliderTheme.trackShape ?? _defaultTrackShape,
      tickMarkShape: sliderTheme.tickMarkShape ?? _defaultTickMarkShape,
      thumbShape: sliderTheme.thumbShape ?? _defaultThumbShape,
      overlayShape: sliderTheme.overlayShape ?? _defaultOverlayShape,
      valueIndicatorShape: sliderTheme.valueIndicatorShape ?? _defaultValueIndicatorShape,
      showValueIndicator: sliderTheme.showValueIndicator ?? _defaultShowValueIndicator,
      valueIndicatorTextStyle: sliderTheme.valueIndicatorTextStyle ?? theme.textTheme.body2.copyWith(
        color: theme.colorScheme.onPrimary,
      ),
    );

    return _SliderRenderObjectWidget(
      value: _unlerp(widget.value),
      divisions: widget.divisions,
      label: widget.label,
      sliderTheme: sliderTheme,
      mediaQueryData: MediaQuery.of(context),
      onChanged: (widget.onChanged != null) && (widget.max > widget.min) ? _handleChanged : null,
      onChangeStart: widget.onChangeStart != null ? _handleDragStart : null,
      onChangeEnd: widget.onChangeEnd != null ? _handleDragEnd : null,
      state: this,
      semanticFormatterCallback: widget.semanticFormatterCallback,
    );
  }

  Widget _buildCupertinoSlider(BuildContext context) {
    // The render box of a slider has a fixed height but takes up the available
    // width. Wrapping the [CupertinoSlider] in this manner will help maintain
    // the same size.
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlider(
        value: widget.value,
        onChanged: widget.onChanged,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        activeColor: widget.activeColor,
      ),
    );
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  const _SliderRenderObjectWidget({
    Key key,
    this.value,
    this.divisions,
    this.label,
    this.sliderTheme,
    this.mediaQueryData,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.state,
    this.semanticFormatterCallback,
  }) : super(key: key);

  final double value;
  final int divisions;
  final String label;
  final SliderThemeData sliderTheme;
  final MediaQueryData mediaQueryData;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final SemanticFormatterCallback semanticFormatterCallback;
  final _SliderState state;

  @override
  _RenderSlider createRenderObject(BuildContext context) {
    return _RenderSlider(
      value: value,
      divisions: divisions,
      label: label,
      sliderTheme: sliderTheme,
      mediaQueryData: mediaQueryData,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      state: state,
      textDirection: Directionality.of(context),
      semanticFormatterCallback: semanticFormatterCallback,
      platform: Theme.of(context).platform,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..label = label
      ..sliderTheme = sliderTheme
      ..theme = Theme.of(context)
      ..mediaQueryData = mediaQueryData
      ..onChanged = onChanged
      ..onChangeStart = onChangeStart
      ..onChangeEnd = onChangeEnd
      ..textDirection = Directionality.of(context)
      ..semanticFormatterCallback = semanticFormatterCallback
      ..platform = Theme.of(context).platform;
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

class _RenderSlider extends RenderBox {
  _RenderSlider({
    @required double value,
    int divisions,
    String label,
    SliderThemeData sliderTheme,
    MediaQueryData mediaQueryData,
    TargetPlatform platform,
    ValueChanged<double> onChanged,
    SemanticFormatterCallback semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    @required _SliderState state,
    @required TextDirection textDirection,
  }) : assert(value != null && value >= 0.0 && value <= 1.0),
       assert(state != null),
       assert(textDirection != null),
       _platform = platform,
       _semanticFormatterCallback = semanticFormatterCallback,
       _label = label,
       _value = value,
       _divisions = divisions,
       _sliderTheme = sliderTheme,
       _mediaQueryData = mediaQueryData,
       _onChanged = onChanged,
       _state = state,
       _textDirection = textDirection {
    _updateLabelPainter();
    final GestureArenaTeam team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction;
    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTapCancel = _endInteraction;
    _overlayAnimation = CurvedAnimation(
      parent: _state.overlayController,
      curve: Curves.fastOutSlowIn,
    );
    _valueIndicatorAnimation = CurvedAnimation(
      parent: _state.valueIndicatorController,
      curve: Curves.fastOutSlowIn,
    );
    _enableAnimation = CurvedAnimation(
      parent: _state.enableController,
      curve: Curves.easeInOut,
    );
  }
  static const Duration _positionAnimationDuration = Duration(milliseconds: 75);
  static const Duration _minimumInteractionTime = Duration(milliseconds: 500);

  // This value is the touch target, 48, multiplied by 3.
  static const double _minPreferredTrackWidth = 144.0;

  // Compute the largest width and height needed to paint the slider shapes,
  // other than the track shape. It is assumed that these shapes are vertically
  // centered on the track.
  double get _maxSliderPartWidth => _sliderPartSizes.map((Size size) => size.width).reduce(math.max);
  double get _maxSliderPartHeight => _sliderPartSizes.map((Size size) => size.width).reduce(math.max);
  List<Size> get _sliderPartSizes => <Size>[
    _sliderTheme.overlayShape.getPreferredSize(isInteractive, isDiscrete),
    _sliderTheme.thumbShape.getPreferredSize(isInteractive, isDiscrete),
    _sliderTheme.tickMarkShape.getPreferredSize(isEnabled: isInteractive, sliderTheme: sliderTheme),
  ];
  double get _minPreferredTrackHeight => _sliderTheme.trackHeight;

  _SliderState _state;
  Animation<double> _overlayAnimation;
  Animation<double> _valueIndicatorAnimation;
  Animation<double> _enableAnimation;
  final TextPainter _labelPainter = TextPainter();
  HorizontalDragGestureRecognizer _drag;
  TapGestureRecognizer _tap;
  bool _active = false;
  double _currentDragValue = 0.0;

  // This rect is used in gesture calculations, where the gesture coordinates
  // are relative to the sliders origin. Therefore, the offset is passed as
  // (0,0).
  Rect get _trackRect => _sliderTheme.trackShape.getPreferredRect(
    parentBox: this,
    offset: Offset.zero,
    sliderTheme: _sliderTheme,
    isDiscrete: false,
  );

  bool get isInteractive => onChanged != null;

  bool get isDiscrete => divisions != null && divisions > 0;

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    final double convertedValue = isDiscrete ? _discretize(newValue) : newValue;
    if (convertedValue == _value) {
      return;
    }
    _value = convertedValue;
    if (isDiscrete) {
      // Reset the duration to match the distance that we're traveling, so that
      // whatever the distance, we still do it in _positionAnimationDuration,
      // and if we get re-targeted in the middle, it still takes that long to
      // get to the new location.
      final double distance = (_value - _state.positionController.value).abs();
      _state.positionController.duration = distance != 0.0
        ? _positionAnimationDuration * (1.0 / distance)
        : Duration.zero;
      _state.positionController.animateTo(convertedValue, curve: Curves.easeInOut);
    } else {
      _state.positionController.value = convertedValue;
    }
    markNeedsSemanticsUpdate();
  }

  TargetPlatform _platform;
  TargetPlatform get platform => _platform;
  set platform(TargetPlatform value) {
    if (_platform == value)
      return;
    _platform = value;
    markNeedsSemanticsUpdate();
  }

  SemanticFormatterCallback _semanticFormatterCallback;
  SemanticFormatterCallback get semanticFormatterCallback => _semanticFormatterCallback;
  set semanticFormatterCallback(SemanticFormatterCallback value) {
    if (_semanticFormatterCallback == value)
      return;
    _semanticFormatterCallback = value;
    markNeedsSemanticsUpdate();
  }

  int get divisions => _divisions;
  int _divisions;
  set divisions(int value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  String get label => _label;
  String _label;
  set label(String value) {
    if (value == _label) {
      return;
    }
    _label = value;
    _updateLabelPainter();
  }

  SliderThemeData get sliderTheme => _sliderTheme;
  SliderThemeData _sliderTheme;
  set sliderTheme(SliderThemeData value) {
    if (value == _sliderTheme) {
      return;
    }
    _sliderTheme = value;
    markNeedsPaint();
  }

  ThemeData get theme => _theme;
  ThemeData _theme;
  set theme(ThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    markNeedsPaint();
  }

  MediaQueryData get mediaQueryData => _mediaQueryData;
  MediaQueryData _mediaQueryData;
  set mediaQueryData(MediaQueryData value) {
    if (value == _mediaQueryData) {
      return;
    }
    _mediaQueryData = value;
    // Media query data includes the textScaleFactor, so we need to update the
    // label painter.
    _updateLabelPainter();
  }

  ValueChanged<double> get onChanged => _onChanged;
  ValueChanged<double> _onChanged;
  set onChanged(ValueChanged<double> value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      if (isInteractive) {
        _state.enableController.forward();
      } else {
        _state.enableController.reverse();
      }
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  ValueChanged<double> onChangeStart;
  ValueChanged<double> onChangeEnd;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    _updateLabelPainter();
  }

  ShowValueIndicator get showValueIndicatorValue => _sliderTheme.showValueIndicator;

  bool get showValueIndicator {
    bool showValueIndicator;
    switch (_sliderTheme.showValueIndicator) {
      case ShowValueIndicator.onlyForDiscrete:
        showValueIndicator = isDiscrete;
        break;
      case ShowValueIndicator.onlyForContinuous:
        showValueIndicator = !isDiscrete;
        break;
      case ShowValueIndicator.always:
        showValueIndicator = true;
        break;
      case ShowValueIndicator.never:
        showValueIndicator = false;
        break;
    }
    return showValueIndicator;
  }

  double get _adjustmentUnit {
    switch (_platform) {
      case TargetPlatform.iOS:
      // Matches iOS implementation of material slider.
        return 0.1;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      default:
      // Matches Android implementation of material slider.
        return 0.05;
    }
  }

  void _updateLabelPainter() {
    if (label != null) {
      _labelPainter
        ..text = TextSpan(
          style: _sliderTheme.valueIndicatorTextStyle,
          text: label,
        )
        ..textDirection = textDirection
        ..textScaleFactor = _mediaQueryData.textScaleFactor
        ..layout();
    } else {
      _labelPainter.text = null;
    }
    // Changing the textDirection can result in the layout changing, because the
    // bidi algorithm might line up the glyphs differently which can result in
    // different ligatures, different shapes, etc. So we always markNeedsLayout.
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayAnimation.addListener(markNeedsPaint);
    _valueIndicatorAnimation.addListener(markNeedsPaint);
    _enableAnimation.addListener(markNeedsPaint);
    _state.positionController.addListener(markNeedsPaint);
    _state.valueIndicatorController.forward();
  }

  @override
  void detach() {
    _state.valueIndicatorController.reverse();
    _overlayAnimation.removeListener(markNeedsPaint);
    _valueIndicatorAnimation.removeListener(markNeedsPaint);
    _enableAnimation.removeListener(markNeedsPaint);
    _state.positionController.removeListener(markNeedsPaint);
    super.detach();
  }

  double _getValueFromVisualPosition(double visualPosition) {
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
    return null;
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final double visualPosition = (globalToLocal(globalPosition).dx - _trackRect.left) / _trackRect.width;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretize(double value) {
    double result = value.clamp(0.0, 1.0);
    if (isDiscrete) {
      result = (result * divisions).round() / divisions;
    }
    return result;
  }

  void _startInteraction(Offset globalPosition) {
    if (isInteractive) {
      _active = true;
      // We supply the *current* value as the start location, so that if we have
      // a tap, it consists of a call to onChangeStart with the previous value and
      // a call to onChangeEnd with the new value.
      if (onChangeStart != null) {
        onChangeStart(_discretize(value));
      }
      _currentDragValue = _getValueFromGlobalPosition(globalPosition);
      onChanged(_discretize(_currentDragValue));
      _state.overlayController.forward();
      if (showValueIndicator) {
        _state.valueIndicatorController.forward();
        _state.interactionTimer?.cancel();
        _state.interactionTimer = Timer(_minimumInteractionTime * timeDilation, () {
          _state.interactionTimer = null;
          if (showValueIndicatorValue != ShowValueIndicator.always && !_active &&
              _state.valueIndicatorController.status == AnimationStatus.completed) {
            _state.valueIndicatorController.reverse();
          }
        });
     }
    }
  }

  void _endInteraction() {
    if (_active && _state.mounted) {
      if (onChangeEnd != null) {
        onChangeEnd(_discretize(_currentDragValue));
      }
      _active = false;
      _currentDragValue = 0.0;
      _state.overlayController.reverse();
      if (showValueIndicatorValue != ShowValueIndicator.always && showValueIndicator && _state.interactionTimer == null) {
        _state.valueIndicatorController.reverse();
      }
    }
  }

  void _handleDragStart(DragStartDetails details) => _startInteraction(details.globalPosition);

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      final double valueDelta = details.primaryDelta / _trackRect.width;
      switch (textDirection) {
        case TextDirection.rtl:
          _currentDragValue -= valueDelta;
          break;
        case TextDirection.ltr:
          _currentDragValue += valueDelta;
          break;
      }
      onChanged(_discretize(_currentDragValue));
    }
  }

  void _handleDragEnd(DragEndDetails details) => _endInteraction();

  void _handleTapDown(TapDownDetails details) => _startInteraction(details.globalPosition);

  void _handleTapUp(TapUpDetails details) => _endInteraction();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMinIntrinsicHeight(double width) => max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  double computeMaxIntrinsicHeight(double width) => max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : _minPreferredTrackWidth + _maxSliderPartWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : max(_minPreferredTrackHeight, _maxSliderPartHeight),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double value = _state.positionController.value;

    // The visual position is the position of the thumb from 0 to 1 from left
    // to right. In left to right, this is the same as the value, but it is
    // reversed for right to left text.
    double visualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - value;
        break;
      case TextDirection.ltr:
        visualPosition = value;
        break;
    }

    final Rect trackRect = _sliderTheme.trackShape.getPreferredRect(
      parentBox: this,
      offset: offset,
      sliderTheme: _sliderTheme,
      isDiscrete: isDiscrete,
    );
    final Offset thumbCenter = Offset(trackRect.left + visualPosition * trackRect.width, trackRect.center.dy);

    _sliderTheme.trackShape.paint(
      context,
      offset,
      parentBox: this,
      sliderTheme: _sliderTheme,
      enableAnimation: _enableAnimation,
      textDirection: _textDirection,
      thumbCenter: thumbCenter,
      isDiscrete: isDiscrete,
      isEnabled: isInteractive,
    );

    if (!_overlayAnimation.isDismissed) {
      _sliderTheme.overlayShape.paint(
        context,
        thumbCenter,
        activationAnimation: _overlayAnimation,
        enableAnimation: _enableAnimation,
        isDiscrete: isDiscrete,
        labelPainter: _labelPainter,
        parentBox: this,
        sliderTheme: _sliderTheme,
        textDirection: _textDirection,
        value: _value,
      );
    }

    if (isDiscrete) {
      final double tickMarkWidth = _sliderTheme.tickMarkShape.getPreferredSize(
        isEnabled: isInteractive,
        sliderTheme: _sliderTheme,
      ).width;
      final double adjustedTrackWidth = trackRect.width - tickMarkWidth;
      // If the tick marks would be too dense, don't bother painting them.
      if (adjustedTrackWidth / divisions >= 3.0 * tickMarkWidth) {
        final double dy = trackRect.center.dy;
        for (int i = 0; i <= divisions; i++) {
          final double value = i / divisions;
          // The ticks are mapped to be within the track, so the tick mark width
          // must be subtracted from the track width.
          final double dx = trackRect.left + value * adjustedTrackWidth + tickMarkWidth / 2;
          final Offset tickMarkOffset = Offset(dx, dy);
          _sliderTheme.tickMarkShape.paint(
            context,
            tickMarkOffset,
            parentBox: this,
            sliderTheme: _sliderTheme,
            enableAnimation: _enableAnimation,
            textDirection: _textDirection,
            thumbCenter: thumbCenter,
            isEnabled: isInteractive,
          );
        }
      }
    }

    if (isInteractive && label != null && !_valueIndicatorAnimation.isDismissed) {
      if (showValueIndicator) {
        _sliderTheme.valueIndicatorShape.paint(
          context,
          thumbCenter,
          activationAnimation: _valueIndicatorAnimation,
          enableAnimation: _enableAnimation,
          isDiscrete: isDiscrete,
          labelPainter: _labelPainter,
          parentBox: this,
          sliderTheme: _sliderTheme,
          textDirection: _textDirection,
          value: _value,
        );
      }
    }

    _sliderTheme.thumbShape.paint(
      context,
      thumbCenter,
      activationAnimation: _valueIndicatorAnimation,
      enableAnimation: _enableAnimation,
      isDiscrete: isDiscrete,
      labelPainter: _labelPainter,
      parentBox: this,
      sliderTheme: _sliderTheme,
      textDirection: _textDirection,
      value: _value,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isSemanticBoundary = isInteractive;
    if (isInteractive) {
      config.textDirection = textDirection;
      config.onIncrease = _increaseAction;
      config.onDecrease = _decreaseAction;
      if (semanticFormatterCallback != null) {
        config.value = semanticFormatterCallback(_state._lerp(value));
        config.increasedValue = semanticFormatterCallback(_state._lerp((value + _semanticActionUnit).clamp(0.0, 1.0)));
        config.decreasedValue = semanticFormatterCallback(_state._lerp((value - _semanticActionUnit).clamp(0.0, 1.0)));
      } else {
        config.value = '${(value * 100).round()}%';
        config.increasedValue = '${((value + _semanticActionUnit).clamp(0.0, 1.0) * 100).round()}%';
        config.decreasedValue = '${((value - _semanticActionUnit).clamp(0.0, 1.0) * 100).round()}%';
      }
    }
  }

  double get _semanticActionUnit => divisions != null ? 1.0 / divisions : _adjustmentUnit;

  void _increaseAction() {
    if (isInteractive) {
      onChanged((value + _semanticActionUnit).clamp(0.0, 1.0));
    }
  }

  void _decreaseAction() {
    if (isInteractive) {
      onChanged((value - _semanticActionUnit).clamp(0.0, 1.0));
    }
  }
}

class ViewSetupGuide extends StatelessWidget {
  const ViewSetupGuide({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(label: Text(S.of(context).view_setup_guides,
      style: TextStyle(color: floPrimaryColor), ),
      onPressed: () async {
        await launch(
          'https://meetflo.com/setup',
          option: CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            //animation: CustomTabsAnimation.slideIn()
          ),
        );
      },
      suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: floPrimaryColor, size: 13, )),
    );
  }
}

class FlatViewSetupGuide extends StatelessWidget {
 /*
 FlatButton(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          color: floLightBlue,
          child: Text(
            S.of(context).floprotect_active,
            textScaleFactor: 1.2,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(floButtonRadius)),
          onPressed: () {},
        ) const FlatViewSetupGuide({Key key}) : super(key: key);
 */

  @override
  Widget build(BuildContext context) {
    return TextButton(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      color: floLightBlue,
      label: Text(S.of(context).view_setup_guides, style: TextStyle(color: floPrimaryColor), textScaleFactor: 1.2,),
      onPressed: () async {
        await launch(
          'https://meetflo.com/setup',
          option: CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            //animation: CustomTabsAnimation.slideIn()
          ),
        );
      },
      suffixIcon: Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward_ios, color: floPrimaryColor, size: 13, )),
    );
  }
}

class Futures<T> extends FutureBuilder<T> {
  const Futures({
    Key key,
    Future<T> future,
    T initialData,
    AsyncWidgetBuilder<T> builder,
  }) : super(key: key, future: future, initialData: initialData, builder: builder);

  static Futures<T> of<T>(Future<T> future, {
    Key key,
    T initialData,
    // Widget onStart(BuildContext context), // none
    Widget onWaiting(BuildContext context), //
    Widget onActive(BuildContext context), //
    Widget catchError(BuildContext context, Exception e), // done with error
    Widget then(BuildContext context, T data), // done with data
    Widget onComplete(BuildContext context), // done
  }) {
    final AsyncWidgetBuilder<T> builder = (context, snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.none: {
          return (initialData != null) ? then(context, initialData) : Container();
          //return onStart(context);
        }
        case ConnectionState.waiting: {
          //return onWaiting(context);
          return (initialData != null) ? then(context, initialData) : Container();
        }
        case ConnectionState.active: {
          //return onActive(context);
          return (initialData != null) ? then(context, initialData) : Container();
        }
        case ConnectionState.done: {
          final widget = snapshot.hasError ? (catchError != null ? catchError(context, snapshot.error) : Container())
                                           : then(context, snapshot.data);
          return onComplete != null ? onComplete(context) : widget;
        }
      }
    };
    return Futures(future: future, key: key, initialData: initialData, builder: builder);
  }
}

typedef WidgetBuilder2<T> = Widget Function(BuildContext context, T t);

class Counter<int> extends StatefulWidget {
  final WidgetBuilder2<int> builder;
  final int begin;
  final int end;
  final VoidCallback onCompleted;

  Counter(this.builder, {Key key,
    this.begin,
    this.end,
    this.onCompleted,
  }) : super(key: key);

  State createState() => _Counter();
}

class _Counter extends State<Counter> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (widget.end - widget.begin).abs()),
    );
    _animation = StepTween(
      begin: widget.begin,
      end: widget.end,
      ).animate(_controller);
    _animation.addListener(() {
      if (_animation.isCompleted) {
        if (widget.onCompleted != null) {
          widget.onCompleted();
        }
      }
      setState(() {
      });
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animation.value);
  }
}

class EmptyAppBar  extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    final Brightness brightness = appBarTheme.brightness
        ?? themeData.primaryColorBrightness;
    final SystemUiOverlayStyle overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Semantics(
      container: true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
            child: Container(
              color: Colors.transparent
            ),
      ),
    );
  }
  @override
  Size get preferredSize => Size(0.0,0.0);
}

class TextFieldButton extends StatelessWidget {
  final String text;
  final Widget child;
  final String endText;
  final Widget leading;
  final Widget trailing;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  TextFieldButton({Key key,
    this.leading,
    this.text,
    this.child,
    this.endText,
    this.trailing = const Icon(Icons.arrow_forward_ios, size: 18,),
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(ignoring: onPressed == null, child: Theme(data: floLightThemeData, child: Builder(builder: (context) => FlatButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding,
      color: Colors.white,
      child: SizedBox(
          width: double.infinity,
          child: Row(children: [
            leading ?? Container(),
            leading != null ? SizedBox(width: 10,) : Container(),
            Expanded(child: child ?? Text(text ?? "", textAlign: TextAlign.left, style: Theme.of(context).textTheme.subhead, textScaleFactor: 0.95,)),
            Text(endText ?? "", textAlign: TextAlign.left, style: Theme.of(context).textTheme.body1.copyWith(color: floBlue.withOpacity(0.5))),
            SizedBox(width: 5,),
            trailing ?? Container(),
          ]
          )),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(floCardRadius),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      onPressed: onPressed ?? () {
      },
    ))));
  }
}

class EmptyLocationCardHorizontal extends StatelessWidget {
  EmptyLocationCardHorizontal({Key key,
    this.icon,
    this.labelText,
  }) : super(key: key);
  final Icon icon;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(6.0), child: InkWell(onTap: () {
      Navigator.of(context).pushNamed('/add_a_home');
    },
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              border: DashPathBorder.all(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
              ),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Padding(padding: EdgeInsets.all(12.0), child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(width: 10,),
                BlueIcon(icon: icon ?? Icon(Icons.add, size: 16,)),
                SizedBox(width: 10,),
                Text(labelText ?? S.of(context).add_a_home, textScaleFactor: 1.2, textAlign: TextAlign.center,),
              ],
            )))));
  }
}

class EmptyDeviceCardHorizontal extends StatelessWidget {
  EmptyDeviceCardHorizontal({Key key,
  this.icon,
  this.labelText,
  }) : super(key: key);
  final Icon icon;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(6.0), child: InkWell(onTap: () {
      Navigator.of(context).pushNamed('/add_a_flo_device');
    },
    child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          border: DashPathBorder.all(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                  dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
                ),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Padding(padding: EdgeInsets.all(12.0), child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: 10,),
            BlueIcon(icon: icon ?? Icon(Icons.add, size: 16,)),
            SizedBox(width: 10,),
            Text(labelText ?? S.of(context).connect_new_device, textAlign: TextAlign.center,),
            SizedBox(width: 10,),
            //Expanded(child: Text(labelText ?? S.of(context).connect_new_device, textAlign: TextAlign.center,)),
            //SizedBox(width: 10,),
          ],
        )))));
  }
}

class BlueIcon extends StatelessWidget {
  BlueIcon({Key key,
  this.icon
  }) : super(key: key);
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              /*
              boxShadow: [
                BoxShadow(color: Color(0xFF42DCF4).withOpacity(0.3), offset: Offset(0, 5), blurRadius: 14)
              ],
              */
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 1],
                colors: [
                  Color(0xFF3EBBE2),
                  Color(0xFF2790BE)
                ],
              ),
            ),
            child: Center(child: icon ?? Icon(Icons.add)));
  }
}

class FloProtectOn extends StatelessWidget {
  FloProtectOn({Key key,
    this.icon,
    this.onPressed,
  }) : super(key: key);
  final Icon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(floButtonRadius),
                    boxShadow: [
                      BoxShadow(color: floSecondaryButtonColor.withOpacity(0.5), offset: Offset(0, 10), blurRadius: 15)
                    ],
                  ),
                child: FlatButton.icon(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 22),
                      icon: Image.asset('assets/ic_protect.png', width: 20, height: 20),
                      color: floSecondaryButtonColor,
                      label: Text(
                        S.of(context).on.toUpperCase(),
                        //style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
                        style: Theme.of(context).textTheme.body2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(floButtonRadius)),
                      onPressed: onPressed ?? () {
                        Navigator.of(context).pushNamed('/floprotect');
                      },
                  ));
  }
}

class FloProtectOff extends StatelessWidget {
  FloProtectOff({Key key,
  this.icon,
  this.onPressed,
  }) : super(key: key);
  final Icon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(floButtonRadius),
                    /*
                    boxShadow: [
                      BoxShadow(color: floSecondaryButtonColor.withOpacity(0.5), offset: Offset(0, 10), blurRadius: 15)
                    ],
                    */
                  ),
                child: FlatButton.icon(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 22),
                      icon: Image.asset('assets/ic_protect.png', width: 20, height: 20, color: Colors.white),
                      color: Colors.white.withOpacity(0.1),
                      label: Text(
                        S.of(context).off.toUpperCase(),
                        style: Theme.of(context).textTheme.body2,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(floButtonRadius)),
                      onPressed: onPressed ?? () {
                        Navigator.of(context).pushNamed('/floprotect');
                      },
                  ));
  }
}

/*
class BadgeBorder extends Border {
  BadgeBorder({
    @required
    this.color,
    BorderSide top = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
    BorderSide bottom = BorderSide.none,
  }) : super(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        );

  factory BadgeBorder.all({
    BorderSide borderSide = const BorderSide(),
    @required
    Color color,
  }) {
    return BadgeBorder(
      color: color,
      top: borderSide,
      right: borderSide,
      left: borderSide,
      bottom: borderSide,
    );
  }
  //final CircularIntervalList<double> dashArray;
  final Color color;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null,
                  'A borderRadius can only be given for rectangular boxes.');
              canvas.drawPath(
                dashPath(Path()..addOval(rect), dashArray: dashArray),
                top.toPaint(),
              );
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                final RRect rrect =
                    RRect.fromRectAndRadius(rect, borderRadius.topLeft);
                canvas.drawPath(
                  dashPath(Path()..addRRect(rrect), dashArray: dashArray),
                  top.toPaint(),
                );
                return;
              }
              canvas.drawPath(
                dashPath(Path()..addRect(rect), dashArray: dashArray),
                top.toPaint(),
              );

              break;
          }
          return;
      }
    }

    assert(borderRadius == null,
        'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle,
        'A border can only be drawn as a circle if it is uniform.');

    // TODO(dnfield): implement when borders are not uniform.
  }
}
*/

class DashPathBorder extends Border {
  DashPathBorder({
    @required this.dashArray,
    BorderSide top = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
    BorderSide bottom = BorderSide.none,
  }) : super(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        );

  factory DashPathBorder.all({
    BorderSide borderSide = const BorderSide(),
    @required CircularIntervalList<double> dashArray,
  }) {
    return DashPathBorder(
      dashArray: dashArray,
      top: borderSide,
      right: borderSide,
      left: borderSide,
      bottom: borderSide,
    );
  }
  final CircularIntervalList<double> dashArray;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null,
                  'A borderRadius can only be given for rectangular boxes.');
              canvas.drawPath(
                dashPath(Path()..addOval(rect), dashArray: dashArray),
                top.toPaint(),
              );
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                final RRect rrect =
                    RRect.fromRectAndRadius(rect, borderRadius.topLeft);
                canvas.drawPath(
                  dashPath(Path()..addRRect(rrect), dashArray: dashArray),
                  top.toPaint(),
                );
                return;
              }
              canvas.drawPath(
                dashPath(Path()..addRect(rect), dashArray: dashArray),
                top.toPaint(),
              );

              break;
          }
          return;
      }
    }

    assert(borderRadius == null,
        'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle,
        'A border can only be drawn as a circle if it is uniform.');

    // TODO(dnfield): implement when borders are not uniform.
  }
}

typedef Changed2<T, T2> = void Function(T value, T2 value2);
typedef Changed3<T, T2, T3> = void Function(T value, T2 value2, T3 value3);
typedef Consumers<T, R> = R Function(T);
typedef Consumers2<T, T2, R> = R Function(T, T2);

class WifiIcon extends StatelessWidget {
  WifiIcon({Key key,
    this.device,
  }) : super(key: key);

  final Device device;

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (!(device.isConnected ?? false)) {
      //icon = Icon(Icons.signal_wifi_off);
      icon = WifiSignalIcon(-90);
    } else {
      icon = WifiSignalIcon(device?.firmwareProperties?.wifiRssi?.toDouble() ?? -40.0);
    }
    return icon;
  }
}

class WifiSignalIcon extends StatelessWidget {
  const WifiSignalIcon(this.signal, {
  Key key,
  this.color,
  this.width,
  this.height,
  this.orElse,
 }) : super(key: key);

  final double signal;
  final Color color;
  final double width;
  final double height;
  final Widget orElse;
  @override
  Widget build(BuildContext context) {
    if (signal > -30) {
      return SvgPicture.asset('assets/ic_wifi_white_highest.svg', color: color ?? floBlue,
        width: width,
        height: height,
      );
    } else if (signal > -50) {
      return SvgPicture.asset('assets/ic_wifi_white_normal.svg', color: color ?? floBlue,
        width: width,
        height: height,
      );
    } else if (signal > -60) {
      return SvgPicture.asset('assets/ic_wifi_white_low.svg', color: color ?? floBlue,
        width: width,
        height: height,
      );
    } else if (signal > -70) {
      return SvgPicture.asset('assets/ic_wifi_white_lowest.svg', color: color ?? floBlue,
        width: width,
        height: height,
      );
    } else {
      return orElse ?? SvgPicture.asset('assets/ic_wifi_offline.svg', color: color ?? floBlue,
        width: width,
        height: height,
      );
    }
  }
}

class RotateContainer extends StatefulWidget {
  final double endAngle; // π = 180°
  final double beginAngle;
  final bool rotated;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  _RotateContainerState createState() => _RotateContainerState();

  RotateContainer({Key key,
    this.beginAngle,
    this.endAngle,
    this.child,
    this.rotated = false,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.fastOutSlowIn,
  }) : super(key: key);
}

class _RotateContainerState extends State<RotateContainer>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  double _angle = 0.0;

  @override
  void initState() {
    //_angle = widget.beginAngle;
    _controller =
        AnimationController(vsync: this, duration: widget.duration);
        Fimber.d("angle: $_angle");
    _animation =
        Tween(begin: _angle, // FIXME
         //end: widget.endAngle
         end: _angle + (pi / 4)
        ).animate(_controller)
          ..addListener(() {
            setState(() {
              _angle = _animation.value;
            });
          });
    super.initState();
  }

  @override
  void didUpdateWidget(RotateContainer oldWidget) {
    if (oldWidget.endAngle == widget.endAngle) return;
    Fimber.d("didUpdateWidget");
    _controller.forward();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("build: $_angle");
    return Transform.rotate(
      angle: _angle,
      child: widget.child,
    );
  }
}

class Enabled extends StatelessWidget {
  Enabled({Key key,
    @required
    this.enabled,
    @required
    this.child,
    this.opacity = 0.5,
  }) : super(key: key);
  final bool enabled;
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(ignoring: !enabled, child: Opacity(opacity: enabled ? 1 : opacity, child: child));
  }
}

class Dot extends StatelessWidget {
  Dot({Key key,
    this.size = const Size(8, 8),
    this.color = Colors.white,
  }) : super(key: key);
  final Size size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ));
  }
}

class Pill2 extends StatelessWidget {
  Pill2({Key key,
    this.size = const Size(20, 10),
    this.color = Colors.white,
    this.shadowColor = Colors.black,
  }) : super(key: key);
  final Size size;
  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4.0),
            boxShadow: [
              BoxShadow(color: shadowColor.withOpacity(0.2), offset: Offset(-1, 0), blurRadius: 2),
            ],
          ),
        ));
  }
}

class Pill extends StatelessWidget {
  Pill({Key key,
    this.size = const Size(20, 10),
    this.color = Colors.white,
    this.shadowColor = Colors.black,
  }) : super(key: key);
  final Size size;
  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
            size: size,
            child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, 1],
                    colors: [
                      TinyColor(color).lighten(20).color,
                      color,
                    ],
                  ),
                  //color: color,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4.0),
                  boxShadow: [
                    BoxShadow(color: shadowColor.withOpacity(0.5), offset: Offset(-1, 0), blurRadius: 5),
                  ],
                ),
              ));
  }
}

class AwayModeIrrigation extends StatefulWidget {
  AwayModeIrrigation({Key key,
    this.enabled = false,
    this.controller,
    this.onCancel,
    this.onChanged,
  }) : super(key: key);
  final TabController controller;
  final enabled;
  final VoidCallback onCancel;
  final VoidCallback onChanged;

  State<AwayModeIrrigation> createState() => _AwayModeIrrigationState();
}

class _AwayModeIrrigationState extends State<AwayModeIrrigation> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);
    final oauthConsumer = Provider.of<OauthTokenNotifier>(context);
    //_enabled = locationConsumer.value?.irrigationSchedule?.enabled ?? false;
    BuiltList<BuiltList<String>> times = IrrigationScheduleChart.sampleSchedule.times;
    if (locationConsumer.value?.irrigationSchedule?.computed?.status == Schedule.FOUND) {
      times = locationConsumer.value?.mergedIrrigationSchedule?.computed?.times;
    }
    final status = locationConsumer.value?.mergedIrrigationSchedule?.computed?.status;
    final child = Theme(
                            data: floLightThemeData,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              title: Text(S.of(context).away_mode),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Text("You will be alerted to any water usage in this mode and we will automatically shut off your Flo by Moen device if we detect any water being used.",
                                textScaleFactor: 0.8,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black.withOpacity(0.5)),
                                ),
                                SizedBox(height: 20),
                                Row(children: <Widget>[
                                  Flexible(child: Text(S.of(context).allow_irrigation_during_away_mode,
                                  style: TextStyle(color: Colors.black),
                                  softWrap: true,
                                  textScaleFactor: 0.9,
                                  )),
                                  SimpleSwitch(value: _enabled, onChanged: (enabled) async {
                                    setState(() {
                                      _enabled = enabled;
                                    });
                                    try {
                                    await flo.setIrrigationEnabled(locationConsumer.value.id, enabled,
                                      authorization: oauthConsumer.value.authorization);
                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                      ..irrigationSchedule = locationConsumer.value?.irrigationSchedule?.rebuild((b) => b..enabled = enabled)?.toBuilder()
                                      );
                                    } catch (e) {
                                      Fimber.e("", ex: e);
                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b
                                      ..irrigationSchedule = locationConsumer.value?.irrigationSchedule?.rebuild((b) => b..enabled = !enabled)?.toBuilder()
                                      );
                                      setState(() {
                                        _enabled = !enabled;
                                      });
                                    }
                                  }),
                                ]),
                                SizedBox(height: 20),
                                Visibility(visible: _enabled, maintainState: true, maintainAnimation: true, maintainSize: true,
                                    child: Visibility(visible: status == Schedule.FOUND, child: Row(children: <Widget>[
                                  Expanded(child: Text(S.of(context).your_estimated_irrigation_schedule,
                                  style: TextStyle(color: Colors.black.withOpacity(0.5)),
                                  softWrap: true,
                                    textScaleFactor: 0.8,
                                  )),
                                  SizedBox(height: 10),
                                  //SvgPicture.asset('assets/ic_outline_question.svg'),
                                  IconButton(icon: Image.asset('assets/ic_info.png', width: 25,),
                                   onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Theme(
                                          data: floLightThemeData,
                                          child: AlertDialog(
                                            //title: Text(""),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                            content: Text("We estimate that your home’s irrigation typically runs between these times of the day", textScaleFactor: 0.8,),
                                        )
                                        );
                                      });
                                   }),
                                ]))),
                                SizedBox(height: 30),
                                  Visibility(visible: _enabled, maintainState: true, maintainAnimation: true, maintainSize: true,
                                   child: Stack(children: [
                                    SizedBox(height: 100,
                                      child: IgnorePointer(ignoring: status != Schedule.FOUND, child: IrrigationScheduleChart(times ?? BuiltList<BuiltList<String>>([BuiltList<String>()]),
                                          color: status == Schedule.FOUND ? floBlue2 : Color(0xFFF0F4F8)))),
                                    Visibility(visible: status != Schedule.FOUND, child: SizedBox(width: double.infinity, height: 100, child: Padding(padding: EdgeInsets.only(top: 20), child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                      Text(S.of(context).no_irrigation_schedule_found, textScaleFactor: 0.9,),
                                      FlatButton(
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                                        child: Text(S.of(context).learn_more,
                                          style: TextStyle(
                                          decoration: TextDecoration.underline,
                                        ),),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Theme(
                                                  data: floLightThemeData,
                                                  child: AlertDialog(
                                                    //title: Text(""),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                                    content: Text("We are currently unable to detect your irrigation pattern. You can still enable Away Mode but you will be alerted about any water usage in this mode, including irrigation."),
                                                  )
                                              );
                                            });
                                      }),
                                    ],))))
                                  ])),
                                  //SizedBox(height: 100, child: _enabled ? IrrigationScheduleChart(IrrigationScheduleChart.sampleSchedule.times, color: floBlue2) : IrrigationScheduleChart(IrrigationScheduleChart.sampleSchedule.times, color: Color(0xFFF0F4F8))),
                                  Visibility(visible: _enabled, maintainState: true, maintainAnimation: true, maintainSize: true, child: Image.asset('assets/ic_time_base_line.png')),
                                /*
                                SizedBox(
                                  width: double.infinity,
                                  height: 100,
                                 child: SimpleLineChart.withSampleData()),
                                */
                              ]),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    widget.controller?.animateTo(widget.controller?.previousIndex, curve: Curves.fastOutSlowIn);
                                    if (widget.onCancel != null) {
                                      widget.onCancel();
                                    }
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text(ReCase(S.of(context).enable_away_mode).titleCase),
                                  onPressed: () async {
                                    try {
                                    await flo.away(locationConsumer.value.id,
                                      authorization: oauthConsumer.value.authorization,
                                    );
                                      locationConsumer.value = locationConsumer.value.rebuild((b) => b.systemModes..target = SystemMode.AWAY);
                                      final locationsProvider = Provider.of<LocationsNotifier>(context, listen: false);
                                      locationsProvider.value = BuiltList<Location>(locationsProvider.value.map((it) => it.id == locationConsumer.value.id ? locationConsumer.value : it));
                                    } catch (e) {
                                      Fimber.e("", ex: e);
                                    }
                                    Navigator.of(context).pop();
                                    if (widget.onChanged != null) {
                                      widget.onChanged();
                                    }
                                  }
                                ),
                              ]),
      );
    return child;
  }
}


class SimpleSwitch extends StatefulWidget {
  SimpleSwitch({Key key,
  this.value,
  this.onChanged,
  }) : super(key: key);
  final bool value;
  final Consumers<bool, Future<bool>> onChanged;

  State<SimpleSwitch> createState() => _SimpleSwitchState();
}

class _SimpleSwitchState extends State<SimpleSwitch> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Switch(value: _checked, onChanged: (checked) async {
      setState(() {
        _checked = checked;
      });
      if (widget.onChanged != null) {
        final changed = await widget.onChanged(checked);
        if (!changed) {
          setState(() {
            _checked = !checked;
          });
        }
      }
    });
  }
}

class SimpleBackButton extends StatelessWidget {
  const SimpleBackButton({
     Key key,
     this.color,
     this.icon,
     this.onPressed,
    }) : super(key: key);

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color color;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: icon ?? const BackButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed == null) {
          Navigator.maybePop(context);
        } else {
          onPressed();
        }
      },
    );
  }
}

class SimpleCloseButton extends StatelessWidget {
  /// Creates a Material Design close button.
  const SimpleCloseButton({ Key key,
     this.color,
     this.icon,
     this.onPressed,
   }) : super(key: key);

  final Color color;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: icon ?? const Icon(Icons.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        if (onPressed == null) {
          Navigator.maybePop(context);
        } else {
          onPressed();
        }
      },
    );
  }
}

class SimpleDrawerButton extends StatelessWidget {
  const SimpleDrawerButton({ Key key,
     this.color,
     this.icon,
     this.onPressed,
    this.back,
   }) : super(key: key);

  final Color color;
  final Widget icon;
  final Widget back;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ScaffoldState scaffold = Scaffold.of(context, nullOk: true);
    return (scaffold.hasDrawer ?? false) ? IconButton(
          color: color,
          icon: icon ?? const Icon(Icons.menu),
          onPressed: onPressed ?? () {
            Scaffold.of(context).openDrawer();
          },
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        ) : back ?? Container();
  }
}

class NotificationCard extends StatefulWidget {
  NotificationCard({
    this.key,
    @required
    this.notification,
    this.systemMode,
    this.labelText,
    this.onPressed,
    this.orElse,
    this.device,
    this.location,
  }) : super(key: key);
  final Key key;
  final Notifications notification;
  final Widget labelText;
  final VoidCallback onPressed;
  final Widget orElse;
  final PendingSystemMode systemMode;
  final Device device;
  final Location location;

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  Notifications _notification;
  @override
  void didUpdateWidget(NotificationCard oldWidget) {
    if (oldWidget.notification != widget.notification) {
      invalidate();
    }
    super.didUpdateWidget(oldWidget);
  }

  void invalidate() {
    _notification = widget.notification;
    if (_notification == null) return;
    final hasSeverity = _notification.hasSeverity ?? false;
    try {
      Fimber.d("hasSeverity: ${hasSeverity}");
      if (!hasSeverity) {
        final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
        if (alarms.isEmpty) {
          Future.delayed(Duration.zero, () async {
            try {
              final flo = Provider .of<FloNotifier>(context) .value;
              final oauth = Provider .of<OauthTokenNotifier>(context) .value;
              final alarmProvider = Provider.of<AlarmsNotifier>(context, listen: false);
              alarmProvider.value = (await flo.getAlarms(authorization: oauth.authorization)).body.items;
              final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
              if (alarms?.isNotEmpty ?? false) {
                _notification = _notification.rebuild((b) => b
                  ..alarmCounts = ListBuilder(_notification?.alarmCounts?.map((alarm) => alarm.rebuild((b) => b
                    ..severity = Maps.get2<Alarm, int>(alarms, b.id).severity
                  ))  ?? <Alarm>[])
                );
              }
              Fimber.d("_notification: ${_notification}");
              setState(() {});
            } catch (err) {
              Fimber.d("", ex: err);
            }
          });
        } else {
          _notification = _notification.rebuild((b) => b
            ..alarmCounts = ListBuilder(_notification?.alarmCounts?.map((alarm) => alarm.rebuild((b) => b
              ..severity = Maps.get2<Alarm, int>(alarms, b.id).severity
            )) ?? <Alarm>[])
          );
          Fimber.d("_notification: ${_notification}");
        }
      }
    } catch (err) {
      Fimber.d("", ex: err);
    }
  }
  @override
  void initState() {
    invalidate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.device != null) {
      final installed = (widget.device?.installStatus?.isInstalled ?? false);
      final isLearning = (widget.device?.isLearning ?? false);
      final isConnected = widget.device?.isConnected ?? false;
      if (!isConnected) {
        return DeviceOfflineCard();
      } else if (!installed) {
        return NeedsInstallCard(key: widget.key, notification: _notification, labelText: widget.labelText);
      } else if (isLearning) {
        return LearningCard();
      }
    }
    final alarms = Maps.fromIterable2<int, Alarm>(Provider.of<AlarmsNotifier>(context, listen: false).value, key: (it) => it.id);
    if (alarms.isNotEmpty) {
      _notification = _notification.rebuild((b) => b
        ..alarmCounts = ListBuilder(_notification.alarmCounts.map((alarm) => alarm.rebuild((b) => b
          ..severity = Maps.get2<Alarm, int>(alarms, b.id)?.severity
        )))
      );
    }
    Fimber.d("notification: ${_notification}");
    Fimber.d("criticalCount: ${_notification?.criticalCount}");
    Fimber.d("warningCount: ${_notification?.warningCount}");
    if ((_notification?.criticalCount ?? 0) > 0) {
      return CriticalCard(key: widget.key, notification: _notification, labelText: widget.labelText,
        device: widget.device, location: widget.location,
        onPressed: widget.onPressed ?? () {
          //Navigator.of(context).pushNamedAndRemoveUntil('/home', ModalRoute.withName('/home'), arguments: {"index": "1"});
          final selectedDevicesProvider = Provider.of<SelectedDevicesNotifier>(context, listen: false);
          if (widget.device != null) {
            selectedDevicesProvider.value = BuiltList<Device>([widget.device]);
          } else {
            selectedDevicesProvider.value = widget.location.devices;
          }
          selectedDevicesProvider.invalidate();
          //Navigator.of(context).pushNamedAndRemoveUntil('/alerts', ModalRoute.withName('/home'));
          Navigator.of(context).pushNamed('/alerts');
        }
      );
    } else if ((_notification?.warningCount ?? 0) > 0) {
      return WarningCard(key: widget.key, notification: _notification, labelText: widget.labelText,
          device: widget.device, location: widget.location,
          onPressed: widget.onPressed ?? () {
            //Navigator.of(context).pushNamedAndRemoveUntil('/home', ModalRoute.withName('/home'), arguments: {"index": "1"});
            final selectedDevicesProvider = Provider.of<SelectedDevicesNotifier>(context, listen: false);
            final flo = Provider.of<FloNotifier>(context, listen: false).value;
            final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
            if (widget.device != null) {
              selectedDevicesProvider.value = BuiltList<Device>([widget.device]);
            } else {
              selectedDevicesProvider.value = widget.location.devices;
            }
            Fimber.d("selectedDevicesProvider.value: ${selectedDevicesProvider.value}");
            //selectedDevicesProvider.invalidate();
            //Navigator.of(context).pushNamedAndRemoveUntil('/alerts', ModalRoute.withName('/home'));
            Navigator.of(context).pushNamed('/alerts');
          }
      );
    } else {
      if (widget.location != null && (widget.location?.isSecure ?? false)) {
        return widget.orElse ?? Container();
      } else if (widget.device != null && (widget.device?.isSecure ?? false)) {
        return widget.orElse ?? Container();
      } else {
        return Container();
      }
    }
  }
}

class DeviceOfflineCard extends StatelessWidget {
  DeviceOfflineCard({Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
        leading: Image.asset('assets/ic_warning2.png', width: 50, height: 50),
        text:  Text(ReCase(S.of(context).device_offline).titleCase, style: Theme.of(context).textTheme.title),
        text2: Text(S.of(context).bring_device_back_online,
          style: Theme.of(context).textTheme.caption,
        ),
        color: Colors.white.withOpacity(0.2),
        onPressed: () async {
          await launch(
            'https://support.meetflo.com/hc/en-us/articles/115000748594-Device-Offline',
            option: CustomTabsOption(
                toolbarColor: Theme
                    .of(context)
                    .primaryColor,
                enableDefaultShare: true,
                enableUrlBarHiding: true,
                showPageTitle: true,
                //animation: CustomTabsAnimation.slideIn()
            ),
          );
        }
    );
  }
}

class ButtonCard extends StatelessWidget {
  ButtonCard({
    Key key,
    this.margin = const EdgeInsets.symmetric(vertical: 2, horizontal: 16.0),
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
    this.height = 68,
    this.leading,
    this.text,
    this.text2,
    this.trailing = const Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white),
    this.gradient,
    this.boxShadow,
    this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.color,
  }) : super(key: key);
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double height;
  Widget leading = Padding(padding: EdgeInsets.only(top: 8), child: Image.asset('assets/ic_warning2.png', width: 50, height: 50));
  final Widget text;
  final Widget text2;
  final Widget trailing;
  final Gradient gradient;
  final List<BoxShadow> boxShadow;
  final VoidCallback onPressed;
  final BorderRadiusGeometry borderRadius;
  Color color = Colors.white.withOpacity(0.2);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: gradient == null ? color ?? Colors.white.withOpacity(0.2) : null,
          gradient: gradient,
          //boxShadow: boxShadow,
          /*
          boxShadow: [
            BoxShadow(
              color: Colors.grey[500],
              offset: Offset(0.0, 1.5),
              blurRadius: 1.5,
            ),
          ],
          */
        ),
        height: height,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () {
                  if (onPressed != null) onPressed();
                },
                child: Padding(padding: padding, child: Row(children: <Widget>[
                  leading ?? Container(),
                  SizedBox(width: 10),
                  Expanded(child: Column(
                    children: <Widget>[
                      text ?? Container(),
                      SizedBox(height: 3),
                      text2 ?? Container(),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  )
                  ),
                  SizedBox(width: 8),
                  trailing ?? Container(),
                ],
                    crossAxisAlignment: CrossAxisAlignment.center,
                ),
                )
            )
        )
    );
  }
}

class LearningCard extends StatelessWidget {
  LearningCard({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
        leading: Image.asset('assets/ic_info_blue.png', width: 55, height: 55),
        text: Text(ReCase(S.of(context).learning_mode).titleCase,
          style: Theme.of(context).textTheme.title,
        ),
        text2: Text(S.of(context).learning_homes_water_habits,
          style: Theme.of(context).textTheme.caption,
        ),
        onPressed: () async {
          await launch(
            'https://support.meetflo.com/hc/en-us/articles/115003205673-Learning-Mode',
            option: CustomTabsOption(
                toolbarColor: Theme.of(context).primaryColor,
                enableDefaultShare: true,
                enableUrlBarHiding: true,
                showPageTitle: true,
                //animation: CustomTabsAnimation.slideIn()
            ),
          );
        }
    );
  }
}

class NeedsInstallCard extends StatelessWidget {
  NeedsInstallCard({
    Key key,
    this.device,
    this.notification,
    this.icon,
    this.labelText,
    this.onPressed,
    this.margin = const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
  }) : super(key: key);
  final Notifications notification;
  final Widget labelText;
  final Widget icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry margin;
  final Device device;

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
      margin: margin,
      leading: icon ?? Image.asset('assets/ic_warning2.png', width: 50, height: 50),
      text: Text(S.of(context).needs_install,
        style: Theme.of(context).textTheme.title,
      ),
      text2: labelText ?? Text(S.of(context).install_device_on_main_water_line,
        style: Theme.of(context).textTheme.caption,
      ),
      onPressed: () async {
        await launch(
          'https://support.meetflo.com/hc/en-us/articles/115003205573--Needs-Install-alert-on-Dashboard',
          option: CustomTabsOption(
              toolbarColor: Theme.of(context).primaryColor,
              enableDefaultShare: true,
              enableUrlBarHiding: true,
              showPageTitle: true,
              //animation: CustomTabsAnimation.slideIn()
          ),
        );
      },
    );
  }
}

class AlertCard extends StatelessWidget {
  AlertCard({
    Key key,
    this.alert,
    this.icon,
    this.iconSize = 35,
    this.labelText,
    this.onPressed,
  }) : super(key: key);
  final Alert alert;
  final Widget labelText;
  final Widget icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    var _icon = icon;
    Gradient _gradient;
    Color _color;

    Widget _trailing = const Icon(Icons.arrow_forward_ios,
        size: 16,
        color: Colors.white);
    if (alert.isResolved) {
      _color = Colors.white.withOpacity(0.2);
      if (alert?.alarm?.severity == Alarm.CRITICAL) {
        _icon = Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_critical.png', width: iconSize, height: iconSize));
      } else if (alert?.alarm?.severity == Alarm.WARNING) {
        _icon = Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_warning.png', width: iconSize, height: iconSize));
      //} else if (alert?.alarm?.severity == Alarm.INFO) {
      } else {
        _icon = Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_info_cyan.png', width: iconSize, height: iconSize));
      }
    } else if (alert?.alarm?.severity == Alarm.CRITICAL) {
      _icon = Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_critical.png', width: iconSize, height: iconSize));
    } else if (alert?.alarm?.severity == Alarm.WARNING) {
      _icon = Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_warning.png', width: iconSize, height: iconSize));
      _gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 1.0],
        colors: [
          Color(0xFFEB9A3A),
          Color(0xFFCC5D32),
        ],
      );
    } else {
      _color = Colors.white.withOpacity(0.2);
    }
    _trailing = TimerWidget(builder: (context, _) => Text(alert.createAgo, style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white.withOpacity(0.5)), softWrap: true, textAlign: TextAlign.end,));
    return ButtonCard(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 16.0),
      color: _color ?? Color(0xFFD75839),
      gradient: _gradient,
      leading: _icon ?? Padding(padding: EdgeInsets.only(top: 6), child: Image.asset('assets/ic_critical.png', width: iconSize, height: iconSize)),
      text: Text(
        alert?.displayTitle ?? alert?.alarm?.displayName ?? S.of(context).critical_alert,
        style: Theme.of(context).textTheme.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textScaleFactor: 0.8,
      ),
      text2: labelText ?? Text("${alert.location?.displayName ?? ""} ${alert.device?.displayName ?? ""}",
        style: Theme.of(context).textTheme.caption,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: SizedBox(width: 80, child: _trailing),
      onPressed: () async {
        final alertProvider = Provider.of<AlertNotifier>(context, listen: false);
        alertProvider.value = alert;
        alertProvider.invalidate();
        if (alert.isResolved) {
          Navigator.of(context).pushNamed('/resolved_alert');
        } else {
          Navigator.of(context).pushNamed('/alert');
        }
      },
    );
  }
}

class CheckIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Color(0xFF42DCF4).withOpacity(0.3), offset: Offset(0, 5), blurRadius: 14)
            ],
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 1],
              colors: [
                Color(0xFF5BE9F9),
                Color(0xFF12C3EA)
              ],
            ),
            border: Border.all(color: Colors.white, width: 0.2),
          ),
          child: Icon(Icons.check));
  }
}


class CriticalCard extends StatelessWidget {
  CriticalCard({
    Key key,
    @required
    this.notification,
    this.icon,
    this.labelText,
    this.onPressed,
    this.margin = const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
    this.device,
    this.location,
  }) : super(key: key);
  final Device device;
  final Location location;
  final Notifications notification;
  final Widget labelText;
  final Widget icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
      margin: margin,
      leading: icon ?? Image.asset('assets/ic_critical.png', width: 50, height: 50),
      color: Color(0xFFD75839),
      text: Text(
        notification.criticalCount == 1 ? "${notification.criticalCount} ${S.of(context).critical_alert}" :
        "${notification.criticalCount} ${S.of(context).critical_alerts}",
        style: Theme.of(context).textTheme.title,
      ),
      text2: labelText ?? Text((notification.criticalCount == 1 ? S.of(context).view_alert : S.of(context).view_alerts),
          style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7))),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white),
      onPressed: onPressed,
    );
  }
}

class WarningCard extends StatelessWidget {
  WarningCard({
    Key key,
    @required
    this.notification,
    this.labelText,
    this.onPressed,
    this.margin = const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
    this.device,
    this.location,
  }) : super(key: key);
  final Notifications notification;
  final Widget labelText;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry margin;
  final Device device;
  final Location location;

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
      margin: margin,
      leading: Image.asset('assets/ic_warning.png', width: 50, height: 50),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 1.0],
        colors: [
          Color(0xFFEB9A3A),
          Color(0xFFCC5D32),
        ],
      ),
      text: Text(
        notification.warningCount == 1 ? "${notification.warningCount} ${S.of(context).warning_alert}" :
        "${notification.warningCount} ${S.of(context).warning_alerts}",
        style: Theme.of(context).textTheme.title,
      ),
      text2: labelText ?? Text((notification.criticalCount == 1 ? S.of(context).view_alert : S.of(context).view_alerts),
          style: TextStyle(color: Colors.white.withOpacity(0.7))),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white),
      onPressed: onPressed,
    );
  }
}

Map<String, Widget> SystemModeIcons = {
  SystemMode.AWAY: AwayBadge(),
  SystemMode.HOME: HomeBadge(),
  SystemMode.SLEEP: SleepBadge(),
};

class EmptyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 10.0, left: 20, right: 20, bottom: 30),
        child: InkWell(onTap: () {
          Navigator.of(context).pushNamed('/add_a_home');
        }, child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              border: DashPathBorder.all(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                dashArray: CircularIntervalList<double>(<double>[5.0, 5.0]),
              ),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(child:
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/ic_homes.png', key: UniqueKey()),
                  SizedBox(height: 30),
                  Text(S.of(context).starting_by_adding_your_home,
                    textAlign: TextAlign.center,
                    textScaleFactor: 1.6,
                    style: TextStyle(height: 1.3),
                  ),
                  SizedBox(height: 30),
                  Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(Icons.add))),
                ]))
        )));
  }
}

class SecureHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 50),
        child: Center(child:
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(S.of(context).youre_secure, style: Theme.of(context).textTheme.title, textAlign: TextAlign.center, textScaleFactor: 1.0,),
                  SizedBox(height: 15),
                  Text(S.of(context).no_alerts_were_detected_at_this_location, style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center, textScaleFactor: 1.0),
                  SizedBox(height: 15),
                  Image.asset('assets/ic_secure_home.png', width: 150),
                ]))
        );
  }
}

class SimpleRefresher extends StatefulWidget {
  //indicate your listView
  final Widget child;

  //final RefreshIndicator header;
  final LoadIndicator footer;

  // This bool will affect whether or not to have the function of drop-up load.
  final bool enablePullUp;

  // controll whether open the second floor function
  final bool enableTwoLevel;

  //This bool will affect whether or not to have the function of drop-down refresh.
  final bool enablePullDown;

  // upper and downer callback when you drag out of the distance
  final VoidCallback onRefresh, onLoading, onTwoLevel;

  // This method will callback when the indicator changes from edge to edge.
  final OnOffsetChange onOffsetChange;

  //controll inner state
  final RefreshController controller;

  SimpleRefresher(
      {Key key,
        @required this.controller,
        this.child,
        //this.header,
        this.footer,
        this.enablePullDown: true,
        this.enablePullUp: false,
        this.enableTwoLevel: false,
        this.onRefresh,
        this.onLoading,
        this.onTwoLevel,
        this.onOffsetChange})
      : assert(controller != null),
        super(key: key);

  static SmartRefresher of(BuildContext context) {
    return context.ancestorWidgetOfExactType(SmartRefresher);
  }

  @override
  State<SimpleRefresher> createState() {
    return _SimpleRefresherState();
  }
}

class _SimpleRefresherState extends State<SimpleRefresher> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}

class FloGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Visibility(visible: MediaQuery.of(context).platformBrightness == Brightness.light, child: Container(
      decoration: BoxDecoration(
        color: floBlue,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [
            floBlueGradientTop,
            floBlueGradientBottom,
          ],
        ),
      ),
    ));
  }
}

class FloGradientRedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: floBlue,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.071, 0.6232, 0.9],
          colors: [
            //linear-gradient(154.83deg, #D8564B 0.71%, #94352C 62.32%, #78211B 89.02%)
            Color(0xFFD8564B),
            Color(0xFF94352C),
            Color(0xFF78211B),
            //Color(0xFFD8564B),
            //Color(0xFF78211B),
          ],
        ),
      ),
    );
  }
}

class FloGradientAmberBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: floBlue,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.1, 1.0, 0.0, 0.1, 1.0],
          colors: [
            Color.fromARGB(255, 242, 170, 62),
            Color.fromARGB(255, 242, 170, 62),
            //Color(0xFFFEAA0A),
            //Color(0xFFFEAA0A),
            Color(0xFFCF2A28),
            //Color(0xFFFEAA0A),
            Color.fromARGB(255, 242, 170, 62),
            Color(0xFFCF2A28),
            Color(0x9FCF2A28),
          ],
        ),
      ),
    );
  }
}

///<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle" >
///    <gradient
///        android:type="linear"
///        android:startColor="#6c6c6c"
///        android:endColor="#848484"
///        android:angle="135"/>
///</shape>
class FloGradientGreyBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF6c6c6c),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 1.0],
          colors: [
            Color(0xFF6c6c6c),
            Color(0xFF848484),
          ],
        ),
      ),
    );
  }
}

class FloOutlineButton extends StatelessWidget {
  const FloOutlineButton( {
    Key key,
    this.child,
    @required
    this.onPressed,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: onPressed,
      child: child,
      padding: EdgeInsets.symmetric(vertical: 16),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(40.0)),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
    );
  }
}

class BlueCircleBadge extends StatelessWidget {
  const BlueCircleBadge( {
    Key key,
    this.padding = const EdgeInsets.all(7),
    @required
    this.child,
    //@required
    //this.onPressed,
  }) : super(key: key);

  final Widget child;
  final EdgeInsets padding;
  //final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      padding: padding,
      child: child,
    );
  }
}

class BlueCircleIcon extends StatelessWidget {
  const BlueCircleIcon( {
    Key key,
    this.padding = const EdgeInsets.all(12),
    @required
    this.child,
    //@required
    //this.onPressed,
  }) : super(key: key);

  final Widget child;
  final EdgeInsets padding;
  //final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2790BE),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [
            Color.fromRGBO(46, 116, 157, 1),
            Color.fromRGBO(24, 100, 144, 1),
          ],
        ),
        //color: color,
        shape: BoxShape.circle,
        //borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(0, -1), blurRadius: 1),
        ],
      ),
      padding: padding,
      child: child ?? Icon(Icons.close, size: 20),
    );
  }
}


class SizedBlueCircleIcon extends StatelessWidget {
  const SizedBlueCircleIcon( {
    Key key,
    this.child,
    this.size = const Size(45, 45),
    //@required
    //this.onPressed,
  }) : super(key: key);

  final Widget child;
  final Size size;
  //final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Color(0xFF2790BE),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [
            Color.fromRGBO(46, 116, 157, 1),
            Color.fromRGBO(24, 100, 144, 1),
          ],
        ),
        //color: color,
        shape: BoxShape.circle,
        //borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(0, -1), blurRadius: 1),
        ],
      ),
      child: child ?? Icon(Icons.close, size: 18),
    );
  }
}

class RoundedBlueLight extends StatelessWidget {

  const RoundedBlueLight(this.child, {Key key,
    this.width
  }) : super(key: key);

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(floButtonRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1.0],
            colors: [
              Color(0xFF3EBBE2),
              Color(0xFF2790BE),
            ],
          ),
        ),
        child: Container(
            margin: EdgeInsets.all(0),
            padding: EdgeInsets.all(0),
            child: child)));
  }
}

class SimpleCircularPercentIndicator extends StatefulWidget {
  ///Percent value between 0.0 and 1.0
  final double percent;
  final double radius;

  ///Width of the line of the Circle
  final double lineWidth;

  ///Color of the background of the circle , default = transparent
  final Color fillColor;

  ///First color applied to the complete circle
  final Color backgroundColor;

  Color get progressColor => _progressColor;

  Color _progressColor;

  ///true if you want the circle to have animation
  final bool animation;

  ///duration of the animation in milliseconds, It only applies if animation attribute is true
  final int animationDuration;

  ///widget at the top of the circle
  final Widget header;

  ///widget at the bottom of the circle
  final Widget footer;

  ///widget inside the circle
  final Widget center;

  final LinearGradient linearGradient;

  ///The kind of finish to place on the end of lines drawn, values supported: butt, round, square
  final CircularStrokeCap circularStrokeCap;

  ///the angle which the circle will start the progress (in degrees, eg: 0.0, 45.0, 90.0)
  final double startAngle;

  /// set true if you want to animate the linear from the last percent value you set
  final bool animateFromLastPercent;

  /// set false if you don't want to preserve the state of the widget
  final bool addAutomaticKeepAlive;

  /// set the arc type
  final ArcType arcType;

  /// set a circular background color when use the arcType property
  final Color arcBackgroundColor;

  /// set true when you want to display the progress in reverse mode
  final bool reverse;

  /// Creates a mask filter that takes the progress shape being drawn and blurs it.
  final MaskFilter maskFilter;

  SimpleCircularPercentIndicator(
      {Key key,
        this.percent = 0.0,
        this.lineWidth = 5.0,
        this.startAngle = 0.0,
        @required this.radius,
        this.fillColor = Colors.transparent,
        this.backgroundColor = const Color(0xFFB8C7CB),
        Color progressColor,
        this.linearGradient,
        this.animation = false,
        this.animationDuration = 300,
        this.header,
        this.footer,
        this.center,
        this.addAutomaticKeepAlive = true,
        this.circularStrokeCap,
        this.arcBackgroundColor,
        this.arcType,
        this.animateFromLastPercent = true,
        this.reverse = false,
        this.maskFilter})
      : super(key: key) {
    if (linearGradient != null && progressColor != null) {
      throw ArgumentError(
          'Cannot provide both linearGradient and progressColor');
    }
    _progressColor = progressColor ?? Colors.red;

    assert(startAngle >= 0.0);
    if (percent < 0.0 || percent > 1.0) {
      throw Exception("Percent value must be a double between 0.0 and 1.0");
    }

    if (arcType == null && arcBackgroundColor != null) {
      throw ArgumentError('arcType is required when you arcBackgroundColor');
    }
  }

  @override
  _CircularPercentIndicatorState createState() =>
      _CircularPercentIndicatorState();
}

class _CircularPercentIndicatorState extends State<SimpleCircularPercentIndicator>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController _animationController;
  Animation _animation;
  double _percent = 0.0;

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.animation) {
      _animationController = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: widget.animationDuration));
      _animation = Tween(begin: 0.0, end: widget.percent).animate(CurvedAnimation(parent:_animationController, curve: Curves.fastOutSlowIn));

      _animation.addListener(() {
        setState(() {
          _percent = _animation.value;
        });
        //Fimber.d("$_percent");
      });
      _animationController.forward();
    } else {
      _updateProgress();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(SimpleCircularPercentIndicator oldWidget) {
    //Fimber.d("precent: ${oldWidget.percent} => ${widget.percent}, _animationController: ${_animationController}");
    if (oldWidget.percent != widget.percent ||
        oldWidget.startAngle != widget.startAngle) {
      if (_animationController != null) {
        _animation = Tween(
          //begin: widget.animateFromLastPercent ? _percent : 0.0,
            begin: _percent,
            end: widget.percent).animate(_animationController);
        _animationController.forward(from: _percent);
      } else {
        _updateProgress();
      }
    } else {
      _updateProgress();
    }
    super.didUpdateWidget(oldWidget);
  }

  _updateProgress() {
    _percent = widget.percent;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var items = List<Widget>();
    if (widget.header != null) {
      items.add(widget.header);
    }
    items.add(Container(
        height: widget.radius + widget.lineWidth,
        width: widget.radius,
        child: CustomPaint(
          painter: SimpleCirclePainter(
              progress: _percent * 360,
              progressColor: widget.progressColor,
              backgroundColor: widget.backgroundColor,
              startAngle: widget.startAngle,
              circularStrokeCap: widget.circularStrokeCap,
              radius: (widget.radius / 2) - widget.lineWidth / 2,
              lineWidth: widget.lineWidth,
              arcBackgroundColor: widget.arcBackgroundColor,
              arcType: widget.arcType,
              reverse: widget.reverse,
              linearGradient: widget.linearGradient,
              maskFilter: widget.maskFilter),
          child: (widget.center != null)
              ? Center(child: widget.center)
              : Container(),
        )));

    if (widget.footer != null) {
      items.add(widget.footer);
    }

    return Material(
      color: widget.fillColor,
      child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: items,
          )),
    );
  }

  @override
  bool get wantKeepAlive => widget.addAutomaticKeepAlive;
}

class SimpleCirclePainter extends CustomPainter {
  final Paint _paintBackground = Paint();
  final Paint _paintLine = Paint();
  final Paint _paintBackgroundStartAngle = Paint();
  final double lineWidth;
  final double progress;
  final double radius;
  final Color progressColor;
  final Color backgroundColor;
  final CircularStrokeCap circularStrokeCap;
  final double startAngle;
  final LinearGradient linearGradient;
  final Color arcBackgroundColor;
  final ArcType arcType;
  final bool reverse;
  final MaskFilter maskFilter;

  SimpleCirclePainter(
      {this.lineWidth,
        this.progress,
        @required this.radius,
        this.progressColor,
        this.backgroundColor,
        this.startAngle = 0.0,
        this.circularStrokeCap = CircularStrokeCap.round,
        this.linearGradient,
        this.reverse,
        this.arcBackgroundColor,
        this.arcType,
        this.maskFilter}) {
    _paintBackground.color = backgroundColor;
    _paintBackground.style = PaintingStyle.stroke;
    _paintBackground.strokeWidth = lineWidth;

    if (arcBackgroundColor != null) {
      _paintBackgroundStartAngle.color = arcBackgroundColor;
      _paintBackgroundStartAngle.style = PaintingStyle.stroke;
      _paintBackgroundStartAngle.strokeWidth = lineWidth;
    }

    _paintLine.color = progressColor;
    _paintLine.style = PaintingStyle.stroke;
    _paintLine.strokeWidth = lineWidth;
    if (circularStrokeCap == CircularStrokeCap.round) {
      _paintLine.strokeCap = StrokeCap.round;
    } else if (circularStrokeCap == CircularStrokeCap.butt) {
      _paintLine.strokeCap = StrokeCap.butt;
    } else {
      _paintLine.strokeCap = StrokeCap.square;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, _paintBackground);

    if (maskFilter != null) {
      _paintLine.maskFilter = maskFilter;
    }
    if (linearGradient != null) {
      /*
      _paintLine.shader = SweepGradient(
              center: FractionalOffset.center,
              startAngle: math.radians(-90.0 + startAngle),
              endAngle: math.radians(progress),
              //tileMode: TileMode.mirror,
              colors: linearGradient.colors)
          .createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );*/
      _paintLine.shader = linearGradient.createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );
    }

    double fixedStartAngle = startAngle;

    double startAngleFixedMargin = 1.0;
    if (arcType != null) {
      if (arcType == ArcType.FULL) {
        fixedStartAngle = 220;
        startAngleFixedMargin = 172 / fixedStartAngle;
      } else {
        fixedStartAngle = 360.0 - 135.0; // 360 - 90 = 270,
        startAngleFixedMargin = 170 / fixedStartAngle;
      }
    }

    if (arcBackgroundColor != null) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.radians(-90.0 + fixedStartAngle),
        math.radians(360 * startAngleFixedMargin),
        false,
        _paintBackgroundStartAngle,
      );
    }

    if (reverse) {
      final start =
      math.radians(360 * startAngleFixedMargin - 90.0 + fixedStartAngle);
      final end = math.radians(-progress * startAngleFixedMargin);
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        start,
        end,
        false,
        _paintLine,
      );
    } else {
      final start = math.radians(-90.0 + fixedStartAngle);
      final end = math.radians(progress * startAngleFixedMargin);
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        start,
        end,
        false,
        _paintLine,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SimpleCircularPercentIndicator2 extends StatelessWidget {
  SimpleCircularPercentIndicator2({
    Key key,
    this.radius = 220.0,
    this.lineWidth = 23.0,
    this.animation = true,
    this.progress = 1.0,
    this.backgroundColor,
  }): super(key: key);

  final double radius;
  final double lineWidth;
  final bool animation;
  final double progress;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final n = 6;
    final bar0 = 1 / n;
    final bar1 = bar0 + 1 / n;
    final bar2 = bar1 + 1 / n;
    final bar3 = bar2 + 1 / n;
    final bar4 = bar3 + 1 / n;
    final bar5 = bar4 + 1 / n;

    final progress0 = min(progress, bar0);
    final progress1 = min(progress, bar1);
    final progress2 = min(progress, bar2);
    final progress3 = min(progress, bar3);
    final progress4 = min(progress, bar4);
    final progress5 = min(progress, bar5);
    final _backgroundColor = backgroundColor ?? Color(0xFF0E5A88).withOpacity(0.1);
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        /*
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [
            Color.fromRGBO(46, 116, 157, 1),
            Color.fromRGBO(24, 100, 144, 1),
          ],
        ),
        */
        //color: color,
        shape: BoxShape.circle,
        //borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: Offset(0, 15), blurRadius: 35),
        ],
      ),
      child: Stack(children: <Widget>[
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: false,
          percent: 1.0,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: _backgroundColor,
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress5,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: floRed,
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress4,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color(0xFFF99258),
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress3,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color(0xFF14DDF0),
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress2,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color(0xFF67EFFC),
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress1,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color(0xFFA7F7FF),
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        SimpleCircularPercentIndicator(
          //startAngle: 180,
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          percent: progress0,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color(0xFFCCFBFF),
          backgroundColor: Colors.transparent,
          arcType: ArcType.HALF,
        ),
        /*
          CircularPercentIndicator(
            startAngle: 180,
            radius: 120.0,
            lineWidth: 13.0,
            animation: true,
            percent: 0.3,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: TinyColor(Color(0xFF14DDF0)).lighten(5).color,
            backgroundColor: Colors.transparent,
          ),
          CircularPercentIndicator(
            startAngle: 180,
            radius: 120.0,
            lineWidth: 13.0,
            animation: true,
            percent: 0.1,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: TinyColor(Color(0xFF14DDF0)).lighten(7).color,
            backgroundColor: Colors.transparent,
          ),
          */
      ],));
  }
}

class WaterUsageCard extends StatefulWidget {
  WaterUsageCard({Key key,
    this.macAddress,
  }) : super(key: key);
  final String macAddress;

  @override
  _WaterUsageCardState createState() => _WaterUsageCardState();

}

class _WaterUsageCardState extends State<WaterUsageCard> with SingleTickerProviderStateMixin<WaterUsageCard>, AfterLayoutMixin<WaterUsageCard> {

  TabController _controller;
  String _macAddress;
  WaterUsage _waterUsageThisMonth;
  double _todayTotalGallonsConsumed = 0;
  StreamSubscription _sub;

  @override
  void dispose() {
    _controller?.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Set<Device> _selectedDevices = {};
  List<Device> _devices = [];
  Map<String, WaterUsage> _waterUsagesToday = {};
  Map<String, WaterUsage> _waterUsagesWeekly = {};
  Map<String, WaterUsage> _waterUsagesMonthly = {};
  WaterUsageAverages _waterUsageAverages;
  Map<String, WaterUsageAverages> _waterUsageAveragesMap = {};

  @override
  void initState() {
    _macAddress = widget.macAddress;

    _controller = TabController(
      length: 2,
      vsync: this,
    );
    _expand = true;
    _sumTotalGallonsConsumed = 0;
    _todayTotalGallonsConsumed = 0;
    _loading = true;
    _times = WaterUsageBarChart.sample24;

    super.initState();

    Future.delayed(Duration.zero, () async {
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final floStreamService = Provider.of<FloStreamServiceNotifier>(context, listen: false).value;
      final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      _devices = location.devices.toList() ?? const <Device>[];

      /// testing
      /*
      final userRes = await flo.getUser("", authorization: "");
      final locationIds = userRes.body.locations;
      _devices = await Observable.fromIterable(locationIds)
          .flatMap((it) => Observable.fromFuture(flo.getLocation(it.id, authorization: "")))
          .map((it) => it.body)
          .flatMap((it) => Observable.fromIterable(it.devices ?? []))
          .flatMap((it) => Observable.fromFuture(flo.getDevice(it.id, authorization: "")))
          .map((it) => it.body)
          .toList() ?? const <Device>[];
      */
      // _devices = List.generate(15, (_) => Device((b) => b..nickname = faker.person.name()));

      _selectedDevices = _devices.toSet();

      await fetchWaterUsages(context, days: 1);
      await fetchWaterUsages(context, days: 7);
      observe(context, _selectedDevices);
      try {
        if (_waterUsagesToday.isNotEmpty) {
          _waterUsageToday = _waterUsagesToday.values.reduce((that, it) => that + it);
        } else {
          _waterUsageToday = (await flo.waterUsageTodayLocation(locationId: location.id, authorization: oauth.authorization)).body;
        }
        _waterUsageAverages = _macAddress == null ? (await flo.waterUsageAveragesLocation(
            locationId: location.id, authorization: oauth.authorization))
            .body : (await flo.waterUsageAveragesDevice(
            macAddress: _macAddress, authorization: oauth.authorization))
            .body;
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        try {
          _waterUsageThisMonth = _macAddress == null ? (await flo.waterUsageLocation(
              interval: Flo.INTERVAL_1D,
              startDate: firstDay.toIso8601String(),
              endDate: now.toIso8601String(),
              locationId: location.id,
              authorization: oauth.authorization))
            .body : (await flo.waterUsageDevice(
              interval: Flo.INTERVAL_1D,
              startDate: firstDay.toIso8601String(),
              endDate: now.toIso8601String(),
              macAddress: _macAddress,
              authorization: oauth.authorization))
            .body;
          } catch(e) {
            Fimber.e("", ex: e);
          }

        final user = Provider.of<UserNotifier>(context, listen: false).value;
        final isMetric = user.isMetric;
        setState(() {
          _waterUsage = _waterUsageToday;
          _loading = false;
          _goalPerDay = (location.gallonsPerDayGoal ?? 1);
          _days = 1;
          _goal = (_goalPerDay * _days);
          // NOTICE: it's risky if just being tomorrow
          _todayTotalGallonsConsumed = _waterUsage.total;
          _sumTotalGallonsConsumed = _todayTotalGallonsConsumed;
          if (_waterUsage?.isNotEmpty ?? false) {
            _times = notEmptyOrNull(or(() => _waterUsage.hours.map((it) => TimeSeries(it.datetime, it?.gallonsConsumed ?? 0.0,
                tooltip: "${intl.DateFormat('h a').format(it.datetime)}: ${isMetric ? it.gallonsConsumed?.round() ?? 0.0 : toLiters(it.gallonsConsumed ?? 0.0).round()} ${isMetric ? S.of(context).liters : "gal."}"
            )).toList())) ?? WaterUsageBarChart.sample24;
          } else {
            Fimber.d("sample24");
            _times = WaterUsageBarChart.sample24;
          }
          Fimber.d("_weekdayAvg: $_weekdayAvg");
          Fimber.d("_dailyAvg: $_dailyAvg");
          //Fimber.d("_monthlyAvg: $_monthlyAvg");
          _avg = _weekdayAvg; // for today
          Fimber.d("_avg: _weekdayAvg: $_weekdayAvg");
        });
      } catch (e) {
        _loading = false;
        _goalPerDay = (location.gallonsPerDayGoal ?? 1);
        _days = 1;
        _goal = (_goalPerDay * _days);
        if (mounted) {
          setState(() {
          });
        }
        Fimber.e("", ex: e);
      }
    });
  }

  bool _expand = true;
  double _sumTotalGallonsConsumed = 0.0;
  WaterUsage _waterUsage;
  WaterUsage _waterUsageToday;
  WaterUsage _waterUsageWeekly;
  double _days = 1;
  double get _progress => _sumTotalGallonsConsumed / max(_goal, 1);
  double _goal = 0.0;
  double _goalPerDay = 0.0;
  bool _loading = false;
  double get _weekdayAvg => _waterUsageAverages?.aggregations?.weekdayAverages?.value ?? 0.0;
  double get _dailyAvg => _waterUsageAverages?.aggregations?.weekdailyAverages?.value ?? 0.0;
  double get _monthlyAvg => _waterUsageAverages?.aggregations?.monthlyAverages?.value ?? 0.0;
  double _avg = 0.0;
  double get _deltaAvg => orEmpty<double>(_sumTotalGallonsConsumed) - orEmpty<double>(_avg);
  List<TimeSeries> _times = [];

  @override
  void didUpdateWidget(WaterUsageCard oldWidget) {
    if (widget.macAddress != oldWidget.macAddress) {
       _macAddress = widget.macAddress;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void afterFirstLayout(BuildContext context) {
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");

    final user = Provider.of<UserNotifier>(context).value;
    final isMetric = user.isMetric;
    final double deltaMonthlyAvg = (_waterUsageThisMonth?.aggregations?.sumTotalGallonsConsumed ?? 0) - _monthlyAvg;
    return Theme(data: floLightThemeData.copyWith(dividerColor: Colors.transparent, accentColor: Colors.black.withOpacity(0.8)), child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
      child: Stack(children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 0, right: 0), child: Column(children: <Widget>[
        ExpansionTile(
            key: PageStorageKey("WaterUsageCard"), // required or exception
            initiallyExpanded: true,
            title: Text(ReCase(S.of(context).water_usage).titleCase),
            children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 15, right: 15), child: Column(children: <Widget>[
        Opacity(opacity: !_loading && (_devices.isNotEmpty && _devices.length > 1) ? 1 : 0, child: Center(child:
          SwitchFlatButton(checked: false, text: (_) {
            final location = Provider.of<CurrentLocationNotifier>(context).value;
            // if (_selectedDevices.map((it) => it.macAddress).toSet() == (location.devices?.map((it) => it.macAddress)?.toSet() ?? {})) {
            if (_selectedDevices.length == 1) {
              return Text(_selectedDevices.first.displayName, style: Theme.of(context).textTheme.title.copyWith(color: Colors.black));
            } else if (_devices.length == _selectedDevices.length) {
              return Text(S.of(context).summary, style: Theme.of(context).textTheme.title.copyWith(color: Colors.black));
            } else { // 1 < selectedDevices < all
              return Text(S.of(context).multiple_devices, style: Theme.of(context).textTheme.title.copyWith(color: Colors.black));
            }
          },
            onPressed: () async {
              await showDialog(context: context,
                  builder: (context) => Theme(
                    data: floLightThemeData,
                    child: Builder(builder: (context) => AlertDialog(
                      contentPadding: EdgeInsets.only(left: 24, right: 24, top: 12),
                      title: Text(S.of(context).devices),
                      content: SingleChildScrollView(child: Wrap(children: _devices.map((device) => SimpleChoiceChipWidget(
                        backgroundColor: Colors.transparent ,
                        selectedColor: Colors.lightBlue[100].withOpacity(0.2),
                        avatarBorder: CircleBorder(side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        shape: StadiumBorder(side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        validator: (selected) {
                          if (selected) {
                            _selectedDevices.add(device);
                          } else {
                            _selectedDevices.remove(device);
                          }
                          final valid = _selectedDevices.isNotEmpty;
                          if (!selected) {
                            _selectedDevices.add(device);
                          } else {
                            _selectedDevices.remove(device);
                          }
                          return valid;
                        },
                        selected: _selectedDevices.contains(device),
                        child: Text(device.displayName),
                        onSelected: (selected) {
                            if (selected) {
                              _selectedDevices.add(device);
                            } else {
                              _selectedDevices.remove(device);
                            }
                            fetchWaterUsages(context);
                        },
                      )).toList(),
                        spacing: 10,
                        //runSpacing: 1,
                      )),
                      actions: <Widget>[
                        FlatButton(
                          child: Text(S.of(context).ok),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    ),
                    ),
                  ));
              Future(() async {
                await fetchWaterUsages(context); // fetch again
                observe(context, _selectedDevices);
                setState(() {
                  Fimber.d("selected Devices: ${_selectedDevices.map((it) => it.displayName)}");
                  try {
                    invalidate(context);
                  } catch (err) {
                    _loading = false;
                    Fimber.e("", ex: err);
                  }
                });
              });
              return true;
            },
          ))),
          SizedBox(height: 8,),
        Center(child:
          Container(
            width: 200,
            height: 40,
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(32.0)),
              color: Color(0xFFE3ECF2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), offset: Offset(0, 10), blurRadius: 25),
              ],
            ),
        child: TabBar(
          indicatorColor: Colors.red,
          onTap: (i) async {
            final flo = Provider.of<FloNotifier>(context).value;
            final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
            final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
            if (i == 0) {
              try {
                setState(() { _loading = true; });
                /*
                Fimber.d("_selectedDevices.length: ${_selectedDevices.length}");
                Fimber.d("_waterUsages.length: ${_waterUsages.length}");
                if (_selectedDevices.isNotEmpty) {
                  _waterUsage = _selectedDevices.where((device) => _waterUsages.containsKey(device.macAddress)).map((device) => _waterUsages[device.macAddress]).reduce((that, it) => that + it);
                } else {
                  _waterUsageToday = (await flo.waterUsageTodayLocation(locationId: location.id, authorization: oauth.authorization)).body;
                }
                */
                setState(() {
                  _days = 1;
                  invalidate(context);
                  _loading = false;
                });
              } catch (e) {
                setState(() { _loading = true; });
                Fimber.e("", ex: e);
              }
            } else {
              try {
                setState(() { _loading = true; });
                /*
                Fimber.d("_selectedDevices.length: ${_selectedDevices.length}");
                Fimber.d("_waterUsagesWeekly.length: ${_waterUsagesWeekly.length}");
                if (_selectedDevices.isNotEmpty && _waterUsagesWeekly.isNotEmpty) {
                  Fimber.d("selected Devices: ${_selectedDevices.map((it) => it.displayName)}");
                  Fimber.d("_waterUsagesWeekly.keys: ${_waterUsagesWeekly.keys}");
                  _waterUsage = _selectedDevices.where((device) => _waterUsagesWeekly.containsKey(device.macAddress)).map((device) => _waterUsagesWeekly[device.macAddress]).reduce((that, it) => that + it);
                } else {
                  _waterUsageWeekly = (await flo.waterUsageWeekLocation(locationId: location.id, authorization: oauth.authorization)).body;
                }
                */
                setState(() {
                  _days = 7;
                  invalidate(context);
                  _loading = false;
                });
              } catch (e) {
                setState(() { _loading = false; });
                Fimber.e("", ex: e);
              }
            }
          },
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.3),
          labelPadding: EdgeInsets.symmetric(vertical: 10),
          tabs: <Widget>[
            Tab(
              text: S.of(context).today,
            ),
            Tab(
              text: S.of(context).week,
            ),
          ],
          indicator: BubbleTabIndicator(
            indicatorHeight: 35.0,
            indicatorColor: Colors.white,
            tabBarIndicatorSize: TabBarIndicatorSize.label,
          ),
          controller: _controller,
        ))
        ),
        SizedBox(height: 10,),
        Center(child: Stack(children: <Widget>[
          SimpleCircularPercentIndicator2(progress: _progress),
          Column(children: <Widget>[
            SizedBox(width: 160.0, child: AutoSizeText("${isMetric ? toLiters(_sumTotalGallonsConsumed).round() : _sumTotalGallonsConsumed.round()}", maxLines: 1, textScaleFactor: 4.2, textAlign: TextAlign.center, style: TextStyle(color: Colors.black))),
            SizedBox(width: 5),
            Text(isMetric ? S.of(context).liters_spent : S.of(context).gallons_spent, style: TextStyle(color: Colors.black), textScaleFactor: 1.2),
          ],
            mainAxisSize: MainAxisSize.min,
          ),
          Positioned(bottom: 35, child:
          Shadowed(
          FlatButton(
            color: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(30)
            ),
            padding: EdgeInsets.all(10),
            child:
            Opacity(opacity: _loading ? 0 : 1, child: Column(children: <Widget>[
            Text(user.unitSystemOr().volumeText(context, orEmpty((_goal - _sumTotalGallonsConsumed).round().abs().toDouble())), textScaleFactor: 1.0, style: TextStyle(color: floBlue2)),
            //_loading ? TextPlaceholder() : Text(user.unitSystemOr().volumeText(context, orEmpty((_goal - _sumTotalGallonsConsumed).round().abs().toDouble())), textScaleFactor: 1.0, style: TextStyle(color: floBlue2)),
            Text(_goal > _sumTotalGallonsConsumed ? S.of(context).remaining_for_goal : S.of(context).over_the_goal, textScaleFactor: 0.8, style: TextStyle(color: floBlue2)),
          ])),
            onPressed: () {
              Navigator.of(context).pushNamed('/goals');
            },
          )),
          ),
        ],
        alignment: AlignmentDirectional.center,
        )),
        SizedBox(height: 10,),
        Row(children: <Widget>[
          //Visibility(visible: _deltaAvg.round() != 0, child: Transform.rotate(angle: _deltaAvg > 0 ? -math.pi/2 : math.pi/2, child: Icon(Icons.arrow_forward_ios, color: _deltaAvg > 0 ? Color(0xFFED616A) : Color(0xFF5FCC35),
            RotationTransition(turns: AlwaysStoppedAnimation(_deltaAvg > 0 ? 0.0 : 0.5), child: Transform.rotate(angle: -math.pi/2, child: Icon(Icons.arrow_forward_ios, color: _deltaAvg > 0 ? Color(0xFFED616A) : Color(0xFF5FCC35),
              size: 16
            ))),
            SizedBox(width: 5,),
            Text(isMetric ? "${toLiters(_deltaAvg.abs()).round()} ${S.of(context).liters}" : "${_deltaAvg.abs().round()} gal. ", textScaleFactor: 1.6, style: TextStyle(color: Colors.black)),
            SizedBox(width: 5,),
            Text("${_deltaAvg.round() == 0 ? S.of(context).about : _deltaAvg.round() > 0 ? S.of(context).above : S.of(context).below} ${_days == 1 ? S.of(context).daily : S.of(context).weekly_} ${S.of(context).average}", textScaleFactor: 1.0, style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.8)),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        ),
        SizedBox(height: 10,),
        //Image.asset('assets/ic_water_usage_chart.png'),
        //SizedBox(height: 100, child: WaterUsageBarChart.withSampleData()),
        //SizedBox(height: 100, child: WaterUsageBarChart(_times)),
        SizedBox(height: 100, child: WaterUsageBarChart(_times,
            color: _sumTotalGallonsConsumed > 0 ? floBlue2 : Colors.black.withOpacity(0.1),
          tooltipColor: Colors.black,
          tooltipFillColor: Colors.white,
          tooltipStrokeColor: Colors.black.withOpacity(0.1),
        ) ),
        Padding(padding: EdgeInsets.only(left: _days == 1 ? 0 : 5, right: _days == 1 ? 0 : 10), child: Image.asset(_days == 1 ? 'assets/ic_time_base_line.png' : 'assets/ic_weekday_base_line.png')),
        SizedBox(height: 10,),
        Theme(data: floLightThemeData, child: Builder(builder: (context) => Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          child: Column(children: <Widget>[
        SizedBox(height: 10,),
        Row(children: <Widget>[
            Text(isMetric ? "${toLiters((_waterUsageThisMonth?.aggregations?.sumTotalGallonsConsumed ?? 0).abs()).round()} ${S.of(context).liters} " : "${(_waterUsageThisMonth?.aggregations?.sumTotalGallonsConsumed ?? 0).abs().round()} gal. ", textScaleFactor: 1.6, style: TextStyle(color: Colors.black)),
            Text(S.of(context).spent_this_month, textScaleFactor: 1.0, style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.8)),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        ),
        SizedBox(height: 5,),
        Row(children: <Widget>[
          Visibility(visible: deltaMonthlyAvg.round() != 0, child: Transform.rotate(angle: deltaMonthlyAvg > 0 ? -math.pi/2 : math.pi/2, child: Icon(Icons.arrow_forward_ios, color: deltaMonthlyAvg > 0 ? Color(0xFFED616A) : Color(0xFF5FCC35),
              size: 16
          ))),
          SizedBox(width: 5,),
            Text(isMetric ? "${toLiters(deltaMonthlyAvg.abs()).round()} ${S.of(context).liters} " : "${deltaMonthlyAvg.abs().round()} gal. ", textScaleFactor: 1.0, style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.8)),
            Text("${deltaMonthlyAvg.round() == 0 ? S.of(context).about : deltaMonthlyAvg.round() > 0 ? S.of(context).above : S.of(context).below} ${S.of(context).monthly_average}", textScaleFactor: 1.0, style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.8)),

        ],
        mainAxisAlignment: MainAxisAlignment.center,
        ),
        SizedBox(height: 10,),
          ])
        ))),
        SizedBox(height: 20,),
      ],
      //mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      ))])
        ],
        )),
        _loading ? CircularProgressIndicator() : Container(),
      ],
        alignment: AlignmentDirectional.center,
      ),
    ))));
  }

  /// Mainly, update `_waterUsage` (selected/merged water usage) for selected `_days` (today or weekly)
  ///
  /// The UI just displays the selected/merged WaterUsage as well
  /// Secondary update `_waterUsageThisMonth` and `_waterUsageAverages`
  void invalidate(BuildContext context) {
    try {
      final user = Provider.of<UserNotifier>(context, listen: false).value;
      final isMetric = user.isMetric;
      Fimber.d("_selectedDevices.length: ${_selectedDevices.length}");
      if (_selectedDevices.isNotEmpty) {
        Fimber.d("selected Devices: ${_selectedDevices.map((it) => it.displayName)}");
        if (_days == 1) {
          Fimber.d("_waterUsagesToday.length: ${_waterUsagesToday.length}");
          if (_waterUsagesToday.isNotEmpty) {
            Fimber.d("_waterUsagesToday.keys: ${_waterUsagesToday.keys}");
            Fimber.d("_waterUsagesToday total: ${_waterUsagesToday.map((k, v) => MapEntry(k, v.aggregations.sumTotalGallonsConsumed))}");
            _waterUsage = _selectedDevices.where((device) => _waterUsagesToday.containsKey(device.macAddress)).map((device) => _waterUsagesToday[device.macAddress]).reduce((that, it) => that + it);
          }
        } else {
          Fimber.d("_waterUsagesWeekly.length: ${_waterUsagesWeekly.length}");
          if (_waterUsagesWeekly.isNotEmpty) {
            Fimber.d("_waterUsagesWeekly.keys: ${_waterUsagesWeekly.keys}");
            Fimber.d("_waterUsagesWeekly total: ${_waterUsagesWeekly.map((k, v) => MapEntry(k, v.aggregations.sumTotalGallonsConsumed))}");
            _waterUsage = _selectedDevices.where((device) => _waterUsagesWeekly.containsKey(device.macAddress)).map((device) => _waterUsagesWeekly[device.macAddress]).reduce((that, it) => that + it);
          }
        }

        if (_waterUsageThisMonth?.isNotEmpty ?? false) {
          _waterUsageThisMonth = or(() =>
              _selectedDevices.where((device) =>
                  _waterUsagesMonthly.containsKey(device.macAddress)).map((
                  device) => _waterUsagesMonthly[device.macAddress]).reduce((
                  that, it) => that + it)
                  ) ?? _waterUsageThisMonth ?? WaterUsage.empty;
        }

        if (_waterUsageAveragesMap?.isNotEmpty ?? false) {
          Fimber.d("updating _waterUsageAverages by selected devices: ${_waterUsageAveragesMap}");
          Fimber.d("_waterUsageAveragesMap.length: ${_waterUsageAveragesMap?.length}");
          Fimber.d("last waterUsageAverages: ${_waterUsageAverages}");
          _waterUsageAverages = or(() =>
              _selectedDevices.where((device) => _waterUsageAveragesMap.containsKey(device.macAddress))
                  .map((device) => _waterUsageAveragesMap[device.macAddress])
                  .reduce((that, it) => that + it)
          ) ?? _waterUsageAverages ?? WaterUsageAverages.empty;
          Fimber.d("_waterUsageAverages: ${_waterUsageAverages}");
          Fimber.d("_weekdayAvg: $_weekdayAvg");
          Fimber.d("_dailyAvg: $_dailyAvg");
          //Fimber.d("_monthlyAvg: $_monthlyAvg");
        }
      } else {
        Fimber.d("_selectedDevices is empty: $_selectedDevices");
        if (_days == 1) {
          Fimber.d("_waterUsageToday: $_waterUsageToday");
          _waterUsage = _waterUsageToday;
        } else {
          Fimber.d("_waterUsageWeekly: $_waterUsageWeekly");
          _waterUsage = _waterUsageWeekly;
        }
      }
      _sumTotalGallonsConsumed = _waterUsage.total;
      _goal = _goalPerDay * _days;
      if (_days == 1) {
        _avg = _weekdayAvg;
        Fimber.d("_avg: _weekdayAvg: $_weekdayAvg");
        // NOTICE: it's risky if just being tomorrow
        if (_waterUsage?.isNotEmpty ?? false) {
          _todayTotalGallonsConsumed = _waterUsage.total > _todayTotalGallonsConsumed ? _waterUsage.total : _todayTotalGallonsConsumed;
          _sumTotalGallonsConsumed = _todayTotalGallonsConsumed;
          _times = notEmptyOrNull(or(() => _waterUsage.hours.map((it) => TimeSeries(it.datetime, it?.gallonsConsumed ?? 0.0,
              tooltip: "${intl.DateFormat.jm().format(it.datetime)}: ${user.unitSystemOr().volumeText(context, orEmpty(it.gallonsConsumed?.roundToDouble()))}"
          )).toList())) ?? WaterUsageBarChart.sample24;
        } else {
          Fimber.d("sample24");
          _times = WaterUsageBarChart.sample24;
        }
      } else {
        _avg = _dailyAvg;
        Fimber.d("_avg: _dailyAvg: $_dailyAvg");
        if (_waterUsage?.isNotEmpty ?? false) {
          if (_selectedDevices.isEmpty) {
            final todayTotalGallonsConsumed = (_waterUsage.weekdays(7).firstWhere((it) => it.today == DateTimes.today(), orElse: null)?.gallonsConsumed ?? 0.0);
            _todayTotalGallonsConsumed = todayTotalGallonsConsumed > _todayTotalGallonsConsumed ? todayTotalGallonsConsumed : _todayTotalGallonsConsumed;
            _sumTotalGallonsConsumed = _sumTotalGallonsConsumed - todayTotalGallonsConsumed + _todayTotalGallonsConsumed;
            _times = or(() => _waterUsage.weekdays(7).map((it) => TimeSeries(it.today, orNull(it?.gallonsConsumed ?? 0.0, (it) => it > 0) ?? 5.0,
                tooltip: "${intl.DateFormat.EEEE().format(it.today)}: ${user.unitSystemOr().volumeText(context, orEmpty(it.gallonsConsumed?.roundToDouble()))}"
            )).toList()) ?? WaterUsageBarChart.sample7;
          } else {
            final todayTotalGallonsConsumed = (_waterUsage.weekdays(7).firstWhere((it) => it.today == DateTimes.today(), orElse: null)?.gallonsConsumed ?? 0.0);
            _todayTotalGallonsConsumed = todayTotalGallonsConsumed > _todayTotalGallonsConsumed ? todayTotalGallonsConsumed : _todayTotalGallonsConsumed;
            _sumTotalGallonsConsumed = _sumTotalGallonsConsumed - todayTotalGallonsConsumed + _todayTotalGallonsConsumed;
            _times = or(() => _waterUsage.weekdays(7).map((it) => TimeSeries(it.today, orNull(it?.gallonsConsumed ?? 0.0, (it) => it > 0) ?? 5.0,
                tooltip: "${intl.DateFormat.EEEE().format(it.today)}: ${user.unitSystemOr().volumeText(context, orEmpty(it.gallonsConsumed?.roundToDouble()))}"
            )).toList()) ?? WaterUsageBarChart.sample7;
          }
        } else {
          Fimber.d("sample7");
          _times = WaterUsageBarChart.sample7;
        }
      }
    } catch (err) {
      Fimber.e("", ex: err);
    }
  }

  void observe(BuildContext context, Iterable<Device> devices) {
    _sub?.cancel();
    final floStreamService = Provider.of<FloStreamServiceNotifier>(navigator.of().context, listen: false).value;
    //if (_days != 1) return;
    Fimber.d("${devices?.map((it) => it.nickname)}");
    Fimber.d("${devices?.map((it) => it.macAddress)}");
    _sub = Observable.zipList((devices ?? <Device>[]).map((device) =>
        floStreamService.device(device.macAddress).skip(1)
            .map<double>((it) => it.estimateWaterUsage?.estimateToday ?? 0)
    ))
        .map((it) => $(it).sum())
        .distinct((that, it) => it.round() == that.round())
        .listen((it) {
      Fimber.d("today: $it");
      if (mounted) {
        setState(() {
          _sumTotalGallonsConsumed -= _todayTotalGallonsConsumed;
          _todayTotalGallonsConsumed = it > _todayTotalGallonsConsumed ? it : _todayTotalGallonsConsumed;
          _sumTotalGallonsConsumed += _todayTotalGallonsConsumed;
        });
      }
    }, onError: (e) {
      Fimber.e("", ex: e);
    });
  }

  /// Fetch selectedDevices for
  ///
  /// * _waterUsagesToday.addAll(waterUsages);
  /// * _waterUsagesWeekly.addAll(waterUsages);
  /// * _todayTotalGallonsConsumed = 0;
  /// * _sumTotalGallonsConsumed = 0;
  /// * _waterUsagesMonthly.addAll(waterUsagesMonthly)
  /// * _waterUsageAveragesMap.addAll(waterUsageAveragesMap);
  FutureOr<void> fetchWaterUsages(BuildContext context, {double days}) async {
    if (context == null) return;
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    days = days ?? _days;
    if (days == 1) {
      final Map<String, WaterUsage> waterUsages = Map.fromEntries(await Observable.fromIterable(_selectedDevices.where((it) => !_waterUsagesToday.containsKey(it.macAddress)))
          .where((it) => it.macAddress != null)
          .asyncMap((device) => flo.waterUsageTodayDevice(
          macAddress: device.macAddress,
          authorization: oauth.authorization)
          .then((res) => res.body)
          .catchError((err) => WaterUsage.empty)
          .then((waterUsage) => MapEntry(device.macAddress, waterUsage))
      )
          .toList());
      _waterUsagesToday.addAll(waterUsages);
      _todayTotalGallonsConsumed = 0;
      _sumTotalGallonsConsumed = 0;
      Fimber.d("_waterUsages: ${_waterUsagesToday.keys}");
      Fimber.d("_waterUsages total: ${_waterUsagesToday.map((k, v) => MapEntry(k, v?.aggregations?.sumTotalGallonsConsumed ?? 0))}");
    } else {
      final Map<String, WaterUsage> waterUsages = Map.fromEntries(await Observable.fromIterable(_selectedDevices.where((it) => !_waterUsagesWeekly.containsKey(it.macAddress)))
          .where((it) => it.macAddress != null)
          .asyncMap((device) => flo.waterUsageWeekDevice(
          macAddress: device.macAddress,
          authorization: oauth.authorization)
          .then((res) => res.body)
          .catchError((err) => WaterUsage.empty)
          .then((waterUsage) => MapEntry(device.macAddress, waterUsage))
      )
          .toList());
      _waterUsagesWeekly.addAll(waterUsages);
      _todayTotalGallonsConsumed = 0;
      _sumTotalGallonsConsumed = 0;
      Fimber.d("_waterUsagesWeekly: ${_waterUsagesWeekly.keys}");
      Fimber.d("_waterUsagesWeekly total: ${_waterUsagesWeekly.map((k, v) => MapEntry(k, v?.aggregations?.sumTotalGallonsConsumed ?? 0))}");
    }

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final Map<String, WaterUsage> waterUsagesMonthly = Map.fromEntries(await Observable.fromIterable(_selectedDevices.where((it) => !_waterUsagesMonthly.containsKey(it.macAddress)))
        .where((it) => it.macAddress != null)
        .asyncMap((device) => flo.waterUsageDevice(
        interval: Flo.INTERVAL_1D,
        startDate: firstDay.toIso8601String(),
        endDate: now.toIso8601String(),
        macAddress: device.macAddress,
        authorization: oauth.authorization)
        .then((res) => res.body)
        .catchError((err) => WaterUsage.empty)
        .then((waterUsage) => MapEntry(device.macAddress, waterUsage))
    ).toList());
    _waterUsagesMonthly.addAll(waterUsagesMonthly);

    final Map<String, WaterUsageAverages> waterUsageAveragesMap = Map.fromEntries(await Observable.fromIterable(_selectedDevices.where((it) => !_waterUsageAveragesMap.containsKey(it.macAddress)))
        .where((it) => it.macAddress != null)
        .asyncMap((device) => flo.waterUsageAveragesDevice(
        macAddress: device.macAddress,
        authorization: oauth.authorization)
        .then((res) => res.body)
        .catchError((err) => WaterUsage.empty)
        .then((avg) => MapEntry(device.macAddress, avg))
    )
        .toList());
    _waterUsageAveragesMap.addAll(waterUsageAveragesMap);
    Fimber.d("fetched _waterUsageAveragesMap: ${_waterUsageAveragesMap}");
  }

}

class SystemModeBadge extends StatelessWidget {
  const SystemModeBadge({Key key,
    this.location,
    this.device,
    this.dark,
  }) : super(key: key);
  final Location location;
  final Device device;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (device != null) {
      final installed = (device?.installStatus?.isInstalled ?? false);
      final isConnected = device.isConnected ?? false;
      final isLearning = (device?.systemMode?.isLearning ?? false); // device?.isLearning includes not installed
      if (isLearning) {
        return Container();
      } else if (installed) {
        return or(() => SystemModeIcons[device?.systemMode?.lastKnown ?? SystemMode.SLEEP]) ?? SleepBadge();
      } else { // !installed && !isLearning
        return Container();
      }
    }
    if (location?.devices?.isEmpty ?? true) return Container();
    return (location?.isLearning ?? true) ? Opacity(opacity: 0.5, child: LearningBadge()) : or(() => SystemModeIcons[location?.systemMode?.target ?? SystemMode.SLEEP]) ?? SleepBadge();
  }
}


class WifiRssiExamples extends StatefulWidget {
  @override
  _WifiRssiExamplesState createState() => _WifiRssiExamplesState();
}

class _WifiRssiExamplesState extends State<WifiRssiExamples> {
  var _rssi = -44.0;
  @override
  Widget build(BuildContext context) {
    final List<double> rssiList = [-10.0, -20, -30, -40, -50, -60, -70, -80];
    final List<Widget> wifiIconList = $(rssiList.map((it) => Row(children: [
        Text("${it}"),
        WifiSignalIcon(it, color: Colors.black, width: 60),
        ])
    )).toList();
    return SingleChildScrollView(child: Column(children: [
      SizedBox(height: 80),
      SimpleSlider(
        min: -90.0,
        max: 0.0,
        divisions: 90,
        onChanged: (value) => setState(() => _rssi = value),
      ),
      SizedBox(height: 20),
      WifiSignalIcon(_rssi, color: Colors.black, width: 60),
      SizedBox(height: 20),
      Column(children: wifiIconList),
    ]));
  }
}

class SimpleSlider extends StatefulWidget {
  SimpleSlider({Key key,
    this.label,
    this.value = 0,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.semanticFormatterCallback,
    this.showText = true,
    this.excludeMin = false,
  }) : super(key: key);
  final ConsumeFunction<double, String> label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final SemanticFormatterCallback semanticFormatterCallback;
  final bool showText;
  final bool excludeMin;

  @override
  State<SimpleSlider> createState() => _SimpleSliderState();
}

class _SimpleSliderState extends State<SimpleSlider> {
  var _value;
  SemanticFormatterCallback _semanticFormatterCallback;

  @override
  void initState() {
    _value = widget.value;
    _semanticFormatterCallback = widget.semanticFormatterCallback ?? (value) => "${intl.NumberFormat("#.#").format(value)}";
    super.initState();
  }

  @override
  void didUpdateWidget(SimpleSlider oldWidget) {
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? (value) => "${value?.round()}";
    return Column(children: <Widget>[
    Slider(
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: label(_value),
        value: _value,
        semanticFormatterCallback: _semanticFormatterCallback,
        onChanged: (value) {
          if (widget.excludeMin && value == widget.min) {
            return;
          }
          if (widget.onChanged != null) {
            widget.onChanged(value);
          }
          setState(() => _value = value);
        },
        onChangeEnd: widget.onChangeEnd,
      ),
      widget.showText ? Row(children: <Widget>[
        Spacer(),
        Text(_semanticFormatterCallback(_value), overflow: TextOverflow.ellipsis,),
      ],) : Container(),
    ],);
  }
}

class SimpleSwitchListTile extends StatefulWidget {
  SimpleSwitchListTile({Key key,
    this.value,
    this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.isThreeLine = false,
    this.dense = false,
  }) : super(key: key);
  final bool value;
  final Consumers<bool, Future<bool>> onChanged;
  final Widget title;
  final Widget subtitle;
  final Widget secondary;
  final bool isThreeLine;
  final bool dense;

  State<SimpleSwitchListTile> createState() => _SimpleSwitchListTile();
}

class _SimpleSwitchListTile extends State<SimpleSwitchListTile> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.value;
  }

  @override
  void didUpdateWidget(SimpleSwitchListTile oldWidget) {
    if (oldWidget.value != widget.value) {
      _checked = widget.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        secondary: widget.secondary,
        isThreeLine: widget.isThreeLine,
        dense: widget.dense,
        value: _checked, onChanged: (checked) async {
      setState(() {
        _checked = checked;
      });
      if (widget.onChanged != null) {
        final changed = (await widget.onChanged(checked)) ?? true;
        if (!changed) {
          setState(() {
            _checked = !checked;
          });
        }
      }
    });
  }
}

class SimpleRangeSlider extends StatefulWidget {
  SimpleRangeSlider({Key key,
    this.min,
    this.max,
    this.divisions,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    @required this.lowerValue,
    @required this.upperValue,
    this.showValueIndicator: false,
    this.touchRadiusExpansionRatio: 3.33,
    this.valueIndicatorMaxDecimals: 1,
    this.valueIndicatorFormatter,
    this.semanticFormatterCallback,
  }) : super(key: key);
  final double min;
  final double max;
  final int divisions;
  final double lowerValue;
  final double upperValue;
  final bool showValueIndicator;
  final double touchRadiusExpansionRatio;
  final int valueIndicatorMaxDecimals;
  final RangeSliderValueIndicatorFormatter valueIndicatorFormatter;
  final RangeSliderCallback onChanged;
  final RangeSliderCallback onChangeStart;
  final RangeSliderCallback onChangeEnd;
  final SemanticFormatterCallback semanticFormatterCallback;

  @override
  State<SimpleRangeSlider> createState() => _SimpleRangeSliderState();
}

class _SimpleRangeSliderState extends State<SimpleRangeSlider> {
  var _lowerValue;
  var _upperValue;
  SemanticFormatterCallback _semanticFormatterCallback;

  @override
  void initState() {
    _lowerValue = widget.lowerValue;
    _upperValue = widget.upperValue;
    _semanticFormatterCallback = widget.semanticFormatterCallback ?? (value) => "${intl.NumberFormat("#.#").format(value)}";
    super.initState();
  }

  @override
  void didUpdateWidget(SimpleRangeSlider oldWidget) {
    if (widget.lowerValue != oldWidget.lowerValue) {
      _lowerValue = widget.lowerValue;
    }
    if (widget.upperValue != oldWidget.upperValue) {
      _upperValue = widget.upperValue;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Column(children: [frs.RangeSlider(
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      lowerValue: _lowerValue,
      upperValue: _upperValue,
      onChanged: (lowerValue, upperValue) {
        if (widget.onChanged != null) {
          widget.onChanged(lowerValue, upperValue);
        }
        setState(() {
          _lowerValue = lowerValue;
          _upperValue = upperValue;
        });
      },
      onChangeEnd: widget.onChangeEnd,
      showValueIndicator: widget.showValueIndicator,
      touchRadiusExpansionRatio: widget.touchRadiusExpansionRatio,
      valueIndicatorMaxDecimals: widget.valueIndicatorMaxDecimals,
      valueIndicatorFormatter: widget.valueIndicatorFormatter,
    ),
    Row(children: <Widget>[
      Text(_semanticFormatterCallback(_lowerValue), overflow: TextOverflow.ellipsis),
      Spacer(),
      Text(_semanticFormatterCallback(_upperValue), overflow: TextOverflow.ellipsis,),
    ],),
    ]));
  }
}

class FloErrorDialog extends StatelessWidget {
  FloErrorDialog({
    Key key,
    this.onPressed,
    this.error,
    this.title,
    this.content,
    this.actions,
  }) : super(key: key);

  final dynamic error;
  final VoidCallback onPressed;
  final Widget title;
  final Widget content;
  final Iterable<Widget> actions;

  @override
  Widget build(BuildContext context) {
    Fimber.e("${or(() => ResponseError.fromJson(as<HttpError>(error)?.response?.body)?.message)}", ex: error);
    return Theme(
        data: floLightThemeData,
        child: Builder(builder: (context) => AlertDialog(
          title: title ?? Text("Flo Error 009"),
          //content: content ?? Text(or(() => ResponseError.fromJson(as<HttpError>(error)?.response?.body)?.message) ?? // TODO: Detect different type of error
          content: content ?? Text(S.of(context).cannot_communicate_with_flo_servers), // TODO: Detect different type of error
          actions: actions ?? <Widget>[
            FlatButton(
              child: Text(S.of(context).ok),
              onPressed: onPressed ?? () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        )));
  }
}

class WifiNotFoundException implements Exception {
}

class HttpException implements Exception {
  HttpException(this.response);
  final http.Response response;
}

class HttpError extends Error {
  HttpError(this.response);
  final http.Response response;
}

Iterable<CountryCode> countryCodes = codes
    .map((s) => CountryCode(
  name: s['name'],
  code: s['code'],
  dialCode: s['dial_code'],
  flagUri: 'flags/${s['code'].toLowerCase()}.png',
)).toList()..add(CountryCode(
name: "United Kingdom",
code: "UK",
dialCode: "+44",
flagUri: 'flags/${'GB'.toLowerCase()}.png',
));

Map<String, CountryCode> dialCodesMap = Maps.fromIterable<CountryCode, String, CountryCode>(countryCodes, key: (it) => it.dialCode);

String dialCodeToCountry(String dialCode) {
  return or(() => dialCodesMap[dialCode].code);
}

String dialNumberToCountry(int dialNumber) {
  return or(() => dialCodesMap["+${dialNumber}"].code);
}

class SimpleSpeechBubble extends StatelessWidget {
  /// Creates a widget that emulates a speech bubble.
  /// Could be used for a tooltip, or as a pop-up notification, etc.
  SimpleSpeechBubble(
      {Key key,
        @required this.child,
        this.nipLocation: NipLocation.BOTTOM,
        this.nipOffset = const Offset(0, 0),
        this.color: Colors.redAccent,
        this.borderRadius: 8.0,
        this.height,
        this.width,
        this.padding})
      : super(key: key);

  /// The [child] contained by the [SpeechBubble]
  final Widget child;
  final Offset nipOffset;

  /// The location of the nip of the speech bubble.
  ///
  /// Use [NipLocation] enum, either [TOP], [RIGHT], [BOTTOM], or [LEFT].
  /// The nip will automatically center to the side that it is assigned.
  final NipLocation nipLocation;

  /// The color of the body of the [SpeechBubble] and nip.
  /// Defaultly red.
  final Color color;

  /// The [borderRadius] of the [SpeechBubble].
  /// The [SpeechBubble] is built with a circular border radius on all 4 corners.
  final double borderRadius;

  /// The explicitly defined height of the [SpeechBubble].
  /// The [SpeechBubble] will defaultly enclose its [child].
  final double height;

  /// The explicitly defined width of the [SpeechBubble].
  /// The [SpeechBubble] will defaultly enclose its [child].
  final double width;

  /// The padding widget between the child and the edges of the [SpeechBubble].
  final Widget padding;

  Widget build(BuildContext context) {
    Offset _nipOffset;
    switch (this.nipLocation) {
      case NipLocation.TOP:
        _nipOffset = Offset(0.0, 7.07 - 1.5);
        break;
      case NipLocation.RIGHT:
        _nipOffset = Offset(-7.07 + 1.5, 0.0);
        break;
      case NipLocation.BOTTOM:
        _nipOffset = Offset(0.0, -7.07 + 1.5);
        break;
      case NipLocation.LEFT:
        _nipOffset = Offset(7.07 - 1.5, 0.0);
        break;
      default:
    }
    _nipOffset += nipOffset;

    if (this.nipLocation == NipLocation.TOP ||
        this.nipLocation == NipLocation.BOTTOM) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: this.nipLocation == NipLocation.BOTTOM
              ? list(_nipOffset)
              : list(_nipOffset).reversed.toList(),
        ),
      );
    } else {
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: this.nipLocation == NipLocation.RIGHT
              ? list(_nipOffset)
              : list(_nipOffset).reversed.toList(),
      );
    }
  }

  List<Widget> list(Offset nipOffset) {
    return <Widget>[
      speechBubble(),
      width != null ? Container(width: width, child: nip(nipOffset)) : nip(nipOffset),
    ];
  }

  Widget speechBubble() {
    return Material(
      borderRadius: BorderRadius.all(
        Radius.circular(this.borderRadius),
      ),
      color: this.color,
      elevation: 1.0,
      child: Container(
        padding: this.padding ?? const EdgeInsets.all(8.0),
        child: this.child,
      ),
    );
  }

  Widget nip(Offset nipOffset) {
    return Transform.translate(
      offset: nipOffset,
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(45 / 360),
        child: Material(
          borderRadius: BorderRadius.all(
            Radius.circular(1.5),
          ),
          color: this.color,
          child: Container(
            height: 10.0,
            width: 10.0,
          ),
        ),
      ),
    );
  }
}

class TextPlaceholder extends StatelessWidget {
  TextPlaceholder({
    Key key,
    this.text = "        ",
  }) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[700].withOpacity(0.5);
    final highlightColor = Colors.grey[300].withOpacity(0.5);
    return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          child: Opacity(opacity: 0, child: Text(text)),
        ));
  }
}

class SimplePlaceholder extends StatelessWidget {
  List<Widget> list;

  SimplePlaceholder({Key key}) : super(key: key) {
    final baseColor = Colors.grey[700].withOpacity(0.5);
    final highlightColor = Colors.grey[300].withOpacity(0.5);
    list = [
      SizedBox(height: 40),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 40),
      Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ListView.builder(itemBuilder: (context, i) => list[i % list.length], itemCount: 30,));
  }
}

class ListPlaceholder extends StatelessWidget {
  List<Widget> list;
  ListPlaceholder({Key key}) : super(key: key) {
    final baseColor = Colors.grey[300].withOpacity(0.8);
    final highlightColor = Colors.grey[100].withOpacity(0.8);
    list = List.generate(3, (it) =>
        Padding(padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10), child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    //return Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ListView.builder(itemBuilder: (context, i) => list[i % list.length], itemCount: 10,));
    return Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Column(children: list));
  }
}

class AlertsPlaceholder extends StatelessWidget {
  List<Widget> list;

  AlertsPlaceholder({Key key}) : super(key: key) {
    final baseColor = Colors.grey[300].withOpacity(0.3);
    final highlightColor = Colors.grey[100].withOpacity(0.3);
    list = [
      SizedBox(height: 30),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Row(children: <Widget>[
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
        Spacer(),
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
      ],),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 10),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ListView.builder(itemBuilder: (context, i) => list[i % list.length], itemCount: 30,));
  }
}

class AlertsSettingsPlaceholder extends StatelessWidget {
  List<Widget> list;

  AlertsSettingsPlaceholder({Key key}) : super(key: key) {
    final baseColor = Colors.grey[300].withOpacity(0.3);
    final highlightColor = Colors.grey[100].withOpacity(0.3);
    list = [
      SizedBox(height: 40),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 20),
      Row(children: <Widget>[
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
        Spacer(),
        Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            )),
      ],),
      SizedBox(height: 10),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 60),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 30),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 30),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          )),
      SizedBox(height: 30),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ListView.builder(itemBuilder: (context, i) => list[i % list.length], itemCount: 30,));
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

Future<void> putLocation(BuildContext context, {Location last}) async {
  final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
  if (last == locationProvider.value) return;

  final floConsumer = Provider.of<FloNotifier>(context, listen: false);
  final flo = floConsumer.value;
  final oauthConsumer = Provider.of<OauthTokenNotifier>(context, listen: false);
  try {
    await flo.putLocation(locationProvider.value, authorization: oauthConsumer.value.authorization);
    final userProvider = Provider.of<UserNotifier>(context, listen: false);
    userProvider.value = userProvider.value.rebuild((b) => b..dirty = true);
    locationProvider.value = locationProvider.value.rebuild((b) => b
      ..dirty = true
    );
  } catch (e) {
    Fimber.e("putLocation", ex: e);
  }
}

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

typedef WillChanged<T> = Future<bool> Function(T value);

class SimpleDropdownButton<T> extends StatefulWidget {
  SimpleDropdownButton({Key key,
    this.label,
    @required this.items,
    this.selectedMenuItemBuilder,
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
    this.selectedItemBuilder,
    this.factor = 1.0,
  }) : super(key: key);

  final Widget label;
  State<SimpleDropdownButton<T>> createState() => _SimpleDropdownButtonState<T>();
  final ItemBuilder<T> selectedMenuItemBuilder;

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
  final WillChanged<T> onChanged;

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
  final double factor;

  final DropdownButtonBuilder selectedItemBuilder;

//final ItemBuilder<T> itemBuilder;
}

class _SimpleDropdownButtonState<T> extends State<SimpleDropdownButton<T>> {
  List<DropdownMenuItem<T>> _items;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
    buildItems();
    if (or(() => _items.firstWhere((DropdownMenuItem<T> item) => item.value == _selected)) == null) {
      Fimber.e("${_selected} not found");
      _selected = null;
    }
  }

  void buildItems() {
    if (widget.selectedMenuItemBuilder != null) {
      _items = widget.items.map<DropdownMenuItem<T>>((it) => it.value == _selected ?
          DropdownMenuItem(value: it.value, child: widget.selectedMenuItemBuilder(it.value)) : it
      ).toList();
    }
  }

  T _selected;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(child: DropdownButton2<T>(
      label: widget.label,
      value: _selected,
      items: _items,
      selectedItemBuilder: widget.selectedItemBuilder,
      onChanged: (value) async {
        final will = await widget.onChanged(value);
        if (will ?? true) {
          setState(() {
            _selected = value;
            buildItems();
          });
        }
      },
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
      factor: widget.factor,
    ));
  }
}

class FloLightBlueGradientButton extends StatelessWidget {
  FloLightBlueGradientButton(
  this.child,
  {Key key}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(floButtonRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 1.0],
              colors: [
                Color(0xFF3EBBE2),
                Color(0xFF2790BE),
              ],
            ),
          ),
          child: child
      );
  }
}

class GreenButton extends StatelessWidget {
  GreenButton(this.child, {
    Key key,
    this.padding = const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
    this.onPressed,
  }) : super();
  
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return
      Container(
          padding: EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(floButtonRadius),
            boxShadow: [
              BoxShadow(color: floSecondaryButtonColor.withOpacity(0.5), offset: Offset(0, 10), blurRadius: 15)
            ],
          ),
          child: FlatButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: padding,
            color: floSecondaryButtonColor,
            child: child,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(floButtonRadius)),
            onPressed: onPressed ?? () {
              Navigator.of(context).pushNamed("/404");
            },
          )
      );
  }
}

class OpenButton extends StatelessWidget {
  OpenButton({Key key,
    this.padding,
    this.onPressed,
  }): super();
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return GreenButton(Text(
      S.of(context).open,
      style: TextStyle(color: Colors.white),
    ), padding: padding, onPressed: onPressed,);
  }
}

class OpenChatButton extends StatelessWidget {
  OpenChatButton({Key key,
    this.padding,
    this.onPressed,
  }): super(key: key);
  final EdgeInsetsGeometry padding;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return GreenButton(Text(
      S.of(context).open_chat,
      style: TextStyle(color: Colors.white),
    ), padding: padding,
      onPressed: onPressed ?? () async {
        final zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
        try {
          await zendesk.startChat();
        } catch (err) {
          Fimber.e("", ex: err);
        }
      },
    );
  }
}

class FloActivateButton extends StatelessWidget {
  FloActivateButton({Key key,
    this.padding = const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
    this.onPressed,
  }): super(key: key);
  final EdgeInsetsGeometry padding;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final location = Provider.of<CurrentLocationNotifier>(context).value;
    return
        Container(
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(floButtonRadius),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                  //162.4deg, #3EBBE2 0%, #2790BE 98.51
                    TinyColor(Color(0xFF3EBBE2)).darken(3).color,
                    Color(0xFF2790BE),
                  ]),
              boxShadow: [
                BoxShadow(color: Color(0xFF2790BE).withOpacity(0.5), offset: Offset(0, 5), blurRadius: 10)
              ],
            ),
            child: FlatButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: padding,
              color: Colors.transparent,
              child: Text(
                S.of(context).activate,
                textScaleFactor: 1.0,
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(floButtonRadius)),
              onPressed: onPressed ?? () async {
                await launch('https://user.meetflo.com/floprotect?plan_id=hp_c_5_ft&source_id=android&location=${location.id}',
                  option: CustomTabsOption(
                      toolbarColor: Theme.of(context).primaryColor,
                      enableDefaultShare: true,
                      enableUrlBarHiding: true,
                      showPageTitle: true,
                      //animation: CustomTabsAnimation.slideIn()
                  ),
                );
              },
            )
    );
  }
}

class FloProtectActiveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child:
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(floButtonRadius),
              boxShadow: [
                BoxShadow(color: floSecondaryButtonColor.withOpacity(0.5), offset: Offset(0, 10), blurRadius: 15)
              ],
            ),
            child: FlatButton.icon(
              padding: EdgeInsets.symmetric(vertical: 15),
              icon: Image.asset('assets/ic_protect.png', width: 15, height: 15),
              color: floSecondaryButtonColor,
              label: Text(
                S.of(context).floprotect_active,
                textScaleFactor: 1.2,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(floButtonRadius)),
              onPressed: () {
                Navigator.of(context).pushNamed("/floprotect");
              },
            )),
        ),
      ],
    );
  }
}

class FloProtectInactiveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child:
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(floButtonRadius),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    /*
                    TinyColor(Color(0xFF3EBBE2)).darken(3).color,
                    Color(0xFF2790BE),
                    */
                    Color(0xFF3EBBE2),
                    TinyColor(Color(0xFF2790BE)).lighten(5).color,
                  ]),
              boxShadow: [
                BoxShadow(color: Color(0xFF3EBBE2).withOpacity(0.5), offset: Offset(0, 10), blurRadius: 15)
              ],
            ),
            child: FlatButton.icon(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(vertical: 15),
              icon: Image.asset('assets/ic_protect.png', width: 15, height: 15),
              color: Colors.transparent,
              label: Text(
                S.of(context).activate_floprotect,
                textScaleFactor: 1.2,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(floButtonRadius)),
              onPressed: () {
                Navigator.of(context).pushNamed("/floprotect");
              },
            )),
        ),
      ],
    );
  }
}

class FloProtectCircleAvatar extends StatefulWidget {
  FloProtectCircleAvatar({
    Key key,
    this.color = const Color(0xFF35AAD4),
    this.radius = 27.0,
    this.padding = const EdgeInsets.all(8),
    this.onPressed,
  }) : super(key: key);

  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback onPressed;

  @override
  _FloProtectCircleAvatarState createState() => _FloProtectCircleAvatarState();
}

class _FloProtectCircleAvatarState extends State<FloProtectCircleAvatar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
        children: [
      Animator(
        key: UniqueKey(),
        tickerMixin: TickerMixin.tickerProviderStateMixin,
        tween: Tween<double>(begin: 1.0, end: 0.87),
        duration: Duration(milliseconds: 1500),
        curve: Curves.decelerate,
        cycles: 0,
        builder: (anim) =>
            Transform.scale(scale: anim.value, child: CircleAvatar(
              backgroundColor: widget.color.withOpacity(0.2),
              radius: widget.radius,
            )),
      ),
      CircleAvatar(backgroundColor: Colors.transparent,
        radius: widget.radius,
        child: Padding(padding: widget.padding, child:
        CircleAvatar(backgroundColor: widget.color,
          radius: double.infinity,
          child: IconButton(
            icon: Image.asset('assets/ic_protect.png', width: double.infinity, height: double.infinity),
            color: widget.color,
            onPressed: widget.onPressed ?? () {
              Navigator.of(context).pushNamed("/floprotect");
            },
          ),
        ))),
    ]);
  }
}

class FloProtectActiveCircleAvatar extends StatelessWidget {
  FloProtectActiveCircleAvatar({
    Key key,
    this.onPressed,
  }) : super(key: key);
  final VoidCallback onPressed;
  Widget build(BuildContext context) {
    return FloProtectCircleAvatar(color: floSecondaryButtonColor,
      onPressed: onPressed,
    );
  }
}

class FloProtectInactiveCircleAvatar extends StatelessWidget {
  FloProtectInactiveCircleAvatar({
    Key key,
    this.onPressed,
  }) : super(key: key);
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return FloProtectCircleAvatar(
        onPressed: onPressed,
    );
  }
}

class SwitchFlatButton extends StatefulWidget {
  SwitchFlatButton({Key key,
    this.checked,
    this.onPressed,
    this.size = 16,
    this.child,
    this.text,
    this.trailing,
    this.padding,
  }) : super(key: key);
  final bool checked;
  final WillPopCallback onPressed;
  final double size;
  final ItemBuilder<bool> child;
  final ItemBuilder<bool> text;
  final ItemBuilder<bool> trailing;
  final EdgeInsetsGeometry padding;
  @override
  _SwitchFlatButtonState createState() {
    return _SwitchFlatButtonState();
  }
}

class _SwitchFlatButtonState extends State<SwitchFlatButton> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.checked ?? false;
  }
  @override
  void didUpdateWidget(SwitchFlatButton oldWidget) {
    if (widget.checked != oldWidget.checked) {
      _checked = widget.checked ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: widget.padding ?? widget.child != null ? EdgeInsets.all(0) : widget.padding,
      child: widget.child != null ? widget.child(_checked) :
      Row(children: <Widget>[
        widget.text != null ? widget.text(_checked) : Text(S.of(context).summary, style: Theme.of(context).textTheme.title),
        SizedBox(width: 10),
        widget.trailing != null ? widget.trailing(_checked) : Transform.rotate(angle: _checked ? -math.pi/2 : math.pi/2, child: Icon(Icons.arrow_forward_ios, size: widget.size)),
      ],
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
      ),
        onPressed: () async {
          setState(() {
            _checked = !_checked;
          });
          if (widget.onPressed != null) {
            final res = await widget.onPressed();
            if (res)  {
              setState(() {
                _checked = !_checked;
              });
            }
          }
        },
      );
  }
}

class SwitchIcon extends StatefulWidget {
  SwitchIcon({Key key,
    this.checked,
    this.size = 18,
    this.onPressed,
    this.child,
  }) : super(key: key);
  final bool checked;
  final double size;
  final WillPopCallback onPressed;
  final ItemBuilder<bool> child;
  @override
  _SwitchIconState createState() {
    return _SwitchIconState();
  }
}

class _SwitchIconState extends State<SwitchIcon> {
  bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.checked ?? false;
  }
  @override
  void didUpdateWidget(SwitchIcon oldWidget) {
    if (widget.checked != oldWidget.checked) {
      _checked = widget.checked ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return
      Transform.rotate(angle: _checked ? -math.pi/2 : math.pi/2, child: IconButton(icon: widget.child != null ? widget.child(_checked) : Icon(Icons.arrow_forward_ios, size: widget.size),
      onPressed: () async {
        setState(() {
          _checked = !_checked;
        });
        if (widget.onPressed != null) {
          final res = await widget.onPressed();
          if (res)  {
            setState(() {
              _checked = !_checked;
            });
          }
        }
      },
    ),
    );
  }
}

class SimpleChoiceChipWidget extends StatefulWidget {
  SimpleChoiceChipWidget({Key key,
    this.margin = const EdgeInsets.symmetric(horizontal: 2),
    this.selected,
    this.validator,
    this.onSelected,
    this.child,
    this.avatar,
    this.selectedColor,
    this.backgroundColor,
    this.avatarBorder,
    this.shape,
  }) : super(key: key);
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Predicate<bool> validator;
  final Widget avatar;
  final Widget child;
  final Color selectedColor;
  final Color backgroundColor;
  final ShapeBorder avatarBorder;
  final ShapeBorder shape;
  final EdgeInsetsGeometry margin;
  @override
  _SimpleChoiceChipWidgetState createState() {
    return _SimpleChoiceChipWidgetState();
  }
}

class _SimpleChoiceChipWidgetState extends State<SimpleChoiceChipWidget> {
  bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected ?? false;
  }

  @override
  void didUpdateWidget(SimpleChoiceChipWidget oldWidget) {
    if (widget.selected != oldWidget.selected) {
      _selected = widget.selected ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: widget.margin, child: ChoiceChip(
      //avatar: _selected ? Icon(Icons.check, size: 14) : Icon(Icons.check, size: 14, color: Colors.transparent),
      //avatar: _selected ? Icon(Icons.check, size: 14) : Icon(Icons.close, size: 14),
      avatar: widget.avatar ?? (_selected ? Icon(Icons.check, size: 14, color: floBlue2,) : Image.asset('assets/ic_flo_device.png', height: 40)),
      label: widget.child,
      selected: _selected,
      onSelected: (selected) {
        if (widget?.validator == null || (widget?.validator(selected) ?? true)) {
          setState(() {
            _selected = selected;
          });
          if (widget.onSelected != null) {
            widget.onSelected(selected);
          }
        }
      },
      selectedColor: widget.selectedColor,
      backgroundColor: widget.backgroundColor,
      avatarBorder: widget.avatarBorder,
      shape: widget.shape,
    ));
  }
}

/*
class SelectedWidget extends StatefulWidget {
  SelectedWidget({Key key,
    this.selected,
    this.onSelected,
    @required
    this.child,
  }) : super(key: key);
  final bool selected;
  final ValueChanged<bool> onSelected;
  final ItemBuilder<bool> child;
  @override
  _SelectedWidgetState createState() {
    return _SelectedWidgetState();
  }
}

class _SelectedWidgetState extends State<SelectedWidget> {
  bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected ?? false;
  }

  @override
  void didUpdateWidget(SelectedWidget oldWidget) {
    if (widget.selected != oldWidget.selected) {
      _selected = widget.selected ?? false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child(_selected);
  }
}
*/


Future<bool> showClearAlert(BuildContext context, Alert alert) async {
  final flo = Provider.of<FloNotifier>(context, listen: false).value;
  final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
  try {
    // Shouldn't be first one, should be home or away?
    final feedbackFlow = alert.userFeedbackFlow;
    if (feedbackFlow?.flow != null) {
      //final options = await showAlertFeedbackDialog(context, feedbackFlow.flow, flowTags: feedbackFlow.flowTags, title: Text(alert.alarm.displayName));
      //final options = await showAlertFeedbackDialog(context, feedbackFlow.flow, flowTags: feedbackFlow.flowTags, title: Text("${S.of(context).clear_} ${alert.alarm.displayName}"));
      final options = await showAlertFeedbackDialog(context, feedbackFlow.flow, flowTags: feedbackFlow.flowTags, title: Text(ReCase(S.of(context).clear_alert).titleCase));
      if (options != null) {
        try {
          await flo.putAlertFeedbacks(
              alert.id,
              options,
              authorization: oauth.authorization);
        } catch (err) {
          Fimber.e("", ex: err);
        }

        final actionOption = or(() => options?.firstWhere((it) => it.hasAction));
        try {
          if (actionOption != null) {
              await flo.snooze(
                  deviceId: alert.device?.id,
                  duration: actionOption.sleepDuration,
                  alarmIds: {alert.alarm?.id},
                  authorization: oauth.authorization);
              /*
              await flo.sleep(alert.device?.id,
                  duration: feedback?.sleepDuration,
                  revertMode: alert.device?.systemMode?.lastKnown,
                  authorization: oauth.authorization);
              */
          } else {
            await flo.snooze(
                deviceId: alert.device?.id,
                duration: Duration.zero,
                alarmIds: {alert.alarm?.id},
                authorization: oauth.authorization);
          }
        } catch (err) {
          // device.id == null
          // device.systemMode?.lastKnown == null
          Fimber.e("", ex: err);
        }
        final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
        alertsStateConsumer.value =
            alertsStateConsumer.value.rebuild((b) => b..dirty = true);
        final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
        locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
        alertsStateConsumer.invalidate();
        locationProvider.invalidate();
        return true;
      } else {
        return false;
      }
    } else if (alert?.alarm?.actions?.isNotEmpty ?? false) {
      final res = await showDialog<bool>(context: context, builder: (context2) =>
          Theme(data: floLightThemeData,
              child: Builder(builder: (context) =>
                  AlertDialog(
                    title: Text(ReCase(S.of(context).clear_alert).titleCase),
                    content: Column(children: $(alert?.alarm?.actionsSorted ?? const <AlarmAction>[]).map((action) =>
                        ListTile(
                          title: Text(action.text, style: Theme.of(context).textTheme.body2),
                          onTap: () async {
                            try {
                              await flo.putAlertAction(
                                  AlertAction((b) => b
                                    ..deviceId = alert.deviceId
                                    ..alarmIds = ListBuilder([alert.alarm.id])
                                    ..snoozeSeconds = action.snoozeSeconds
                                  ), authorization: oauth.authorization);
                              Navigator.of(context2).pop(true);
                            } catch (err) {
                              Fimber.e("", ex: err);
                              Navigator.of(context2).pop(false);
                            }
                          },
                        )
                    ).toList(),
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ))));
      if (res) {
        final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
        alertsStateConsumer.value =
            alertsStateConsumer.value.rebuild((b) => b..dirty = true);
        final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
        locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
        alertsStateConsumer.invalidate();
        locationProvider.invalidate();
      }
      return res;
    } else {
      await flo.snooze(
          deviceId: alert.device?.id,
          duration: Duration.zero,
          alarmIds: {alert.alarm?.id},
          authorization: oauth.authorization);
      final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
      alertsStateConsumer.value =
          alertsStateConsumer.value.rebuild((b) => b..dirty = true);
      final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
      locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
      alertsStateConsumer.invalidate();
      locationProvider.invalidate();
    }
  } catch (err) {
    Fimber.e("", ex: err);
  }
  return false;
}

Future<List<AlertFeedbackOption>> showAlertFeedbackDialog(BuildContext context, AlertFeedbackStep step, {Widget title, AlertFeedbackFlowTags flowTags}) async {
  String value = "";
    return await showDialog(context: context, builder: (context2) =>
        Theme(data: floLightThemeData, child: Builder(builder: (context) =>
            AlertDialog(
              title: title,
              content: SingleChildScrollView(child: Column(children: <Widget>[
                (step?.titleText?.isNotEmpty ?? false) ? Text(step.titleText, style: Theme.of(context).textTheme.body1) : Container(),
                (step?.titleText?.isNotEmpty ?? false) ? SizedBox(height: 10) : Container(),
                ((step?.type == AlertFeedbackStep.LIST) ?? false) ? Column(children: $(step.options ?? const <AlertFeedbackOption>[])
                  .sortedBy((it) => it.sortOrder ?? 0)
                  .map((option) =>
                  ListTile(
                    title: Text(option.displayText, style: Theme.of(context).textTheme.body2),
                    onTap: () async {
                      if (option.flow == null) {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([option.payload]);
                      } else if (option?.flow?.tag == AlertFeedbackStep.SLEEP_FLOW && flowTags?.sleepFlow != null) {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([option.payload, ... (await showAlertFeedbackDialog(context, flowTags.sleepFlow, flowTags: flowTags, title: title))]);
                      } else {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([option.payload, ... (await showAlertFeedbackDialog(context, option.flow, flowTags: flowTags, title: title))]);
                      }
                    },
                  )
              ).toList(),
                mainAxisSize: MainAxisSize.min,
              ) : ((step?.type == AlertFeedbackStep.TEXT) ?? false) ?
                Column(children: <Widget>[
                  OutlineTextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) {
                      value = text;
                    },
                    onFieldSubmitted: (_) async {
                      final option = step?.options?.first;
                      final payload = option?.payload?.rebuild((b) => b..value = value);
                      if (option?.flow == null) {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload]);
                      } else if (option?.flow?.tag == AlertFeedbackStep.SLEEP_FLOW && flowTags?.sleepFlow != null) {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload, ... (await showAlertFeedbackDialog(context, flowTags.sleepFlow, flowTags: flowTags, title: title))]);
                      } else {
                        Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload, ... (await showAlertFeedbackDialog(context, option.flow, flowTags: flowTags, title: title))]);
                      }
                    },
                  ),
                ]) : Container()
              ]),
              ),
              actions: ((step?.type == AlertFeedbackStep.TEXT) ?? false) ? <Widget>[
                FlatButton(child: Text(S.of(context).done), onPressed: () async {
                  final option = step?.options?.first;
                  final payload = option?.payload?.rebuild((b) => b..value = value);
                  if (option?.flow == null) {
                    Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload]);
                  } else if (option?.flow?.tag == AlertFeedbackStep.SLEEP_FLOW && flowTags?.sleepFlow != null) {
                    Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload, ... (await showAlertFeedbackDialog(context, flowTags.sleepFlow, flowTags: flowTags, title: title))]);
                  } else {
                    Navigator.of(context2).pop<List<AlertFeedbackOption>>([payload, ... (await showAlertFeedbackDialog(context, option.flow, flowTags: flowTags, title: title))]);
                  }
                })
              ] : null,
            )
        )));
}


class AlertSummary3 extends StatefulWidget {

  AlertSummary3(this.alert, {Key key}): super(key: key);
  final Alert alert;

  @override
  _AlertSummary3State createState() => _AlertSummary3State();
}

class _AlertSummary3State extends State<AlertSummary3> {
  Alert _alert;

  @override
  void initState() {
    super.initState();

    invalidate();
  }


  FutureOr<void> invalidate({BuildContext context}) async {
    context = context ?? this.context;
    _alert = widget.alert;
    await Future.delayed(Duration.zero, () async {
      if (_alert.healthTest?.roundId != null && !(_alert.healthTest?.isValid ?? false)) {
        final flo = Provider.of<FloNotifier>(context, listen: false).value;
        final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
        try {
          final healthTest = (await flo.getHealthTestByRoundId(_alert.deviceId, _alert.healthTest.roundId, authorization: oauth.authorization)).body;
          setState(() {
            _alert = _alert.rebuild((b) => b
              ..healthTest = healthTest.toBuilder()
            );
          });
        } catch (err) {
          Fimber.e("", ex: err);
        }
      }
    });
  }

  @override
  void didUpdateWidget(AlertSummary3 oldWidget) {
    if (oldWidget.alert != widget.alert) {
      invalidate();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("${_alert}");
    Fimber.d("${_alert.duration}");
    final user = Provider.of<UserNotifier>(context).value;

    final isMetric = user.isMetric;
    final psiDelta = _alert.firmwareValue?.psiDelta ?? 0;
    final gpm = _alert.firmwareValue?.gpm ?? 0;
    final galUsed = _alert.firmwareValue?.galUsed ?? 0;
    final leakLossMinGal = _alert.firmwareValue?.leakLossMinGal ?? 0;
    final leakLossMaxGal = _alert.firmwareValue?.leakLossMaxGal ?? 0;

    if (_alert?.alarm?.isShutoff ?? false) {
      return Container();
    }

    /// title: from "displayTitle"
    /// message: from "displayMessage"
    /// estimated daily gallons: from "fwValues.leakLossMaxGal"
    /// time since it happened: see "ALARM-APP-Critical"
    /// duration: use healthTest.roundId to retrieve duration from healthTest information
    /// pressure loss: use healthTest.roundId to retrieve pressure from healthTest information
    //user.unitSystemOr().volumeText(context, orEmpty());

    return _alert.alarm.severity == Alarm.CRITICAL ? Row(children: <Widget>[
      Flexible(child: Column(children: <Widget>[
        Text(user.unitSystemOr().volumeText(context, orEmpty(gpm)), style: Theme.of(context).textTheme.body1),
        SizedBox(height: 5),
        Text(S.of(context).flow_rate_during_event, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
      SizedBox(width: 15),
      Flexible(child: Column(children: <Widget>[
        //Text("${alert.duration.inMinutes} min.", style: Theme.of(context).textTheme.subhead),
        Text("${timeago.formatDuration(_alert?.firmwareValue?.flowEventDuration ?? Duration(seconds: 1), locale: 'en_duration')}", style: Theme.of(context).textTheme.body1),
        SizedBox(height: 5),
        Text(S.of(context).event_duration, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5)),),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
      SizedBox(width: 15),
      Flexible(child: Column(children: <Widget>[
        Text(user.unitSystemOr().volumeText(context, orEmpty(gpm)), style: Theme.of(context).textTheme.subhead),
        SizedBox(height: 5),
        Text(user.isMetric ? S.of(context).total_liters_used : S.of(context).total_gallons_used, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5)),),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
    ],
      crossAxisAlignment: CrossAxisAlignment.start,
    )
        : _alert.isSmallDrip ? Row(children: <Widget>[
      Flexible(child: Column(children: <Widget>[
        Text((_alert.healthTest?.isValid ?? false) ? timeago.formatDuration(_alert.healthTest?.duration, locale: 'en_duration') : S.of(context).less_than_9_min, style: Theme.of(context).textTheme.body1),
        SizedBox(height: 5),
        Text(S.of(context).health_test_duration, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
      SizedBox(width: 15),
      Flexible(flex: 2, child: Column(children: <Widget>[
        Text("${S.of(context).up_to} ${user.unitSystemOr().volumeText(context, orEmpty(leakLossMaxGal))}", style: Theme.of(context).textTheme.subhead),
        SizedBox(height: 5),
        Text(ReCase(S.of(context).est_daily_water_loss).sentenceCase, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5)),),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
      SizedBox(width: 15),
      Flexible(child: Column(children: <Widget>[
        Text((_alert.healthTest?.lossPressureRatio != null ?? false)  ? "${intl.NumberFormat('#.#').format(_alert.healthTest.lossPressureRatio * 100)}%" : "${intl.NumberFormat("#.#").format(psiDelta)}%", style: Theme.of(context).textTheme.body1),
        SizedBox(height: 5),
        Text(S.of(context).pressure_loss, softWrap: true, style: TextStyle(color: Colors.white.withOpacity(0.5)),),
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
    ],
      crossAxisAlignment: CrossAxisAlignment.start,
    ) : Container();
  }
}

class KeepAliveFutureBuilder<T> extends StatefulWidget {

  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;
  final bool wantKeepAlive;

  KeepAliveFutureBuilder({
    this.future,
    this.builder,
    this.wantKeepAlive,
  });

  @override
  _KeepAliveFutureBuilderState<T> createState() => _KeepAliveFutureBuilderState<T>();
}

class _KeepAliveFutureBuilderState<T> extends State<KeepAliveFutureBuilder<T>> with AutomaticKeepAliveClientMixin {
  bool _wantKeepAlive = true;

  @override
  void initState() {
    _wantKeepAlive = widget.wantKeepAlive ?? true;
    super.initState();
  }

  @override
  void didUpdateWidget(KeepAliveFutureBuilder<T> oldWidget) {
    _wantKeepAlive = widget.wantKeepAlive ?? oldWidget.future == widget.future;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<T>(
      future: widget.future,
      builder: (context, snapshot) {
        _wantKeepAlive = snapshot.hasError ? false : widget.wantKeepAlive ?? true;
        return widget.builder(context, snapshot);
      },
    );
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;
}

typedef OnTime<T> = T Function(Timer t, T value);
//typedef TimerWidgetBuilder<T> = Widget Function(BuildContext context, T value);
typedef TimerWidgetBuilder = Widget Function(BuildContext context, Timer value);
class TimerWidget<T> extends StatefulWidget {
  const TimerWidget({
    Key key,
    @required this.builder,
    this.onTime,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);
  final Duration duration;
  final OnTime<T> onTime;
  final TimerWidgetBuilder builder;

  @override
  _TimerState<T> createState() => _TimerState<T>();
}

class _TimerState<T> extends State<TimerWidget<T>> {
  Timer _timer;
  Timer _ticker;
  T _value;

  @override
  void initState() {
    _timer = Timer.periodic(widget.duration, (Timer ticker) {
      _ticker = ticker;
      //if (widget.onTime != null) {
      //  _value = widget.onTime(t, _value);
      //}
      setState(() {});
    });
    _ticker = _timer;

    super.initState();
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    if (oldWidget.duration != widget.duration) {
      _timer?.cancel();

      _timer = Timer.periodic(widget.duration, (Timer t) {
        _ticker = _timer;
        setState(() {});
      });
      _ticker = _timer;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _ticker);
}

class EmptyLocations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('assets/bg_locations.png'),
          SizedBox(height: 40),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Text(S.of(context).a_list_of_your_homes_will_be_displayed_here,
                  textScaleFactor: 1.2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                  )
              )
          )
        ]);
  }
}

// FIXME: Tricky
class ZendeskWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserNotifier>(context).value;
    //final oauth = Provider.of<OauthTokenNotifier>(context).value;
    Future.delayed(Duration.zero, () async {
      final Zendesk zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
      await zendesk.setVisitorInfo(
        name: "${user.firstName} ${user.lastName}",
        email: "${user.email}",
        phoneNumber: "${user.phoneMobile}",
        note: "",
      );
    });
    return Container();
  }
}


class ThemeBuilder extends StatelessWidget {
  const ThemeBuilder({Key key,
    @required
    this.data,
    @required
    this.builder,
  }) : super(key: key);

  final ThemeData data;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Theme(data: data, child: Builder(builder: builder));
  }
}

class Shadowed extends StatelessWidget {
  const Shadowed(this.child, {Key key,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          shape: BoxShape.rectangle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 18.0,
              offset: Offset(0.0, 8.0),
            )
          ],
        ),
        child: child);
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
            width: 40,
            height: 40)
      ],);
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
            SizedBox(width: 70, height: 90, child: icon ?? FloDeviceIcon()),
            SizedBox(width: 5),
            Flexible(child: Container(child: text ?? Text(label ?? Device.FLO_DEVICE_075_V2_DISPLAY,
              style: Theme.of(context).textTheme.subhead,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ))), // FIXME
          ]),
      onPressed: onPressed ?? () {},
    );
  }
}

class FloDeviceIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleIcon(
        width: 54,
        height: 54,
        icon: Padding(padding: EdgeInsets.only(left: 0), child: Image.asset('assets/ic_flo_device_on.png',
            width: 55,
            height: 55))
    );
  }
}

class FloDeviceQuarterIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleIcon(
        width: 54,
        height: 54,
        icon: Container(
            width: 65,
            height: 65,
            child: Padding(padding: EdgeInsets.only(left: 0), child: Image.asset('assets/ic_flo_device_on.png',
              width: 65,
              height: 65,
            )))
    );
  }
}

class PuckV1Icon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(offset: Offset(5, 5), child: Image.asset('assets/ic_puck.png',
      width: 95,
      height: 95,
    ));
  }
}

class FloDeviceImage extends StatelessWidget {
  FloDeviceImage({
    Key key,
    this.width,
    this.height,
  }) : super(key: key);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment:  AlignmentDirectional.center,
      children: <Widget>[
        Container(
          width: width * 0.5 ?? 54,
          height: height ?? 54,
        ),
        Image.asset('assets/ic_flo_device_on.png',
            width: width ?? 60,
            height: width ?? 60)
      ],);
  }
}

class KeepWaterRunningDialog extends StatelessWidget {
  KeepWaterRunningDialog(this.device);
  final Device device;
  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    return AlertDialog(
      //title: Text("Unusual Activity"),
        content: SingleChildScrollView(child: Column(children: <Widget>[
          // FIXME: translatable
          Center(child: Text("Unusual Activity", style: Theme.of(context).textTheme.title, textScaleFactor: 1.2)),
          SizedBox(height: 10),
          // FIXME: device.displayName
          Center(child: Text("123 Flo Test")),
          SizedBox(height: 20),
          // FIXME: translatable
          Center(child: Text("Your water will shut off in", style: Theme.of(context).textTheme.title, textScaleFactor: 1.0,)),
          SizedBox(height: 20),
          Center(child: TimerWidget(builder: (context, t) =>
              Container(
                width: 200,
                padding: EdgeInsets.all(16),
                child: Center(child: Text(
                  Durations.ms(Duration(seconds: orEmpty(device.firmwareProperties?.alarmShutoffTimeRemaining)) - Duration(seconds: t.tick)),
                  style: Theme.of(context).textTheme.display2.copyWith(color: Colors.white),
                )),
                decoration: BoxDecoration(
                  color: floRed,
                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                ),
              )
          )),
          SizedBox(height: 20),
          // FIXME: translatable
          Text("If you do not know why this alert triggered, we strongly suggest shutting off the water immediately. If you know why this alert was triggered and know it is not a leak, you can keep the water running.",
            style: Theme.of(context).textTheme.body1,
          ),
        ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        )),
        actions: <Widget>[
          FlatButton(
            //child: Text("Shut Off Now", style: Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.bold),),
            child: Text("Shut Off Now"), // FIXME: translatable
            onPressed: () async {
              await flo.closeValveById(device?.id, authorization: oauth.authorization);
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            //child: Text("Keep Water Running", style: Theme.of(context).textTheme.subhead),
            child: Text("Keep Water Running"), // FIXME: translatable
            onPressed: () async {
              await flo.keepWaterRunning(device?.id, authorization: oauth.authorization);
              Navigator.of(context).pop();
            },
          ),
        ]
    );
  }
}

class SimpleTextSpan extends TextSpan {

  // Beware!
  //
  // This class is only safe because the TapGestureRecognizer is not
  // given a deadline and therefore never allocates any resources.
  //
  // In any other situation -- setting a deadline, using any of the less trivial
  // recognizers, etc -- you would have to manage the gesture recognizer's
  // lifetime and call dispose() when the TextSpan was no longer being rendered.
  //
  // Since TextSpan itself is @immutable, this means that you would have to
  // manage the recognizer from outside the TextSpan, e.g. in the State of a
  // stateful widget that then hands the recognizer to the TextSpan.

  SimpleTextSpan(BuildContext context, {
    TextStyle style,
    String url,
    @required
    String text,
  }) : super(
      style: style ?? canLaunch(url ?? text) ? Theme.of(context).textTheme.body2.copyWith(color: Theme.of(context).accentColor) : Theme.of(context).textTheme.body2,
      text: text ?? url,
      recognizer: TapGestureRecognizer()..onTap = () async {
        url ??= text;
        if (url.startsWith("http://") || url.startsWith("https://")) {
          launch(
            url,
            option: CustomTabsOption(
              toolbarColor: Theme.of(context).primaryColor,
              enableDefaultShare: true,
              enableUrlBarHiding: true,
              showPageTitle: true,
              //animation: CustomTabsAnimation.slideIn()
            ),
          );
        } else {
          launcher.launch(url);
        }
      }
  );

  static bool canLaunch(String url) {
    if (url != null) {
      return url.startsWith("http://") ||
          url.startsWith("https:") ||
          url.startsWith("mailto:") ||
          url.startsWith("tel:");
    }
    return false;
  }

}
