// GENERATED CODE - DO NOT MODIFY BY HAND

part of wifi_station_jsonrpc;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WifiStationJsonRpc> _$wifiStationJsonRpcSerializer =
    new _$WifiStationJsonRpcSerializer();

class _$WifiStationJsonRpcSerializer
    implements StructuredSerializer<WifiStationJsonRpc> {
  @override
  final Iterable<Type> types = const [WifiStationJsonRpc, _$WifiStationJsonRpc];
  @override
  final String wireName = 'WifiStationJsonRpc';

  @override
  Iterable<Object> serialize(Serializers serializers, WifiStationJsonRpc object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'jsonrpc',
      serializers.serialize(object.jsonrpc,
          specifiedType: const FullType(String)),
      'method',
      serializers.serialize(object.method,
          specifiedType: const FullType(String)),
      'params',
      serializers.serialize(object.params,
          specifiedType: const FullType(WifiStation)),
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  WifiStationJsonRpc deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WifiStationJsonRpcBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'jsonrpc':
          result.jsonrpc = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'method':
          result.method = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'params':
          result.params.replace(serializers.deserialize(value,
              specifiedType: const FullType(WifiStation)) as WifiStation);
          break;
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$WifiStationJsonRpc extends WifiStationJsonRpc {
  @override
  final String jsonrpc;
  @override
  final String method;
  @override
  final WifiStation params;
  @override
  final int id;

  factory _$WifiStationJsonRpc(
          [void Function(WifiStationJsonRpcBuilder) updates]) =>
      (new WifiStationJsonRpcBuilder()..update(updates)).build();

  _$WifiStationJsonRpc._({this.jsonrpc, this.method, this.params, this.id})
      : super._() {
    if (jsonrpc == null) {
      throw new BuiltValueNullFieldError('WifiStationJsonRpc', 'jsonrpc');
    }
    if (method == null) {
      throw new BuiltValueNullFieldError('WifiStationJsonRpc', 'method');
    }
    if (params == null) {
      throw new BuiltValueNullFieldError('WifiStationJsonRpc', 'params');
    }
    if (id == null) {
      throw new BuiltValueNullFieldError('WifiStationJsonRpc', 'id');
    }
  }

  @override
  WifiStationJsonRpc rebuild(
          void Function(WifiStationJsonRpcBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WifiStationJsonRpcBuilder toBuilder() =>
      new WifiStationJsonRpcBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WifiStationJsonRpc &&
        jsonrpc == other.jsonrpc &&
        method == other.method &&
        params == other.params &&
        id == other.id;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, jsonrpc.hashCode), method.hashCode), params.hashCode),
        id.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WifiStationJsonRpc')
          ..add('jsonrpc', jsonrpc)
          ..add('method', method)
          ..add('params', params)
          ..add('id', id))
        .toString();
  }
}

class WifiStationJsonRpcBuilder
    implements Builder<WifiStationJsonRpc, WifiStationJsonRpcBuilder> {
  _$WifiStationJsonRpc _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  WifiStationBuilder _params;
  WifiStationBuilder get params => _$this._params ??= new WifiStationBuilder();
  set params(WifiStationBuilder params) => _$this._params = params;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  WifiStationJsonRpcBuilder();

  WifiStationJsonRpcBuilder get _$this {
    if (_$v != null) {
      _jsonrpc = _$v.jsonrpc;
      _method = _$v.method;
      _params = _$v.params?.toBuilder();
      _id = _$v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WifiStationJsonRpc other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WifiStationJsonRpc;
  }

  @override
  void update(void Function(WifiStationJsonRpcBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WifiStationJsonRpc build() {
    _$WifiStationJsonRpc _$result;
    try {
      _$result = _$v ??
          new _$WifiStationJsonRpc._(
              jsonrpc: jsonrpc, method: method, params: params.build(), id: id);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'params';
        params.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'WifiStationJsonRpc', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
