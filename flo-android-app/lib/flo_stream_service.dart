import 'dart:async';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'package:uuid/uuid.dart';
import 'model/device.dart';
import 'model/health_test.dart';
import 'model/serializers.dart';
import 'model/telemetries.dart';
import 'model/telemetry2.dart';
import 'model/valve.dart';
import 'model/will.dart';
import 'model/telemetry.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FloStreamService {
  Future<bool> awaitOnline(String deviceId) async {
    return Observable(device(deviceId))
      .debounceTime(Duration(seconds: 3))
      .map((it) => it.isConnected ?? false)
      .map((it) {
        Fimber.d("awaitOnline: isConnected: $it");
        return it;
      })
      .firstWhere((it) => it);
  }

  Stream<Telemetry> telemetry(String deviceId);

  Stream<Device> device(String deviceId);

  Stream<HealthTest> healthTest(String deviceId) {
    return device(deviceId).map((it) => it.healthTest);
  }

  Stream<Telemetry2> telemetry2(String deviceId) {
    return device(deviceId).map((it) => it.telemetries.current);
  }

  Future<FirebaseUser> login(String token);
}

const ONLINE = "online";
const OFFLINE = "offline";

class FloStreamServiceMocked extends FloStreamService {
  @override
  Future<bool> awaitOnline(String deviceId) async {
    return Future.delayed(Duration(seconds: 5), () => true);
  }

  @override
  Stream<Telemetry> telemetry(String deviceId) {
    return Observable.range(0, 1<<16)
      .interval(Duration(seconds: 1))
      .doOnData((it) => print("$it"))
      .map((it) => Telemetry.random)
      .asBroadcastStream(onCancel: (subscription) {
        subscription.cancel();
        Fimber.d("onCancel");
    });
  }

  @override
  Stream<Telemetry2> telemetry2(String deviceId) {
    return Observable.range(0, 1<<16)
        .interval(Duration(seconds: 1))
        .doOnData((it) => print("$it"))
        .map((it) => Telemetry2.random)
        .asBroadcastStream(onCancel: (subscription) {
      subscription.cancel();
      Fimber.d("onCancel");
    });
  }

  @override
  Stream<Device> device(String deviceId) {
      return Observable.range(0, 1<<16)
          .interval(Duration(seconds: 1))
          .doOnData((it) => {
            Fimber.d("onDevice: healthTest.status: ${_healthTest?.status}")
          })
          .map((it) => Device.empty.rebuild((b) => b
            ..valve = Valve((b) => b..lastKnown = Valve.OPEN).toBuilder()
            ..valveState = Valve((b) => b..lastKnown = Valve.CLOSED).toBuilder()
            ..telemetries = Telemetries((b) => b..current = Telemetry2.random.toBuilder()).toBuilder()
            ..healthTest = _healthTest?.toBuilder(),
            //..isConnected = true
          ));
  }

  @override
  Future<FirebaseUser> login(String token) async {
    return null;
  }

  Observable<Device> _device;

  HealthTest _healthTest = HealthTest((b) => b..status = HealthTest.COMPLETED
    ..startDate = DateTime.now().subtract(Duration(minutes: 3)).toString()
    ..endDate = DateTime.now().toString()
  );

  @override
  Stream<HealthTest> healthTest(String deviceId) {
    return Observable.concat([
      Observable.fromFuture(Future(() async {
        _healthTest = _healthTest.rebuild((b) => b..status = HealthTest.PENDING
          ..startDate = DateTime.now().toString()
          ..endDate = DateTime.now().add(Duration(minutes: 1)).toString()
        );
        return _healthTest;
      })).delay(Duration(seconds: 3)),
      Observable.fromFuture(Future(() async {
        _healthTest = _healthTest.rebuild((b) => b..status = HealthTest.RUNNING
            ..startDate = DateTime.now().toString()
            ..endDate = DateTime.now().add(Duration(minutes: 2)).toString()
          );
        return _healthTest;
      })).delay(Duration(seconds: 3)),
      Observable.fromFuture(Future(() async {
      _healthTest = _healthTest.rebuild((b) => b
        ..status = $([HealthTest.CANCELLED, HealthTest.COMPLETED, HealthTest.COMPLETED, HealthTest.COMPLETED]).shuffled().first
        ..leakType = $(HealthTest.LEAK_TYPES).shuffled().first
        ..startDate = DateTime.now().subtract(Duration(minutes: 3)).toString()
        ..endDate = DateTime.now().toString()
        ..leakLossMinGal = faker.randomGenerator.decimal(scale: 100.0)
        ..leakLossMaxGal = faker.randomGenerator.decimal(scale: 100.0)
        ..startPressure = faker.randomGenerator.decimal(scale: 100.0)
        ..endPressure = faker.randomGenerator.decimal(scale: 100.0)
      );
      return _healthTest;
      })).delay(Duration(seconds: 10)),
    ]);
  }
}


class FloFirestoreService extends FloStreamService {
  static const String DEVICES = "devices";

  @override
  Stream<Device> device(String deviceId) {
    Fimber.d("Firestore: subscribes: $deviceId");
    return Firestore.instance.collection(DEVICES).document(deviceId).snapshots().map((it) =>
      serializers.deserializeWith<Device>(Device.serializer, it.data)
    )
        .asBroadcastStream(onCancel: (sub) => sub.cancel())
    ;
  }

  @deprecated
  @override
  Stream<Telemetry> telemetry(String deviceId) { // v2 to v1
    return telemetry2(deviceId)
      .map((it) => Telemetry((b) => b
        ..flow = it.flow
        ..pressure = it.pressure
        ..temperature = it.temperature
      ));
  }

  @override
  Future<FirebaseUser> login(String token) async {
    return await FirebaseAuth.instance.signInWithCustomToken(token: token);
  }
}
