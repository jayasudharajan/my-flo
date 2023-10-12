// GENERATED CODE - DO NOT MODIFY BY HAND

part of config;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Config> _$configSerializer = new _$ConfigSerializer();

class _$ConfigSerializer implements StructuredSerializer<Config> {
  @override
  final Iterable<Type> types = const [Config, _$Config];
  @override
  final String wireName = 'Config';

  @override
  Iterable<Object> serialize(Serializers serializers, Config object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.api != null) {
      result
        ..add('api')
        ..add(serializers.serialize(object.api,
            specifiedType: const FullType(ApiConfigs)));
    }
    if (object.iosApp != null) {
      result
        ..add('iosApp')
        ..add(serializers.serialize(object.iosApp,
            specifiedType: const FullType(AppConfig)));
    }
    if (object.androidApp != null) {
      result
        ..add('androidApp')
        ..add(serializers.serialize(object.androidApp,
            specifiedType: const FullType(AppConfig)));
    }
    if (object.enabledFeatures != null) {
      result
        ..add('enabledFeatures')
        ..add(serializers.serialize(object.enabledFeatures,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    return result;
  }

  @override
  Config deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'api':
          result.api.replace(serializers.deserialize(value,
              specifiedType: const FullType(ApiConfigs)) as ApiConfigs);
          break;
        case 'iosApp':
          result.iosApp.replace(serializers.deserialize(value,
              specifiedType: const FullType(AppConfig)) as AppConfig);
          break;
        case 'androidApp':
          result.androidApp.replace(serializers.deserialize(value,
              specifiedType: const FullType(AppConfig)) as AppConfig);
          break;
        case 'enabledFeatures':
          result.enabledFeatures.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Config extends Config {
  @override
  final ApiConfigs api;
  @override
  final AppConfig iosApp;
  @override
  final AppConfig androidApp;
  @override
  final BuiltList<String> enabledFeatures;

  factory _$Config([void Function(ConfigBuilder) updates]) =>
      (new ConfigBuilder()..update(updates)).build();

  _$Config._({this.api, this.iosApp, this.androidApp, this.enabledFeatures})
      : super._();

  @override
  Config rebuild(void Function(ConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfigBuilder toBuilder() => new ConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Config &&
        api == other.api &&
        iosApp == other.iosApp &&
        androidApp == other.androidApp &&
        enabledFeatures == other.enabledFeatures;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, api.hashCode), iosApp.hashCode), androidApp.hashCode),
        enabledFeatures.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Config')
          ..add('api', api)
          ..add('iosApp', iosApp)
          ..add('androidApp', androidApp)
          ..add('enabledFeatures', enabledFeatures))
        .toString();
  }
}

class ConfigBuilder implements Builder<Config, ConfigBuilder> {
  _$Config _$v;

  ApiConfigsBuilder _api;
  ApiConfigsBuilder get api => _$this._api ??= new ApiConfigsBuilder();
  set api(ApiConfigsBuilder api) => _$this._api = api;

  AppConfigBuilder _iosApp;
  AppConfigBuilder get iosApp => _$this._iosApp ??= new AppConfigBuilder();
  set iosApp(AppConfigBuilder iosApp) => _$this._iosApp = iosApp;

  AppConfigBuilder _androidApp;
  AppConfigBuilder get androidApp =>
      _$this._androidApp ??= new AppConfigBuilder();
  set androidApp(AppConfigBuilder androidApp) =>
      _$this._androidApp = androidApp;

  ListBuilder<String> _enabledFeatures;
  ListBuilder<String> get enabledFeatures =>
      _$this._enabledFeatures ??= new ListBuilder<String>();
  set enabledFeatures(ListBuilder<String> enabledFeatures) =>
      _$this._enabledFeatures = enabledFeatures;

  ConfigBuilder();

  ConfigBuilder get _$this {
    if (_$v != null) {
      _api = _$v.api?.toBuilder();
      _iosApp = _$v.iosApp?.toBuilder();
      _androidApp = _$v.androidApp?.toBuilder();
      _enabledFeatures = _$v.enabledFeatures?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Config other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Config;
  }

  @override
  void update(void Function(ConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Config build() {
    _$Config _$result;
    try {
      _$result = _$v ??
          new _$Config._(
              api: _api?.build(),
              iosApp: _iosApp?.build(),
              androidApp: _androidApp?.build(),
              enabledFeatures: _enabledFeatures?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'api';
        _api?.build();
        _$failedField = 'iosApp';
        _iosApp?.build();
        _$failedField = 'androidApp';
        _androidApp?.build();
        _$failedField = 'enabledFeatures';
        _enabledFeatures?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Config', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
