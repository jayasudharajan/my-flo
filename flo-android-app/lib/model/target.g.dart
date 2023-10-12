// GENERATED CODE - DO NOT MODIFY BY HAND

part of target;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Target> _$targetSerializer = new _$TargetSerializer();

class _$TargetSerializer implements StructuredSerializer<Target> {
  @override
  final Iterable<Type> types = const [Target, _$Target];
  @override
  final String wireName = 'Target';

  @override
  Iterable<Object> serialize(Serializers serializers, Target object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'target',
      serializers.serialize(object.target,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Target deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TargetBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Target extends Target {
  @override
  final String target;

  factory _$Target([void Function(TargetBuilder) updates]) =>
      (new TargetBuilder()..update(updates)).build();

  _$Target._({this.target}) : super._() {
    if (target == null) {
      throw new BuiltValueNullFieldError('Target', 'target');
    }
  }

  @override
  Target rebuild(void Function(TargetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TargetBuilder toBuilder() => new TargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Target && target == other.target;
  }

  @override
  int get hashCode {
    return $jf($jc(0, target.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Target')..add('target', target))
        .toString();
  }
}

class TargetBuilder implements Builder<Target, TargetBuilder> {
  _$Target _$v;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  TargetBuilder();

  TargetBuilder get _$this {
    if (_$v != null) {
      _target = _$v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Target other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Target;
  }

  @override
  void update(void Function(TargetBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Target build() {
    final _$result = _$v ?? new _$Target._(target: target);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
