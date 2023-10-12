// GENERATED CODE - DO NOT MODIFY BY HAND

part of alarm;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alarm> _$alarmSerializer = new _$AlarmSerializer();

class _$AlarmSerializer implements StructuredSerializer<Alarm> {
  @override
  final Iterable<Type> types = const [Alarm, _$Alarm];
  @override
  final String wireName = 'Alarm';

  @override
  Iterable<Object> serialize(Serializers serializers, Alarm object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(int)));
    }
    if (object.name != null) {
      result
        ..add('name')
        ..add(serializers.serialize(object.name,
            specifiedType: const FullType(String)));
    }
    if (object.text != null) {
      result
        ..add('text')
        ..add(serializers.serialize(object.text,
            specifiedType: const FullType(String)));
    }
    if (object.displayName != null) {
      result
        ..add('displayName')
        ..add(serializers.serialize(object.displayName,
            specifiedType: const FullType(String)));
    }
    if (object.description != null) {
      result
        ..add('description')
        ..add(serializers.serialize(object.description,
            specifiedType: const FullType(String)));
    }
    if (object.severity != null) {
      result
        ..add('severity')
        ..add(serializers.serialize(object.severity,
            specifiedType: const FullType(String)));
    }
    if (object.isInternal != null) {
      result
        ..add('isInternal')
        ..add(serializers.serialize(object.isInternal,
            specifiedType: const FullType(bool)));
    }
    if (object.isShutoff != null) {
      result
        ..add('isShutoff')
        ..add(serializers.serialize(object.isShutoff,
            specifiedType: const FullType(bool)));
    }
    if (object.triggersAlarm != null) {
      result
        ..add('triggersAlarm')
        ..add(serializers.serialize(object.triggersAlarm,
            specifiedType: const FullType(Alarm)));
    }
    if (object.actions != null) {
      result
        ..add('actions')
        ..add(serializers.serialize(object.actions,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlarmAction)])));
    }
    if (object.supportOptions != null) {
      result
        ..add('supportOptions')
        ..add(serializers.serialize(object.supportOptions,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlarmOption)])));
    }
    if (object.active != null) {
      result
        ..add('active')
        ..add(serializers.serialize(object.active,
            specifiedType: const FullType(bool)));
    }
    if (object.children != null) {
      result
        ..add('children')
        ..add(serializers.serialize(object.children,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Alarm)])));
    }
    if (object.parent != null) {
      result
        ..add('parent')
        ..add(serializers.serialize(object.parent,
            specifiedType: const FullType(Alarm)));
    }
    if (object.deliveryMedium != null) {
      result
        ..add('deliveryMedium')
        ..add(serializers.serialize(object.deliveryMedium,
            specifiedType: const FullType(DeliveryMediums)));
    }
    if (object.userFeedbackFlows != null) {
      result
        ..add('userFeedbackFlow')
        ..add(serializers.serialize(object.userFeedbackFlows,
            specifiedType: const FullType(
                BuiltList, const [const FullType(AlertFeedbackFlow)])));
    }
    if (object.count != null) {
      result
        ..add('count')
        ..add(serializers.serialize(object.count,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  Alarm deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlarmBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'text':
          result.text = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'displayName':
          result.displayName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'description':
          result.description = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'severity':
          result.severity = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isInternal':
          result.isInternal = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'isShutoff':
          result.isShutoff = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'triggersAlarm':
          result.triggersAlarm.replace(serializers.deserialize(value,
              specifiedType: const FullType(Alarm)) as Alarm);
          break;
        case 'actions':
          result.actions.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlarmAction)]))
              as BuiltList<dynamic>);
          break;
        case 'supportOptions':
          result.supportOptions.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlarmOption)]))
              as BuiltList<dynamic>);
          break;
        case 'active':
          result.active = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'children':
          result.children.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Alarm)]))
              as BuiltList<dynamic>);
          break;
        case 'parent':
          result.parent.replace(serializers.deserialize(value,
              specifiedType: const FullType(Alarm)) as Alarm);
          break;
        case 'deliveryMedium':
          result.deliveryMedium.replace(serializers.deserialize(value,
                  specifiedType: const FullType(DeliveryMediums))
              as DeliveryMediums);
          break;
        case 'userFeedbackFlow':
          result.userFeedbackFlows.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(AlertFeedbackFlow)]))
              as BuiltList<dynamic>);
          break;
        case 'count':
          result.count = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Alarm extends Alarm {
  @override
  final int id;
  @override
  final String name;
  @override
  final String text;
  @override
  final String displayName;
  @override
  final String description;
  @override
  final String severity;
  @override
  final bool isInternal;
  @override
  final bool isShutoff;
  @override
  final Alarm triggersAlarm;
  @override
  final BuiltList<AlarmAction> actions;
  @override
  final BuiltList<AlarmOption> supportOptions;
  @override
  final bool active;
  @override
  final BuiltList<Alarm> children;
  @override
  final Alarm parent;
  @override
  final DeliveryMediums deliveryMedium;
  @override
  final BuiltList<AlertFeedbackFlow> userFeedbackFlows;
  @override
  final int count;

  factory _$Alarm([void Function(AlarmBuilder) updates]) =>
      (new AlarmBuilder()..update(updates)).build();

  _$Alarm._(
      {this.id,
      this.name,
      this.text,
      this.displayName,
      this.description,
      this.severity,
      this.isInternal,
      this.isShutoff,
      this.triggersAlarm,
      this.actions,
      this.supportOptions,
      this.active,
      this.children,
      this.parent,
      this.deliveryMedium,
      this.userFeedbackFlows,
      this.count})
      : super._();

  @override
  Alarm rebuild(void Function(AlarmBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlarmBuilder toBuilder() => new AlarmBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alarm &&
        id == other.id &&
        name == other.name &&
        text == other.text &&
        displayName == other.displayName &&
        description == other.description &&
        severity == other.severity &&
        isInternal == other.isInternal &&
        isShutoff == other.isShutoff &&
        triggersAlarm == other.triggersAlarm &&
        actions == other.actions &&
        supportOptions == other.supportOptions &&
        active == other.active &&
        children == other.children &&
        parent == other.parent &&
        deliveryMedium == other.deliveryMedium &&
        userFeedbackFlows == other.userFeedbackFlows &&
        count == other.count;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(0,
                                                                        id.hashCode),
                                                                    name.hashCode),
                                                                text.hashCode),
                                                            displayName.hashCode),
                                                        description.hashCode),
                                                    severity.hashCode),
                                                isInternal.hashCode),
                                            isShutoff.hashCode),
                                        triggersAlarm.hashCode),
                                    actions.hashCode),
                                supportOptions.hashCode),
                            active.hashCode),
                        children.hashCode),
                    parent.hashCode),
                deliveryMedium.hashCode),
            userFeedbackFlows.hashCode),
        count.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alarm')
          ..add('id', id)
          ..add('name', name)
          ..add('text', text)
          ..add('displayName', displayName)
          ..add('description', description)
          ..add('severity', severity)
          ..add('isInternal', isInternal)
          ..add('isShutoff', isShutoff)
          ..add('triggersAlarm', triggersAlarm)
          ..add('actions', actions)
          ..add('supportOptions', supportOptions)
          ..add('active', active)
          ..add('children', children)
          ..add('parent', parent)
          ..add('deliveryMedium', deliveryMedium)
          ..add('userFeedbackFlows', userFeedbackFlows)
          ..add('count', count))
        .toString();
  }
}

class AlarmBuilder implements Builder<Alarm, AlarmBuilder> {
  _$Alarm _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _text;
  String get text => _$this._text;
  set text(String text) => _$this._text = text;

  String _displayName;
  String get displayName => _$this._displayName;
  set displayName(String displayName) => _$this._displayName = displayName;

  String _description;
  String get description => _$this._description;
  set description(String description) => _$this._description = description;

  String _severity;
  String get severity => _$this._severity;
  set severity(String severity) => _$this._severity = severity;

  bool _isInternal;
  bool get isInternal => _$this._isInternal;
  set isInternal(bool isInternal) => _$this._isInternal = isInternal;

  bool _isShutoff;
  bool get isShutoff => _$this._isShutoff;
  set isShutoff(bool isShutoff) => _$this._isShutoff = isShutoff;

  AlarmBuilder _triggersAlarm;
  AlarmBuilder get triggersAlarm =>
      _$this._triggersAlarm ??= new AlarmBuilder();
  set triggersAlarm(AlarmBuilder triggersAlarm) =>
      _$this._triggersAlarm = triggersAlarm;

  ListBuilder<AlarmAction> _actions;
  ListBuilder<AlarmAction> get actions =>
      _$this._actions ??= new ListBuilder<AlarmAction>();
  set actions(ListBuilder<AlarmAction> actions) => _$this._actions = actions;

  ListBuilder<AlarmOption> _supportOptions;
  ListBuilder<AlarmOption> get supportOptions =>
      _$this._supportOptions ??= new ListBuilder<AlarmOption>();
  set supportOptions(ListBuilder<AlarmOption> supportOptions) =>
      _$this._supportOptions = supportOptions;

  bool _active;
  bool get active => _$this._active;
  set active(bool active) => _$this._active = active;

  ListBuilder<Alarm> _children;
  ListBuilder<Alarm> get children =>
      _$this._children ??= new ListBuilder<Alarm>();
  set children(ListBuilder<Alarm> children) => _$this._children = children;

  AlarmBuilder _parent;
  AlarmBuilder get parent => _$this._parent ??= new AlarmBuilder();
  set parent(AlarmBuilder parent) => _$this._parent = parent;

  DeliveryMediumsBuilder _deliveryMedium;
  DeliveryMediumsBuilder get deliveryMedium =>
      _$this._deliveryMedium ??= new DeliveryMediumsBuilder();
  set deliveryMedium(DeliveryMediumsBuilder deliveryMedium) =>
      _$this._deliveryMedium = deliveryMedium;

  ListBuilder<AlertFeedbackFlow> _userFeedbackFlows;
  ListBuilder<AlertFeedbackFlow> get userFeedbackFlows =>
      _$this._userFeedbackFlows ??= new ListBuilder<AlertFeedbackFlow>();
  set userFeedbackFlows(ListBuilder<AlertFeedbackFlow> userFeedbackFlows) =>
      _$this._userFeedbackFlows = userFeedbackFlows;

  int _count;
  int get count => _$this._count;
  set count(int count) => _$this._count = count;

  AlarmBuilder();

  AlarmBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _name = _$v.name;
      _text = _$v.text;
      _displayName = _$v.displayName;
      _description = _$v.description;
      _severity = _$v.severity;
      _isInternal = _$v.isInternal;
      _isShutoff = _$v.isShutoff;
      _triggersAlarm = _$v.triggersAlarm?.toBuilder();
      _actions = _$v.actions?.toBuilder();
      _supportOptions = _$v.supportOptions?.toBuilder();
      _active = _$v.active;
      _children = _$v.children?.toBuilder();
      _parent = _$v.parent?.toBuilder();
      _deliveryMedium = _$v.deliveryMedium?.toBuilder();
      _userFeedbackFlows = _$v.userFeedbackFlows?.toBuilder();
      _count = _$v.count;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alarm other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alarm;
  }

  @override
  void update(void Function(AlarmBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alarm build() {
    _$Alarm _$result;
    try {
      _$result = _$v ??
          new _$Alarm._(
              id: id,
              name: name,
              text: text,
              displayName: displayName,
              description: description,
              severity: severity,
              isInternal: isInternal,
              isShutoff: isShutoff,
              triggersAlarm: _triggersAlarm?.build(),
              actions: _actions?.build(),
              supportOptions: _supportOptions?.build(),
              active: active,
              children: _children?.build(),
              parent: _parent?.build(),
              deliveryMedium: _deliveryMedium?.build(),
              userFeedbackFlows: _userFeedbackFlows?.build(),
              count: count);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'triggersAlarm';
        _triggersAlarm?.build();
        _$failedField = 'actions';
        _actions?.build();
        _$failedField = 'supportOptions';
        _supportOptions?.build();

        _$failedField = 'children';
        _children?.build();
        _$failedField = 'parent';
        _parent?.build();
        _$failedField = 'deliveryMedium';
        _deliveryMedium?.build();
        _$failedField = 'userFeedbackFlows';
        _userFeedbackFlows?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Alarm', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
