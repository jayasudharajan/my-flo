// GENERATED CODE - DO NOT MODIFY BY HAND

part of valve;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Valve> _$valveSerializer = new _$ValveSerializer();

class _$ValveSerializer implements StructuredSerializer<Valve> {
  @override
  final Iterable<Type> types = const [Valve, _$Valve];
  @override
  final String wireName = 'Valve';

  @override
  Iterable<Object> serialize(Serializers serializers, Valve object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.target != null) {
      result
        ..add('target')
        ..add(serializers.serialize(object.target,
            specifiedType: const FullType(String)));
    }
    if (object.lastKnown != null) {
      result
        ..add('lastKnown')
        ..add(serializers.serialize(object.lastKnown,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Valve deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ValveBuilder();

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
        case 'lastKnown':
          result.lastKnown = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Valve extends Valve {
  @override
  final String target;
  @override
  final String lastKnown;

  factory _$Valve([void Function(ValveBuilder) updates]) =>
      (new ValveBuilder()..update(updates)).build();

  _$Valve._({this.target, this.lastKnown}) : super._();

  @override
  Valve rebuild(void Function(ValveBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ValveBuilder toBuilder() => new ValveBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Valve &&
        target == other.target &&
        lastKnown == other.lastKnown;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, target.hashCode), lastKnown.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Valve')
          ..add('target', target)
          ..add('lastKnown', lastKnown))
        .toString();
  }
}

class ValveBuilder implements Builder<Valve, ValveBuilder> {
  _$Valve _$v;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  String _lastKnown;
  String get lastKnown => _$this._lastKnown;
  set lastKnown(String lastKnown) => _$this._lastKnown = lastKnown;

  ValveBuilder();

  ValveBuilder get _$this {
    if (_$v != null) {
      _target = _$v.target;
      _lastKnown = _$v.lastKnown;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Valve other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Valve;
  }

  @override
  void update(void Function(ValveBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Valve build() {
    final _$result = _$v ?? new _$Valve._(target: target, lastKnown: lastKnown);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
