// GENERATED CODE - DO NOT MODIFY BY HAND

part of push_notification;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PushNotification> _$pushNotificationSerializer =
    new _$PushNotificationSerializer();

class _$PushNotificationSerializer
    implements StructuredSerializer<PushNotification> {
  @override
  final Iterable<Type> types = const [PushNotification, _$PushNotification];
  @override
  final String wireName = 'PushNotification';

  @override
  Iterable<Object> serialize(Serializers serializers, PushNotification object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.notification != null) {
      result
        ..add('notification')
        ..add(serializers.serialize(object.notification,
            specifiedType: const FullType(PendingPushNotification)));
    }
    if (object.data != null) {
      result
        ..add('data')
        ..add(serializers.serialize(object.data,
            specifiedType: const FullType(PushNotificationData)));
    }
    return result;
  }

  @override
  PushNotification deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PushNotificationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'notification':
          result.notification.replace(serializers.deserialize(value,
                  specifiedType: const FullType(PendingPushNotification))
              as PendingPushNotification);
          break;
        case 'data':
          result.data.replace(serializers.deserialize(value,
                  specifiedType: const FullType(PushNotificationData))
              as PushNotificationData);
          break;
      }
    }

    return result.build();
  }
}

class _$PushNotification extends PushNotification {
  @override
  final PendingPushNotification notification;
  @override
  final PushNotificationData data;

  factory _$PushNotification(
          [void Function(PushNotificationBuilder) updates]) =>
      (new PushNotificationBuilder()..update(updates)).build();

  _$PushNotification._({this.notification, this.data}) : super._();

  @override
  PushNotification rebuild(void Function(PushNotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushNotificationBuilder toBuilder() =>
      new PushNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushNotification &&
        notification == other.notification &&
        data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, notification.hashCode), data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PushNotification')
          ..add('notification', notification)
          ..add('data', data))
        .toString();
  }
}

class PushNotificationBuilder
    implements Builder<PushNotification, PushNotificationBuilder> {
  _$PushNotification _$v;

  PendingPushNotificationBuilder _notification;
  PendingPushNotificationBuilder get notification =>
      _$this._notification ??= new PendingPushNotificationBuilder();
  set notification(PendingPushNotificationBuilder notification) =>
      _$this._notification = notification;

  PushNotificationDataBuilder _data;
  PushNotificationDataBuilder get data =>
      _$this._data ??= new PushNotificationDataBuilder();
  set data(PushNotificationDataBuilder data) => _$this._data = data;

  PushNotificationBuilder();

  PushNotificationBuilder get _$this {
    if (_$v != null) {
      _notification = _$v.notification?.toBuilder();
      _data = _$v.data?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushNotification other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PushNotification;
  }

  @override
  void update(void Function(PushNotificationBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PushNotification build() {
    _$PushNotification _$result;
    try {
      _$result = _$v ??
          new _$PushNotification._(
              notification: _notification?.build(), data: _data?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'notification';
        _notification?.build();
        _$failedField = 'data';
        _data?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PushNotification', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
