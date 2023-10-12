// GENERATED CODE - DO NOT MODIFY BY HAND

part of alerts;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Alerts> _$alertsSerializer = new _$AlertsSerializer();

class _$AlertsSerializer implements StructuredSerializer<Alerts> {
  @override
  final Iterable<Type> types = const [Alerts, _$Alerts];
  @override
  final String wireName = 'Alerts';

  @override
  Iterable<Object> serialize(Serializers serializers, Alerts object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.items != null) {
      result
        ..add('items')
        ..add(serializers.serialize(object.items,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Alert)])));
    }
    if (object.page != null) {
      result
        ..add('page')
        ..add(serializers.serialize(object.page,
            specifiedType: const FullType(int)));
    }
    if (object.total != null) {
      result
        ..add('total')
        ..add(serializers.serialize(object.total,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  Alerts deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Alert)]))
              as BuiltList<dynamic>);
          break;
        case 'page':
          result.page = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'total':
          result.total = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Alerts extends Alerts {
  @override
  final BuiltList<Alert> items;
  @override
  final int page;
  @override
  final int total;

  factory _$Alerts([void Function(AlertsBuilder) updates]) =>
      (new AlertsBuilder()..update(updates)).build();

  _$Alerts._({this.items, this.page, this.total}) : super._();

  @override
  Alerts rebuild(void Function(AlertsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertsBuilder toBuilder() => new AlertsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Alerts &&
        items == other.items &&
        page == other.page &&
        total == other.total;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, items.hashCode), page.hashCode), total.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Alerts')
          ..add('items', items)
          ..add('page', page)
          ..add('total', total))
        .toString();
  }
}

class AlertsBuilder implements Builder<Alerts, AlertsBuilder> {
  _$Alerts _$v;

  ListBuilder<Alert> _items;
  ListBuilder<Alert> get items => _$this._items ??= new ListBuilder<Alert>();
  set items(ListBuilder<Alert> items) => _$this._items = items;

  int _page;
  int get page => _$this._page;
  set page(int page) => _$this._page = page;

  int _total;
  int get total => _$this._total;
  set total(int total) => _$this._total = total;

  AlertsBuilder();

  AlertsBuilder get _$this {
    if (_$v != null) {
      _items = _$v.items?.toBuilder();
      _page = _$v.page;
      _total = _$v.total;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Alerts other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Alerts;
  }

  @override
  void update(void Function(AlertsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Alerts build() {
    _$Alerts _$result;
    try {
      _$result = _$v ??
          new _$Alerts._(items: _items?.build(), page: page, total: total);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Alerts', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
