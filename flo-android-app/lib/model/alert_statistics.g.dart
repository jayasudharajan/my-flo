// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_statistics;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertStatistics> _$alertStatisticsSerializer =
    new _$AlertStatisticsSerializer();

class _$AlertStatisticsSerializer
    implements StructuredSerializer<AlertStatistics> {
  @override
  final Iterable<Type> types = const [AlertStatistics, _$AlertStatistics];
  @override
  final String wireName = 'AlertStatistics';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertStatistics object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.pending != null) {
      result
        ..add('pending')
        ..add(serializers.serialize(object.pending,
            specifiedType: const FullType(Notifications)));
    }
    return result;
  }

  @override
  AlertStatistics deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertStatisticsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'pending':
          result.pending.replace(serializers.deserialize(value,
              specifiedType: const FullType(Notifications)) as Notifications);
          break;
      }
    }

    return result.build();
  }
}

class _$AlertStatistics extends AlertStatistics {
  @override
  final Notifications pending;

  factory _$AlertStatistics([void Function(AlertStatisticsBuilder) updates]) =>
      (new AlertStatisticsBuilder()..update(updates)).build();

  _$AlertStatistics._({this.pending}) : super._();

  @override
  AlertStatistics rebuild(void Function(AlertStatisticsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertStatisticsBuilder toBuilder() =>
      new AlertStatisticsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertStatistics && pending == other.pending;
  }

  @override
  int get hashCode {
    return $jf($jc(0, pending.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertStatistics')
          ..add('pending', pending))
        .toString();
  }
}

class AlertStatisticsBuilder
    implements Builder<AlertStatistics, AlertStatisticsBuilder> {
  _$AlertStatistics _$v;

  NotificationsBuilder _pending;
  NotificationsBuilder get pending =>
      _$this._pending ??= new NotificationsBuilder();
  set pending(NotificationsBuilder pending) => _$this._pending = pending;

  AlertStatisticsBuilder();

  AlertStatisticsBuilder get _$this {
    if (_$v != null) {
      _pending = _$v.pending?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertStatistics other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertStatistics;
  }

  @override
  void update(void Function(AlertStatisticsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertStatistics build() {
    _$AlertStatistics _$result;
    try {
      _$result = _$v ?? new _$AlertStatistics._(pending: _pending?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'pending';
        _pending?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AlertStatistics', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
