// GENERATED CODE - DO NOT MODIFY BY HAND

part of token_jsonrpc;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<TokenJsonRpc> _$tokenJsonRpcSerializer =
    new _$TokenJsonRpcSerializer();

class _$TokenJsonRpcSerializer implements StructuredSerializer<TokenJsonRpc> {
  @override
  final Iterable<Type> types = const [TokenJsonRpc, _$TokenJsonRpc];
  @override
  final String wireName = 'TokenJsonRpc';

  @override
  Iterable<Object> serialize(Serializers serializers, TokenJsonRpc object,
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
          specifiedType: const FullType(TokenParams)),
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  TokenJsonRpc deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TokenJsonRpcBuilder();

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
              specifiedType: const FullType(TokenParams)) as TokenParams);
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

class _$TokenJsonRpc extends TokenJsonRpc {
  @override
  final String jsonrpc;
  @override
  final String method;
  @override
  final TokenParams params;
  @override
  final int id;

  factory _$TokenJsonRpc([void Function(TokenJsonRpcBuilder) updates]) =>
      (new TokenJsonRpcBuilder()..update(updates)).build();

  _$TokenJsonRpc._({this.jsonrpc, this.method, this.params, this.id})
      : super._() {
    if (jsonrpc == null) {
      throw new BuiltValueNullFieldError('TokenJsonRpc', 'jsonrpc');
    }
    if (method == null) {
      throw new BuiltValueNullFieldError('TokenJsonRpc', 'method');
    }
    if (params == null) {
      throw new BuiltValueNullFieldError('TokenJsonRpc', 'params');
    }
    if (id == null) {
      throw new BuiltValueNullFieldError('TokenJsonRpc', 'id');
    }
  }

  @override
  TokenJsonRpc rebuild(void Function(TokenJsonRpcBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenJsonRpcBuilder toBuilder() => new TokenJsonRpcBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenJsonRpc &&
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
    return (newBuiltValueToStringHelper('TokenJsonRpc')
          ..add('jsonrpc', jsonrpc)
          ..add('method', method)
          ..add('params', params)
          ..add('id', id))
        .toString();
  }
}

class TokenJsonRpcBuilder
    implements Builder<TokenJsonRpc, TokenJsonRpcBuilder> {
  _$TokenJsonRpc _$v;

  String _jsonrpc;
  String get jsonrpc => _$this._jsonrpc;
  set jsonrpc(String jsonrpc) => _$this._jsonrpc = jsonrpc;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  TokenParamsBuilder _params;
  TokenParamsBuilder get params => _$this._params ??= new TokenParamsBuilder();
  set params(TokenParamsBuilder params) => _$this._params = params;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  TokenJsonRpcBuilder();

  TokenJsonRpcBuilder get _$this {
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
  void replace(TokenJsonRpc other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TokenJsonRpc;
  }

  @override
  void update(void Function(TokenJsonRpcBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TokenJsonRpc build() {
    _$TokenJsonRpc _$result;
    try {
      _$result = _$v ??
          new _$TokenJsonRpc._(
              jsonrpc: jsonrpc, method: method, params: params.build(), id: id);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'params';
        params.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'TokenJsonRpc', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
