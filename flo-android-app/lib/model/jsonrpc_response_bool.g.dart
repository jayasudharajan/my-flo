// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonrpc_response_bool;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<JsonRpcResponseBool> _$jsonRpcResponseBoolSerializer =
    new _$JsonRpcResponseBoolSerializer();

class _$JsonRpcResponseBoolSerializer
    implements StructuredSerializer<JsonRpcResponseBool> {
  @override
  final Iterable<Type> types = const [
    JsonRpcResponseBool,
    _$JsonRpcResponseBool
  ];
  @override
  final String wireName = 'JsonRpcResponseBool';

  @override
  Iterable<Object> serialize(
      Serializers serializers, JsonRpcResponseBool object,
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
            specifiedType: const FullType(bool)));
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
  JsonRpcResponseBool deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new JsonRpcResponseBoolBuilder();

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
              specifiedType: const FullType(bool)) as bool;
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

class _$JsonRpcResponseBool extends JsonRpcResponseBool {
  @override
  final String jsonrpc;
  @override
  final bool result;
  @override
  final String method;
  @override
  final int id;

  factory _$JsonRpcResponseBool(
          [void Function(JsonRpcResponseBoolBuilder) updates]) =>
      (new JsonRpcResponseBoolBuilder()..update(updates)).build();

  _$JsonRpcResponseBool._({this.jsonrpc, this.result, this.method, this.id})
      : super._();

  @override
  JsonRpcResponseBool rebuild(
          void Function(JsonRpcResponseBoolBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JsonRpcResponseBoolBuilder toBuilder() =>
      new JsonRpcResponseBoolBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JsonRpcResponseBool &&
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
    return (newBuiltValueToStringHelper('JsonRpcResponseBool')
          ..add('jsonrpc', jsonrpc)
          ..add('result', result)
          ..add('method', method)
          ..add('id', id))
        .toString();
  }
}

class JsonRpcResponseBoolBuilder
    implements Builder<JsonRpcResponseBool, JsonRpcResponseBoolBuilder> {
  _$JsonRpcResponseBool _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  bool _result;
  bool get result => _$this._result;
  set result(bool result) => _$this._result = result;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  JsonRpcResponseBoolBuilder();

  JsonRpcResponseBoolBuilder get _$this {
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
  void replace(JsonRpcResponseBool other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$JsonRpcResponseBool;
  }

  @override
  void update(void Function(JsonRpcResponseBoolBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$JsonRpcResponseBool build() {
    final _$result = _$v ??
        new _$JsonRpcResponseBool._(
            jsonrpc: jsonrpc, result: result, method: method, id: id);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
