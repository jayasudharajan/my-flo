// GENERATED CODE - DO NOT MODIFY BY HAND

part of firmware_properties_result;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FirmwarePropertiesResult> _$firmwarePropertiesResultSerializer =
    new _$FirmwarePropertiesResultSerializer();

class _$FirmwarePropertiesResultSerializer
    implements StructuredSerializer<FirmwarePropertiesResult> {
  @override
  final Iterable<Type> types = const [
    FirmwarePropertiesResult,
    _$FirmwarePropertiesResult
  ];
  @override
  final String wireName = 'FirmwarePropertiesResult';

  @override
  Iterable<Object> serialize(
      Serializers serializers, FirmwarePropertiesResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.result != null) {
      result
        ..add('result')
        ..add(serializers.serialize(object.result,
            specifiedType: const FullType(FirmwareProperties)));
    }
    return result;
  }

  @override
  FirmwarePropertiesResult deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FirmwarePropertiesResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'result':
          result.result.replace(serializers.deserialize(value,
                  specifiedType: const FullType(FirmwareProperties))
              as FirmwareProperties);
          break;
      }
    }

    return result.build();
  }
}

class _$FirmwarePropertiesResult extends FirmwarePropertiesResult {
  @override
  final FirmwareProperties result;

  factory _$FirmwarePropertiesResult(
          [void Function(FirmwarePropertiesResultBuilder) updates]) =>
      (new FirmwarePropertiesResultBuilder()..update(updates)).build();

  _$FirmwarePropertiesResult._({this.result}) : super._();

  @override
  FirmwarePropertiesResult rebuild(
          void Function(FirmwarePropertiesResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FirmwarePropertiesResultBuilder toBuilder() =>
      new FirmwarePropertiesResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FirmwarePropertiesResult && result == other.result;
  }

  @override
  int get hashCode {
    return $jf($jc(0, result.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FirmwarePropertiesResult')
          ..add('result', result))
        .toString();
  }
}

class FirmwarePropertiesResultBuilder
    implements
        Builder<FirmwarePropertiesResult, FirmwarePropertiesResultBuilder> {
  _$FirmwarePropertiesResult _$v;

  FirmwarePropertiesBuilder _result;
  FirmwarePropertiesBuilder get result =>
      _$this._result ??= new FirmwarePropertiesBuilder();
  set result(FirmwarePropertiesBuilder result) => _$this._result = result;

  FirmwarePropertiesResultBuilder();

  FirmwarePropertiesResultBuilder get _$this {
    if (_$v != null) {
      _result = _$v.result?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FirmwarePropertiesResult other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FirmwarePropertiesResult;
  }

  @override
  void update(void Function(FirmwarePropertiesResultBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FirmwarePropertiesResult build() {
    _$FirmwarePropertiesResult _$result;
    try {
      _$result =
          _$v ?? new _$FirmwarePropertiesResult._(result: _result?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'result';
        _result?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FirmwarePropertiesResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
