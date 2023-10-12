// GENERATED CODE - DO NOT MODIFY BY HAND

part of jsonrpc;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<JsonRpc> _$jsonRpcSerializer = new _$JsonRpcSerializer();

class _$JsonRpcSerializer implements StructuredSerializer<JsonRpc> {
  @override
  final Iterable<Type> types = const [JsonRpc, _$JsonRpc];
  @override
  final String wireName = 'JsonRpc';

  @override
  Iterable<Object> serialize(Serializers serializers, JsonRpc object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[];
    if (object.jsonrpc != null) {
      result
        ..add('jsonrpc')
        ..add(serializers.serialize(object.jsonrpc,
            specifiedType: const FullType(String)));
    }
    if (object.method != null) {
      result
        ..add('method')
        ..add(serializers.serialize(object.method,
            specifiedType: const FullType(String)));
    }
    if (object.params != null) {
      result
        ..add('params')
        ..add(serializers.serialize(object.params, specifiedType: parameterT));
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
  JsonRpc deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new JsonRpcBuilder<Object>()
        : serializers.newBuilder(specifiedType) as JsonRpcBuilder;

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
          result.params =
              serializers.deserialize(value, specifiedType: parameterT);
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

class _$JsonRpc<T> extends JsonRpc<T> {
  @override
  final String jsonrpc;
  @override
  final String method;
  @override
  final T params;
  @override
  final int id;

  factory _$JsonRpc([void Function(JsonRpcBuilder<T>) updates]) =>
      (new JsonRpcBuilder<T>()..update(updates)).build();

  _$JsonRpc._({this.jsonrpc, this.method, this.params, this.id}) : super._() {
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('JsonRpc', 'T');
    }
  }

  @override
  JsonRpc<T> rebuild(void Function(JsonRpcBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JsonRpcBuilder<T> toBuilder() => new JsonRpcBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JsonRpc &&
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
    return (newBuiltValueToStringHelper('JsonRpc')
          ..add('jsonrpc', jsonrpc)
          ..add('method', method)
          ..add('params', params)
          ..add('id', id))
        .toString();
  }
}

class JsonRpcBuilder<T> implements Builder<JsonRpc<T>, JsonRpcBuilder<T>> {
  _$JsonRpc<T> _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  T _params;
  T get params => _$this._params;
  set params(T params) => _$this._params = params;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  JsonRpcBuilder();

  JsonRpcBuilder<T> get _$this {
    if (_$v != null) {
      _jsonrpc = _$v.jsonrpc;
      _method = _$v.method;
      _params = _$v.params;
      _id = _$v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JsonRpc<T> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$JsonRpc<T>;
  }

  @override
  void update(void Function(JsonRpcBuilder<T>) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$JsonRpc<T> build() {
    final _$result = _$v ??
        new _$JsonRpc<T>._(
            jsonrpc: jsonrpc, method: method, params: params, id: id);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
