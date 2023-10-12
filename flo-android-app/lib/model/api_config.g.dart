// GENERATED CODE - DO NOT MODIFY BY HAND

part of api_config;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ApiConfig> _$apiConfigSerializer = new _$ApiConfigSerializer();

class _$ApiConfigSerializer implements StructuredSerializer<ApiConfig> {
  @override
  final Iterable<Type> types = const [ApiConfig, _$ApiConfig];
  @override
  final String wireName = 'ApiConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, ApiConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    if (object.url != null) {
      result
        ..add('url')
        ..add(serializers.serialize(object.url,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  ApiConfig deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ApiConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'url':
          result.url = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ApiConfig extends ApiConfig {
  @override
  final String status;
  @override
  final String url;

  factory _$ApiConfig([void Function(ApiConfigBuilder) updates]) =>
      (new ApiConfigBuilder()..update(updates)).build();

  _$ApiConfig._({this.status, this.url}) : super._();

  @override
  ApiConfig rebuild(void Function(ApiConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApiConfigBuilder toBuilder() => new ApiConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApiConfig && status == other.status && url == other.url;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, status.hashCode), url.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ApiConfig')
          ..add('status', status)
          ..add('url', url))
        .toString();
  }
}

class ApiConfigBuilder implements Builder<ApiConfig, ApiConfigBuilder> {
  _$ApiConfig _$v;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  String _url;
  String get url => _$this._url;
  set url(String url) => _$this._url = url;

  ApiConfigBuilder();

  ApiConfigBuilder get _$this {
    if (_$v != null) {
      _status = _$v.status;
      _url = _$v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApiConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ApiConfig;
  }

  @override
  void update(void Function(ApiConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ApiConfig build() {
    final _$result = _$v ?? new _$ApiConfig._(status: status, url: url);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
