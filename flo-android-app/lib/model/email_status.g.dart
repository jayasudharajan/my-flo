// GENERATED CODE - DO NOT MODIFY BY HAND

part of email_status;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<EmailStatus> _$emailStatusSerializer = new _$EmailStatusSerializer();

class _$EmailStatusSerializer implements StructuredSerializer<EmailStatus> {
  @override
  final Iterable<Type> types = const [EmailStatus, _$EmailStatus];
  @override
  final String wireName = 'EmailStatus';

  @override
  Iterable<Object> serialize(Serializers serializers, EmailStatus object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'is_registered',
      serializers.serialize(object.isRegistered,
          specifiedType: const FullType(bool)),
      'is_pending',
      serializers.serialize(object.isPending,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  EmailStatus deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new EmailStatusBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'is_registered':
          result.isRegistered = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'is_pending':
          result.isPending = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$EmailStatus extends EmailStatus {
  @override
  final bool isRegistered;
  @override
  final bool isPending;

  factory _$EmailStatus([void Function(EmailStatusBuilder) updates]) =>
      (new EmailStatusBuilder()..update(updates)).build();

  _$EmailStatus._({this.isRegistered, this.isPending}) : super._() {
    if (isRegistered == null) {
      throw new BuiltValueNullFieldError('EmailStatus', 'isRegistered');
    }
    if (isPending == null) {
      throw new BuiltValueNullFieldError('EmailStatus', 'isPending');
    }
  }

  @override
  EmailStatus rebuild(void Function(EmailStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EmailStatusBuilder toBuilder() => new EmailStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EmailStatus &&
        isRegistered == other.isRegistered &&
        isPending == other.isPending;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, isRegistered.hashCode), isPending.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EmailStatus')
          ..add('isRegistered', isRegistered)
          ..add('isPending', isPending))
        .toString();
  }
}

class EmailStatusBuilder implements Builder<EmailStatus, EmailStatusBuilder> {
  _$EmailStatus _$v;

  bool _isRegistered;
  bool get isRegistered => _$this._isRegistered;
  set isRegistered(bool isRegistered) => _$this._isRegistered = isRegistered;

  bool _isPending;
  bool get isPending => _$this._isPending;
  set isPending(bool isPending) => _$this._isPending = isPending;

  EmailStatusBuilder();

  EmailStatusBuilder get _$this {
    if (_$v != null) {
      _isRegistered = _$v.isRegistered;
      _isPending = _$v.isPending;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EmailStatus other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$EmailStatus;
  }

  @override
  void update(void Function(EmailStatusBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EmailStatus build() {
    final _$result = _$v ??
        new _$EmailStatus._(isRegistered: isRegistered, isPending: isPending);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
