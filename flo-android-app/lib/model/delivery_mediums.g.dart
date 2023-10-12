// GENERATED CODE - DO NOT MODIFY BY HAND

part of delivery_mediums;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DeliveryMediums> _$deliveryMediumsSerializer =
    new _$DeliveryMediumsSerializer();

class _$DeliveryMediumsSerializer
    implements StructuredSerializer<DeliveryMediums> {
  @override
  final Iterable<Type> types = const [DeliveryMediums, _$DeliveryMediums];
  @override
  final String wireName = 'DeliveryMediums';

  @override
  Iterable<Object> serialize(Serializers serializers, DeliveryMediums object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.sms != null) {
      result
        ..add('sms')
        ..add(serializers.serialize(object.sms,
            specifiedType: const FullType(DeliveryMedium)));
    }
    if (object.push != null) {
      result
        ..add('push')
        ..add(serializers.serialize(object.push,
            specifiedType: const FullType(DeliveryMedium)));
    }
    if (object.call != null) {
      result
        ..add('call')
        ..add(serializers.serialize(object.call,
            specifiedType: const FullType(DeliveryMedium)));
    }
    if (object.email != null) {
      result
        ..add('email')
        ..add(serializers.serialize(object.email,
            specifiedType: const FullType(DeliveryMedium)));
    }
    if (object.userConfigurable != null) {
      result
        ..add('userConfigurable')
        ..add(serializers.serialize(object.userConfigurable,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  DeliveryMediums deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DeliveryMediumsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'sms':
          result.sms.replace(serializers.deserialize(value,
              specifiedType: const FullType(DeliveryMedium)) as DeliveryMedium);
          break;
        case 'push':
          result.push.replace(serializers.deserialize(value,
              specifiedType: const FullType(DeliveryMedium)) as DeliveryMedium);
          break;
        case 'call':
          result.call.replace(serializers.deserialize(value,
              specifiedType: const FullType(DeliveryMedium)) as DeliveryMedium);
          break;
        case 'email':
          result.email.replace(serializers.deserialize(value,
              specifiedType: const FullType(DeliveryMedium)) as DeliveryMedium);
          break;
        case 'userConfigurable':
          result.userConfigurable = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$DeliveryMediums extends DeliveryMediums {
  @override
  final DeliveryMedium sms;
  @override
  final DeliveryMedium push;
  @override
  final DeliveryMedium call;
  @override
  final DeliveryMedium email;
  @override
  final bool userConfigurable;

  factory _$DeliveryMediums([void Function(DeliveryMediumsBuilder) updates]) =>
      (new DeliveryMediumsBuilder()..update(updates)).build();

  _$DeliveryMediums._(
      {this.sms, this.push, this.call, this.email, this.userConfigurable})
      : super._();

  @override
  DeliveryMediums rebuild(void Function(DeliveryMediumsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeliveryMediumsBuilder toBuilder() =>
      new DeliveryMediumsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeliveryMediums &&
        sms == other.sms &&
        push == other.push &&
        call == other.call &&
        email == other.email &&
        userConfigurable == other.userConfigurable;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc($jc(0, sms.hashCode), push.hashCode), call.hashCode),
            email.hashCode),
        userConfigurable.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DeliveryMediums')
          ..add('sms', sms)
          ..add('push', push)
          ..add('call', call)
          ..add('email', email)
          ..add('userConfigurable', userConfigurable))
        .toString();
  }
}

class DeliveryMediumsBuilder
    implements Builder<DeliveryMediums, DeliveryMediumsBuilder> {
  _$DeliveryMediums _$v;

  DeliveryMediumBuilder _sms;
  DeliveryMediumBuilder get sms => _$this._sms ??= new DeliveryMediumBuilder();
  set sms(DeliveryMediumBuilder sms) => _$this._sms = sms;

  DeliveryMediumBuilder _push;
  DeliveryMediumBuilder get push =>
      _$this._push ??= new DeliveryMediumBuilder();
  set push(DeliveryMediumBuilder push) => _$this._push = push;

  DeliveryMediumBuilder _call;
  DeliveryMediumBuilder get call =>
      _$this._call ??= new DeliveryMediumBuilder();
  set call(DeliveryMediumBuilder call) => _$this._call = call;

  DeliveryMediumBuilder _email;
  DeliveryMediumBuilder get email =>
      _$this._email ??= new DeliveryMediumBuilder();
  set email(DeliveryMediumBuilder email) => _$this._email = email;

  bool _userConfigurable;
  bool get userConfigurable => _$this._userConfigurable;
  set userConfigurable(bool userConfigurable) =>
      _$this._userConfigurable = userConfigurable;

  DeliveryMediumsBuilder();

  DeliveryMediumsBuilder get _$this {
    if (_$v != null) {
      _sms = _$v.sms?.toBuilder();
      _push = _$v.push?.toBuilder();
      _call = _$v.call?.toBuilder();
      _email = _$v.email?.toBuilder();
      _userConfigurable = _$v.userConfigurable;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeliveryMediums other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DeliveryMediums;
  }

  @override
  void update(void Function(DeliveryMediumsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DeliveryMediums build() {
    _$DeliveryMediums _$result;
    try {
      _$result = _$v ??
          new _$DeliveryMediums._(
              sms: _sms?.build(),
              push: _push?.build(),
              call: _call?.build(),
              email: _email?.build(),
              userConfigurable: userConfigurable);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'sms';
        _sms?.build();
        _$failedField = 'push';
        _push?.build();
        _$failedField = 'call';
        _call?.build();
        _$failedField = 'email';
        _email?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DeliveryMediums', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
