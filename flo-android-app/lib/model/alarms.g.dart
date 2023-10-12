// GENERATED CODE - DO NOT MODIFY BY HAND

part of alarms;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alarms> _$alarmsSerializer = new _$AlarmsSerializer();

class _$AlarmsSerializer implements StructuredSerializer<Alarms> {
  @override
  final Iterable<Type> types = const [Alarms, _$Alarms];
  @override
  final String wireName = 'Alarms';

  @override
  Iterable<Object> serialize(Serializers serializers, Alarms object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Alarm)])));
    }
    return result;
  }

  @override
  Alarms deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlarmsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Alarm)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Alarms extends Alarms {
  @override
  final BuiltList<Alarm> items;

  factory _$Alarms([void Function(AlarmsBuilder) updates]) =>
      (new AlarmsBuilder()..update(updates)).build();

  _$Alarms._({this.items}) : super._();

  @override
  Alarms rebuild(void Function(AlarmsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlarmsBuilder toBuilder() => new AlarmsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alarms && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alarms')..add('items', items))
        .toString();
  }
}

class AlarmsBuilder implements Builder<Alarms, AlarmsBuilder> {
  _$Alarms _$v;

  ListBuilder<Alarm> _items;
  ListBuilder<Alarm> get items => _$this._items ??= new ListBuilder<Alarm>();
  set items(ListBuilder<Alarm> items) => _$this._items = items;

  AlarmsBuilder();

  AlarmsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alarms other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alarms;
  }

  @override
  void update(void Function(AlarmsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alarms build() {
    _$Alarms _$result;
    try {
      _$result = _$v ?? new _$Alarms._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Alarms', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
