// GENERATED CODE - DO NOT MODIFY BY HAND

part of token_params;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<TokenParams> _$tokenParamsSerializer = new _$TokenParamsSerializer();

class _$TokenParamsSerializer implements StructuredSerializer<TokenParams> {
  @override
  final Iterable<Type> types = const [TokenParams, _$TokenParams];
  @override
  final String wireName = 'TokenParams';

  @override
  Iterable<Object> serialize(Serializers serializers, TokenParams object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'token',
      serializers.serialize(object.token,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  TokenParams deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TokenParamsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'token':
          result.token = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$TokenParams extends TokenParams {
  @override
  final String token;

  factory _$TokenParams([void Function(TokenParamsBuilder) updates]) =>
      (new TokenParamsBuilder()..update(updates)).build();

  _$TokenParams._({this.token}) : super._() {
    if (token == null) {
      throw new BuiltValueNullFieldError('TokenParams', 'token');
    }
  }

  @override
  TokenParams rebuild(void Function(TokenParamsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenParamsBuilder toBuilder() => new TokenParamsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenParams && token == other.token;
  }

  @override
  int get hashCode {
    return $jf($jc(0, token.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TokenParams')..add('token', token))
        .toString();
  }
}

class TokenParamsBuilder implements Builder<TokenParams, TokenParamsBuilder> {
  _$TokenParams _$v;

  String _token;
  String get token => _$this._token;
  set token(String token) => _$this._token = token;

  TokenParamsBuilder();

  TokenParamsBuilder get _$this {
    if (_$v != null) {
      _token = _$v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenParams other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TokenParams;
  }

  @override
  void update(void Function(TokenParamsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TokenParams build() {
    final _$result = _$v ?? new _$TokenParams._(token: token);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
