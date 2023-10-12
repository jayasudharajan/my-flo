// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedback_flow_tags;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedbackFlowTags> _$alertFeedbackFlowTagsSerializer =
    new _$AlertFeedbackFlowTagsSerializer();

class _$AlertFeedbackFlowTagsSerializer
    implements StructuredSerializer<AlertFeedbackFlowTags> {
  @override
  final Iterable<Type> types = const [
    AlertFeedbackFlowTags,
    _$AlertFeedbackFlowTags
  ];
  @override
  final String wireName = 'AlertFeedbackFlowTags';

  @override
  Iterable<Object> serialize(
      Serializers serializers, AlertFeedbackFlowTags object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.sleepFlow != null) {
      result
        ..add('sleep_flow')
        ..add(serializers.serialize(object.sleepFlow,
            specifiedType: const FullType(AlertFeedbackStep)));
    }
    return result;
  }

  @override
  AlertFeedbackFlowTags deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbackFlowTagsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'sleep_flow':
          result.sleepFlow.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertFeedbackStep))
              as AlertFeedbackStep);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedbackFlowTags extends AlertFeedbackFlowTags {
  @override
  final AlertFeedbackStep sleepFlow;

  factory _$AlertFeedbackFlowTags(
          [void Function(AlertFeedbackFlowTagsBuilder) updates]) =>
      (new AlertFeedbackFlowTagsBuilder()..update(updates)).build();

  _$AlertFeedbackFlowTags._({this.sleepFlow}) : super._();

  @override
  AlertFeedbackFlowTags rebuild(
          void Function(AlertFeedbackFlowTagsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbackFlowTagsBuilder toBuilder() =>
      new AlertFeedbackFlowTagsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedbackFlowTags && sleepFlow == other.sleepFlow;
  }

  @override
  int get hashCode {
    return $jf($jc(0, sleepFlow.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedbackFlowTags')
          ..add('sleepFlow', sleepFlow))
        .toString();
  }
}

class AlertFeedbackFlowTagsBuilder
    implements Builder<AlertFeedbackFlowTags, AlertFeedbackFlowTagsBuilder> {
  _$AlertFeedbackFlowTags _$v;

  AlertFeedbackStepBuilder _sleepFlow;
  AlertFeedbackStepBuilder get sleepFlow =>
      _$this._sleepFlow ??= new AlertFeedbackStepBuilder();
  set sleepFlow(AlertFeedbackStepBuilder sleepFlow) =>
      _$this._sleepFlow = sleepFlow;

  AlertFeedbackFlowTagsBuilder();

  AlertFeedbackFlowTagsBuilder get _$this {
    if (_$v != null) {
      _sleepFlow = _$v.sleepFlow?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedbackFlowTags other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedbackFlowTags;
  }

  @override
  void update(void Function(AlertFeedbackFlowTagsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedbackFlowTags build() {
    _$AlertFeedbackFlowTags _$result;
    try {
      _$result =
          _$v ?? new _$AlertFeedbackFlowTags._(sleepFlow: _sleepFlow?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'sleepFlow';
        _sleepFlow?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertFeedbackFlowTags', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
