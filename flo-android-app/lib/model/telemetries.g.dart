// GENERATED CODE - DO NOT MODIFY BY HAND

part of telemetries;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Telemetries> _$telemetriesSerializer = new _$TelemetriesSerializer();

class _$TelemetriesSerializer implements StructuredSerializer<Telemetries> {
  @override
  final Iterable<Type> types = const [Telemetries, _$Telemetries];
  @override
  final String wireName = 'Telemetries';

  @override
  Iterable<Object> serialize(Serializers serializers, Telemetries object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.current != null) {
      result
        ..add('current')
        ..add(serializers.serialize(object.current,
            specifiedType: const FullType(Telemetry2)));
    }
    if (object.updated != null) {
      result
        ..add('updated')
        ..add(serializers.serialize(object.updated,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Telemetries deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TelemetriesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'current':
          result.current.replace(serializers.deserialize(value,
              specifiedType: const FullType(Telemetry2)) as Telemetry2);
          break;
        case 'updated':
          result.updated = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Telemetries extends Telemetries {
  @override
  final Telemetry2 current;
  @override
  final String updated;

  factory _$Telemetries([void Function(TelemetriesBuilder) updates]) =>
      (new TelemetriesBuilder()..update(updates)).build();

  _$Telemetries._({this.current, this.updated}) : super._();

  @override
  Telemetries rebuild(void Function(TelemetriesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TelemetriesBuilder toBuilder() => new TelemetriesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Telemetries &&
        current == other.current &&
        updated == other.updated;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, current.hashCode), updated.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Telemetries')
          ..add('current', current)
          ..add('updated', updated))
        .toString();
  }
}

class TelemetriesBuilder implements Builder<Telemetries, TelemetriesBuilder> {
  _$Telemetries _$v;

  Telemetry2Builder _current;
  Telemetry2Builder get current => _$this._current ??= new Telemetry2Builder();
  set current(Telemetry2Builder current) => _$this._current = current;

  String _updated;
  String get updated => _$this._updated;
  set updated(String updated) => _$this._updated = updated;

  TelemetriesBuilder();

  TelemetriesBuilder get _$this {
    if (_$v != null) {
      _current = _$v.current?.toBuilder();
      _updated = _$v.updated;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Telemetries other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Telemetries;
  }

  @override
  void update(void Function(TelemetriesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Telemetries build() {
    _$Telemetries _$result;
    try {
      _$result = _$v ??
          new _$Telemetries._(current: _current?.build(), updated: updated);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'current';
        _current?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Telemetries', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
