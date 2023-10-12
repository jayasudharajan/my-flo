// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedback_step;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedbackStep> _$alertFeedbackStepSerializer =
    new _$AlertFeedbackStepSerializer();

class _$AlertFeedbackStepSerializer
    implements StructuredSerializer<AlertFeedbackStep> {
  @override
  final Iterable<Type> types = const [AlertFeedbackStep, _$AlertFeedbackStep];
  @override
  final String wireName = 'AlertFeedbackStep';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertFeedbackStep object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.titleText != null) {
      result
        ..add('titleText')
        ..add(serializers.serialize(object.titleText,
            specifiedType: const FullType(String)));
    }
    if (object.type != null) {
      result
        ..add('type')
        ..add(serializers.serialize(object.type,
            specifiedType: const FullType(String)));
    }
    if (object.options != null) {
      result
        ..add('options')
        ..add(serializers.serialize(object.options,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlertFeedbackOption)])));
    }
    if (object.tag != null) {
      result
        ..add('tag')
        ..add(serializers.serialize(object.tag,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  AlertFeedbackStep deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbackStepBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'titleText':
          result.titleText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'options':
          result.options.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlertFeedbackOption)]))
              as BuiltList<dynamic>);
          break;
        case 'tag':
          result.tag = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedbackStep extends AlertFeedbackStep {
  @override
  final String titleText;
  @override
  final String type;
  @override
  final BuiltList<AlertFeedbackOption> options;
  @override
  final String tag;

  factory _$AlertFeedbackStep(
          [void Function(AlertFeedbackStepBuilder) updates]) =>
      (new AlertFeedbackStepBuilder()..update(updates)).build();

  _$AlertFeedbackStep._({this.titleText, this.type, this.options, this.tag})
      : super._();

  @override
  AlertFeedbackStep rebuild(void Function(AlertFeedbackStepBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbackStepBuilder toBuilder() =>
      new AlertFeedbackStepBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedbackStep &&
        titleText == other.titleText &&
        type == other.type &&
        options == other.options &&
        tag == other.tag;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, titleText.hashCode), type.hashCode), options.hashCode),
        tag.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedbackStep')
          ..add('titleText', titleText)
          ..add('type', type)
          ..add('options', options)
          ..add('tag', tag))
        .toString();
  }
}

class AlertFeedbackStepBuilder
    implements Builder<AlertFeedbackStep, AlertFeedbackStepBuilder> {
  _$AlertFeedbackStep _$v;

  String _titleText;
  String get titleText => _$this._titleText;
  set titleText(String titleText) => _$this._titleText = titleText;

  String _type;
  String get type => _$this._type;
  set type(String type) => _$this._type = type;

  ListBuilder<AlertFeedbackOption> _options;
  ListBuilder<AlertFeedbackOption> get options =>
      _$this._options ??= new ListBuilder<AlertFeedbackOption>();
  set options(ListBuilder<AlertFeedbackOption> options) =>
      _$this._options = options;

  String _tag;
  String get tag => _$this._tag;
  set tag(String tag) => _$this._tag = tag;

  AlertFeedbackStepBuilder();

  AlertFeedbackStepBuilder get _$this {
    if (_$v != null) {
      _titleText = _$v.titleText;
      _type = _$v.type;
      _options = _$v.options?.toBuilder();
      _tag = _$v.tag;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedbackStep other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedbackStep;
  }

  @override
  void update(void Function(AlertFeedbackStepBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedbackStep build() {
    _$AlertFeedbackStep _$result;
    try {
      _$result = _$v ??
          new _$AlertFeedbackStep._(
              titleText: titleText,
              type: type,
              options: _options?.build(),
              tag: tag);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'options';
        _options?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertFeedbackStep', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
