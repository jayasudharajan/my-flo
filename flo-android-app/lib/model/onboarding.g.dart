// GENERATED CODE - DO NOT MODIFY BY HAND

part of onboarding;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Onboarding> _$onboardingSerializer = new _$OnboardingSerializer();

class _$OnboardingSerializer implements StructuredSerializer<Onboarding> {
  @override
  final Iterable<Type> types = const [Onboarding, _$Onboarding];
  @override
  final String wireName = 'Onboarding';

  @override
  Iterable<Object> serialize(Serializers serializers, Onboarding object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('device_id')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.event != null) {
      result
        ..add('event')
        ..add(serializers.serialize(object.event,
            specifiedType: const FullType(Name)));
    }
    return result;
  }

  @override
  Onboarding deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OnboardingBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'device_id':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'event':
          result.event.replace(serializers.deserialize(value,
              specifiedType: const FullType(Name)) as Name);
          break;
      }
    }

    return result.build();
  }
}

class _$Onboarding extends Onboarding {
  @override
  final String id;
  @override
  final String deviceId;
  @override
  final Name event;

  factory _$Onboarding([void Function(OnboardingBuilder) updates]) =>
      (new OnboardingBuilder()..update(updates)).build();

  _$Onboarding._({this.id, this.deviceId, this.event}) : super._();

  @override
  Onboarding rebuild(void Function(OnboardingBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OnboardingBuilder toBuilder() => new OnboardingBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Onboarding &&
        id == other.id &&
        deviceId == other.deviceId &&
        event == other.event;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, id.hashCode), deviceId.hashCode), event.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Onboarding')
          ..add('id', id)
          ..add('deviceId', deviceId)
          ..add('event', event))
        .toString();
  }
}

class OnboardingBuilder implements Builder<Onboarding, OnboardingBuilder> {
  _$Onboarding _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  NameBuilder _event;
  NameBuilder get event => _$this._event ??= new NameBuilder();
  set event(NameBuilder event) => _$this._event = event;

  OnboardingBuilder();

  OnboardingBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _deviceId = _$v.deviceId;
      _event = _$v.event?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Onboarding other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Onboarding;
  }

  @override
  void update(void Function(OnboardingBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Onboarding build() {
    _$Onboarding _$result;
    try {
      _$result = _$v ??
          new _$Onboarding._(
              id: id, deviceId: deviceId, event: _event?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'event';
        _event?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Onboarding', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
