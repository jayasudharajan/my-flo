// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_config;

// **************************************************************************
// ChopperGenerator
// **************************************************************************

class _$FloConfig extends FloConfig {
  _$FloConfig([ChopperClient client]) {
    if (client == null) return;
    this.client = client;
  }

  final definitionType = FloConfig;

  Future<Response<Config>> get() {
    final $url = '';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<Config, Config>($request);
  }
}
