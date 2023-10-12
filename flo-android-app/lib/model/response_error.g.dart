// GENERATED CODE - DO NOT MODIFY BY HAND

part of response_error;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ResponseError> _$responseErrorSerializer =
    new _$ResponseErrorSerializer();

class _$ResponseErrorSerializer implements StructuredSerializer<ResponseError> {
  @override
  final Iterable<Type> types = const [ResponseError, _$ResponseError];
  @override
  final String wireName = 'ResponseError';

  @override
  Iterable<Object> serialize(Serializers serializers, ResponseError object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'error',
      serializers.serialize(object.error, specifiedType: const FullType(bool)),
      'message',
      serializers.serialize(object.message,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ResponseError deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ResponseErrorBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'error':
          result.error = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'message':
          result.message = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ResponseError extends ResponseError {
  @override
  final bool error;
  @override
  final String message;

  factory _$ResponseError([void Function(ResponseErrorBuilder) updates]) =>
      (new ResponseErrorBuilder()..update(updates)).build();

  _$ResponseError._({this.error, this.message}) : super._() {
    if (error == null) {
      throw new BuiltValueNullFieldError('ResponseError', 'error');
    }
    if (message == null) {
      throw new BuiltValueNullFieldError('ResponseError', 'message');
    }
  }

  @override
  ResponseError rebuild(void Function(ResponseErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResponseErrorBuilder toBuilder() => new ResponseErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResponseError &&
        error == other.error &&
        message == other.message;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, error.hashCode), message.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ResponseError')
          ..add('error', error)
          ..add('message', message))
        .toString();
  }
}

class ResponseErrorBuilder
    implements Builder<ResponseError, ResponseErrorBuilder> {
  _$ResponseError _$v;

  bool _error;
  bool get error => _$this._error;
  set error(bool error) => _$this._error = error;

  String _message;
  String get message => _$this._message;
  set message(String message) => _$this._message = message;

  ResponseErrorBuilder();

  ResponseErrorBuilder get _$this {
    if (_$v != null) {
      _error = _$v.error;
      _message = _$v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResponseError other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ResponseError;
  }

  @override
  void update(void Function(ResponseErrorBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ResponseError build() {
    final _$result =
        _$v ?? new _$ResponseError._(error: error, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
