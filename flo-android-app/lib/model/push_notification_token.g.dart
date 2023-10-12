// GENERATED CODE - DO NOT MODIFY BY HAND

part of push_notification_token;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PushNotificationToken> _$pushNotificationTokenSerializer =
    new _$PushNotificationTokenSerializer();

class _$PushNotificationTokenSerializer
    implements StructuredSerializer<PushNotificationToken> {
  @override
  final Iterable<Type> types = const [
    PushNotificationToken,
    _$PushNotificationToken
  ];
  @override
  final String wireName = 'PushNotificationToken';

  @override
  Iterable<Object> serialize(
      Serializers serializers, PushNotificationToken object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.mobileDeviceId != null) {
      result
        ..add('mobile_device_id')
        ..add(serializers.serialize(object.mobileDeviceId,
            specifiedType: const FullType(String)));
    }
    if (object.clientId != null) {
      result
        ..add('client_id')
        ..add(serializers.serialize(object.clientId,
            specifiedType: const FullType(String)));
    }
    if (object.userId != null) {
      result
        ..add('user_id')
        ..add(serializers.serialize(object.userId,
            specifiedType: const FullType(String)));
    }
    if (object.token != null) {
      result
        ..add('token')
        ..add(serializers.serialize(object.token,
            specifiedType: const FullType(String)));
    }
    if (object.awsEndpointId != null) {
      result
        ..add('aws_endpoint_id')
        ..add(serializers.serialize(object.awsEndpointId,
            specifiedType: const FullType(String)));
    }
    if (object.clientType != null) {
      result
        ..add('client_type')
        ..add(serializers.serialize(object.clientType,
            specifiedType: const FullType(int)));
    }
    if (object.createdAt != null) {
      result
        ..add('created_at')
        ..add(serializers.serialize(object.createdAt,
            specifiedType: const FullType(String)));
    }
    if (object.updatedAt != null) {
      result
        ..add('updated_at')
        ..add(serializers.serialize(object.updatedAt,
            specifiedType: const FullType(String)));
    }
    if (object.isDisabled != null) {
      result
        ..add('is_disabled')
        ..add(serializers.serialize(object.isDisabled,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  PushNotificationToken deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PushNotificationTokenBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'mobile_device_id':
          result.mobileDeviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_id':
          result.clientId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'user_id':
          result.userId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'token':
          result.token = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'aws_endpoint_id':
          result.awsEndpointId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_type':
          result.clientType = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'created_at':
          result.createdAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'updated_at':
          result.updatedAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'is_disabled':
          result.isDisabled = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$PushNotificationToken extends PushNotificationToken {
  @override
  final String mobileDeviceId;
  @override
  final String clientId;
  @override
  final String userId;
  @override
  final String token;
  @override
  final String awsEndpointId;
  @override
  final int clientType;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final int isDisabled;

  factory _$PushNotificationToken(
          [void Function(PushNotificationTokenBuilder) updates]) =>
      (new PushNotificationTokenBuilder()..update(updates)).build();

  _$PushNotificationToken._(
      {this.mobileDeviceId,
      this.clientId,
      this.userId,
      this.token,
      this.awsEndpointId,
      this.clientType,
      this.createdAt,
      this.updatedAt,
      this.isDisabled})
      : super._();

  @override
  PushNotificationToken rebuild(
          void Function(PushNotificationTokenBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushNotificationTokenBuilder toBuilder() =>
      new PushNotificationTokenBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushNotificationToken &&
        mobileDeviceId == other.mobileDeviceId &&
        clientId == other.clientId &&
        userId == other.userId &&
        token == other.token &&
        awsEndpointId == other.awsEndpointId &&
        clientType == other.clientType &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        isDisabled == other.isDisabled;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc($jc(0, mobileDeviceId.hashCode),
                                    clientId.hashCode),
                                userId.hashCode),
                            token.hashCode),
                        awsEndpointId.hashCode),
                    clientType.hashCode),
                createdAt.hashCode),
            updatedAt.hashCode),
        isDisabled.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PushNotificationToken')
          ..add('mobileDeviceId', mobileDeviceId)
          ..add('clientId', clientId)
          ..add('userId', userId)
          ..add('token', token)
          ..add('awsEndpointId', awsEndpointId)
          ..add('clientType', clientType)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('isDisabled', isDisabled))
        .toString();
  }
}

class PushNotificationTokenBuilder
    implements Builder<PushNotificationToken, PushNotificationTokenBuilder> {
  _$PushNotificationToken _$v;

  String _mobileDeviceId;
  String get mobileDeviceId => _$this._mobileDeviceId;
  set mobileDeviceId(String mobileDeviceId) =>
      _$this._mobileDeviceId = mobileDeviceId;

  String _clientId;
  String get clientId => _$this._clientId;
  set clientId(String clientId) => _$this._clientId = clientId;

  String _userId;
  String get userId => _$this._userId;
  set userId(String userId) => _$this._userId = userId;

  String _token;
  String get token => _$this._token;
  set token(String token) => _$this._token = token;

  String _awsEndpointId;
  String get awsEndpointId => _$this._awsEndpointId;
  set awsEndpointId(String awsEndpointId) =>
      _$this._awsEndpointId = awsEndpointId;

  int _clientType;
  int get clientType => _$this._clientType;
  set clientType(int clientType) => _$this._clientType = clientType;

  String _createdAt;
  String get createdAt => _$this._createdAt;
  set createdAt(String createdAt) => _$this._createdAt = createdAt;

  String _updatedAt;
  String get updatedAt => _$this._updatedAt;
  set updatedAt(String updatedAt) => _$this._updatedAt = updatedAt;

  int _isDisabled;
  int get isDisabled => _$this._isDisabled;
  set isDisabled(int isDisabled) => _$this._isDisabled = isDisabled;

  PushNotificationTokenBuilder();

  PushNotificationTokenBuilder get _$this {
    if (_$v != null) {
      _mobileDeviceId = _$v.mobileDeviceId;
      _clientId = _$v.clientId;
      _userId = _$v.userId;
      _token = _$v.token;
      _awsEndpointId = _$v.awsEndpointId;
      _clientType = _$v.clientType;
      _createdAt = _$v.createdAt;
      _updatedAt = _$v.updatedAt;
      _isDisabled = _$v.isDisabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushNotificationToken other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PushNotificationToken;
  }

  @override
  void update(void Function(PushNotificationTokenBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PushNotificationToken build() {
    final _$result = _$v ??
        new _$PushNotificationToken._(
            mobileDeviceId: mobileDeviceId,
            clientId: clientId,
            userId: userId,
            token: token,
            awsEndpointId: awsEndpointId,
            clientType: clientType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDisabled: isDisabled);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
