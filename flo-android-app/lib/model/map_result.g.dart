// GENERATED CODE - DO NOT MODIFY BY HAND

part of map_result;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MapResult> _$mapResultSerializer = new _$MapResultSerializer();

class _$MapResultSerializer implements StructuredSerializer<MapResult> {
  @override
  final Iterable<Type> types = const [MapResult, _$MapResult];
  @override
  final String wireName = 'MapResult';

  @override
  Iterable<Object> serialize(Serializers serializers, MapResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.result != null) {
      result
        ..add('result')
        ..add(serializers.serialize(object.result,
            specifiedType: const FullType(BuiltMap,
                const [const FullType(String), const FullType(String)])));
    }
    return result;
  }

  @override
  MapResult deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MapResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'result':
          result.result.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(String)
              ])) as BuiltMap<dynamic, dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$MapResult extends MapResult {
  @override
  final BuiltMap<String, String> result;

  factory _$MapResult([void Function(MapResultBuilder) updates]) =>
      (new MapResultBuilder()..update(updates)).build();

  _$MapResult._({this.result}) : super._();

  @override
  MapResult rebuild(void Function(MapResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MapResultBuilder toBuilder() => new MapResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MapResult && result == other.result;
  }

  @override
  int get hashCode {
    return $jf($jc(0, result.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MapResult')..add('result', result))
        .toString();
  }
}

class MapResultBuilder implements Builder<MapResult, MapResultBuilder> {
  _$MapResult _$v;

  MapBuilder<String, String> _result;
  MapBuilder<String, String> get result =>
      _$this._result ??= new MapBuilder<String, String>();
  set result(MapBuilder<String, String> result) => _$this._result = result;

  MapResultBuilder();

  MapResultBuilder get _$this {
    if (_$v != null) {
      _result = _$v.result?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MapResult other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$MapResult;
  }

  @override
  void update(void Function(MapResultBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$MapResult build() {
    _$MapResult _$result;
    try {
      _$result = _$v ?? new _$MapResult._(result: _result?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'result';
        _result?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'MapResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
