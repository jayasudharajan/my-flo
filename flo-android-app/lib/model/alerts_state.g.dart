// GENERATED CODE - DO NOT MODIFY BY HAND

part of alerts_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AlertsState extends AlertsState {
  @override
  final bool dirty;

  factory _$AlertsState([void Function(AlertsStateBuilder) updates]) =>
      (new AlertsStateBuilder()..update(updates)).build();

  _$AlertsState._({this.dirty}) : super._();

  @override
  AlertsState rebuild(void Function(AlertsStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertsStateBuilder toBuilder() => new AlertsStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertsState && dirty == other.dirty;
  }

  @override
  int get hashCode {
    return $jf($jc(0, dirty.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertsState')..add('dirty', dirty))
        .toString();
  }
}

class AlertsStateBuilder implements Builder<AlertsState, AlertsStateBuilder> {
  _$AlertsState _$v;

  bool _dirty;
  bool get dirty => _$this._dirty;
  set dirty(bool dirty) => _$this._dirty = dirty;

  AlertsStateBuilder();

  AlertsStateBuilder get _$this {
    if (_$v != null) {
      _dirty = _$v.dirty;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertsState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertsState;
  }

  @override
  void update(void Function(AlertsStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertsState build() {
    final _$result = _$v ?? new _$AlertsState._(dirty: dirty);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
