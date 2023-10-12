// GENERATED CODE - DO NOT MODIFY BY HAND

part of logout_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<LogoutPayload> _$logoutPayloadSerializer =
    new _$LogoutPayloadSerializer();

class _$LogoutPayloadSerializer implements StructuredSerializer<LogoutPayload> {
  @override
  final Iterable<Type> types = const [LogoutPayload, _$LogoutPayload];
  @override
  final String wireName = 'LogoutPayload';

  @override
  Iterable<Object> serialize(Serializers serializers, LogoutPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'mobile_device_id',
      serializers.serialize(object.deviceId,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  LogoutPayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LogoutPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'mobile_device_id':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$LogoutPayload extends LogoutPayload {
  @override
  final String deviceId;

  factory _$LogoutPayload([void Function(LogoutPayloadBuilder) updates]) =>
      (new LogoutPayloadBuilder()..update(updates)).build();

  _$LogoutPayload._({this.deviceId}) : super._() {
    if (deviceId == null) {
      throw new BuiltValueNullFieldError('LogoutPayload', 'deviceId');
    }
  }

  @override
  LogoutPayload rebuild(void Function(LogoutPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LogoutPayloadBuilder toBuilder() => new LogoutPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogoutPayload && deviceId == other.deviceId;
  }

  @override
  int get hashCode {
    return $jf($jc(0, deviceId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LogoutPayload')
          ..add('deviceId', deviceId))
        .toString();
  }
}

class LogoutPayloadBuilder
    implements Builder<LogoutPayload, LogoutPayloadBuilder> {
  _$LogoutPayload _$v;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  LogoutPayloadBuilder();

  LogoutPayloadBuilder get _$this {
    if (_$v != null) {
      _deviceId = _$v.deviceId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogoutPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LogoutPayload;
  }

  @override
  void update(void Function(LogoutPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LogoutPayload build() {
    final _$result = _$v ?? new _$LogoutPayload._(deviceId: deviceId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
