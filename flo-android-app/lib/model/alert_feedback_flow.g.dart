// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedback_flow;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedbackFlow> _$alertFeedbackFlowSerializer =
    new _$AlertFeedbackFlowSerializer();

class _$AlertFeedbackFlowSerializer
    implements StructuredSerializer<AlertFeedbackFlow> {
  @override
  final Iterable<Type> types = const [AlertFeedbackFlow, _$AlertFeedbackFlow];
  @override
  final String wireName = 'AlertFeedbackFlow';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertFeedbackFlow object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.systemMode != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemMode,
            specifiedType: const FullType(String)));
    }
    if (object.flow != null) {
      result
        ..add('flow')
        ..add(serializers.serialize(object.flow,
            specifiedType: const FullType(AlertFeedbackStep)));
    }
    if (object.flowTags != null) {
      result
        ..add('flowTags')
        ..add(serializers.serialize(object.flowTags,
            specifiedType: const FullType(AlertFeedbackFlowTags)));
    }
    return result;
  }

  @override
  AlertFeedbackFlow deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbackFlowBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'systemMode':
          result.systemMode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'flow':
          result.flow.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertFeedbackStep))
              as AlertFeedbackStep);
          break;
        case 'flowTags':
          result.flowTags.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertFeedbackFlowTags))
              as AlertFeedbackFlowTags);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedbackFlow extends AlertFeedbackFlow {
  @override
  final String systemMode;
  @override
  final AlertFeedbackStep flow;
  @override
  final AlertFeedbackFlowTags flowTags;

  factory _$AlertFeedbackFlow(
          [void Function(AlertFeedbackFlowBuilder) updates]) =>
      (new AlertFeedbackFlowBuilder()..update(updates)).build();

  _$AlertFeedbackFlow._({this.systemMode, this.flow, this.flowTags})
      : super._();

  @override
  AlertFeedbackFlow rebuild(void Function(AlertFeedbackFlowBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbackFlowBuilder toBuilder() =>
      new AlertFeedbackFlowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedbackFlow &&
        systemMode == other.systemMode &&
        flow == other.flow &&
        flowTags == other.flowTags;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, systemMode.hashCode), flow.hashCode), flowTags.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedbackFlow')
          ..add('systemMode', systemMode)
          ..add('flow', flow)
          ..add('flowTags', flowTags))
        .toString();
  }
}

class AlertFeedbackFlowBuilder
    implements Builder<AlertFeedbackFlow, AlertFeedbackFlowBuilder> {
  _$AlertFeedbackFlow _$v;

  String _systemMode;
  String get systemMode => _$this._systemMode;
  set systemMode(String systemMode) => _$this._systemMode = systemMode;

  AlertFeedbackStepBuilder _flow;
  AlertFeedbackStepBuilder get flow =>
      _$this._flow ??= new AlertFeedbackStepBuilder();
  set flow(AlertFeedbackStepBuilder flow) => _$this._flow = flow;

  AlertFeedbackFlowTagsBuilder _flowTags;
  AlertFeedbackFlowTagsBuilder get flowTags =>
      _$this._flowTags ??= new AlertFeedbackFlowTagsBuilder();
  set flowTags(AlertFeedbackFlowTagsBuilder flowTags) =>
      _$this._flowTags = flowTags;

  AlertFeedbackFlowBuilder();

  AlertFeedbackFlowBuilder get _$this {
    if (_$v != null) {
      _systemMode = _$v.systemMode;
      _flow = _$v.flow?.toBuilder();
      _flowTags = _$v.flowTags?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedbackFlow other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedbackFlow;
  }

  @override
  void update(void Function(AlertFeedbackFlowBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedbackFlow build() {
    _$AlertFeedbackFlow _$result;
    try {
      _$result = _$v ??
          new _$AlertFeedbackFlow._(
              systemMode: systemMode,
              flow: _flow?.build(),
              flowTags: _flowTags?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'flow';
        _flow?.build();
        _$failedField = 'flowTags';
        _flowTags?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertFeedbackFlow', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
