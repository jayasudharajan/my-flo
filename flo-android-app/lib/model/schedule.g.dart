// GENERATED CODE - DO NOT MODIFY BY HAND

part of schedule;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Schedule> _$scheduleSerializer = new _$ScheduleSerializer();

class _$ScheduleSerializer implements StructuredSerializer<Schedule> {
  @override
  final Iterable<Type> types = const [Schedule, _$Schedule];
  @override
  final String wireName = 'Schedule';

  @override
  Iterable<Object> serialize(Serializers serializers, Schedule object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    if (object.times != null) {
      result
        ..add('times')
        ..add(serializers.serialize(object.times,
            specifiedType: const FullType(BuiltList, const [
              const FullType(BuiltList, const [const FullType(String)])
            ])));
    }
    return result;
  }

  @override
  Schedule deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ScheduleBuilder();

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
        case 'times':
          result.times.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(BuiltList, const [const FullType(String)])
              ])) as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Schedule extends Schedule {
  @override
  final String status;
  @override
  final BuiltList<BuiltList<String>> times;

  factory _$Schedule([void Function(ScheduleBuilder) updates]) =>
      (new ScheduleBuilder()..update(updates)).build();

  _$Schedule._({this.status, this.times}) : super._();

  @override
  Schedule rebuild(void Function(ScheduleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScheduleBuilder toBuilder() => new ScheduleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Schedule && status == other.status && times == other.times;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, status.hashCode), times.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Schedule')
          ..add('status', status)
          ..add('times', times))
        .toString();
  }
}

class ScheduleBuilder implements Builder<Schedule, ScheduleBuilder> {
  _$Schedule _$v;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  ListBuilder<BuiltList<String>> _times;
  ListBuilder<BuiltList<String>> get times =>
      _$this._times ??= new ListBuilder<BuiltList<String>>();
  set times(ListBuilder<BuiltList<String>> times) => _$this._times = times;

  ScheduleBuilder();

  ScheduleBuilder get _$this {
    if (_$v != null) {
      _status = _$v.status;
      _times = _$v.times?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Schedule other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Schedule;
  }

  @override
  void update(void Function(ScheduleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Schedule build() {
    _$Schedule _$result;
    try {
      _$result =
          _$v ?? new _$Schedule._(status: status, times: _times?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'times';
        _times?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Schedule', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
