library flo_config;

import 'package:chopper/chopper.dart';
import 'package:flutter_embrace/flutter_embrace.dart';

import 'config.dart';
import 'flo.dart';

part 'flo_config.chopper.dart';

@ChopperApi()
abstract class FloConfig extends ChopperService {
  @Get(path: "")
  Future<Response<Config>> get();

  static FloConfig of() {
    final client = ChopperClient(
      baseUrl: "https://client-config.meetflo.com",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter(),
      interceptors: [
        (Request req) async {
          print("req.baseUrl: ${req.baseUrl}");
          print("req.url: ${req.method} ${req.url}");
          print("req.parameters: ${req.parameters}");
          print("req.headers: ${req.headers}");
          print("req.body: ${req.body}");
          return req;
        },
        (Response res) {
          print("res.body: ${res.body}");
          return res;
        },
      ],
    );
    client.onError.listen((res) {
      print("onError: req.url: ${res.base.request.method} ${res.base.request
          .url}");
      print("onError: req.headers: ${res.base.request.headers}");
      print("onError: req.statusCode: ${res.statusCode}");
      print("onError: res.body: ${res.body}");
    });

    return _$FloConfig(client);
  }
}