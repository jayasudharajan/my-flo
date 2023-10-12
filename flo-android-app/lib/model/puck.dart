library puck;

import 'package:built_collection/built_collection.dart';
import 'package:chopper/chopper.dart';
import 'package:chopper/chopper.dart' as prefix0;
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:http/http.dart' as http;
import 'firmware_properties.dart';
import 'firmware_properties_result.dart';
import 'flo.dart';
import 'map_result.dart';
import 'puck_ticket.dart';
import 'scan_result.dart';

part 'puck.chopper.dart';

@ChopperApi()
abstract class Puck extends ChopperService {

  @Get(path: "puck/v1/props")
  Future<Response<MapResult>> getPropertiesMap();

  @Get(path: "puck/v1/props")
  Future<Response<FirmwarePropertiesResult>> getProperties();

  @Post(path: "puck/v1/props")
  Future<Response<dynamic>> putPropertiesMap(BuiltMap<String, String> props);

  @Post(path: "puck/v1/props")
  Future<Response<dynamic>> putProperties(FirmwareProperties props);

  @Get(path: "puck/v1/scanList")
  Future<Response<ScanResult>> scanList();

  @Post(path: "puck/v1/pair")
  Future<Response<dynamic>> pair(@Body() PuckTicket ticket);

  Future<http.Response> pair2(PuckTicket ticket) async {
    final client = http.Client();
    final jsonString = ticket.toJson();
    Fimber.d("jsonString: $jsonString");
    return await client.post('http://192.168.4.1/puck/v1/pair',
        headers: {"Content-Type": "application/json"},
        body: jsonString
    );
  }

  @Post(path: "puck/v1/disconnect")
  Future<Response<dynamic>> disconnect();

  @Post(path: "puck/v1/fwUpdate")
  @multipart
  Future<Response<dynamic>> updateFirmware(@PartFile() http.MultipartFile file);

  static Puck of() {
    final client = ChopperClient(
      baseUrl: "http://192.168.4.1",
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

    return _$Puck(client);
  }
}