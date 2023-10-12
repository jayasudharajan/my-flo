// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedback_option;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedbackOption> _$alertFeedbackOptionSerializer =
    new _$AlertFeedbackOptionSerializer();

class _$AlertFeedbackOptionSerializer
    implements StructuredSerializer<AlertFeedbackOption> {
  @override
  final Iterable<Type> types = const [
    AlertFeedbackOption,
    _$AlertFeedbackOption
  ];
  @override
  final String wireName = 'AlertFeedbackOption';

  @override
  Iterable<Object> serialize(
      Serializers serializers, AlertFeedbackOption object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.property != null) {
      result
        ..add('property')
        ..add(serializers.serialize(object.property,
            specifiedType: const FullType(String)));
    }
    if (object.displayText != null) {
      result
        ..add('displayText')
        ..add(serializers.serialize(object.displayText,
            specifiedType: const FullType(String)));
    }
    if (object.sortOrder != null) {
      result
        ..add('sortOrder')
        ..add(serializers.serialize(object.sortOrder,
            specifiedType: const FullType(int)));
    }
    if (object.action != null) {
      result
        ..add('action')
        ..add(serializers.serialize(object.action,
            specifiedType: const FullType(String)));
    }
    if (object.value != null) {
      result
        ..add('value')
        ..add(serializers.serialize(object.value,
            specifiedType: const FullType(Object)));
    }
    if (object.flow != null) {
      result
        ..add('flow')
        ..add(serializers.serialize(object.flow,
            specifiedType: const FullType(AlertFeedbackStep)));
    }
    return result;
  }

  @override
  AlertFeedbackOption deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbackOptionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'property':
          result.property = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'displayText':
          result.displayText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'sortOrder':
          result.sortOrder = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'action':
          result.action = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'value':
          result.value = serializers.deserialize(value,
              specifiedType: const FullType(Object));
          break;
        case 'flow':
          result.flow.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertFeedbackStep))
              as AlertFeedbackStep);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedbackOption extends AlertFeedbackOption {
  @override
  final String property;
  @override
  final String displayText;
  @override
  final int sortOrder;
  @override
  final String action;
  @override
  final Object value;
  @override
  final AlertFeedbackStep flow;

  factory _$AlertFeedbackOption(
          [void Function(AlertFeedbackOptionBuilder) updates]) =>
      (new AlertFeedbackOptionBuilder()..update(updates)).build();

  _$AlertFeedbackOption._(
      {this.property,
      this.displayText,
      this.sortOrder,
      this.action,
      this.value,
      this.flow})
      : super._();

  @override
  AlertFeedbackOption rebuild(
          void Function(AlertFeedbackOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbackOptionBuilder toBuilder() =>
      new AlertFeedbackOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedbackOption &&
        property == other.property &&
        displayText == other.displayText &&
        sortOrder == other.sortOrder &&
        action == other.action &&
        value == other.value &&
        flow == other.flow;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, property.hashCode), displayText.hashCode),
                    sortOrder.hashCode),
                action.hashCode),
            value.hashCode),
        flow.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedbackOption')
          ..add('property', property)
          ..add('displayText', displayText)
          ..add('sortOrder', sortOrder)
          ..add('action', action)
          ..add('value', value)
          ..add('flow', flow))
        .toString();
  }
}

class AlertFeedbackOptionBuilder
    implements Builder<AlertFeedbackOption, AlertFeedbackOptionBuilder> {
  _$AlertFeedbackOption _$v;

  String _property;
  String get property => _$this._property;
  set property(String property) => _$this._property = property;

  String _displayText;
  String get displayText => _$this._displayText;
  set displayText(String displayText) => _$this._displayText = displayText;

  int _sortOrder;
  int get sortOrder => _$this._sortOrder;
  set sortOrder(int sortOrder) => _$this._sortOrder = sortOrder;

  String _action;
  String get action => _$this._action;
  set action(String action) => _$this._action = action;

  Object _value;
  Object get value => _$this._value;
  set value(Object value) => _$this._value = value;

  AlertFeedbackStepBuilder _flow;
  AlertFeedbackStepBuilder get flow =>
      _$this._flow ??= new AlertFeedbackStepBuilder();
  set flow(AlertFeedbackStepBuilder flow) => _$this._flow = flow;

  AlertFeedbackOptionBuilder();

  AlertFeedbackOptionBuilder get _$this {
    if (_$v != null) {
      _property = _$v.property;
      _displayText = _$v.displayText;
      _sortOrder = _$v.sortOrder;
      _action = _$v.action;
      _value = _$v.value;
      _flow = _$v.flow?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedbackOption other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedbackOption;
  }

  @override
  void update(void Function(AlertFeedbackOptionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedbackOption build() {
    _$AlertFeedbackOption _$result;
    try {
      _$result = _$v ??
          new _$AlertFeedbackOption._(
              property: property,
              displayText: displayText,
              sortOrder: sortOrder,
              action: action,
              value: value,
              flow: _flow?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'flow';
        _flow?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertFeedbackOption', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
