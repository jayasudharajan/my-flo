// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_action;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertAction> _$alertActionSerializer = new _$AlertActionSerializer();

class _$AlertActionSerializer implements StructuredSerializer<AlertAction> {
  @override
  final Iterable<Type> types = const [AlertAction, _$AlertAction];
  @override
  final String wireName = 'AlertAction';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertAction object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.alarmIds != null) {
      result
        ..add('alarmIds')
        ..add(serializers.serialize(object.alarmIds,
            specifiedType:
                const FullType(BuiltList, const [const FullType(int)])));
    }
    if (object.snoozeSeconds != null) {
      result
        ..add('snoozeSeconds')
        ..add(serializers.serialize(object.snoozeSeconds,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  AlertAction deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertActionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'alarmIds':
          result.alarmIds.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(int)]))
              as BuiltList<dynamic>);
          break;
        case 'snoozeSeconds':
          result.snoozeSeconds = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$AlertAction extends AlertAction {
  @override
  final String deviceId;
  @override
  final BuiltList<int> alarmIds;
  @override
  final int snoozeSeconds;

  factory _$AlertAction([void Function(AlertActionBuilder) updates]) =>
      (new AlertActionBuilder()..update(updates)).build();

  _$AlertAction._({this.deviceId, this.alarmIds, this.snoozeSeconds})
      : super._();

  @override
  AlertAction rebuild(void Function(AlertActionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertActionBuilder toBuilder() => new AlertActionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertAction &&
        deviceId == other.deviceId &&
        alarmIds == other.alarmIds &&
        snoozeSeconds == other.snoozeSeconds;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, deviceId.hashCode), alarmIds.hashCode),
        snoozeSeconds.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertAction')
          ..add('deviceId', deviceId)
          ..add('alarmIds', alarmIds)
          ..add('snoozeSeconds', snoozeSeconds))
        .toString();
  }
}

class AlertActionBuilder implements Builder<AlertAction, AlertActionBuilder> {
  _$AlertAction _$v;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  ListBuilder<int> _alarmIds;
  ListBuilder<int> get alarmIds => _$this._alarmIds ??= new ListBuilder<int>();
  set alarmIds(ListBuilder<int> alarmIds) => _$this._alarmIds = alarmIds;

  int _snoozeSeconds;
  int get snoozeSeconds => _$this._snoozeSeconds;
  set snoozeSeconds(int snoozeSeconds) => _$this._snoozeSeconds = snoozeSeconds;

  AlertActionBuilder();

  AlertActionBuilder get _$this {
    if (_$v != null) {
      _deviceId = _$v.deviceId;
      _alarmIds = _$v.alarmIds?.toBuilder();
      _snoozeSeconds = _$v.snoozeSeconds;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertAction other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertAction;
  }

  @override
  void update(void Function(AlertActionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertAction build() {
    _$AlertAction _$result;
    try {
      _$result = _$v ??
          new _$AlertAction._(
              deviceId: deviceId,
              alarmIds: _alarmIds?.build(),
              snoozeSeconds: snoozeSeconds);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'alarmIds';
        _alarmIds?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertAction', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
