// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:built_collection/built_collection.dart';
import 'package:flotechnologies/main.dart';
import 'package:flotechnologies/model/device.dart';
import 'package:flotechnologies/model/location.dart';
import 'package:flotechnologies/model/oauth_token.dart';
import 'package:flotechnologies/model/registration_payload2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flotechnologies/model/flo.dart';
import 'dart:io' show Platform;
import 'package:faker/faker.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  final username = Platform.environment["FLO_USERNAME"] ?? "dbaena@gmail.com";
  final password = Platform.environment["FLO_PASSWORD"] ?? "Flo12345678";
  if (username == null) return;
  if (password == null) return;
  final flo = Flo.createProd();
  final tokenFuture = Observable.fromFuture(flo.loginByUsername(username, password)).shareReplay(maxSize: 1);
  //final tokenFuture = Observable.defer(() => Stream.fromFuture(flo.loginByUsername(username, password))).map((it) => it.body).shareReplay();
  //final BehaviorSubject<OauthToken> tokenSub = BehaviorSubject();
  //flo.loginByUsername(username, password).then((it) => it.body).then((it) => tokenSub.add(it));

  test('flo.lists2()', () async {
    final res = await flo.listsById(["prv", "pipe_type"].join(","));
    print("${res.body}");
  });
  test('flo.lists()', () async {
    final res = await flo.lists({"prv", "pipe_type"});
    print("${res.body}");
  });
  /*
  test('flo.locationProfiles()', () async {
    final res = await flo.locationProfiles();
    print("${res.body}");
  });
  */
  test('flo.getAlarmEventsByDevice()', () async {
    final token = await tokenFuture.first;

    /*
    final waterUsage2 = await flo.waterUsage(startDate: DateTime.now().toIso8601String(), authorization: token.authorization);
    print("${waterUsage2}");
    print("${waterUsage2.body}");
    */

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    final locationIds = userRes.body.locations;
    final Iterable<Device> devices = await Observable.fromIterable(locationIds)
        .flatMap((it) => Observable.fromFuture(flo.getLocation(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .flatMap((it) => Observable.fromIterable(it.devices ?? []))
        .flatMap((it) => Observable.fromFuture(flo.getDevice(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .toList();
    try {

    final alerts = await Stream.fromIterable(devices)
        .asyncMap((device) async {
      final res = await flo.getAlertsByDevice(device.macAddress,
          authorization: token.authorization);
      return res.body;
    }).toList();
    print("$alerts");
    } catch (err) {
    }
    try {
    final alerts = await Stream.fromIterable(devices)
        .asyncMap((device) async {
      final res = await flo.getAlertsByDevice(device.macAddress,
          authorization: token.authorization);
      return res.body;
    }).toList();
    print("$alerts");
    } catch (err) {
    }
  });
  test('flo.getAlarmEventsByLocation()', () async {
    final token = await tokenFuture.first;

    /*
    final waterUsage2 = await flo.waterUsage(startDate: DateTime.now().toIso8601String(), authorization: token.authorization);
    print("${waterUsage2}");
    print("${waterUsage2.body}");
    */

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    final locationIds = userRes.body.locations;
    final List<Location> locations = await Observable.fromIterable(locationIds)
        .flatMap((location) => Observable.fromFuture(flo.getLocation(location.id, authorization: token.authorization))
        .map((it) => it.body).map((it) => it.rebuild((b) => b..id = location.id))
    ).toList();
    //print("${BuiltList<Location>(locations)}");
    //final location = locations.where((it) => it.address != null).first;
    await Stream.fromIterable(locations)
    .asyncMap((location) async {
      final res = await flo.getAlertsByLocation(location.id,
          authorization: token.authorization);
      return res.body;
    }).toList();
    /*
    final res = await flo.getAlarmEventsByLocation(location.id,
        authorization: token.authorization);
    print("res: ${res}");
    print("res.body: ${res?.body}");
    */
  });
  test('flo.getAlarms()', () async {
    final token = await tokenFuture.first;

    /*
    final waterUsage2 = await flo.waterUsage(startDate: DateTime.now().toIso8601String(), authorization: token.authorization);
    print("${waterUsage2}");
    print("${waterUsage2.body}");
    */

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    print("userRes.body: ${userRes?.body?.alertsSettings}");
    final res = await flo.getAlarms(
        isInternal: true,
        //isShutoff: false,
        //active: true,
        authorization: token.authorization);
    print("res: ${res}");
    print("res.body: ${res?.body}");
  });
  test('flo water usage averages', () async {
    final token = await tokenFuture.first;

    /*
    final waterUsage2 = await flo.waterUsage(startDate: DateTime.now().toIso8601String(), authorization: token.authorization);
    print("${waterUsage2}");
    print("${waterUsage2.body}");
    */

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);

    final locationIds = userRes.body.locations;
    final List<Location> locations = await Observable.fromIterable(locationIds)
        .flatMap((location) => Observable.fromFuture(flo.getLocation(location.id, authorization: token.authorization))
        .map((it) => it.body).map((it) => it.rebuild((b) => b..id = location.id))
    ).toList();
    //print("${BuiltList<Location>(locations)}");
    final location = locations.where((it) => it.address != null).first;
    print("${location}");
    //final waterUsage = await flo.waterUsage(locationId: location.id, authorization: token.authorization).then((it) => it.body);
    final waterUsageAvg = await flo.waterUsageAveragesLocation(locationId: location.id, authorization: token.authorization);
    print("waterUsageAvg: ${waterUsageAvg}");
    print("waterUsageAvg.body: ${waterUsageAvg?.body}");
  });
  test('flo.waterUsageWeek', () async {
    final token = await tokenFuture.first;

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);

    final locationIds = userRes.body.locations;
    final List<Location> locations = await Observable.fromIterable(locationIds)
        .flatMap((location) => Observable.fromFuture(flo.getLocation(location.id, authorization: token.authorization))
        .map((it) => it.body).map((it) => it.rebuild((b) => b..id = location.id))
    ).toList();
    final location = locations.where((it) => it.address != null).first;
    print("${location}");
    final waterUsage = await flo.waterUsageWeekLocation(locationId: location.id, authorization: token.authorization);
    print("${waterUsage}");
    print("${waterUsage?.bodyString}");
    print("${waterUsage?.body}");
  });
  test('flo.waterUsageToday', () async {
    final token = await tokenFuture.first;

    /*
    final waterUsage2 = await flo.waterUsage(startDate: DateTime.now().toIso8601String(), authorization: token.authorization);
    print("${waterUsage2}");
    print("${waterUsage2.body}");
    */

    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);

    final locationIds = userRes.body.locations;
    final List<Location> locations = await Observable.fromIterable(locationIds)
        .flatMap((location) => Observable.fromFuture(flo.getLocation(location.id, authorization: token.authorization))
        .map((it) => it.body).map((it) => it.rebuild((b) => b..id = location.id))
    ).toList();
    //print("${BuiltList<Location>(locations)}");
    final location = locations.where((it) => it.address != null).first;
    print("${location}");
    //final waterUsage = await flo.waterUsage(locationId: location.id, authorization: token.authorization).then((it) => it.body);
    final waterUsage = await flo.waterUsageTodayLocation(locationId: location.id, authorization: token.authorization);
    print("${waterUsage}");
    print("${waterUsage.body}");
  });
  test('flo locations', () async {
    final token = await tokenFuture.first;
    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    final locationIds = userRes.body.locations;
    /*
    final List<Location> locations = await Stream.fromIterable(locationIds)
        .asyncMap((it) => flo.getLocation(it.id, authorization: authorization)).map((it) => it.body).toList();
    print("${BuiltList<Location>(locations)}");
    */
    final List<Location> locations2 = await Observable.fromIterable(locationIds)
        .flatMap((it) => Observable.fromFuture(flo.getLocation(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .toList();
    print("${BuiltList<Location>(locations2)}");
  });

  test('flo.getDevice()', () async {
    final token = await tokenFuture.first;
    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    final locationIds = userRes.body.locations;
    final List<Device> devices = await Observable.fromIterable(locationIds)
        .flatMap((it) => Observable.fromFuture(flo.getLocation(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .flatMap((it) => Observable.fromIterable(it.devices ?? []))
        .flatMap((it) => Observable.fromFuture(flo.getDevice(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .toList();
    print("${BuiltList<Device>(devices)}");
  });
  test('flo.installDevice()', () async {
    final token = await tokenFuture.first;
    final userId = token.userId;
    final userRes = await flo.getUser(userId, authorization: token.authorization);
    final locationIds = userRes.body.locations;
    final Device device = await Observable.fromIterable(locationIds)
        .flatMap((it) => Observable.fromFuture(flo.getLocation(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .flatMap((it) => Observable.fromIterable(it.devices ?? []))
        .flatMap((it) => Observable.fromFuture(flo.getDevice(it.id, authorization: token.authorization)))
        .map((it) => it.body)
        .first;
    print(device);
    flo.installDevice(device.macAddress, authorization: null);
  });

  test('flo.getUser()', () async {
    final token = await tokenFuture.first;
    final userRes = await flo.getUser(token.userId, authorization: token.authorization);
    expect(userRes.body != null, true);
    /*
    User(
      ..id = 'cc922c4f-f923-4e84-a910-ffffffffffff',
      ..email = 'andrew@flotechnologies.com',
      ..isActive = true,
      ..firstName = 'Andrew',
      ..lastName = 'Chen',
      ..phoneMobile = '+886910161616',
      ..locations = [Locations((b) =>
        ..id = '449ccbff-cfeb-49aa-8005-ffffffffffff',
      )],
      locationRoles = [LocationRoles (
        ..locationId = '449ccbff-cfeb-49aa-8005-ffffffffffff',
        ..roles = ['owner'],
      )],
      accountRole = AccountRole (
        ..accountId = '52150f9f-78e1-4cf9-81f8-ffffffffffff',
        ..roles = ['owner'],
      ),
      account = Account(
        ..id = 'ffffffff-78e1-4cf9-81f8-ffffffffffff',
      ),
    )
    */
  });
  /*
  test('flo.registration()', () async {
    final flo = Flo.createDefault();
    //print(flo.clientId);
    //print(flo.clientSecret);
    //print(flo.client.baseUrl);
    final tokenRes = await flo.registration2(RegistrationPayload2((b) => b
      ..email = "andrew+0607@flotechnologies.com"
      ..password = "Xxxx0000"
      ..firstName = "Andrew"
      ..lastName = "Chen"
      ..country = "us"
      ..phone = "+13104043914"
    ));
    print(tokenRes);
    print(tokenRes.body);
    expect(tokenRes.body != null, true);
  });
  */
}