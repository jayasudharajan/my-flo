// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedbacks;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedbacks> _$alertFeedbacksSerializer =
    new _$AlertFeedbacksSerializer();

class _$AlertFeedbacksSerializer
    implements StructuredSerializer<AlertFeedbacks> {
  @override
  final Iterable<Type> types = const [AlertFeedbacks, _$AlertFeedbacks];
  @override
  final String wireName = 'AlertFeedbacks';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertFeedbacks object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.userId != null) {
      result
        ..add('userId')
        ..add(serializers.serialize(object.userId,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.createdAt != null) {
      result
        ..add('createdAt')
        ..add(serializers.serialize(object.createdAt,
            specifiedType: const FullType(String)));
    }
    if (object.feedbacks != null) {
      result
        ..add('feedback')
        ..add(serializers.serialize(object.feedbacks,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlertFeedbackOption)])));
    }
    return result;
  }

  @override
  AlertFeedbacks deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbacksBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'userId':
          result.userId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'createdAt':
          result.createdAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'feedback':
          result.feedbacks.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlertFeedbackOption)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedbacks extends AlertFeedbacks {
  @override
  final String userId;
  @override
  final String deviceId;
  @override
  final String createdAt;
  @override
  final BuiltList<AlertFeedbackOption> feedbacks;

  factory _$AlertFeedbacks([void Function(AlertFeedbacksBuilder) updates]) =>
      (new AlertFeedbacksBuilder()..update(updates)).build();

  _$AlertFeedbacks._(
      {this.userId, this.deviceId, this.createdAt, this.feedbacks})
      : super._();

  @override
  AlertFeedbacks rebuild(void Function(AlertFeedbacksBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbacksBuilder toBuilder() =>
      new AlertFeedbacksBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedbacks &&
        userId == other.userId &&
        deviceId == other.deviceId &&
        createdAt == other.createdAt &&
        feedbacks == other.feedbacks;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, userId.hashCode), deviceId.hashCode),
            createdAt.hashCode),
        feedbacks.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedbacks')
          ..add('userId', userId)
          ..add('deviceId', deviceId)
          ..add('createdAt', createdAt)
          ..add('feedbacks', feedbacks))
        .toString();
  }
}

class AlertFeedbacksBuilder
    implements Builder<AlertFeedbacks, AlertFeedbacksBuilder> {
  _$AlertFeedbacks _$v;

  String _userId;
  String get userId => _$this._userId;
  set userId(String userId) => _$this._userId = userId;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _createdAt;
  String get createdAt => _$this._createdAt;
  set createdAt(String createdAt) => _$this._createdAt = createdAt;

  ListBuilder<AlertFeedbackOption> _feedbacks;
  ListBuilder<AlertFeedbackOption> get feedbacks =>
      _$this._feedbacks ??= new ListBuilder<AlertFeedbackOption>();
  set feedbacks(ListBuilder<AlertFeedbackOption> feedbacks) =>
      _$this._feedbacks = feedbacks;

  AlertFeedbacksBuilder();

  AlertFeedbacksBuilder get _$this {
    if (_$v != null) {
      _userId = _$v.userId;
      _deviceId = _$v.deviceId;
      _createdAt = _$v.createdAt;
      _feedbacks = _$v.feedbacks?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedbacks other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedbacks;
  }

  @override
  void update(void Function(AlertFeedbacksBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedbacks build() {
    _$AlertFeedbacks _$result;
    try {
      _$result = _$v ??
          new _$AlertFeedbacks._(
              userId: userId,
              deviceId: deviceId,
              createdAt: createdAt,
              feedbacks: _feedbacks?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'feedbacks';
        _feedbacks?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertFeedbacks', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
