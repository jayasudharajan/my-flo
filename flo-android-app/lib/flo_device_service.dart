import 'dart:io';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:rxdart/rxdart.dart';

import 'model/jsonrpc_response.dart';
import 'model/jsonrpc_response_bool.dart';
import 'model/jsonrpc_wifi_response.dart';
import 'model/jsonrpc.dart';
import 'model/token_jsonrpc.dart';
import 'model/token_params.dart';
import 'model/wifi.dart';
import 'model/wifi_station.dart';
import 'model/wifi_station_jsonrpc.dart';
import 'model/certificates_jsonrpc.dart';
import 'package:web_socket_channel/io.dart';
import 'model/certificates.dart';
//import 'package:json_rpc_2/json_rpc_2.dart';
//import "package:json_rpc_2/json_rpc_2.dart" as jsonrpc;
import 'package:flutter_okhttp_ws/flutter_okhttp_ws.dart';

/// Flo Device API via Websocket
abstract class FloDeviceService {

  Future<JsonRpcResponseBool> login(String token);

  Future<JsonRpcWifiResponse> scanWifi();

  Future<JsonRpcResponseBool> setCertificates(Certificates certs);

  Future<JsonRpcResponseBool> setWifiStationConfig(WifiStation station);

  /* TODO
  Future<bool> hasMultipleAp() async {
    return futureOr(getKernelVersion().then((it) => it), orElse: () => false);
  }
  */

  Future<JsonRpcResponse> getKernelVersion();

  Future<String> connect(String url, {String certificate});

}

class FloDeviceServiceMocked implements FloDeviceService {
  @override
  Future<JsonRpcResponse> getKernelVersion() async {
    return JsonRpcResponse((b) => b
    ..id = 0
    ..jsonrpc = "2.0"
    ..method = "get_kernel_version"
    ..result = ""
    );
  }

  @override
  Future<JsonRpcResponseBool> login(String token) async {
    return JsonRpcResponseBool((b) => b
    ..id = 0
    ..jsonrpc = "2.0"
    ..method = "login"
    ..result = true
    );
  }

  @override
  Future<JsonRpcWifiResponse> scanWifi() async {
    return JsonRpcWifiResponse((b) => b
    ..id = 0
    ..jsonrpc = "2.0"
    ..method = "scan_wifi_ap"
    ..result = ListBuilder([
      Wifi((b) => b
        ..ssid = "HomeRouter"
        ..encryption = "psk-mixed+tkip"
        ..signal = -60
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter"
        ..encryption = ""
        ..signal = -10
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter2"
        ..encryption = "psk2"
        ..signal = -70
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter3"
        ..encryption = "none"
        ..signal = -10
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter4"
        ..encryption = "psk2"
        ..signal = -30
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter5"
        ..encryption = "psk2"
        ..signal = -70
      ),
      Wifi((b) => b
        ..ssid = "NeighborsRouter6"
        ..encryption = "psk2"
        ..signal = -10
      ),
    ]));
  }

  @override
  Future<JsonRpcResponseBool> setCertificates(Certificates certs) async {
    return JsonRpcResponseBool((b) => b
    ..method = "set_certificates"
    ..id = 0
    ..jsonrpc = "2.0"
    ..result = true
    );
  }

  @override
  Future<JsonRpcResponseBool> setWifiStationConfig(WifiStation station) async {
    return JsonRpcResponseBool((b) => b
    ..method = "set_wifi_sta_config"
    ..id = 0
    ..jsonrpc = "2.0"
    ..result = true
    );
  }

  @override
  Future<String> connect(String url, {String certificate}) {
    return Future.value(null);
  }
}
/*
class FloDeviceServiceImpl2 implements FloDeviceService {
  BehaviorSubject<String> _subject = BehaviorSubject<String>();
  PublishSubject<String> _publishSubject = PublishSubject<String>();
  jsonrpc.Client client;

  FloDeviceServiceImpl2(String url) {
    final socket = IOWebSocketChannel.connect(url);
    //final socket = HtmlWebSocketChannel.connect(url);
    client = jsonrpc.Client(socket.cast<String>());
    client.listen();
  }

  Future<JsonRpcResponseBool> login(String token) {
    final method = 'login';
    final id = Random().nextInt(1<<32);
    return client.sendRequest(method, TokenParams((b) => b..token = token))
    .then((it) {
      print("${it}");
    })
    .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  Future<JsonRpcWifiResponse> scanWifi() {
    final method = 'scan_wifi_ap';
    final id = Random().nextInt(1<<32);
    return client.sendRequest(method)
    .then((it) {
      print("${it}");
    })
    .then((it) => JsonRpcWifiResponse.fromJson(it));
    //.then((it) => JsonRpcWifiResponse((b) => b..result = it));
  }

  Future<JsonRpcResponseBool> setCertificates(Certificates certs) {
    final method = 'set_certificates';
    final id = Random().nextInt(1<<32);
    return client.sendRequest(method,
      certs.toJson()
    )
    .then((it) {
      print("${it}");
    })
    .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  Future<JsonRpcResponseBool> setWifiStationConfig(WifiStation station) {
    final method = 'set_wifi_sta_config';

    final id = Random().nextInt(1<<32);
    return client.sendRequest(method, station.toJson())
    .then((it) {
      print("${it}");
    })
    .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  Future<JsonRpcResponse> getKernelVersion() {
    final method = 'get_kernel_version';

    final id = Random().nextInt(1<<32);
    return Future.value(null);
  }

}
*/

class FloDeviceServiceImpl implements FloDeviceService {
  final IOWebSocketChannel channel;
  BehaviorSubject<String> _subject = BehaviorSubject<String>();
  PublishSubject<String> _publishSubject = PublishSubject<String>();

  FloDeviceServiceImpl(this.channel) {
    channel.stream
        .listen((it) {
          print(it);
          _subject.add(it);
          _publishSubject.add(it);
        }, onError: (e) {
          Fimber.d("${e}", ex: e);
        });
  }

    /*
  connects(String url, {int port}) async {
    WebSocket ws = WebSocket.fromUpgradedSocket(socket);
    Stream.fromFuture(
      SecureSocket.connect(url, port, onBadCertificate: (cert) => true).then((socket) {
      })
      WebSocket.connect(url.toString(), headers: headers).then((webSocket) {
    }).catchError((error) => throw WebSocketChannelException.from(error)))
  }
    */

  factory FloDeviceServiceImpl.connects(url,
      {Iterable<String> protocols,
      Map<String, dynamic> headers,
      Duration pingInterval}) {

    return FloDeviceServiceImpl(IOWebSocketChannel.connect(
      url,
      protocols: protocols,
      headers: headers,
      pingInterval: pingInterval));
  }

  Future<JsonRpcResponseBool> login(String token) {
    final method = 'login';

    final id = Random().nextInt(1<<32);
    final json = TokenJsonRpc((b) => b
      ..method = method
      ..params = TokenParams((b) => b..token = token).toBuilder()
      ..id = id
      ..jsonrpc = '2.0'
      ).toJson();

    print(json);
    Future.delayed(Duration(seconds: 1), () {
      channel.sink.add(json);
    });
    return _subject
      .doOnEach(print)
      .map((it) => JsonRpcResponseBool.fromJson(it))
      .firstWhere((it) => it.id == id && it.method == method)
      .timeout(Duration(seconds: 10));
  }

  Future<JsonRpcWifiResponse> scanWifi() {
    final method = 'scan_wifi_ap';

    final id = Random().nextInt(1<<32);
    final future = _publishSubject
      .map((it) => JsonRpcWifiResponse.fromJson(it))
      .firstWhere((it) => it.id == id && it.method == method);
    channel.sink.add(JsonRpc<String>((b) => b
    ..method = method
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson());
    return future.timeout(Duration(seconds: 10));
  }

  Future<JsonRpcResponseBool> setCertificates(Certificates certs) {
    final method = 'set_certificates';

    final id = Random().nextInt(1<<32);
    final future = _publishSubject
      .map((it) => JsonRpcResponseBool.fromJson(it))
      .firstWhere((it) => it.id == id&& it.method == method);
    channel.sink.add(CertificatesJsonRpc((b) => b
    ..method = method
    ..params = certs.toBuilder()
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson());
    return future.timeout(Duration(seconds: 10));
  }

  Future<JsonRpcResponseBool> setWifiStationConfig(WifiStation station) {
    final method = 'set_wifi_sta_config';

    final id = Random().nextInt(1<<32);
    final future = _publishSubject
      .map((it) => JsonRpcResponseBool.fromJson(it))
      .firstWhere((it) => it.id == id&& it.method == method);
    channel.sink.add(WifiStationJsonRpc((b) => b
    ..method = method
    ..params = station.toBuilder()
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson());
    return future.timeout(Duration(seconds: 10));
  }

  /* TODO
  Future<bool> hasMultipleAp() async {
    return futureOr(getKernelVersion().then((it) => it), orElse: () => false);
  }
  */

  Future<JsonRpcResponse> getKernelVersion() {
    final method = 'get_kernel_version';

    final id = Random().nextInt(1<<32);
    final future = channel.stream
      .map((it) => JsonRpcResponse.fromJson(it)) // TODO
      .firstWhere((it) => it.id == id && it.method == method);
    channel.sink.add(JsonRpc((b) => b
    ..method = method
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson());
    return future.timeout(Duration(seconds: 10));
  }

  @override
  Future<String> connect(String url, {String certificate}) {
    return Future.value(null);
  }
}

class FloDeviceServiceOk implements FloDeviceService {
  FloDeviceServiceOk();

  Future<String> connect(String url, {String certificate}) {
    Fimber.d("FlutterOkhttpWs.connect()");
    return FlutterOkhttpWs.connect(url, certificate: certificate);
  }

  Future<JsonRpcResponseBool> login(String token) {
    Fimber.d("FlutterOkhttpWs.login(${token})");
    final method = 'login';

    final id = Random().nextInt(1<<32);
    final json = TokenJsonRpc((b) => b
      ..method = method
      ..params = TokenParams((b) => b..token = token).toBuilder()
      ..id = id
      ..jsonrpc = '2.0'
      ).toJson();

    return FlutterOkhttpWs.send(json)
      .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  Future<JsonRpcWifiResponse> scanWifi() {
    Fimber.d("FlutterOkhttpWs.scanWifi()");
    final method = 'scan_wifi_ap';

    final id = Random().nextInt(1<<32);
    final json = JsonRpc<String>((b) => b
    ..method = method
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson();
    return FlutterOkhttpWs.send(json)
      .then((it) => JsonRpcWifiResponse.fromJson(it));
  }

  Future<JsonRpcResponseBool> setCertificates(Certificates certs) {
    final method = 'set_certificates';

    final id = Random().nextInt(1<<32);
    final json = CertificatesJsonRpc((b) => b
    ..method = method
    ..params = certs.toBuilder()
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson();
    return FlutterOkhttpWs.send(json)
      .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  Future<JsonRpcResponseBool> setWifiStationConfig(WifiStation station) {
    final method = 'set_wifi_sta_config';

    final id = Random().nextInt(1<<32);
    final json = WifiStationJsonRpc((b) => b
    ..method = method
    ..params = station.toBuilder()
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson();
    return FlutterOkhttpWs.send(json)
      .then((it) => JsonRpcResponseBool.fromJson(it));
  }

  /* TODO
  Future<bool> hasMultipleAp() async {
    return futureOr(getKernelVersion().then((it) => it), orElse: () => false);
  }
  */

  Future<JsonRpcResponse> getKernelVersion() {
    final method = 'get_kernel_version';

    final id = Random().nextInt(1<<32);
    final json = JsonRpc((b) => b
    ..method = method
    ..id = id
    ..jsonrpc = '2.0'
    ).toJson();
    return FlutterOkhttpWs.send(json)
      .then((it) => JsonRpcResponse.fromJson(it));
  }

}
