// GENERATED CODE - DO NOT MODIFY BY HAND

part of api_configs;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ApiConfigs> _$apiConfigsSerializer = new _$ApiConfigsSerializer();

class _$ApiConfigsSerializer implements StructuredSerializer<ApiConfigs> {
  @override
  final Iterable<Type> types = const [ApiConfigs, _$ApiConfigs];
  @override
  final String wireName = 'ApiConfigs';

  @override
  Iterable<Object> serialize(Serializers serializers, ApiConfigs object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.v2 != null) {
      result
        ..add('v2')
        ..add(serializers.serialize(object.v2,
            specifiedType: const FullType(ApiConfig)));
    }
    return result;
  }

  @override
  ApiConfigs deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ApiConfigsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'v2':
          result.v2.replace(serializers.deserialize(value,
              specifiedType: const FullType(ApiConfig)) as ApiConfig);
          break;
      }
    }

    return result.build();
  }
}

class _$ApiConfigs extends ApiConfigs {
  @override
  final ApiConfig v2;

  factory _$ApiConfigs([void Function(ApiConfigsBuilder) updates]) =>
      (new ApiConfigsBuilder()..update(updates)).build();

  _$ApiConfigs._({this.v2}) : super._();

  @override
  ApiConfigs rebuild(void Function(ApiConfigsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApiConfigsBuilder toBuilder() => new ApiConfigsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApiConfigs && v2 == other.v2;
  }

  @override
  int get hashCode {
    return $jf($jc(0, v2.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ApiConfigs')..add('v2', v2))
        .toString();
  }
}

class ApiConfigsBuilder implements Builder<ApiConfigs, ApiConfigsBuilder> {
  _$ApiConfigs _$v;

  ApiConfigBuilder _v2;
  ApiConfigBuilder get v2 => _$this._v2 ??= new ApiConfigBuilder();
  set v2(ApiConfigBuilder v2) => _$this._v2 = v2;

  ApiConfigsBuilder();

  ApiConfigsBuilder get _$this {
    if (_$v != null) {
      _v2 = _$v.v2?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApiConfigs other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ApiConfigs;
  }

  @override
  void update(void Function(ApiConfigsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ApiConfigs build() {
    _$ApiConfigs _$result;
    try {
      _$result = _$v ?? new _$ApiConfigs._(v2: _v2?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'v2';
        _v2?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ApiConfigs', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
