import 'dart:math';


import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:recase/recase.dart';
import 'package:superpower/superpower.dart';

import 'generated/i18n.dart';
import 'model/alarm.dart';
import 'model/alert.dart';
import 'model/device.dart';
import 'model/location.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';


class AlertsPage extends StatefulWidget {
  AlertsPage({
    Key key,
    this.filterEnabled = true,
  }) : super(key: key);
  final bool filterEnabled;

  State<AlertsPage> createState() => AlertsPageState();
}

class AlertsPageState extends State<AlertsPage> with SingleTickerProviderStateMixin, AfterLayoutMixin<AlertsPage>, AutomaticKeepAliveClientMixin<AlertsPage> {
//class AlertsPageState extends State<AlertsPage> with SingleTickerProviderStateMixin, AfterLayoutMixin<AlertsPage> {

  TabController tabController;

  RefreshController _refreshController;
  ScrollController _scrollController;
  bool _loading = true;
  bool _loadingMore = true;
  bool _filterEnabled = true;

  @override
  void didUpdateWidget(AlertsPage oldWidget) {
    if (oldWidget.filterEnabled != widget.filterEnabled) {
      _filterEnabled = widget.filterEnabled;
      super.didUpdateWidget(oldWidget);
    } else {
      super.didUpdateWidget(oldWidget);
    }
  }

  @override
  void initState() {
    super.initState();
    Fimber.d("initState");
    _refreshController = RefreshController(initialRefresh: false);
    _scrollController = ScrollController();
    tabController = TabController(
      length: 3,
      vsync: this,
    );
    _filterEnabled = widget.filterEnabled;
    _page = 1;
    //setState(() {
    //  _loading = true;
    //});
    /*
    Future.delayed(Duration(microseconds: 500), () {
      _refreshController.requestRefresh();
      //setState(() {
      //  _loading = false;
      //});
    });
    Future.delayed(Duration(microseconds: 5000), () {
      _refreshController.refreshCompleted();
      //setState(() {
      //  _loading = false;
      //});
    });
    */

    Future.delayed(Duration.zero, () async {
      final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
      final locationsConsumer = Provider.of<LocationsNotifier>(context);
      final locationName = locationConsumer.value.nickname ?? locationConsumer.value.address;
      final location = locationConsumer.value;
      final flo = Provider.of<FloNotifier>(context, listen: false).value;
      final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
      //final alarms = Provider.of<AlarmsNotifier>(context, listen: false).value;
      final alarmsProvider = Provider.of<AlarmsNotifier>(context, listen: false);
      //_selectedLocations.add(location);
      final Iterable<Device> devices = locationsConsumer.value.where((it) => it?.devices?.isNotEmpty ?? false)
          .expand((location) => location.devices);
      //Fimber.d("devices: ${devices.map((it) => it.displayName)}");
      final selectedDevicesNotifier = Provider.of<SelectedDevicesNotifier>(context, listen: false);
      if (selectedDevicesNotifier.value.isNotEmpty) {
        Fimber.d("selectedDevicesNotifier: ${selectedDevicesNotifier.value.map((it) => it.displayName)}");
        _selectedDevices.clear();
        _selectedDevices.addAll(selectedDevicesNotifier.value);
        selectedDevicesNotifier.value = BuiltList<Device>();
      } else {
        _selectedDevices.addAll(devices);
      }
      //Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");
      //_selection.putIfAbsent(S.of(context).all, () => devices.toSet());
      locationsConsumer.value.forEach((location) => _selection.putIfAbsent(location.displayName, () => location.devices.toSet()));
      _selection.removeWhere((k, v) => v.isEmpty);
      _selection.entries.forEach((it) {
        Fimber.d("selection: ${it.key} : ${it.value.map((v) => v.displayName)}");
      });

      Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.nickname)}");
      try {
        final alarms = (await flo.getAlarms(authorization: oauth.authorization)).body;
        alarmsProvider.value = alarms.items;
        await fetch(context);
        //$(_alerts).sortedBy((it) => it)
        setState(() {
          _loading = false;
        });
      } catch (err) {
        setState(() {
          _loading = false;
        });
        Fimber.e("", ex: err);
      }
    });
  }

  // <locationId, devcies>
  Map<String, Set<Device>> _selection = {};
  List<Alert> _alerts = [];
  //Set<Location> _selectedLocations = {};
  Set<Device> _selectedDevices = {};
  //Set<Device> _selectedDevicesResolved = {};
  Set<String> _alertSeverities = {Alarm.CRITICAL, Alarm.WARNING, Alarm.INFO};
  Set<String> _alertResolutionTypes = {Alert.CLEARED, Alert.SNOOZED, Alert.CANCELLED};
  int _page = 1;

  fetch(BuildContext context, {bool isReset = false, int page = 1, bool orThrow = false}) async {
    final flo = Provider.of<FloNotifier>(context, listen: false).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context, listen: false);
    final locations = Provider.of<LocationsNotifier>(context, listen: false).value;
    final Iterable<Device> devices = locations.where((it) => it?.devices?.isNotEmpty ?? false)
        .expand((location) => location.devices);

    try {
      Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");
      final Iterable<Alert> alerts = (await flo.getAlerts(
          deviceIds: devices.map((it) => it.id).toSet(),
          page: page,
          authorization: oauth.authorization)).body
          .items
          .map((alert) => alert.rebuild((b) => b
            ..device = or(() => devices.firstWhere((device) => device.id == alert.deviceId).toBuilder())
      ));
      Fimber.d("getAlerts.length: ${alerts.length}");
      if (alerts.isEmpty) {
        Fimber.d("getAlerts(${page}) is empty");
        throw RangeError("");
      }
      if (isReset) {
        _alerts = alerts?.toList() ?? const <Alert>[];
      } else {
        _alerts.addAll(alerts ?? const <Alert>[]);
        _alerts = $(_alerts).distinct().toList();
      }
      alertsStateConsumer.value =
          alertsStateConsumer.value.rebuild((b) => b..dirty = false);
      Fimber.d("alertsStateConsumer.value: ${alertsStateConsumer.value.dirty}");
    } catch (err) {
      if (orThrow) {
        throw err;
      } else {
        Fimber.e("alertsState", ex: err);
      }
    } finally {
      //Fimber.d("getAlerts.length totally: ${_alerts.length}");
    }
  }

  List<Alert> get _selectedAlerts => or(() => _alerts.where((alert) => _selectedDevices.any((device) => device.id == alert.deviceId))
      ?.toList())
      ?? const <Alert>[];
  List<Alert> get _selectedPendingAlerts => _selectedAlerts
      ?.where((alert) => alert.alarm.severity != Alarm.INFO)
      ?.toList()
      ?? const <Alert>[];
  List<Alert> get _selectedResolvedAlerts => _selectedAlerts;

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final locationsConsumer = Provider.of<LocationsNotifier>(context);
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final locationName = locationConsumer.value.nickname ?? locationConsumer.value.address;
    final location = locationConsumer.value;
    //final devicesConsumer = Provider.of<DevicesNotifier>(context);
    //Fimber.d("${locationConsumer.value}");
    Fimber.d("$locationName");
    final alarms = Provider.of<AlarmsNotifier>(context, listen: false).value;
    final selectedDevicesNotifier = Provider.of<SelectedDevicesNotifier>(context);
    //Fimber.d("selectedDevicesNotifier: ${or(() => selectedDevicesNotifier.value.map((it) => it.displayName)})");
    if (selectedDevicesNotifier.value.isNotEmpty) {
      _selectedDevices.clear();
      //Future.delayed(Fut)
      _selectedDevices.addAll(selectedDevicesNotifier.value);
      Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");
      //selectedDevicesNotifier.value = BuiltList<Device>(); // Avoid recursive
    } else {
      /*
      final devices = locationsConsumer.value.where((it) => it?.devices?.isNotEmpty ?? false)
          .expand((location) => location.devices);
      _selectedDevices.addAll(devices);
      */
    }


    Widget body = Container();

    try {
    Fimber.d("${_selection}");
    Fimber.d("${_selection.entries}");
    _selection.entries.forEach((it) {
      Fimber.d("selection: ${it.key} : ${it.value.map((v) => v.displayName)}");
    });
    Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");

    List<Widget> headerList = const [];
    List<Widget> pendingAlertWidgets = const [];

    final selectedLocations = or(() => _selection.entries.where((it) => _selectedDevices.any((that) => it.value.any((v) => v.id == that.id)))) ?? <MapEntry<String, Set<Device>>>[];
    //final selectedLocation = or(() => _selection.entries.firstWhere((it) => it.value.difference(_selectedDevices).isEmpty).key);
    Fimber.d("selectedLocations: ${selectedLocations.map((it) => it.key)}");
    final selectedLocation = or(() => selectedLocations.first.key);
    Fimber.d("selectedLocation: $selectedLocation");

    final Iterable<Device> devices = or(() => locationsConsumer.value.where((it) => it?.devices?.isNotEmpty ?? false)
        .expand((location) => location.devices)) ?? <Device>[];
    _filterEnabled = devices.length > 1;
    headerList = [
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child:
      SwitchFlatButton(
        child: (checked) => Row(children: <Widget>[
        //Text("${locationConsumer.value.nickname ?? locationConsumer.value.address}",
        Text(selectedLocations.length == 1 ? selectedLocation ?? "" : S.of(context).multiple_locations,
          //textScaleFactor: 1.4,
          style: Theme.of(context).textTheme.subhead,
        ),
        SizedBox(width: 8),
          _filterEnabled ? Transform.rotate(angle: checked ? -pi/2 : pi/2, child: Icon(Icons.arrow_forward_ios, size: 18)) : Container(),
      ],),
          onPressed: _filterEnabled ? () async {
            //showBottomSheet(context: context, builder: (context2) {
            //});

            /*
              final List<Widget> locations = locationsConsumer.value.map((location) =>
                  SimpleCheckboxListTile(
                    dense: true,
                      controlAffinity:  ListTileControlAffinity.leading,
                    title: Text(location.nickname),
                value: _selectedLocations.contains(location.id), onChanged: (value) {
                  if (value) {
                    _selectedLocations.add(location);
                  } else {
                    _selectedLocations.remove(location);
                  }
              })
              ).toList();
              */
            final locations = or(() => locationsConsumer.value.where((it) => it?.devices?.isNotEmpty ?? false)) ?? <Location>[];
            final devices = locations.expand((it) => it.devices);

            Fimber.d("devices: ${devices.map((it) => it.displayName)}");
            Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");
            await showDialog(context: context, builder: (context2) =>
                Theme(data: floLightThemeData, child: AlertDialog(
                    content: SingleChildScrollView(child: Column(children: <Widget>[
                      Text(S.of(context).locations,),
                      SizedBox(height: 20),
                      ...locations.map((location) => Column(children: [
                        Text(location.nickname ?? "", textScaleFactor: 0.8),
                        ...location.devices.map((device) =>
                            SimpleCheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(device.nickname),
                                value: _selectedDevices.any((it) => it.id == device.id),
                                validator: (value) {
                                  if (value) {
                                    _selectedDevices.add(device);
                                  } else {
                                    _selectedDevices.remove(device);
                                  }
                                  if (_selectedDevices.isEmpty) {
                                    if (!value) {
                                      _selectedDevices.add(device);
                                    } else {
                                      _selectedDevices.remove(device);
                                    }
                                    return false;
                                  }
                                  return true;
                                },
                                onChanged: (value) {
                                  if (value) {
                                    _selectedDevices.add(device);
                                  } else {
                                    _selectedDevices.remove(device);
                                  }
                                  Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.nickname)}");
                                })
                        ).toList()
                      ],
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      ),
                      SizedBox(height: 10),
                    ],
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ))
                ))
            );
            setState(() {});
            return true;
          } : () {}),
      ),
      //AlertCriticalCard(),
      //AlertWarningCard(),
      //AlertWarningCard(),
      SizedBox(height: 3),
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child:
      Text(_selectedDevices.length == 1 ? or(() => _selectedDevices?.first?.displayName) : S.of(context).multiple_devices,
        style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white.withOpacity(0.5)),
      )),
    ];

    final alertsStateConsumer = Provider.of<AlertsStateNotifier>(context);
    Fimber.d("alertsStateConsumer.value.dirty: ${alertsStateConsumer.value.dirty}");
    if (alertsStateConsumer.value.dirty ?? false) {
      Future.delayed(Duration.zero, () async {
        await fetch(context, isReset: true);
        setState(() {
          _loading = false;
        });
      });
    }
    if (_loading) {
    //list = [Container()];
      return AlertsPlaceholder();
    }

    final List<Alert> selectedPendingAlerts = $(_selectedPendingAlerts)
        .distinctBy((alert) => "${alert.alarm?.id}${alert.deviceId}").toList()
        .map((alert) => alert.rebuild((b) => b
      ..alarm = or(() => alarms.firstWhere((alarm) => b.alarm.id == alarm.id).toBuilder()) ?? null
    ))
        .where((alert) => alert.status == Alert.TRIGGERED)
        .where((alert) => _alertSeverities.contains(alert?.alarm?.severity ?? Alarm.INFO))
        .where((it) => it.alarm != null)
        .toList()
      ..sort((that, it) => -that.createAtDateTime.compareTo(it.createAtDateTime));

    if (selectedPendingAlerts?.isEmpty ?? true) {
      pendingAlertWidgets = [SecureHome()];
    } else {
      pendingAlertWidgets = selectedPendingAlerts
            .map((alert) => Padding(padding: EdgeInsets.symmetric(vertical: 3), child: AlertCard(alert: alert)))
            .toList();
    }

    List<Widget> resolvedAlertWidgets = [];
    if (_selectedResolvedAlerts.isEmpty ?? true) {
      resolvedAlertWidgets = [
        Container(height: 200, child: Center(child: Text(S.of(context).no_alerts, style: TextStyle(color: Colors.white.withOpacity(0.5)))))
      ];
    } else {
      final sorted = _selectedResolvedAlerts.map((alert) => alert.rebuild((b) => b
        ..alarm = or(() => alarms.firstWhere((alarm) => b.alarm.id == alarm.id).toBuilder()) ?? null
      //..reason = Alert.CLEARED
        ..status = Alert.RESOLVED
      ))
          .where((it) => it.alarm != null)
          .where((alert) => _alertSeverities.contains(alert?.alarm?.severity ?? Alarm.INFO))
          .where((alert) => _alertResolutionTypes.contains(alert?.reason ?? Alert.CLEARED)).toList();
      sorted.sort((that, it) => -that.createAtDateTime.compareTo(it.createAtDateTime));
    resolvedAlertWidgets =
        sorted
            .map((alert) {
              return Padding(padding: EdgeInsets.symmetric(vertical: 3), child: AlertCard(alert: alert));
            })
            .toList();
    }

    List<Widget> resolvedAlertsHeader = [
      Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20), child:
      Row(children: <Widget>[
        Text("${S.of(context).activity_log} (${_selectedResolvedAlerts.isEmpty ? 0 : resolvedAlertWidgets.length})",
            style: Theme.of(context).textTheme.subhead
        ),
        Spacer(),
        SwitchFlatButton(
            text: (_) => Text(S.of(context).filter, style: Theme.of(context).textTheme.subhead),
            onPressed: () async {
              //showBottomSheet(context: context, builder: (context2) {
              //});

              Fimber.d("_selectedDevices: ${_selectedDevices.map((it) => it.displayName)}");
              await showDialog(context: context, builder: (context2) =>
                  Theme(data: floLightThemeData, child: AlertDialog(
                      content: SingleChildScrollView(child: Column(children: <Widget>[
                        Text(S.of(context).alert_types),
                        SizedBox(height: 20),
                        ...Alarm.SEVERITIES.map((it) =>
                            SimpleCheckboxListTile(
                                dense: true,
                                controlAffinity:  ListTileControlAffinity.leading,
                                title: Text(ReCase(it == Alarm.CRITICAL ? S.of(context).critical : it == Alarm.WARNING ? S.of(context).warning : S.of(context).info).titleCase),
                                value: _alertSeverities.contains(it),
                                validator: (value) {
                                  if (value) {
                                    _alertSeverities.add(it);
                                  } else {
                                    _alertSeverities.remove(it);
                                  }
                                  if (_alertSeverities.isEmpty) {
                                    if (!value) {
                                      _alertSeverities.add(it);
                                    } else {
                                      _alertSeverities.remove(it);
                                    }
                                    return false;
                                  }
                                  return true;
                                },
                                onChanged: (value) {
                                  if (value) {
                                    _alertSeverities.add(it);
                                  } else {
                                    _alertSeverities.remove(it);
                                  }
                                }),
                        ),
                        SizedBox(height: 15),
                        Text(S.of(context).resolution_types),
                        SizedBox(height: 15),
                        ...Alert.REASONS.map((it) =>
                            SimpleCheckboxListTile(
                                dense: true,
                                controlAffinity:  ListTileControlAffinity.leading,
                                title: Text(it == Alert.CLEARED ? S.of(context).cleared : it == Alert.SNOOZED ? S.of(context).ignored : S.of(context).cancelled),
                                value: _alertResolutionTypes.contains(it),
                                validator: (value) {
                                  if (value) {
                                    _alertResolutionTypes.add(it);
                                  } else {
                                    _alertResolutionTypes.remove(it);
                                  }
                                  if (_alertResolutionTypes.isEmpty) {
                                    if (!value) {
                                      _alertResolutionTypes.add(it);
                                    } else {
                                      _alertResolutionTypes.remove(it);
                                    }
                                    return false;
                                  }
                                  return true;
                                },
                                onChanged: (value) {
                                  if (value) {
                                    _alertResolutionTypes.add(it);
                                  } else {
                                    _alertResolutionTypes.remove(it);
                                  }
                                }),
                        ),
                        SizedBox(height: 10),
                      ],
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ))
                  ))
              );
              setState(() {});
              return true;
            }
        ),
     ],)
      ),
    ];


    /*
    Widget body = ListView(
      controller: _scrollController,
      children: list,
      key: widget.key,
    );
    */

    body = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          loadMore();
        }
      }, child: CustomScrollView(
      key: widget.key,
      controller: _scrollController,
      slivers: <Widget>[
        SliverAppBar(
          floating: true,
          title: Text(S.of(context).alerts, textScaleFactor: 1.4,),
          centerTitle: true,
          //leading: SimpleDrawerButton(icon: SvgPicture.asset('assets/ic_fancy_menu.svg'),
          leading: SimpleDrawerButton(icon: Container(),
            back: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          ),
        ),
        SliverList(delegate: SliverChildListDelegate(headerList)),
        /*
        SliverPersistentHeader(
          pinned: true,
            //floating: true,
            delegate: SimpleSliverPersistentHeaderDelegate(
          minHeight: 50,
          maxHeight: 50,
          child: Container(color: TinyColor(floBlueGradientTop).darken(3).color, child: Row(children: [
            /*
              SimpleChoiceChipWidget(
                validator: (_) => false,
                avatar: Icon(Icons.tune),
                backgroundColor: floBlue2,
                selectedColor: Colors.lightBlue[100],
                avatarBorder: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                child: Text("Filters"),
                onSelected: (selected) {
                },
              ),
            */
             Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Row(children:
                [
              SimpleChoiceChipWidget(
                validator: (_) => false,
                avatar: Icon(Icons.tune, size: 16),
                backgroundColor: floBlue2,
                selectedColor: Colors.lightBlue[100],
                avatarBorder: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                child: Text("Filters"),
                onSelected: (selected) {
                },
              ),

                  ...List.generate(10, (i) => faker.person.name()).map((name) => SimpleChoiceChipWidget(
                backgroundColor: floBlue2,
                selectedColor: Colors.lightBlue[100],
                avatarBorder: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                child: Text(name),
                onSelected: (selected) {
                },
              )
              ).toList(),

              SimpleChoiceChipWidget(
                validator: (_) => false,
                avatar: Icon(Icons.tune, size: 16),
                backgroundColor: floBlue2,
                selectedColor: Colors.lightBlue[100],
                avatarBorder: CircleBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                child: Text("Filters"),
                onSelected: (selected) {
                },
              ),
                ],
              )
              )
          )),]
          ),
          ),
        )
        ),
        */
        SliverPadding(padding: EdgeInsets.symmetric(vertical: 5)),
        SliverList(delegate: SliverChildListDelegate(pendingAlertWidgets)),
        //SliverPersistentHeader(delegate: SliverPersistentHeaderDelegate()),
        SliverList(delegate: SliverChildListDelegate(resolvedAlertsHeader)),
        /*
        SliverPersistentHeader(
            pinned: false,
            //floating: true,
            delegate: SimpleSliverPersistentHeaderDelegate(
              minHeight: 70,
              maxHeight: 70,
              child: Container(
                  color: TinyColor(floBlueGradientTop).darken(5).color,
                  child: Column(children: [
                  resolvedAlertsHeader
                  ])),
            )
        ),
        */
        SliverList(delegate: SliverChildBuilderDelegate((context, i) {
          if (i < resolvedAlertWidgets.length) {
            return resolvedAlertWidgets[i];
          } else {
            _page += 1;
            Future.delayed(Duration.zero, () async {
              if (_loadingMore) {
                await futureOr(() async {
                  try {
                    await fetch(context, page: _page, orThrow: true);
                  } catch (err) {
                    _loadingMore = false;
                  }
                  setState(() {});
                });
              }
            });
            return Visibility(visible: _loadingMore, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator())));
          }
        },
            childCount: resolvedAlertWidgets.length + 1
        )),
        SliverPadding(padding: EdgeInsets.symmetric(vertical: 15)),
      ],
    ));

    /*
    body = SmartRefresher(
        controller: _refreshController,
        //enableTwoLevel: true,
        onRefresh: () async {
          final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
          locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
          locationProvider.invalidate();
          //await Future.delayed(Duration(milliseconds: 500));
          //_scrollController.animateTo(_scrollController.position.minScrollExtent, duration: null, curve: null);
          //_refreshController.refreshCompleted();
        },
        child: body
    );
    */

    } catch (err) {
      Fimber.e("", ex: err);
    }
    return Builder(builder: (context) => SafeArea(child: body));
    }

  loadMore() {
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Fimber.d("");
    /*
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    //_refreshController.requestRefresh();
    if ((locationProvider.value?.dirty ?? false)) {
      Fimber.d("");
      _refreshController.requestRefresh();
    } else {
      _refreshController.refreshCompleted();
    }
    */
  }

  @override
  bool get wantKeepAlive => true;
}

class SimpleSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  SimpleSliverPersistentHeaderDelegate({
      @required this.minHeight,
      @required this.maxHeight,
      @required this.child,
      }) : super();
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(child: SizedBox.expand(child: child), elevation: shrinkOffset != 0 ? 8 : 0);
  }

  @override
  bool shouldRebuild(SimpleSliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
