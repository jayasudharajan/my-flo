// GENERATED CODE - DO NOT MODIFY BY HAND

part of scan_result;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ScanResult> _$scanResultSerializer = new _$ScanResultSerializer();

class _$ScanResultSerializer implements StructuredSerializer<ScanResult> {
  @override
  final Iterable<Type> types = const [ScanResult, _$ScanResult];
  @override
  final String wireName = 'ScanResult';

  @override
  Iterable<Object> serialize(Serializers serializers, ScanResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'result',
      serializers.serialize(object.result,
          specifiedType:
              const FullType(BuiltList, const [const FullType(Wifi)])),
    ];

    return result;
  }

  @override
  ScanResult deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ScanResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
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

class _$ScanResult extends ScanResult {
  @override
  final BuiltList<Wifi> result;

  factory _$ScanResult([void Function(ScanResultBuilder) updates]) =>
      (new ScanResultBuilder()..update(updates)).build();

  _$ScanResult._({this.result}) : super._() {
    if (result == null) {
      throw new BuiltValueNullFieldError('ScanResult', 'result');
    }
  }

  @override
  ScanResult rebuild(void Function(ScanResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScanResultBuilder toBuilder() => new ScanResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScanResult && result == other.result;
  }

  @override
  int get hashCode {
    return $jf($jc(0, result.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ScanResult')..add('result', result))
        .toString();
  }
}

class ScanResultBuilder implements Builder<ScanResult, ScanResultBuilder> {
  _$ScanResult _$v;

  ListBuilder<Wifi> _result;
  ListBuilder<Wifi> get result => _$this._result ??= new ListBuilder<Wifi>();
  set result(ListBuilder<Wifi> result) => _$this._result = result;

  ScanResultBuilder();

  ScanResultBuilder get _$this {
    if (_$v != null) {
      _result = _$v.result?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ScanResult other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ScanResult;
  }

  @override
  void update(void Function(ScanResultBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ScanResult build() {
    _$ScanResult _$result;
    try {
      _$result = _$v ?? new _$ScanResult._(result: result.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'result';
        result.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ScanResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
