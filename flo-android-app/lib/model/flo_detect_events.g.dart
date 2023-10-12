// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_detect_events;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FloDetectEvents> _$floDetectEventsSerializer =
    new _$FloDetectEventsSerializer();

class _$FloDetectEventsSerializer
    implements StructuredSerializer<FloDetectEvents> {
  @override
  final Iterable<Type> types = const [FloDetectEvents, _$FloDetectEvents];
  @override
  final String wireName = 'FloDetectEvents';

  @override
  Iterable<Object> serialize(Serializers serializers, FloDetectEvents object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType: const FullType(
                BuiltList, const [const FullType(FloDetectEvent)])));
    }
    return result;
  }

  @override
  FloDetectEvents deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FloDetectEventsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(FloDetectEvent)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$FloDetectEvents extends FloDetectEvents {
  @override
  final BuiltList<FloDetectEvent> items;

  factory _$FloDetectEvents([void Function(FloDetectEventsBuilder) updates]) =>
      (new FloDetectEventsBuilder()..update(updates)).build();

  _$FloDetectEvents._({this.items}) : super._();

  @override
  FloDetectEvents rebuild(void Function(FloDetectEventsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FloDetectEventsBuilder toBuilder() =>
      new FloDetectEventsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FloDetectEvents && items == other.items;
  }

  @override
  int get hashCode {
    return $jf($jc(0, items.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FloDetectEvents')..add('items', items))
        .toString();
  }
}

class FloDetectEventsBuilder
    implements Builder<FloDetectEvents, FloDetectEventsBuilder> {
  _$FloDetectEvents _$v;

  ListBuilder<FloDetectEvent> _items;
  ListBuilder<FloDetectEvent> get items =>
      _$this._items ??= new ListBuilder<FloDetectEvent>();
  set items(ListBuilder<FloDetectEvent> items) => _$this._items = items;

  FloDetectEventsBuilder();

  FloDetectEventsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FloDetectEvents other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FloDetectEvents;
  }

  @override
  void update(void Function(FloDetectEventsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FloDetectEvents build() {
    _$FloDetectEvents _$result;
    try {
      _$result = _$v ?? new _$FloDetectEvents._(items: _items?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FloDetectEvents', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
