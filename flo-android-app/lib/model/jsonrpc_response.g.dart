// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonrpc_response;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<JsonRpcResponse> _$jsonRpcResponseSerializer =
    new _$JsonRpcResponseSerializer();

class _$JsonRpcResponseSerializer
    implements StructuredSerializer<JsonRpcResponse> {
  @override
  final Iterable<Type> types = const [JsonRpcResponse, _$JsonRpcResponse];
  @override
  final String wireName = 'JsonRpcResponse';

  @override
  Iterable<Object> serialize(Serializers serializers, JsonRpcResponse object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.jsonrpc != null) {
      result
        ..add('jsonrpc')
        ..add(serializers.serialize(object.jsonrpc,
            specifiedType: const FullType(String)));
    }
    if (object.result != null) {
      result
        ..add('result')
        ..add(serializers.serialize(object.result,
            specifiedType: const FullType(String)));
    }
    if (object.method != null) {
      result
        ..add('from_method')
        ..add(serializers.serialize(object.method,
            specifiedType: const FullType(String)));
    }
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  JsonRpcResponse deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new JsonRpcResponseBuilder();

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
        case 'result':
          result.result = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'from_method':
          result.method = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
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

class _$JsonRpcResponse extends JsonRpcResponse {
  @override
  final String jsonrpc;
  @override
  final String result;
  @override
  final String method;
  @override
  final int id;

  factory _$JsonRpcResponse([void Function(JsonRpcResponseBuilder) updates]) =>
      (new JsonRpcResponseBuilder()..update(updates)).build();

  _$JsonRpcResponse._({this.jsonrpc, this.result, this.method, this.id})
      : super._();

  @override
  JsonRpcResponse rebuild(void Function(JsonRpcResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JsonRpcResponseBuilder toBuilder() =>
      new JsonRpcResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JsonRpcResponse &&
        jsonrpc == other.jsonrpc &&
        result == other.result &&
        method == other.method &&
        id == other.id;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, jsonrpc.hashCode), result.hashCode), method.hashCode),
        id.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('JsonRpcResponse')
          ..add('jsonrpc', jsonrpc)
          ..add('result', result)
          ..add('method', method)
          ..add('id', id))
        .toString();
  }
}

class JsonRpcResponseBuilder
    implements Builder<JsonRpcResponse, JsonRpcResponseBuilder> {
  _$JsonRpcResponse _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  String _result;
  String get result => _$this._result;
  set result(String result) => _$this._result = result;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  JsonRpcResponseBuilder();

  JsonRpcResponseBuilder get _$this {
    if (_$v != null) {
      _jsonrpc = _$v.jsonrpc;
      _result = _$v.result;
      _method = _$v.method;
      _id = _$v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JsonRpcResponse other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$JsonRpcResponse;
  }

  @override
  void update(void Function(JsonRpcResponseBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$JsonRpcResponse build() {
    final _$result = _$v ??
        new _$JsonRpcResponse._(
            jsonrpc: jsonrpc, result: result, method: method, id: id);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
