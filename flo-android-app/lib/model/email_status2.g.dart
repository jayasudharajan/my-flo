// GENERATED CODE - DO NOT MODIFY BY HAND

part of email_status2;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<EmailStatus2> _$emailStatus2Serializer =
    new _$EmailStatus2Serializer();

class _$EmailStatus2Serializer implements StructuredSerializer<EmailStatus2> {
  @override
  final Iterable<Type> types = const [EmailStatus2, _$EmailStatus2];
  @override
  final String wireName = 'EmailStatus2';

  @override
  Iterable<Object> serialize(Serializers serializers, EmailStatus2 object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'isRegistered',
      serializers.serialize(object.isRegistered,
          specifiedType: const FullType(bool)),
      'isPending',
      serializers.serialize(object.isPending,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  EmailStatus2 deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new EmailStatus2Builder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'isRegistered':
          result.isRegistered = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'isPending':
          result.isPending = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$EmailStatus2 extends EmailStatus2 {
  @override
  final bool isRegistered;
  @override
  final bool isPending;

  factory _$EmailStatus2([void Function(EmailStatus2Builder) updates]) =>
      (new EmailStatus2Builder()..update(updates)).build();

  _$EmailStatus2._({this.isRegistered, this.isPending}) : super._() {
    if (isRegistered == null) {
      throw new BuiltValueNullFieldError('EmailStatus2', 'isRegistered');
    }
    if (isPending == null) {
      throw new BuiltValueNullFieldError('EmailStatus2', 'isPending');
    }
  }

  @override
  EmailStatus2 rebuild(void Function(EmailStatus2Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EmailStatus2Builder toBuilder() => new EmailStatus2Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EmailStatus2 &&
        isRegistered == other.isRegistered &&
        isPending == other.isPending;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, isRegistered.hashCode), isPending.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EmailStatus2')
          ..add('isRegistered', isRegistered)
          ..add('isPending', isPending))
        .toString();
  }
}

class EmailStatus2Builder
    implements Builder<EmailStatus2, EmailStatus2Builder> {
  _$EmailStatus2 _$v;

  bool _isRegistered;
  bool get isRegistered => _$this._isRegistered;
  set isRegistered(bool isRegistered) => _$this._isRegistered = isRegistered;

  bool _isPending;
  bool get isPending => _$this._isPending;
  set isPending(bool isPending) => _$this._isPending = isPending;

  EmailStatus2Builder();

  EmailStatus2Builder get _$this {
    if (_$v != null) {
      _isRegistered = _$v.isRegistered;
      _isPending = _$v.isPending;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EmailStatus2 other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$EmailStatus2;
  }

  @override
  void update(void Function(EmailStatus2Builder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EmailStatus2 build() {
    final _$result = _$v ??
        new _$EmailStatus2._(isRegistered: isRegistered, isPending: isPending);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
