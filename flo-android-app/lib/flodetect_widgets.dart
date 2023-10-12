import 'dart:async';
import 'dart:ui';

import 'package:animator/animator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:built_collection/built_collection.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:superpower/superpower.dart';

import 'generated/i18n.dart';
import 'model/device.dart';
import 'model/fixture.dart';
import 'model/flo_detect.dart';
import 'model/flo_detect_event.dart';
import 'model/flo_detect_events.dart';
import 'model/flo_detect_feedback.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:faker/faker.dart';

import 'widgets.dart';

class FloDetectCollapsibleCard extends StatelessWidget {
  FloDetectCollapsibleCard({
    Key key,
    this.showLastUpdate = false,
    this.limit,
  }) : super(key: key);
  final bool showLastUpdate;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return FloLightCard(ExpansionTile(
        key: key ?? PageStorageKey("FloDetectCollapsibleCard"), // required or exception
        initiallyExpanded: true,
        title: Text(S.of(context).fixtures),
        children: <Widget>[
          FloDetectWidget(key: key,
              hasMore: true,
              limit: limit,
          ),
          SizedBox(height: 20),
        ])
    );
  }
}

class FloDetectCard extends StatelessWidget {
  FloDetectCard({
    Key key,
    this.showLastUpdate = false,
    this.limit,
  }) : super(key: key);
  final bool showLastUpdate;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return FloLightCard(Padding(padding: EdgeInsets.only(top: 15), child: FloDetectWidget(key: key, showLastUpdate: showLastUpdate, limit: limit) ));
  }
}

class FloDetectWidget extends StatefulWidget {

  FloDetectWidget({Key key,
    this.hasMore = false,
    this.showLastUpdate = false,
    this.limit,
  }): super(key: key);
  final bool hasMore;
  final bool showLastUpdate;
  final int limit;

  @override
  _FloDetectWidgetState createState() => _FloDetectWidgetState();
}

class _FloDetectWidgetState extends State<FloDetectWidget> with TickerProviderStateMixin<FloDetectWidget> {

  bool _loading = true;
  bool _isDummy = false;
  FloDetect _floDetect;
  List<FloDetect> _floDetects;
  List<Fixture> _fixtures;
  bool _hasData = false;

  //bool get isLearning => (_floDetects?.isNotEmpty ?? false) ? or(() => _floDetects?.every((it) => it.isLearning)) ?? false : false;
  bool get isLearning => _floDetect?.isLearning ?? false;
  TabController _tabController;

  FutureOr fetchFloDetect(BuildContext context, {String duration = FloDetect.DURATION_24H}) async {
    //_loading = true;

    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    //final locations = Provider.of<LocationsNotifier>(context, listen: false).value;
    //final devices = locations.expand((location) => location.devices);
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
    final bool isSubscribed = (location?.subscription?.isActive ?? false);
    _isDummy = !(isSubscribed);

    if (isSubscribed) {
      try {
        _floDetects = await Observable.fromIterable(location.devices ?? <Device>[])
            .asyncMap((device) => flo.getFloDetectByDevice(device.macAddress, authorization: oauth.authorization, duration: duration)
            .then((res) => res.body)
            .then((floDetect) => floDetect.rebuild((b) => b..device = device.toBuilder()))
        )
            .onErrorResumeNext(Stream.empty()) // 404 error if no data
            .toList();
        //Fimber.d("_floDetects: $_floDetects");
        _floDetect = or(() => _floDetects.reduce((that, it) => that + it));
        //Fimber.d("_floDetect: $_floDetect");
      } catch (err) {
        // TODO empty screen
        Fimber.e("", ex: err);
      }
      Fimber.d("isLearning: $isLearning");
      _fixtures = or(() => _floDetect?.fixtures?.where((it) => it.name != null))?.toList() ?? <Fixture>[];
      _hasData = _fixtures.isNotEmpty; // isSubscribed && !isLearning && fixtures.isEmpty
      Fimber.d("_hasData: $_hasData");
      if (!_hasData && !isLearning) {
        _floDetect = FloDetect((b) => b
          ..status = FloDetect.EXECUTED
          ..fixtures = ListBuilder(
              Fixture.FIXTURE_TYPES_NO_OTHER.map((it) => Fixture((b) => b
                ..name = Fixture.nameBy(it)
                ..type = it
                ..gallons = faker.randomGenerator.decimal(scale: 100.0)
                ..ratio = faker.randomGenerator.decimal(scale: 1.0)
              ))
          ));
      }
      if (isLearning) {
        _floDetect = _floDetect.rebuild((b) => b
          ..status = FloDetect.LEARNING
          ..fixtures = ListBuilder(
              Fixture.FIXTURE_TYPES_NO_OTHER.map((it) =>
                  Fixture((b) => b
                    ..name = Fixture.nameBy(it)
                    ..type = it
                    ..gallons = faker.randomGenerator.decimal(scale: 100.0)
                    ..ratio = faker.randomGenerator.decimal(scale: 1.0)
                  ))
          ));
      } else if (!_hasData) {
        _floDetect = _floDetect.rebuild((b) => b
          ..status = FloDetect.LEARNING
          ..fixtures = ListBuilder(
              Fixture.FIXTURE_TYPES_NO_OTHER.map((it) =>
                  Fixture((b) => b
                    ..name = Fixture.nameBy(it)
                    ..type = it
                    ..gallons = faker.randomGenerator.decimal(scale: 100.0)
                    ..ratio = faker.randomGenerator.decimal(scale: 1.0)
                  ))
          ));
      }
    } else { // dummy
      _floDetect = FloDetect((b) => b
        ..status = FloDetect.EXECUTED
        ..fixtures = ListBuilder(
            Fixture.FIXTURE_TYPES_NO_OTHER.map((it) => Fixture((b) => b
              ..name = Fixture.nameBy(it)
              ..type = it
              ..gallons = faker.randomGenerator.decimal(scale: 100.0)
              ..ratio = faker.randomGenerator.decimal(scale: 1.0)
            ))
        ));
    }
    _fixtures = or(() => _floDetect?.fixtures?.where((it) => it.name != null))?.toList() ?? <Fixture>[];
    Fimber.d("isLearning: $isLearning");
    Fimber.d("_hasData: $_hasData");
    Fimber.d("_fixtures: $_fixtures");
    _loading = false;
    if (mounted) {
      setState(() {
      });
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loading = true;
    _hasData = false;
    _fixtures = <Fixture>[];

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      await fetchFloDetect(context);
    });
  }

  //Widget _child;
  bool _isDonus = false;

  @override
  Widget build(BuildContext context) {
    //if (_loading || (_floDetect?.fixtures?.isEmpty ?? true)) return Container();
    //if (_loading) return Container();
    final location = Provider.of<CurrentLocationNotifier>(context).value;
    final bool isSubscribed = (location?.subscription?.isActive ?? false);
    _isDummy = !(isSubscribed);
    final limit = widget.limit;
    //final limit = widget.limit != null ? widget.limit
    //                                   : isSubscribed ? 3 : null;
    List<Fixture> fixtures = _fixtures;
    fixtures.sort((a, b) => -orEmpty(a.ratio).compareTo(orEmpty(b.ratio)));
    if (limit != null) {
      fixtures = fixtures.take(limit).toList();
      fixtures.sort((a, b) => -orEmpty(a.ratio).compareTo(orEmpty(b.ratio)));
    }

    return Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity,
      child: Column(children: <Widget>[
      Row(children: [
        SizedBox(width: 20),
        Expanded(child: Text(S.of(context).usage_by_fixture, textScaleFactor: 1.0, style: Theme.of(context).textTheme.title)),
        Transform.translate(offset: Offset(0, 0), child: FlatButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.all(0),
          child: Row(children: [
          Text(ReCase(!_isDonus ? S.of(context).chart : S.of(context).list).titleCase, textScaleFactor: 1.0, style: Theme.of(context).textTheme.subhead),
          SizedBox(width: 8),
          !_isDonus ? SvgPicture.asset(
              'assets/ic_donut_chart.svg',
              width: 16
          ) : SvgPicture.asset(
              'assets/ic_list.svg',
              width: 16
          ),
            SizedBox(width: 10),
        ]),
            onPressed: () {
              setState(() {
                _isDonus = !_isDonus;
              });
            },
        )),
      ],
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
      ),
      SizedBox(height: 10),
      Center(
          child: Container(
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
              Fimber.d("onTap $i");
              if (i == 0) {
                await fetchFloDetect(context, duration: FloDetect.DURATION_24H);
              } else {
                await fetchFloDetect(context, duration: FloDetect.DURATION_7D);
              }
            },
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black.withOpacity(0.3),
            labelPadding: EdgeInsets.symmetric(vertical: 10),
            tabs: <Widget>[
              Tab(
                text: S.of(context).last_24h,
              ),
              Tab(
                text: S.of(context).last_7d,
              ),
            ],
            indicator: BubbleTabIndicator(
              indicatorHeight: 35.0,
              indicatorColor: Colors.white,
              tabBarIndicatorSize: TabBarIndicatorSize.label,
            ),
            controller: _tabController,
          ))),
      SizedBox(height: 10),
      Visibility(visible: !isSubscribed, child: Card(
        elevation: 12.0,
        margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        color: Color(0xFF073F62),
        child: InkWell(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: ThemeBuilder(data: floThemeData, builder: (context) => Row(children: <Widget>[
          Image.asset('assets/ic_flodetect.png', scale: 1.5,),
          SizedBox(width: 10),
          Expanded(child: Text(S.of(context).add_floprotect_to_see_your_homes_usage_by_fixture, style: Theme.of(context).textTheme.body1)),
          SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios, size: 16),
          SizedBox(width: 10),
        ],))),
          onTap: () {
            Navigator.of(context).pushNamed('/floprotect');
          },
        ),
      )),
      Visibility(visible: isSubscribed && !_hasData && !_isDonus, child: Card(
          elevation: 12.0,
          margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          color: Color(0xFF073F62),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15), child: ThemeBuilder(data: floThemeData, builder: (context) => Row(children: <Widget>[
            Expanded(child: Text(!_hasData ? S.of(context).no_fixture_data_detected_description : S.of(context).fixture_learning_description, style: Theme.of(context).textTheme.body1)),
          ],)),
          ))),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: !_isDonus ? _loading ? Padding(padding: EdgeInsets.only(left: 20), child: ListPlaceholder()) :
        Visibility(visible: _hasData || isLearning || _isDummy, child: Column(
            children: fixtures.map<Widget>((it) =>
                SizedBox(width: double.infinity,
                    child: Padding(padding: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 20),
                        child: _isDummy ? FixtureWidget(it, enabled: !isLearning && _hasData, text: isLearning ? S.of(context).learning_ : _isDummy ? null : !_hasData ? "No Data" : null, isDummy: _isDummy)
                                        : FixtureWidget(it, enabled: !isLearning && _hasData, text: isLearning ? S.of(context).learning_ : _isDummy ? null : !_hasData ? "No Data" : null)))).toList(),
          mainAxisSize: MainAxisSize.min,
        )) : Enabled(enabled: !_isDummy, child: FloDetectDonut(key: widget.key, hasData: _hasData, floDetect: _floDetect, isDummy: _isDummy)),
      ),
      SizedBox(height: 15),
      //Text("Last calculation on Sep 11 at 5:00pm"),
      Visibility(visible: widget.showLastUpdate && _floDetect != null && _floDetect?.computeEndDate != null,
          child: Center(child: Text("${S.of(context).last_calculation_on} ${_floDetect?.computeEndDateTimeFormatted}", style: Theme.of(context).textTheme.caption, textAlign: TextAlign.center)),
      ),
      Visibility(visible: _floDetect != null && _floDetect?.computeEndDate != null, child: SizedBox(height: 15)),
      Visibility(visible: widget.hasMore,
        //Visibility(visible: widget.hasMore && _hasData && !isLearning,
          child: Center(child: Container(
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
          child: FlatButton(
              child: Text(S.of(context).view_more_details, style: TextStyle(color: floPrimaryColor)),
              color: Color(0xFFF0F4F8),
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(30)
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/fixtures');
              })))),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      //mainAxisSize: MainAxisSize.min,
    ),
    )));
  }
}


class ApplianceButton extends StatelessWidget {
  static const IC_APPLIANCE = 'assets/ic_appliance.svg';
  static const IC_PATH = IC_APPLIANCE;
  static const COLOR = Color(0xFF01B6CD);
  ApplianceButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
        child: SvgPicture.asset(
            IC_APPLIANCE,
          color: Colors.white,
          width: 24
        ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}


class IrrigationButton extends StatelessWidget {
  static const IC_IRRIGATION = 'assets/ic_irrigation.svg';
  static const IC_PATH = IC_IRRIGATION;
  static const COLOR = Color(0xFF4B84BD);
  IrrigationButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
        child: SvgPicture.asset(
            IC_IRRIGATION,
          color: Colors.white,
            width: 24
        ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}

class OtherFixtureButton extends StatelessWidget {
  static const IC_OTHER_FIXTURE = 'assets/ic_other_fixture.svg';
  static const IC_PATH = IC_OTHER_FIXTURE;
  static const COLOR = Color(0xFF9DBED1);
  OtherFixtureButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
        child: SvgPicture.asset(
            IC_OTHER_FIXTURE,
          color: Colors.white,
            width: 24
        ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}

class PoolButton extends StatelessWidget {
  static const IC_POOL = 'assets/ic_pool.svg';
  static const IC_PATH = IC_POOL;
  static const COLOR = Color(0xFF1EF1CF);
  PoolButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
        child: SvgPicture.asset(
            IC_POOL,
          color: Colors.white,
            width: 24
        ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}

class FixtureButton2 extends StatelessWidget {
  FixtureButton2({
    Key key,
    @required
    this.color,
    this.iconPath,
    this.icon,
    this.onPressed,
  }) : super(key: key);

  final Color color;
  final String iconPath;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: iconPath == null ? icon ?? Container() : SvgPicture.asset(
          iconPath,
          color: color,
          width: 24
      ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color.withOpacity(0.2),
      onPressed: onPressed ?? () {
      },
    );
  }
}
class ToiletButton2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FixtureButton2(
          color: ToiletButton.COLOR,
      iconPath: ToiletButton.IC_TOILET);
  }
}

class ToiletButton extends StatelessWidget {
  static const String IC_TOILET = 'assets/ic_toilet.svg';
  static const IC_PATH = IC_TOILET;
  static const COLOR = Color(0xFFF4A73B);
  ToiletButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
      child: SvgPicture.asset(
          IC_TOILET,
          color: Colors.white,
          width: 24
      ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}

class FaucetButton extends StatelessWidget {
  static const IC_FAUCET = 'assets/ic_faucet.svg';
  static const IC_PATH = IC_FAUCET;
  static const COLOR = Color(0xFFA43DB6);
  FaucetButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(
      child: SvgPicture.asset(
          IC_FAUCET,
          color: Colors.white,
          width: 24
      ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: COLOR,
      onPressed: () {
      },
    ));
  }
}

class ShowerButton extends StatelessWidget {
  static const IC_SHOWER = 'assets/ic_shower.svg';
  static const IC_PATH = IC_SHOWER;
  static const COLOR = Color(0xFFEC3824);
  ShowerButton({Key key,
    this.color = COLOR,
  }) : super(key: key);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child:
    FlatButton(child:
    SvgPicture.asset(
        IC_SHOWER,
        color: Colors.white,
        width: 24
    ),
      padding: EdgeInsets.all(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: color,
      onPressed: () {
      },
    ));
  }
}


Widget fixtureButton2(int type) {
  Widget icon = FixtureButton2(color: OtherFixtureButton.COLOR, iconPath: OtherFixtureButton.IC_PATH);
  switch (type) {
    case Fixture.TYPE_TOILET: {
      icon = FixtureButton2(color: ToiletButton.COLOR, iconPath: ToiletButton.IC_PATH);
    } break;
    case Fixture.TYPE_SHOWER: {
      icon = FixtureButton2(color: ShowerButton.COLOR, iconPath: ShowerButton.IC_PATH);
    } break;
    case Fixture.TYPE_FAUCET: {
      icon = FixtureButton2(color: FaucetButton.COLOR, iconPath: FaucetButton.IC_PATH);
    } break;
    case Fixture.TYPE_APPLIANCE: {
      icon = FixtureButton2(color: ApplianceButton.COLOR, iconPath: ApplianceButton.IC_PATH);
    } break;
    case Fixture.TYPE_POOL: {
      icon = FixtureButton2(color: PoolButton.COLOR, iconPath: PoolButton.IC_PATH);
    } break;
    case Fixture.TYPE_IRRIGATION: {
      icon = FixtureButton2(color: IrrigationButton.COLOR, iconPath: IrrigationButton.IC_PATH);
    } break;
    case Fixture.TYPE_OTHER: {
      icon = FixtureButton2(color: OtherFixtureButton.COLOR, iconPath: OtherFixtureButton.IC_PATH);
    } break;
  }
  return icon;
}

class FixtureButton extends StatefulWidget {
  FixtureButton(
      this.fixture, {Key key,
        this.onPressed,
        this.shadowEnabled = false,
        this.color,
        this.invertColor,
      }) : super(key: key);
  final Fixture fixture;
  final VoidCallback onPressed;
  final bool shadowEnabled;
  final Color color;
  final Color invertColor;
  @override
  _FixtureButtonState createState() => _FixtureButtonState();
}

class _FixtureButtonState extends State<FixtureButton> {
  Color _color;
  String _iconPath;

  @override
  void initState() {
    super.initState();

    _color = OtherFixtureButton.COLOR;
    _iconPath = OtherFixtureButton.IC_PATH;
    switch (widget.fixture.type) {
      case Fixture.TYPE_TOILET: {
        _color = ToiletButton.COLOR;
        _iconPath = ToiletButton.IC_PATH;
      } break;
      case Fixture.TYPE_SHOWER: {
        _color = ShowerButton.COLOR;
        _iconPath = ShowerButton.IC_PATH;
      } break;
      case Fixture.TYPE_FAUCET: {
        _color = FaucetButton.COLOR;
        _iconPath = FaucetButton.IC_PATH;
      } break;
      case Fixture.TYPE_APPLIANCE: {
        _color = ApplianceButton.COLOR;
        _iconPath = ApplianceButton.IC_PATH;
      } break;
      case Fixture.TYPE_POOL: {
        _color = PoolButton.COLOR;
        _iconPath = PoolButton.IC_PATH;
      } break;
      case Fixture.TYPE_IRRIGATION: {
        _color = IrrigationButton.COLOR;
        _iconPath = IrrigationButton.IC_PATH;
      } break;
      case Fixture.TYPE_OTHER: {
        _color = OtherFixtureButton.COLOR;
        _iconPath = OtherFixtureButton.IC_PATH;
      } break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: widget.shadowEnabled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3.0,
              offset: Offset(
                0.0, // horizontal, move right 10
                3.0, // vertical, move down 10
              ),
            )
          ] : const [],
        ),
        child:
    FlatButton(
      child: SvgPicture.asset(
          _iconPath,
          color: widget.invertColor ?? Colors.white,
          width: 24
      ),
      padding: EdgeInsets.all(10),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: CircleBorder(),
      color: widget.invertColor?.withOpacity(0.1) ?? widget.color ?? _color,
      onPressed: widget.onPressed ?? () {
      },
    ));
  }
}

Color fixtureColor(int type) {
  switch (type) {
    case Fixture.TYPE_TOILET: return ToiletButton.COLOR;
    case Fixture.TYPE_SHOWER: return ShowerButton.COLOR;
    case Fixture.TYPE_FAUCET: return FaucetButton.COLOR;
    case Fixture.TYPE_APPLIANCE: return ApplianceButton.COLOR;
    case Fixture.TYPE_POOL: return PoolButton.COLOR;
    case Fixture.TYPE_IRRIGATION: return IrrigationButton.COLOR;
    case Fixture.TYPE_OTHER: return OtherFixtureButton.COLOR;
  }
  return OtherFixtureButton.COLOR;
}

class FixtureWidget extends StatelessWidget {
  FixtureWidget(this.fixture, {Key key,
    //this.icon,
    this.color,
    this.isDummy = false,
    this.enabled = true,
    this.text,
  }): super(key: key);
  //final Widget icon;
  final Color color;
  final Fixture fixture;
  final bool isDummy;
  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserNotifier>(context).value;
    Widget icon = FixtureButton(fixture, invertColor: color);
    return Enabled(enabled: enabled, opacity: 0.3, child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: icon),
      Expanded(child: Column(children: <Widget>[
        Row(children: <Widget>[
          Text(fixture.display(context)),
          Spacer(),
          Text(text != null ? text : user.unitSystemOr().volumeText(context, orEmpty(fixture?.gallons))),
        ],
          mainAxisSize: MainAxisSize.min,
        ),
        SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 10,
          percent: fixture?.ratio ?? 0,
          backgroundColor: Color(0xFFF0F4F8),
          linearGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 1.0],
            colors: [
              color?.withOpacity(0.2) ?? Color(0xFF67EFFC),
              color?.withOpacity(0.2) ?? Color(0xFF2FE3F4),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 6),
          // padding: EdgeInsets.all(0),
          linearStrokeCap: LinearStrokeCap.roundAll,
          //color: Color(0x67EFFC),
        ),
          SizedBox(height: 5),
    //LinearProgressIndicator(color: Color(0x67EFFC))
      ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )
      ),
    ],
      //crossAxisAlignment: CrossAxisAlignment.start,
    ));
  }
}

class FloDetectPlaceholder extends StatelessWidget {
  List<Widget> list;

  FloDetectPlaceholder({Key key}) : super(key: key) {
    final baseColor = Colors.grey[700].withOpacity(0.5);
    final highlightColor = Colors.grey[300].withOpacity(0.5);
    list = [
      SizedBox(height: 40),
      Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 80,
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
    return Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ListView.builder(itemBuilder: (context, i) => list[i % list.length], itemCount: 7,));
  }
}

class FloLightCard extends StatelessWidget {
  FloLightCard(this.child, {
    Key key
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: floLightThemeData.copyWith(dividerColor: Colors.transparent, accentColor: Colors.black.withOpacity(0.8)), child: Card(child: child));
  }
}

class FloDetectEventsCollapsibleCard extends StatelessWidget {
  FloDetectEventsCollapsibleCard({
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloLightCard(ExpansionTile(
            key: key ?? PageStorageKey(S.of(context).fixtures),
            initiallyExpanded: true,
            title: Text(S.of(context).fixtures),
            children: <Widget>[
              FloDetectEventsWidget()
            ])
        );
  }
}

class FloDetectEventsCard extends StatelessWidget {
  FloDetectEventsCard({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloLightCard( Padding(padding: EdgeInsets.only(top: 10), child: FloDetectEventsWidget() ));
  }
}

class FloDetectEventsWidget extends StatefulWidget {

  FloDetectEventsWidget({Key key,
  }): super(key: key);

  @override
  _FloDetectEventsWidget createState() => _FloDetectEventsWidget();
}

class _FloDetectEventsWidget extends State<FloDetectEventsWidget> with TickerProviderStateMixin<FloDetectEventsWidget>{
  bool _loading = true;
  bool _isDummy = false;
  bool _hasData = false;
  FloDetect _floDetect;
  List<FloDetect> _floDetects;
  //Set<Fixture> _fixtures;
  List<FloDetectEvent> _floDetectEvents;
  bool get isLearning => (_floDetects?.isNotEmpty ?? false) ? (or(() => _floDetects?.every((it) => it.isLearning)) ?? false) : false;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loading = true;
    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    Future.delayed(Duration.zero, () async {
      await fetchFloDetect(context);
    });
  }

  FutureOr fetchFloDetect(BuildContext context, {String duration = FloDetect.DURATION_24H}) async {
    _loading = true;
    _isDummy = false;
    _hasData = false;
    _floDetect = null;
    _floDetects = null;
    _floDetectEvents = null;

    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final location = Provider.of<CurrentLocationNotifier>(context, listen: false).value;
    try {
      _floDetects = await Observable.fromIterable(location.devices ?? <Device>[])
          .asyncMap((device) => flo.getFloDetectByDevice(device.macAddress, authorization: oauth.authorization, duration: duration)
          .then((res) => res.body)
          .then((floDetect) => floDetect.rebuild((b) => b..device = device.toBuilder()))
      )
          .onErrorResumeNext(Stream.empty())
          .toList();
      Fimber.d("_floDetects: $_floDetects");
      _floDetect = or(() => _floDetects.reduce((that, it) => that + it));
      Fimber.d("_floDetect: $_floDetect");
      //_fixtures = or(() => _floDetect?.fixtures?.where((it) => it.name != null))?.toSet() ?? {};

      //final _floDetectEventItems = (await flo.getFloDetectEvents("", authorization: oauth.authorization)).body;
      //_floDetectEvents = or(() => _floDetectEventItems?.items?.toList()) ?? [];

      if (isLearning) {
        _floDetectEvents = Iterable<int>.generate(1).map((it) {
                final fixture = $(Fixture.FIXTURES).shuffled().first;
                final correctFixture = $(Fixture.FIXTURES).shuffled().first;
                return FloDetectEvent((b) => b
                  ..computationId = _floDetect?.id
                  ..flow = faker.randomGenerator.decimal(scale: 100.0)
                  ..gpm = faker.randomGenerator.decimal(scale: 100.0)
                  ..fixture = fixture
                  ..duration = Duration(minutes: faker.randomGenerator.decimal(scale: 100.0).toInt()).inSeconds
                  ..feedback = FloDetectFeedback((b) => b
                    ..cases = correctFixture == fixture ? $([FloDetectFeedback.CONFIRM, FloDetectFeedback.INFORM]).shuffled().first : FloDetectFeedback.WRONG
                    ..correctFixture = correctFixture
                  ).toBuilder()
                );
              }).toList();
      } else {
        _floDetectEvents = await Observable.fromIterable(_floDetects)
            .asyncMap((floDetect) => flo.getFloDetectEvents(floDetect.id, size: 10000, authorization: oauth.authorization, order: FloDetectEvent.DESC)
        )
            .map((res) => res.body)
            .expand((events) => events.items)
            .toList();
      }
      /*
      _hasData = _floDetectEvents.isNotEmpty ?? false;
      if (!_hasData) {
        _floDetectEvents = Iterable<int>.generate(1).map((it) {
          final fixture = $(Fixture.FIXTURES).shuffled().first;
          final correctFixture = $(Fixture.FIXTURES).shuffled().first;
          return FloDetectEvent((b) => b
            ..computationId = _floDetect?.id
            ..flow = faker.randomGenerator.decimal(scale: 100.0)
            ..gpm = faker.randomGenerator.decimal(scale: 100.0)
            ..fixture = fixture
            ..duration = Duration(minutes: faker.randomGenerator.decimal(scale: 100.0).toInt()).inSeconds
            ..feedback = FloDetectFeedback((b) => b
              ..cases = correctFixture == fixture ? $([FloDetectFeedback.CONFIRM, FloDetectFeedback.INFORM]).shuffled().first : FloDetectFeedback.WRONG
              ..correctFixture = correctFixture
            ).toBuilder()
          );
        }).toList();
      }
      */
      /*
      final events = FloDetectEvents((b) => b
        ..items = ListBuilder(
            Iterable<int>.generate(24).map((it) {
              final fixture = $(Fixture.FIXTURES).shuffled().first;
              final correctFixture = $(Fixture.FIXTURES).shuffled().first;
              return FloDetectEvent((b) => b
                ..computationId = id
                ..flow = faker.randomGenerator.decimal(scale: 100.0)
                ..gpm = faker.randomGenerator.decimal(scale: 100.0)
                ..fixture = fixture
                ..duration = Duration(minutes: faker.randomGenerator.decimal(scale: 100.0).toInt()).inSeconds
                ..feedback = FloDetectFeedback((b) => b
                  ..cases = correctFixture == fixture ? $([FloDetectFeedback.CONFIRM, FloDetectFeedback.INFORM]).shuffled().first : FloDetectFeedback.WRONG
                  ..correctFixture = correctFixture
                ).toBuilder()
              );
            })
        ));
      */
    } catch (err) {
      Fimber.e("", ex: err);
    }

    Fimber.d("_floDetectEvents: ${_floDetectEvents}");
    Fimber.d("isLearning: ${isLearning}");
    Fimber.d("_floDetect.isLearning: ${_floDetect?.isLearning}");
    //_hasData = (_floDetectEvents?.isNotEmpty ?? false);
    /*
      if (_floDetectEvents?.isEmpty ?? true) {
        _floDetectEvents = Iterable<int>.generate(24).map((it) {
              final fixture = $(Fixture.FIXTURES).shuffled().first;
              final correctFixture = $(Fixture.FIXTURES).shuffled().first;
              return FloDetectEvent((b) => b
                ..computationId = ""
                ..flow = faker.randomGenerator.decimal(scale: 100.0)
                ..gpm = faker.randomGenerator.decimal(scale: 100.0)
                ..fixture = fixture
                ..duration = Duration(minutes: faker.randomGenerator.decimal(scale: 100.0).toInt()).inSeconds
                ..feedback = FloDetectFeedback((b) => b
                  ..cases = correctFixture == fixture ? $([FloDetectFeedback.CONFIRM, FloDetectFeedback.INFORM]).shuffled().first : FloDetectFeedback.WRONG
                  ..correctFixture = correctFixture
                ).toBuilder()
              );
            }).toList();
      }
      */
    _loading = false;
    if (mounted) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //if (_loading) return Container();
    //if (_floDetectEvents?.isEmpty ?? true) return Container();
    Fimber.d("_floDetectEvents.length: ${_floDetectEvents?.length}");
    return Theme(data: floLightThemeData.copyWith(dividerColor: Colors.transparent, accentColor: floPrimaryColor),
        child: Builder(builder: (context) =>
            Column(children: [
              Padding(padding: EdgeInsets.only(left: 20, right: 10),
                  child: Row(children: <Widget>[
                    Expanded(child: Text(ReCase(S.of(context).usage_history).titleCase, textScaleFactor: 1.0, style: Theme.of(context).textTheme.title)),
                    IconButton(
                      //icon: Icon(Icons.info_outline, color: floBlue),
                      icon: SvgPicture.asset('assets/ic_info_grey.svg'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context2) =>
                              Theme(data: floLightThemeData, child: Builder(builder: (context2) => AlertDialog(
                                title: Text(ReCase(S.of(context).about).titleCase),
                                content: Text(S.of(context).about_reclassify_flow_events),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text(S.of(context).ok),
                                    onPressed: () { Navigator.of(context2).pop(); },
                                  ),
                                ],
                              ))),
                        );
                      },
                    ),
                  ])),
              SizedBox(height: 10),
              Center(
                  child: Container(
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
                          Fimber.d("onTap $i");
                          if (i == 0) {
                            await fetchFloDetect(context, duration: FloDetect.DURATION_24H);
                          } else {
                            await fetchFloDetect(context, duration: FloDetect.DURATION_7D);
                          }
                        },
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black.withOpacity(0.3),
                        labelPadding: EdgeInsets.symmetric(vertical: 10),
                        tabs: <Widget>[
                          Tab(
                            text: S.of(context).last_24h,
                          ),
                          Tab(
                            text: S.of(context).last_7d,
                          ),
                        ],
                        indicator: BubbleTabIndicator(
                          indicatorHeight: 35.0,
                          indicatorColor: Colors.white,
                          tabBarIndicatorSize: TabBarIndicatorSize.label,
                        ),
                        controller: _tabController,
                      ))),
              SizedBox(height: 10),
              Visibility(visible: !_loading && isLearning, child: Card(
                  elevation: 12.0,
                  margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                  color: Color(0xFF073F62),
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15), child: ThemeBuilder(data: floThemeData, builder: (context) => Row(children: <Widget>[
                    Expanded(child: Text(S.of(context).fixture_learning_description, style: Theme.of(context).textTheme.body1)),
                  ],)),
                  ))),
              _loading ? ListPlaceholder() : (_floDetectEvents?.isEmpty ?? true) ?
              Card(
                  elevation: 12.0,
                  margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                  color: Color(0xFF073F62),
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15), child: ThemeBuilder(data: floThemeData, builder: (context) => Row(children: <Widget>[
                    Expanded(child: Text(S.of(context).no_fixture_data_detected_description, style: Theme.of(context).textTheme.body1)),
                  ],)),
                  ))
                  : Column(children: _floDetectEvents.fold<List<FloDetectEventParentWidget>>(<FloDetectEventParentWidget>[], (that, it) {
                if (or(() => that?.last?.event?.selectedFixture == it.selectedFixture) ?? false) {
                  that.last.children.add(it);
                } else {
                  that.add(FloDetectEventParentWidget(it, isLearning: isLearning, children: [it], onValueChanged: (event, newEvent) {
                    setState(() {
                      final i = _floDetectEvents.indexOf(event);
                      Fimber.d("removing $event");
                      _floDetectEvents.remove(event);
                      _floDetectEvents.insert(i, newEvent);
                      Fimber.d("inserted $newEvent");
                    });
                  },));
                }
                return that;
              }),),
            ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
        ));
  }
}

class FloDetectEventParentWidget extends StatelessWidget {
  FloDetectEventParentWidget(this.event, {
    Key key,
    this.children,
    this.onValueChanged,
    this.isLearning = false,
  }) : super(key: key);

  final FloDetectEvent event;
  final List<FloDetectEvent> children;
  final Changed2<FloDetectEvent, FloDetectEvent> onValueChanged;
  final bool isLearning;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserNotifier>(context).value;
    final volume = children?.map((it) => it.flow ?? 0.0)?.reduce((that, it) => that + it) ?? 0.0;

    final selectedFixtureType = event.selectedFixtureType;
    final icPath = selectedFixtureType == Fixture.TYPE_TOILET ? ToiletButton.IC_PATH :
      selectedFixtureType == Fixture.TYPE_SHOWER ? ShowerButton.IC_PATH :
      selectedFixtureType == Fixture.TYPE_FAUCET ? FaucetButton.IC_PATH :
      selectedFixtureType == Fixture.TYPE_APPLIANCE ? ApplianceButton.IC_PATH :
      selectedFixtureType == Fixture.TYPE_POOL ? PoolButton.IC_PATH :
      selectedFixtureType == Fixture.TYPE_IRRIGATION ? IrrigationButton.IC_PATH :
      OtherFixtureButton.IC_PATH;

    return ExpansionTile(
    key: PageStorageKey(event.fixture ?? ""),
        initiallyExpanded: true,
        title: Row(children: <Widget>[
          Padding(padding: EdgeInsets.all(6), child: SvgPicture.asset(
              icPath,
              color: floPrimaryColor, width: 18, height: 18)),
          SizedBox(width: 10),
          Expanded(child: Row(children: <Widget>[
            Text(event.display(context), style: TextStyle(color: Colors.black)),
            SizedBox(width: 10),
            Text("${children.length} ${S.of(context).events}", style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 1.1,),
          ],)),
          SizedBox(width: 10),
          //Text(true ? "${intl.NumberFormat('#.#').format(volume)} gal." : "${intl.NumberFormat('#.#').format(toLiters(volume))} ${S.of(context).liters}", style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black)),
          Text(isLearning ? S.of(context).learning_ : user.unitSystemOr().volumeText(context, orEmpty(volume)), style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black)),
        ]),
        //trailing: SwitchIcon(),
        children: children?.map((it) => FloDetectEventWidget(it, isLearning: isLearning, key: ValueKey(it.id), onValueChanged: onValueChanged))?.toList());
  }
}

class FloDetectEventWidget extends StatelessWidget {
  FloDetectEventWidget(this.event, {
    Key key,
    this.onValueChanged,
    this.isLearning = false,
  }) : super(key: key);

  final FloDetectEvent event;
  final Changed2<FloDetectEvent, FloDetectEvent> onValueChanged;
  final bool isLearning;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserNotifier>(context).value;
    final volume = event?.flow ?? 0.0;
    return InkWell(child: Padding(
      padding: EdgeInsets.only(left: 18, right: 56),
      child: Column(children: <Widget>[
        Row(children: <Widget>[
        SizedBox(width: 8),
        Stack(children: <Widget>[
          Column(children: <Widget>[
            SizedBox(width: 18),
            Pill2(size: Size(1, 14), color: Color(0xFFC3D3DE), shadowColor: Colors.transparent,),
            //Padding(padding: EdgeInsets.all(6), child: SvgPicture.asset(IC_TOILET, color: floPrimaryColor, width: 18, height: 18)),
            //Icon(Icons.close, size: 14, color: floPrimaryColor.withOpacity(0.3)),
            //Icon(Icons.check, size: 14, color: floPrimaryColor.withOpacity(0.3)),
            //x Icon(Icons.fiber_manual_record, size: 14, color: floPrimaryColor.withOpacity(0.3)),
            /*
            event?.feedback?.cases == FloDetectFeedback.CONFIRM ? Icon(Icons.check, size: 12, color: floPrimaryColor.withOpacity(0.3))
                : event?.feedback?.cases == FloDetectFeedback.INFORM ? Dot(color: floPrimaryColor.withOpacity(0.3))
                : event?.feedback?.cases == FloDetectFeedback.WRONG ? Icon(Icons.close, size: 12, color: floPrimaryColor.withOpacity(0.3))
                : Dot(color: floPrimaryColor.withOpacity(0.3)),
            */
            SizedBox(height: 8),
            Pill2(size: Size(1, 14), color: Color(0xFFC3D3DE), shadowColor: Colors.transparent),
          ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          /*
          Align(alignment: Alignment.center, child: event?.feedback?.cases == FloDetectFeedback.CONFIRM ? Icon(Icons.check, size: 12, color: floPrimaryColor.withOpacity(0.3))
              : event?.feedback?.cases == FloDetectFeedback.INFORM ? Dot(color: floPrimaryColor.withOpacity(0.3))
              : event?.feedback?.cases == FloDetectFeedback.WRONG ? Icon(Icons.close, size: 12, color: floPrimaryColor.withOpacity(0.3))
              : Dot(color: floPrimaryColor.withOpacity(0.3))),
          */
          event?.feedback?.cases == FloDetectFeedback.CONFIRM ? Icon(Icons.check, size: 14, color: floPrimaryColor)
              : event?.feedback?.cases == FloDetectFeedback.INFORM ? Dot(color: Color(0xFFC3D3DE))
              : event?.feedback?.cases == FloDetectFeedback.WRONG ? Icon(Icons.close, size: 14, color: floPrimaryColor)
              : Dot(color: floPrimaryColor.withOpacity(0.3)),
        ],
          alignment: AlignmentDirectional.center,
        ),
        SizedBox(width: 20),
          Expanded(child: Column(children: <Widget>[
            Row(children: <Widget>[
              Text("${intl.DateFormat.Md().add_jm().format(event.startDateTime)}",
                style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 1.1,),
              SizedBox(width: 10),
              Text(event.durationDisplay, style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 1.1,),
            ],),
            //Text("${event.fixture != (event?.feedback?.correctFixture ?? event.fixture) ? S.of(context).was_fixture(Fixture.displayByName(context, event.fixture)) : ""}",
            Visibility(visible: event.fixture != (event?.feedback?.correctFixture ?? event.fixture),
                child: Text(S.of(context).was_fixture(event.wasDisplay(context)),
              style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 1.0,)),
          ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
          )),
        SizedBox(width: 10),
        Text(isLearning ? S.of(context).learning_ : user.unitSystemOr().volumeText(context, orEmpty(volume)), style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black)),
      ]),
      ])
    ), onTap: () {
      if (event?.feedback == null || event?.feedback?.cases == FloDetectFeedback.INFORM) {
      showDialog(context: context, builder: (context2) =>
          Theme(data: floLightThemeData,
              child: Builder(builder: (context) => AlertDialog(
                  title: Text("${S.of(context).confirm} ${event.display(context)}"),
                  content:
                    //Text("Flo predicted ${intl.NumberFormat("#.#").format(event.flow ?? 0)} gallon(s) used from a ${event.selectedFixture} between ${intl.DateFormat.jm().format(event.startDateTime)} – ${intl.DateFormat.jm().format(event.endDateTime)}.", style: Theme.of(context).textTheme.body1),
                    Text(S.of(context).predicted_something_water_usage_from_something_between_something(user.unitSystemOr().volumeText(context, orEmpty(event.flow)), event.display(context), intl.DateFormat.jm().format(event.startDateTime), intl.DateFormat.jm().format(event.endDateTime)), style: Theme.of(context).textTheme.body1),
                  actions: <Widget>[
                    FlatButton(child: Text(S.of(context).looks_good, textScaleFactor: 0.9,), onPressed: () async {
                      final flo = Provider.of<FloNotifier>(context2, listen: false).value;
                      final oauth = Provider.of<OauthTokenNotifier>(context2, listen: false).value;
                      final newEvent = event?.putFeedback(event?.selectedFixture);
                      if (onValueChanged != null) {
                        onValueChanged(event, newEvent);
                      }
                      Navigator.of(context2).pop();
                      try {
                        await flo.putFloDetectFeedback2(
                            newEvent.computationId,
                            newEvent.start,
                            newEvent.feedback,
                            authorization: oauth.authorization);
                      } catch (err) {
                        Fimber.e("", ex: err);
                      }
                    }),
                    FlatButton(child: Text(S.of(context).wrong_fixture, textScaleFactor: 0.9), onPressed: () {
                      Navigator.of(context2).pop();
                      showDialog(context: context, builder: (context2) =>
                          AlertDialog(
                            title: Text(S.of(context).classify_fixture),
                            content: Column(children:
                            Fixture.FIXTURES.where((it) => it != event.selectedFixture).map((it) =>
                                ListTile(title: Text(Fixture.displayByName(context, it)), onTap: () async {
                                  final flo = Provider.of<FloNotifier>(context2, listen: false).value;
                                  final oauth = Provider.of<OauthTokenNotifier>(context2, listen: false).value;
                                  final newEvent = event?.putFeedback(it);
                                  if (onValueChanged != null) {
                                    onValueChanged(event, newEvent);
                                  }
                                  Navigator.of(context2).pop();
                                  try {
                                    await flo.putFloDetectFeedback2(
                                        newEvent.computationId,
                                        newEvent.start,
                                        newEvent.feedback,
                                        authorization: oauth.authorization);
                                  } catch (err) {
                                    Fimber.e("", ex: err);
                                  }
                                },)
                            ).toList(),
                              mainAxisSize: MainAxisSize.min,
                            ),
                          )
                      );
                    },),
                    FlatButton(child: Text(S.of(context).cancel, textScaleFactor: 0.9), onPressed: () {
                      Navigator.of(context2).pop();
                    },),
                  ]),
              )));
      } else {
        showDialog(context: context, builder: (context2) =>
            Theme(data: floLightThemeData,
                child: Builder(builder: (context) => AlertDialog(
                  title: Text(S.of(context).reclassify_fixture),
                  content:
                  Column(children: <Widget>[
                    Text(S.of(context).please_select_the_fixture),
                    Column(children:
                    Fixture.FIXTURES.where((it) => it != event.selectedFixture).map((it) =>
                        ListTile(title: Text(Fixture.displayByName(context, it)), onTap: () async {
                          final flo = Provider.of<FloNotifier>(context, listen: false).value;
                          final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
                          final newEvent = event?.putFeedback(it);
                          if (onValueChanged != null) {
                            onValueChanged(event, newEvent);
                          }
                          Navigator.of(context2).pop();
                          try {
                            await flo.putFloDetectFeedback2(
                                newEvent.computationId,
                                newEvent.start,
                                newEvent.feedback,
                                authorization: oauth.authorization);
                          } catch (err) {
                            Fimber.e("", ex: err);
                          }
                        },)
                    ).toList(),
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ],
                    mainAxisSize: MainAxisSize.min,
                  ),
                ),
                )
            )
        );
      }
    });
  }
}

class FloDetectDonut extends StatefulWidget {

  FloDetectDonut({Key key,
    @required
    this.floDetect,
    this.isDummy = false,
    this.hasData = false,
  }): super(key: key);

  final FloDetect floDetect;
  final bool isDummy;
  final bool hasData;

  @override
  _FloDetectDonut createState() => _FloDetectDonut();
}

class _FloDetectDonut extends State<FloDetectDonut> {
  bool _loading = true;
  StreamController<PieTouchResponse> _chartController;
  Fixture _fixture;
  List<PieChartSectionData> _sections;

  @override
  void initState() {
    super.initState();
    _loading = true;

    _fixture = or(() => widget?.floDetect?.fixtures?.first);
    Fimber.d("_fixtures: ${widget?.floDetect?.fixtures}");
    Fimber.d("_fixture: ${_fixture}");

    _chartController = StreamController();
    _chartController.stream.distinct().listen((details) {
      if (details?.sectionData == null) {
        return;
      }
      final i = _sections?.indexOf(details.sectionData) ?? -1;
      if (i >= 0) {
        setState(() {
          _fixture = widget?.floDetect?.fixtures[i];
        });
      }
    });

    Future.delayed(Duration.zero, () async {
      _loading = false;
      if (mounted) {
        setState(() {
        });
      }
    });
  }

  @override
  void didUpdateWidget(FloDetectDonut oldWidget) {
    if (oldWidget.floDetect != widget.floDetect) {
      _fixture = or(() => widget?.floDetect?.fixtures?.first);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _chartController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserNotifier>(context).value;
    final isEmpty = widget?.floDetect?.fixtures?.isEmpty ?? true;
    final location = Provider.of<CurrentLocationNotifier>(context).value;
    final bool isSubscribed = (location?.subscription?.isActive ?? false);
    if (widget?.floDetect?.fixtures?.isEmpty ?? true) return Container();
    if ((widget?.floDetect?.isLearning ?? false) && !widget.isDummy) {
          _sections = <PieChartSectionData>[
            PieChartSectionData(
              color: Color(0xFFF0F4F8),
              value: 1,
              title: "",
              radius: 40,
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffffffff)),
            )
          ];
    } else {
      _sections = orEmpty(widget?.floDetect?.fixtures).map((fixture) =>
          PieChartSectionData(
            color: fixtureColor(fixture.type),
            value: orEmpty(fixture.gallons),
            title: "",
            radius: _fixture == fixture ? 48 : 40,
            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffffffff)),
          )
      ).toList();
    }
    //final hasData = widget.floDetect != null || _fixture != null;
    if (isSubscribed && (widget.floDetect?.isLearning ?? false)) {
      return Stack(children: <Widget>[
        Align(alignment: Alignment.center, child: Container(width: 290, height: 290,
          child: Padding(padding: EdgeInsets.all(70), child: Column(children: <Widget>[
            AutoSizeText(ReCase(S.of(context).learning_).titleCase, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center,),
            SizedBox(height: 10,),
            AutoSizeText(S.of(context).fixture_learning_description, style: Theme.of(context).textTheme.subtitle, textAlign: TextAlign.center,),
          ],
            mainAxisAlignment: MainAxisAlignment.center,
          )),
        )),
        Align(alignment: Alignment.center, child: Container(width: double.infinity, height: 290, child: AspectRatio(
            aspectRatio: 1,
            child:
            FlChart(key: widget.key,
              chart: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                      touchResponseStreamSink: _chartController.sink
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 95,
                  sections: _sections,
                ),
              ),
            )
        ))),
      ],
        alignment: Alignment.center,
      );
    }
    else if (!widget.hasData && isSubscribed) {
      _sections = <PieChartSectionData>[
        PieChartSectionData(
          color: Color(0xFFF0F4F8),
          value: 1,
          title: "",
          radius: 40,
          titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffffffff)),
        )
      ];
      return Stack(children: <Widget>[
      Align(alignment: Alignment.center, child: Container(width: 290, height: 290,
        child: Padding(padding: EdgeInsets.all(70), child: Column(children: <Widget>[
          Text(S.of(context).no_fixture_data_detected, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center,),
          SizedBox(height: 10,),
          Text(S.of(context).no_fixture_data_detected_description, style: Theme.of(context).textTheme.subtitle, textAlign: TextAlign.center,),
        ],
          mainAxisAlignment: MainAxisAlignment.center,
        )),
      )),
        Align(alignment: Alignment.center, child: Container(width: double.infinity, height: 290, child: AspectRatio(
            aspectRatio: 1,
            child:
            FlChart(key: widget.key,
              chart: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                      touchResponseStreamSink: _chartController.sink
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 95,
                  sections: _sections,
                ),
              ),
            )
        ))),
      ],
        alignment: Alignment.center,
      );
    }
    return Column(children: <Widget>[
      Stack(children: <Widget>[
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Center(key: ValueKey(_fixture), child: Column(children: <Widget>[
          fixtureButton2(_fixture.type),
          SizedBox(height: 5),
          Text(_fixture?.display(context), style: TextStyle(
            color: fixtureColor(_fixture.type)
          )),
          SizedBox(height: 10),
          //Text(UnitSystem.imperialUs.volumeText(context, _fixture.gallons ?? 0, inUnit: user.unitSystem), style: TextStyle(color: Colors.black), textScaleFactor: 1.1,),
          Text(user.unitSystemOr().volumeText(context, orEmpty(_fixture.gallons)), style: TextStyle(color: Colors.black), textScaleFactor: 1.1,),
          SizedBox(height: 3),
          Text("${intl.NumberFormat("#.#").format(orEmpty(_fixture.ratio) * 100)}%", style: TextStyle(color: Colors.black.withOpacity(0.6))),
        ],
          mainAxisAlignment: MainAxisAlignment.center,
        ))),
        Align(alignment: Alignment.topCenter, child: Container(width: double.infinity, height: 290, child: AspectRatio(
            aspectRatio: 1,
            child:
            FlChart(key: widget.key,
              chart: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(
                        touchResponseStreamSink: _chartController.sink
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 95,
                    sections: _sections,
                    ),
              ),
            )
        ))),
      ],
            alignment: Alignment.center,
          ),
      SizedBox(height: 5),
      Align(alignment: Alignment.topCenter, child: SingleChildScrollView(child: Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Row(children:
          !widget.isDummy ? orEmpty(widget?.floDetect?.fixtures).where((fixture) => (fixture?.gallons ?? 0) != 0).map((fixture) =>
          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child:
          _fixture == fixture ? Animator(tween: Tween(begin: 1.0, end: 1.1),
              key: UniqueKey(),
              tickerMixin: TickerMixin.tickerProviderStateMixin,
              duration: Duration(milliseconds: 150),
              builder: (anim) =>
                  Transform.scale(scale: anim.value, child: FixtureButton(fixture, shadowEnabled: _fixture == fixture, onPressed: () {
            setState(() {
              _fixture = fixture;
            });
          },)))
              : FixtureButton(fixture, shadowEnabled: _fixture == fixture, onPressed: () {
            setState(() {
              _fixture = fixture;
            });
          })
          )
          ).toList() : 
       <Widget>[
            SizedBox(width: 15),
            ToiletButton(),
            SizedBox(width: 15),
            ShowerButton(),
            SizedBox(width: 15),
            FaucetButton(),
            SizedBox(width: 15),
            ApplianceButton(),
            SizedBox(width: 15),
            PoolButton(),
            SizedBox(width: 15),
            IrrigationButton(),
            SizedBox(width: 15),
            OtherFixtureButton(),
            SizedBox(width: 15),
       ],
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
          )),
            scrollDirection: Axis.horizontal,
          )
      ),
      SizedBox(height: 5),
      Padding(padding: EdgeInsets.all(20), child: OutlineButton(
            padding: EdgeInsets.all(15),
            shape: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            ),
            child: Row(children: [
            Text(user.unitSystemOr().volumeText(context, orEmpty(widget.floDetect?.gallons)), style: TextStyle(color: Colors.black), textScaleFactor: 1.2,),
            SizedBox(width: 10),
            Text(S.of(context).spent_in_total, style: TextStyle(color: Colors.black.withOpacity(0.6))),
          ],
              mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
              onPressed: () {},
          )),
  ],
      mainAxisSize: MainAxisSize.min,
    );
  }
}

class BlurContainer extends StatelessWidget {
  const BlurContainer(this.child, {Key key,
    this.enabled = true,
  }) : super(key: key);

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return enabled ? Stack(
      //fit: StackFit.expand,
      children: <Widget>[
        child,
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3.0,
            sigmaY: 3.0,
          ),
          child: Container(
            //width: 1,
            //height: 1,
            color: Colors.transparent,
          ),
        ),
      ],
    ) : child;
  }
}
