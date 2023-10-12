// GENERATED CODE - DO NOT MODIFY BY HAND

part of irrigation_schedule;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<IrrigationSchedule> _$irrigationScheduleSerializer =
    new _$IrrigationScheduleSerializer();

class _$IrrigationScheduleSerializer
    implements StructuredSerializer<IrrigationSchedule> {
  @override
  final Iterable<Type> types = const [IrrigationSchedule, _$IrrigationSchedule];
  @override
  final String wireName = 'IrrigationSchedule';

  @override
  Iterable<Object> serialize(Serializers serializers, IrrigationSchedule object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.computed != null) {
      result
        ..add('computed')
        ..add(serializers.serialize(object.computed,
            specifiedType: const FullType(Schedule)));
    }
    if (object.enabled != null) {
      result
        ..add('isEnabled')
        ..add(serializers.serialize(object.enabled,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  IrrigationSchedule deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new IrrigationScheduleBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'computed':
          result.computed.replace(serializers.deserialize(value,
              specifiedType: const FullType(Schedule)) as Schedule);
          break;
        case 'isEnabled':
          result.enabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$IrrigationSchedule extends IrrigationSchedule {
  @override
  final Schedule computed;
  @override
  final bool enabled;
  @override
  final String updatedAt;

  factory _$IrrigationSchedule(
          [void Function(IrrigationScheduleBuilder) updates]) =>
      (new IrrigationScheduleBuilder()..update(updates)).build();

  _$IrrigationSchedule._({this.computed, this.enabled, this.updatedAt})
      : super._();

  @override
  IrrigationSchedule rebuild(
          void Function(IrrigationScheduleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IrrigationScheduleBuilder toBuilder() =>
      new IrrigationScheduleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IrrigationSchedule &&
        computed == other.computed &&
        enabled == other.enabled &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, computed.hashCode), enabled.hashCode), updatedAt.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('IrrigationSchedule')
          ..add('computed', computed)
          ..add('enabled', enabled)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class IrrigationScheduleBuilder
    implements Builder<IrrigationSchedule, IrrigationScheduleBuilder> {
  _$IrrigationSchedule _$v;

  ScheduleBuilder _computed;
  ScheduleBuilder get computed => _$this._computed ??= new ScheduleBuilder();
  set computed(ScheduleBuilder computed) => _$this._computed = computed;

  bool _enabled;
  bool get enabled => _$this._enabled;
  set enabled(bool enabled) => _$this._enabled = enabled;

  String _updatedAt;
  String get updatedAt => _$this._updatedAt;
  set updatedAt(String updatedAt) => _$this._updatedAt = updatedAt;

  IrrigationScheduleBuilder();

  IrrigationScheduleBuilder get _$this {
    if (_$v != null) {
      _computed = _$v.computed?.toBuilder();
      _enabled = _$v.enabled;
      _updatedAt = _$v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IrrigationSchedule other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$IrrigationSchedule;
  }

  @override
  void update(void Function(IrrigationScheduleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$IrrigationSchedule build() {
    _$IrrigationSchedule _$result;
    try {
      _$result = _$v ??
          new _$IrrigationSchedule._(
              computed: _computed?.build(),
              enabled: enabled,
              updatedAt: updatedAt);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'computed';
        _computed?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'IrrigationSchedule', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
