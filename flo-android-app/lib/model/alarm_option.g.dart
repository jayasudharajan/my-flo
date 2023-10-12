// GENERATED CODE - DO NOT MODIFY BY HAND

part of alarm_option;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlarmOption> _$alarmOptionSerializer = new _$AlarmOptionSerializer();

class _$AlarmOptionSerializer implements StructuredSerializer<AlarmOption> {
  @override
  final Iterable<Type> types = const [AlarmOption, _$AlarmOption];
  @override
  final String wireName = 'AlarmOption';

  @override
  Iterable<Object> serialize(Serializers serializers, AlarmOption object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(int)));
    }
    if (object.text != null) {
      result
        ..add('text')
        ..add(serializers.serialize(object.text,
            specifiedType: const FullType(String)));
    }
    if (object.alarmId != null) {
      result
        ..add('alarmId')
        ..add(serializers.serialize(object.alarmId,
            specifiedType: const FullType(int)));
    }
    if (object.actionPath != null) {
      result
        ..add('actionPath')
        ..add(serializers.serialize(object.actionPath,
            specifiedType: const FullType(String)));
    }
    if (object.actionType != null) {
      result
        ..add('actionType')
        ..add(serializers.serialize(object.actionType,
            specifiedType: const FullType(int)));
    }
    if (object.sort != null) {
      result
        ..add('sort')
        ..add(serializers.serialize(object.sort,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  AlarmOption deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlarmOptionBuilder();

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
        case 'text':
          result.text = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'alarmId':
          result.alarmId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'actionPath':
          result.actionPath = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'actionType':
          result.actionType = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'sort':
          result.sort = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$AlarmOption extends AlarmOption {
  @override
  final int id;
  @override
  final String text;
  @override
  final int alarmId;
  @override
  final String actionPath;
  @override
  final int actionType;
  @override
  final int sort;

  factory _$AlarmOption([void Function(AlarmOptionBuilder) updates]) =>
      (new AlarmOptionBuilder()..update(updates)).build();

  _$AlarmOption._(
      {this.id,
      this.text,
      this.alarmId,
      this.actionPath,
      this.actionType,
      this.sort})
      : super._();

  @override
  AlarmOption rebuild(void Function(AlarmOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlarmOptionBuilder toBuilder() => new AlarmOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlarmOption &&
        id == other.id &&
        text == other.text &&
        alarmId == other.alarmId &&
        actionPath == other.actionPath &&
        actionType == other.actionType &&
        sort == other.sort;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, id.hashCode), text.hashCode), alarmId.hashCode),
                actionPath.hashCode),
            actionType.hashCode),
        sort.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlarmOption')
          ..add('id', id)
          ..add('text', text)
          ..add('alarmId', alarmId)
          ..add('actionPath', actionPath)
          ..add('actionType', actionType)
          ..add('sort', sort))
        .toString();
  }
}

class AlarmOptionBuilder implements Builder<AlarmOption, AlarmOptionBuilder> {
  _$AlarmOption _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _text;
  String get text => _$this._text;
  set text(String text) => _$this._text = text;

  int _alarmId;
  int get alarmId => _$this._alarmId;
  set alarmId(int alarmId) => _$this._alarmId = alarmId;

  String _actionPath;
  String get actionPath => _$this._actionPath;
  set actionPath(String actionPath) => _$this._actionPath = actionPath;

  int _actionType;
  int get actionType => _$this._actionType;
  set actionType(int actionType) => _$this._actionType = actionType;

  int _sort;
  int get sort => _$this._sort;
  set sort(int sort) => _$this._sort = sort;

  AlarmOptionBuilder();

  AlarmOptionBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _text = _$v.text;
      _alarmId = _$v.alarmId;
      _actionPath = _$v.actionPath;
      _actionType = _$v.actionType;
      _sort = _$v.sort;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlarmOption other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlarmOption;
  }

  @override
  void update(void Function(AlarmOptionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlarmOption build() {
    final _$result = _$v ??
        new _$AlarmOption._(
            id: id,
            text: text,
            alarmId: alarmId,
            actionPath: actionPath,
            actionType: actionType,
            sort: sort);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
