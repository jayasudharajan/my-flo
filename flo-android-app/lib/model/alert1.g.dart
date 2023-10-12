// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert1;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alert1> _$alert1Serializer = new _$Alert1Serializer();

class _$Alert1Serializer implements StructuredSerializer<Alert1> {
  @override
  final Iterable<Type> types = const [Alert1, _$Alert1];
  @override
  final String wireName = 'Alert1';

  @override
  Iterable<Object> serialize(Serializers serializers, Alert1 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.notification != null) {
      result
        ..add('notification')
        ..add(serializers.serialize(object.notification,
            specifiedType: const FullType(Alert1Notification)));
    }
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.icd != null) {
      result
        ..add('icd')
        ..add(serializers.serialize(object.icd,
            specifiedType: const FullType(Icd)));
    }
    if (object.ts != null) {
      result
        ..add('ts')
        ..add(serializers.serialize(object.ts,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Alert1 deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new Alert1Builder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'notification':
          result.notification.replace(serializers.deserialize(value,
                  specifiedType: const FullType(Alert1Notification))
              as Alert1Notification);
          break;
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'icd':
          result.icd.replace(serializers.deserialize(value,
              specifiedType: const FullType(Icd)) as Icd);
          break;
        case 'ts':
          result.ts = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Alert1 extends Alert1 {
  @override
  final Alert1Notification notification;
  @override
  final String id;
  @override
  final Icd icd;
  @override
  final String ts;

  factory _$Alert1([void Function(Alert1Builder) updates]) =>
      (new Alert1Builder()..update(updates)).build();

  _$Alert1._({this.notification, this.id, this.icd, this.ts}) : super._();

  @override
  Alert1 rebuild(void Function(Alert1Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  Alert1Builder toBuilder() => new Alert1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alert1 &&
        notification == other.notification &&
        id == other.id &&
        icd == other.icd &&
        ts == other.ts;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, notification.hashCode), id.hashCode), icd.hashCode),
        ts.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alert1')
          ..add('notification', notification)
          ..add('id', id)
          ..add('icd', icd)
          ..add('ts', ts))
        .toString();
  }
}

class Alert1Builder implements Builder<Alert1, Alert1Builder> {
  _$Alert1 _$v;

  Alert1NotificationBuilder _notification;
  Alert1NotificationBuilder get notification =>
      _$this._notification ??= new Alert1NotificationBuilder();
  set notification(Alert1NotificationBuilder notification) =>
      _$this._notification = notification;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  IcdBuilder _icd;
  IcdBuilder get icd => _$this._icd ??= new IcdBuilder();
  set icd(IcdBuilder icd) => _$this._icd = icd;

  String _ts;
  String get ts => _$this._ts;
  set ts(String ts) => _$this._ts = ts;

  Alert1Builder();

  Alert1Builder get _$this {
    if (_$v != null) {
      _notification = _$v.notification?.toBuilder();
      _id = _$v.id;
      _icd = _$v.icd?.toBuilder();
      _ts = _$v.ts;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alert1 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alert1;
  }

  @override
  void update(void Function(Alert1Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alert1 build() {
    _$Alert1 _$result;
    try {
      _$result = _$v ??
          new _$Alert1._(
              notification: _notification?.build(),
              id: id,
              icd: _icd?.build(),
              ts: ts);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'notification';
        _notification?.build();

        _$failedField = 'icd';
        _icd?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Alert1', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
