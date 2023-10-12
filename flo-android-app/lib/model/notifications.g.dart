// GENERATED CODE - DO NOT MODIFY BY HAND

part of notifications;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Notifications> _$notificationsSerializer =
    new _$NotificationsSerializer();

class _$NotificationsSerializer implements StructuredSerializer<Notifications> {
  @override
  final Iterable<Type> types = const [Notifications, _$Notifications];
  @override
  final String wireName = 'Notifications';

  @override
  Iterable<Object> serialize(Serializers serializers, Notifications object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.fsUpdate != null) {
      result
        ..add('fsUpdate')
        ..add(serializers.serialize(object.fsUpdate,
            specifiedType: const FullType(String)));
    }
    if (object.criticalCountFlatten != null) {
      result
        ..add('criticalCount')
        ..add(serializers.serialize(object.criticalCountFlatten,
            specifiedType: const FullType(int)));
    }
    if (object.warningCountFlatten != null) {
      result
        ..add('warningCount')
        ..add(serializers.serialize(object.warningCountFlatten,
            specifiedType: const FullType(int)));
    }
    if (object.infoCountFlatten != null) {
      result
        ..add('infoCount')
        ..add(serializers.serialize(object.infoCountFlatten,
            specifiedType: const FullType(int)));
    }
    if (object.alarmCounts != null) {
      result
        ..add('alarmCount')
        ..add(serializers.serialize(object.alarmCounts,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Alarm)])));
    }
    return result;
  }

  @override
  Notifications deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NotificationsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'fsUpdate':
          result.fsUpdate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'criticalCount':
          result.criticalCountFlatten = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'warningCount':
          result.warningCountFlatten = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'infoCount':
          result.infoCountFlatten = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'alarmCount':
          result.alarmCounts.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Alarm)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Notifications extends Notifications {
  @override
  final String fsUpdate;
  @override
  final int criticalCountFlatten;
  @override
  final int warningCountFlatten;
  @override
  final int infoCountFlatten;
  @override
  final BuiltList<Alarm> alarmCounts;

  factory _$Notifications([void Function(NotificationsBuilder) updates]) =>
      (new NotificationsBuilder()..update(updates)).build();

  _$Notifications._(
      {this.fsUpdate,
      this.criticalCountFlatten,
      this.warningCountFlatten,
      this.infoCountFlatten,
      this.alarmCounts})
      : super._();

  @override
  Notifications rebuild(void Function(NotificationsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationsBuilder toBuilder() => new NotificationsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Notifications &&
        fsUpdate == other.fsUpdate &&
        criticalCountFlatten == other.criticalCountFlatten &&
        warningCountFlatten == other.warningCountFlatten &&
        infoCountFlatten == other.infoCountFlatten &&
        alarmCounts == other.alarmCounts;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, fsUpdate.hashCode), criticalCountFlatten.hashCode),
                warningCountFlatten.hashCode),
            infoCountFlatten.hashCode),
        alarmCounts.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Notifications')
          ..add('fsUpdate', fsUpdate)
          ..add('criticalCountFlatten', criticalCountFlatten)
          ..add('warningCountFlatten', warningCountFlatten)
          ..add('infoCountFlatten', infoCountFlatten)
          ..add('alarmCounts', alarmCounts))
        .toString();
  }
}

class NotificationsBuilder
    implements Builder<Notifications, NotificationsBuilder> {
  _$Notifications _$v;

  String _fsUpdate;
  String get fsUpdate => _$this._fsUpdate;
  set fsUpdate(String fsUpdate) => _$this._fsUpdate = fsUpdate;

  int _criticalCountFlatten;
  int get criticalCountFlatten => _$this._criticalCountFlatten;
  set criticalCountFlatten(int criticalCountFlatten) =>
      _$this._criticalCountFlatten = criticalCountFlatten;

  int _warningCountFlatten;
  int get warningCountFlatten => _$this._warningCountFlatten;
  set warningCountFlatten(int warningCountFlatten) =>
      _$this._warningCountFlatten = warningCountFlatten;

  int _infoCountFlatten;
  int get infoCountFlatten => _$this._infoCountFlatten;
  set infoCountFlatten(int infoCountFlatten) =>
      _$this._infoCountFlatten = infoCountFlatten;

  ListBuilder<Alarm> _alarmCounts;
  ListBuilder<Alarm> get alarmCounts =>
      _$this._alarmCounts ??= new ListBuilder<Alarm>();
  set alarmCounts(ListBuilder<Alarm> alarmCounts) =>
      _$this._alarmCounts = alarmCounts;

  NotificationsBuilder();

  NotificationsBuilder get _$this {
    if (_$v != null) {
      _fsUpdate = _$v.fsUpdate;
      _criticalCountFlatten = _$v.criticalCountFlatten;
      _warningCountFlatten = _$v.warningCountFlatten;
      _infoCountFlatten = _$v.infoCountFlatten;
      _alarmCounts = _$v.alarmCounts?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Notifications other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Notifications;
  }

  @override
  void update(void Function(NotificationsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Notifications build() {
    _$Notifications _$result;
    try {
      _$result = _$v ??
          new _$Notifications._(
              fsUpdate: fsUpdate,
              criticalCountFlatten: criticalCountFlatten,
              warningCountFlatten: warningCountFlatten,
              infoCountFlatten: infoCountFlatten,
              alarmCounts: _alarmCounts?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'alarmCounts';
        _alarmCounts?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Notifications', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
