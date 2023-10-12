// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_detect_feedback_payload;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FloDetectFeedbackPayload> _$floDetectFeedbackPayloadSerializer =
    new _$FloDetectFeedbackPayloadSerializer();

class _$FloDetectFeedbackPayloadSerializer
    implements StructuredSerializer<FloDetectFeedbackPayload> {
  @override
  final Iterable<Type> types = const [
    FloDetectFeedbackPayload,
    _$FloDetectFeedbackPayload
  ];
  @override
  final String wireName = 'FloDetectFeedbackPayload';

  @override
  Iterable<Object> serialize(
      Serializers serializers, FloDetectFeedbackPayload object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.feedback != null) {
      result
        ..add('feedback')
        ..add(serializers.serialize(object.feedback,
            specifiedType: const FullType(FloDetectFeedback)));
    }
    return result;
  }

  @override
  FloDetectFeedbackPayload deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FloDetectFeedbackPayloadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'feedback':
          result.feedback.replace(serializers.deserialize(value,
                  specifiedType: const FullType(FloDetectFeedback))
              as FloDetectFeedback);
          break;
      }
    }

    return result.build();
  }
}

class _$FloDetectFeedbackPayload extends FloDetectFeedbackPayload {
  @override
  final FloDetectFeedback feedback;

  factory _$FloDetectFeedbackPayload(
          [void Function(FloDetectFeedbackPayloadBuilder) updates]) =>
      (new FloDetectFeedbackPayloadBuilder()..update(updates)).build();

  _$FloDetectFeedbackPayload._({this.feedback}) : super._();

  @override
  FloDetectFeedbackPayload rebuild(
          void Function(FloDetectFeedbackPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FloDetectFeedbackPayloadBuilder toBuilder() =>
      new FloDetectFeedbackPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FloDetectFeedbackPayload && feedback == other.feedback;
  }

  @override
  int get hashCode {
    return $jf($jc(0, feedback.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FloDetectFeedbackPayload')
          ..add('feedback', feedback))
        .toString();
  }
}

class FloDetectFeedbackPayloadBuilder
    implements
        Builder<FloDetectFeedbackPayload, FloDetectFeedbackPayloadBuilder> {
  _$FloDetectFeedbackPayload _$v;

  FloDetectFeedbackBuilder _feedback;
  FloDetectFeedbackBuilder get feedback =>
      _$this._feedback ??= new FloDetectFeedbackBuilder();
  set feedback(FloDetectFeedbackBuilder feedback) =>
      _$this._feedback = feedback;

  FloDetectFeedbackPayloadBuilder();

  FloDetectFeedbackPayloadBuilder get _$this {
    if (_$v != null) {
      _feedback = _$v.feedback?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FloDetectFeedbackPayload other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FloDetectFeedbackPayload;
  }

  @override
  void update(void Function(FloDetectFeedbackPayloadBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FloDetectFeedbackPayload build() {
    _$FloDetectFeedbackPayload _$result;
    try {
      _$result =
          _$v ?? new _$FloDetectFeedbackPayload._(feedback: _feedback?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'feedback';
        _feedback?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FloDetectFeedbackPayload', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
