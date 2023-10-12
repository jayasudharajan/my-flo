// GENERATED CODE - DO NOT MODIFY BY HAND

part of subscription;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Subscription> _$subscriptionSerializer =
    new _$SubscriptionSerializer();

class _$SubscriptionSerializer implements StructuredSerializer<Subscription> {
  @override
  final Iterable<Type> types = const [Subscription, _$Subscription];
  @override
  final String wireName = 'Subscription';

  @override
  Iterable<Object> serialize(Serializers serializers, Subscription object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.isActive != null) {
      result
        ..add('isActive')
        ..add(serializers.serialize(object.isActive,
            specifiedType: const FullType(bool)));
    }
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    if (object.provider != null) {
      result
        ..add('providerInfo')
        ..add(serializers.serialize(object.provider,
            specifiedType: const FullType(SubscriptionProvider)));
    }
    return result;
  }

  @override
  Subscription deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new SubscriptionBuilder();

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
        case 'isActive':
          result.isActive = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'providerInfo':
          result.provider.replace(serializers.deserialize(value,
                  specifiedType: const FullType(SubscriptionProvider))
              as SubscriptionProvider);
          break;
      }
    }

    return result.build();
  }
}

class _$Subscription extends Subscription {
  @override
  final String id;
  @override
  final bool isActive;
  @override
  final String status;
  @override
  final SubscriptionProvider provider;

  factory _$Subscription([void Function(SubscriptionBuilder) updates]) =>
      (new SubscriptionBuilder()..update(updates)).build();

  _$Subscription._({this.id, this.isActive, this.status, this.provider})
      : super._();

  @override
  Subscription rebuild(void Function(SubscriptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubscriptionBuilder toBuilder() => new SubscriptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Subscription &&
        id == other.id &&
        isActive == other.isActive &&
        status == other.status &&
        provider == other.provider;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, id.hashCode), isActive.hashCode), status.hashCode),
        provider.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Subscription')
          ..add('id', id)
          ..add('isActive', isActive)
          ..add('status', status)
          ..add('provider', provider))
        .toString();
  }
}

class SubscriptionBuilder
    implements Builder<Subscription, SubscriptionBuilder> {
  _$Subscription _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  bool _isActive;
  bool get isActive => _$this._isActive;
  set isActive(bool isActive) => _$this._isActive = isActive;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  SubscriptionProviderBuilder _provider;
  SubscriptionProviderBuilder get provider =>
      _$this._provider ??= new SubscriptionProviderBuilder();
  set provider(SubscriptionProviderBuilder provider) =>
      _$this._provider = provider;

  SubscriptionBuilder();

  SubscriptionBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _isActive = _$v.isActive;
      _status = _$v.status;
      _provider = _$v.provider?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Subscription other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Subscription;
  }

  @override
  void update(void Function(SubscriptionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Subscription build() {
    _$Subscription _$result;
    try {
      _$result = _$v ??
          new _$Subscription._(
              id: id,
              isActive: isActive,
              status: status,
              provider: _provider?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'provider';
        _provider?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Subscription', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
