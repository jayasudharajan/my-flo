// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert1_notification;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alert1Notification> _$alert1NotificationSerializer =
    new _$Alert1NotificationSerializer();

class _$Alert1NotificationSerializer
    implements StructuredSerializer<Alert1Notification> {
  @override
  final Iterable<Type> types = const [Alert1Notification, _$Alert1Notification];
  @override
  final String wireName = 'Alert1Notification';

  @override
  Iterable<Object> serialize(Serializers serializers, Alert1Notification object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.severity != null) {
      result
        ..add('severity')
        ..add(serializers.serialize(object.severity,
            specifiedType: const FullType(int)));
    }
    if (object.name != null) {
      result
        ..add('name')
        ..add(serializers.serialize(object.name,
            specifiedType: const FullType(String)));
    }
    if (object.alarmId != null) {
      result
        ..add('alarm_id')
        ..add(serializers.serialize(object.alarmId,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  Alert1Notification deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new Alert1NotificationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'severity':
          result.severity = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'alarm_id':
          result.alarmId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Alert1Notification extends Alert1Notification {
  @override
  final int severity;
  @override
  final String name;
  @override
  final int alarmId;

  factory _$Alert1Notification(
          [void Function(Alert1NotificationBuilder) updates]) =>
      (new Alert1NotificationBuilder()..update(updates)).build();

  _$Alert1Notification._({this.severity, this.name, this.alarmId}) : super._();

  @override
  Alert1Notification rebuild(
          void Function(Alert1NotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Alert1NotificationBuilder toBuilder() =>
      new Alert1NotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alert1Notification &&
        severity == other.severity &&
        name == other.name &&
        alarmId == other.alarmId;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, severity.hashCode), name.hashCode), alarmId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alert1Notification')
          ..add('severity', severity)
          ..add('name', name)
          ..add('alarmId', alarmId))
        .toString();
  }
}

class Alert1NotificationBuilder
    implements Builder<Alert1Notification, Alert1NotificationBuilder> {
  _$Alert1Notification _$v;

  int _severity;
  int get severity => _$this._severity;
  set severity(int severity) => _$this._severity = severity;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  int _alarmId;
  int get alarmId => _$this._alarmId;
  set alarmId(int alarmId) => _$this._alarmId = alarmId;

  Alert1NotificationBuilder();

  Alert1NotificationBuilder get _$this {
    if (_$v != null) {
      _severity = _$v.severity;
      _name = _$v.name;
      _alarmId = _$v.alarmId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alert1Notification other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alert1Notification;
  }

  @override
  void update(void Function(Alert1NotificationBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alert1Notification build() {
    final _$result = _$v ??
        new _$Alert1Notification._(
            severity: severity, name: name, alarmId: alarmId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
