// GENERATED CODE - DO NOT MODIFY BY HAND

part of puck;

// **************************************************************************
// ChopperGenerator
// **************************************************************************

class _$Puck extends Puck {
  _$Puck([ChopperClient client]) {
    if (client == null) return;
    this.client = client;
  }

  final definitionType = Puck;

  Future<Response<MapResult>> getPropertiesMap() {
    final $url = 'puck/v1/props';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<MapResult, MapResult>($request);
  }

  Future<Response<FirmwarePropertiesResult>> getProperties() {
    final $url = 'puck/v1/props';
    final $request = Request('GET', $url, client.baseUrl);
    return client
        .send<FirmwarePropertiesResult, FirmwarePropertiesResult>($request);
  }

  Future<Response> putPropertiesMap(BuiltMap<String, String> props) {
    final $url = 'puck/v1/props';
    final $request = Request('POST', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> putProperties(FirmwareProperties props) {
    final $url = 'puck/v1/props';
    final $request = Request('POST', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<ScanResult>> scanList() {
    final $url = 'puck/v1/scanList';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<ScanResult, ScanResult>($request);
  }

  Future<Response> pair(PuckTicket ticket) {
    final $url = 'puck/v1/pair';
    final $body = ticket;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> disconnect() {
    final $url = 'puck/v1/disconnect';
    final $request = Request('POST', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> updateFirmware(http.MultipartFile file) {
    final $url = 'puck/v1/fwUpdate';
    final $parts = <PartValue>[PartValueFile<http.MultipartFile>('file', file)];
    final $request =
        Request('POST', $url, client.baseUrl, parts: $parts, multipart: true);
    return client.send<dynamic, dynamic>($request);
  }
}
