// GENERATED CODE - DO NOT MODIFY BY HAND

part of alarm_action;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlarmAction> _$alarmActionSerializer = new _$AlarmActionSerializer();

class _$AlarmActionSerializer implements StructuredSerializer<AlarmAction> {
  @override
  final Iterable<Type> types = const [AlarmAction, _$AlarmAction];
  @override
  final String wireName = 'AlarmAction';

  @override
  Iterable<Object> serialize(Serializers serializers, AlarmAction object,
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
    if (object.displayOnStatus != null) {
      result
        ..add('displayOnStatus')
        ..add(serializers.serialize(object.displayOnStatus,
            specifiedType: const FullType(int)));
    }
    if (object.sort != null) {
      result
        ..add('sort')
        ..add(serializers.serialize(object.sort,
            specifiedType: const FullType(int)));
    }
    if (object.snoozeSeconds != null) {
      result
        ..add('snoozeSeconds')
        ..add(serializers.serialize(object.snoozeSeconds,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  AlarmAction deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlarmActionBuilder();

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
        case 'displayOnStatus':
          result.displayOnStatus = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'sort':
          result.sort = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'snoozeSeconds':
          result.snoozeSeconds = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$AlarmAction extends AlarmAction {
  @override
  final int id;
  @override
  final String name;
  @override
  final String text;
  @override
  final int displayOnStatus;
  @override
  final int sort;
  @override
  final int snoozeSeconds;

  factory _$AlarmAction([void Function(AlarmActionBuilder) updates]) =>
      (new AlarmActionBuilder()..update(updates)).build();

  _$AlarmAction._(
      {this.id,
      this.name,
      this.text,
      this.displayOnStatus,
      this.sort,
      this.snoozeSeconds})
      : super._();

  @override
  AlarmAction rebuild(void Function(AlarmActionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlarmActionBuilder toBuilder() => new AlarmActionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlarmAction &&
        id == other.id &&
        name == other.name &&
        text == other.text &&
        displayOnStatus == other.displayOnStatus &&
        sort == other.sort &&
        snoozeSeconds == other.snoozeSeconds;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, id.hashCode), name.hashCode), text.hashCode),
                displayOnStatus.hashCode),
            sort.hashCode),
        snoozeSeconds.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlarmAction')
          ..add('id', id)
          ..add('name', name)
          ..add('text', text)
          ..add('displayOnStatus', displayOnStatus)
          ..add('sort', sort)
          ..add('snoozeSeconds', snoozeSeconds))
        .toString();
  }
}

class AlarmActionBuilder implements Builder<AlarmAction, AlarmActionBuilder> {
  _$AlarmAction _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _text;
  String get text => _$this._text;
  set text(String text) => _$this._text = text;

  int _displayOnStatus;
  int get displayOnStatus => _$this._displayOnStatus;
  set displayOnStatus(int displayOnStatus) =>
      _$this._displayOnStatus = displayOnStatus;

  int _sort;
  int get sort => _$this._sort;
  set sort(int sort) => _$this._sort = sort;

  int _snoozeSeconds;
  int get snoozeSeconds => _$this._snoozeSeconds;
  set snoozeSeconds(int snoozeSeconds) => _$this._snoozeSeconds = snoozeSeconds;

  AlarmActionBuilder();

  AlarmActionBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _name = _$v.name;
      _text = _$v.text;
      _displayOnStatus = _$v.displayOnStatus;
      _sort = _$v.sort;
      _snoozeSeconds = _$v.snoozeSeconds;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlarmAction other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlarmAction;
  }

  @override
  void update(void Function(AlarmActionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlarmAction build() {
    final _$result = _$v ??
        new _$AlarmAction._(
            id: id,
            name: name,
            text: text,
            displayOnStatus: displayOnStatus,
            sort: sort,
            snoozeSeconds: snoozeSeconds);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
