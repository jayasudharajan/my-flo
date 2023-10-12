// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonrpc_wifi_response;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<JsonRpcWifiResponse> _$jsonRpcWifiResponseSerializer =
    new _$JsonRpcWifiResponseSerializer();

class _$JsonRpcWifiResponseSerializer
    implements StructuredSerializer<JsonRpcWifiResponse> {
  @override
  final Iterable<Type> types = const [
    JsonRpcWifiResponse,
    _$JsonRpcWifiResponse
  ];
  @override
  final String wireName = 'JsonRpcWifiResponse';

  @override
  Iterable<Object> serialize(
      Serializers serializers, JsonRpcWifiResponse object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.jsonrpc != null) {
      result
        ..add('jsonrpc')
        ..add(serializers.serialize(object.jsonrpc,
            specifiedType: const FullType(String)));
    }
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(int)));
    }
    if (object.method != null) {
      result
        ..add('from_method')
        ..add(serializers.serialize(object.method,
            specifiedType: const FullType(String)));
    }
    if (object.result != null) {
      result
        ..add('result')
        ..add(serializers.serialize(object.result,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Wifi)])));
    }
    return result;
  }

  @override
  JsonRpcWifiResponse deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new JsonRpcWifiResponseBuilder();

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
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'from_method':
          result.method = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'result':
          result.result.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Wifi)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$JsonRpcWifiResponse extends JsonRpcWifiResponse {
  @override
  final String jsonrpc;
  @override
  final int id;
  @override
  final String method;
  @override
  final BuiltList<Wifi> result;

  factory _$JsonRpcWifiResponse(
          [void Function(JsonRpcWifiResponseBuilder) updates]) =>
      (new JsonRpcWifiResponseBuilder()..update(updates)).build();

  _$JsonRpcWifiResponse._({this.jsonrpc, this.id, this.method, this.result})
      : super._();

  @override
  JsonRpcWifiResponse rebuild(
          void Function(JsonRpcWifiResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JsonRpcWifiResponseBuilder toBuilder() =>
      new JsonRpcWifiResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JsonRpcWifiResponse &&
        jsonrpc == other.jsonrpc &&
        id == other.id &&
        method == other.method &&
        result == other.result;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, jsonrpc.hashCode), id.hashCode), method.hashCode),
        result.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('JsonRpcWifiResponse')
          ..add('jsonrpc', jsonrpc)
          ..add('id', id)
          ..add('method', method)
          ..add('result', result))
        .toString();
  }
}

class JsonRpcWifiResponseBuilder
    implements Builder<JsonRpcWifiResponse, JsonRpcWifiResponseBuilder> {
  _$JsonRpcWifiResponse _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  ListBuilder<Wifi> _result;
  ListBuilder<Wifi> get result => _$this._result ??= new ListBuilder<Wifi>();
  set result(ListBuilder<Wifi> result) => _$this._result = result;

  JsonRpcWifiResponseBuilder();

  JsonRpcWifiResponseBuilder get _$this {
    if (_$v != null) {
      _jsonrpc = _$v.jsonrpc;
      _id = _$v.id;
      _method = _$v.method;
      _result = _$v.result?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JsonRpcWifiResponse other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$JsonRpcWifiResponse;
  }

  @override
  void update(void Function(JsonRpcWifiResponseBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$JsonRpcWifiResponse build() {
    _$JsonRpcWifiResponse _$result;
    try {
      _$result = _$v ??
          new _$JsonRpcWifiResponse._(
              jsonrpc: jsonrpc,
              id: id,
              method: method,
              result: _result?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'result';
        _result?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'JsonRpcWifiResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
