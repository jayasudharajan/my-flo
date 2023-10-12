// GENERATED CODE - DO NOT MODIFY BY HAND

part of will;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Will> _$willSerializer = new _$WillSerializer();

class _$WillSerializer implements StructuredSerializer<Will> {
  @override
  final Iterable<Type> types = const [Will, _$Will];
  @override
  final String wireName = 'Will';

  @override
  Iterable<Object> serialize(Serializers serializers, Will object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'status',
      serializers.serialize(object.status,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Will deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WillBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Will extends Will {
  @override
  final String status;

  factory _$Will([void Function(WillBuilder) updates]) =>
      (new WillBuilder()..update(updates)).build();

  _$Will._({this.status}) : super._() {
    if (status == null) {
      throw new BuiltValueNullFieldError('Will', 'status');
    }
  }

  @override
  Will rebuild(void Function(WillBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WillBuilder toBuilder() => new WillBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Will && status == other.status;
  }

  @override
  int get hashCode {
    return $jf($jc(0, status.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Will')..add('status', status))
        .toString();
  }
}

class WillBuilder implements Builder<Will, WillBuilder> {
  _$Will _$v;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  WillBuilder();

  WillBuilder get _$this {
    if (_$v != null) {
      _status = _$v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Will other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Will;
  }

  @override
  void update(void Function(WillBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Will build() {
    final _$result = _$v ?? new _$Will._(status: status);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
