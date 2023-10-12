// GENERATED CODE - DO NOT MODIFY BY HAND

part of subscription_provider;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<SubscriptionProvider> _$subscriptionProviderSerializer =
    new _$SubscriptionProviderSerializer();

class _$SubscriptionProviderSerializer
    implements StructuredSerializer<SubscriptionProvider> {
  @override
  final Iterable<Type> types = const [
    SubscriptionProvider,
    _$SubscriptionProvider
  ];
  @override
  final String wireName = 'SubscriptionProvider';

  @override
  Iterable<Object> serialize(
      Serializers serializers, SubscriptionProvider object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.name != null) {
      result
        ..add('name')
        ..add(serializers.serialize(object.name,
            specifiedType: const FullType(String)));
    }
    if (object.isActive != null) {
      result
        ..add('isActive')
        ..add(serializers.serialize(object.isActive,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  SubscriptionProvider deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new SubscriptionProviderBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isActive':
          result.isActive = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$SubscriptionProvider extends SubscriptionProvider {
  @override
  final String name;
  @override
  final bool isActive;

  factory _$SubscriptionProvider(
          [void Function(SubscriptionProviderBuilder) updates]) =>
      (new SubscriptionProviderBuilder()..update(updates)).build();

  _$SubscriptionProvider._({this.name, this.isActive}) : super._();

  @override
  SubscriptionProvider rebuild(
          void Function(SubscriptionProviderBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubscriptionProviderBuilder toBuilder() =>
      new SubscriptionProviderBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubscriptionProvider &&
        name == other.name &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, name.hashCode), isActive.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SubscriptionProvider')
          ..add('name', name)
          ..add('isActive', isActive))
        .toString();
  }
}

class SubscriptionProviderBuilder
    implements Builder<SubscriptionProvider, SubscriptionProviderBuilder> {
  _$SubscriptionProvider _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  bool _isActive;
  bool get isActive => _$this._isActive;
  set isActive(bool isActive) => _$this._isActive = isActive;

  SubscriptionProviderBuilder();

  SubscriptionProviderBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _isActive = _$v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubscriptionProvider other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$SubscriptionProvider;
  }

  @override
  void update(void Function(SubscriptionProviderBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$SubscriptionProvider build() {
    final _$result =
        _$v ?? new _$SubscriptionProvider._(name: name, isActive: isActive);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
