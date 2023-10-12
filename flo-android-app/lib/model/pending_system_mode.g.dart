// GENERATED CODE - DO NOT MODIFY BY HAND

part of pending_system_mode;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PendingSystemMode> _$pendingSystemModeSerializer =
    new _$PendingSystemModeSerializer();

class _$PendingSystemModeSerializer
    implements StructuredSerializer<PendingSystemMode> {
  @override
  final Iterable<Type> types = const [PendingSystemMode, _$PendingSystemMode];
  @override
  final String wireName = 'PendingSystemMode';

  @override
  Iterable<Object> serialize(Serializers serializers, PendingSystemMode object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.target != null) {
      result
        ..add('target')
        ..add(serializers.serialize(object.target,
            specifiedType: const FullType(String)));
    }
    if (object.shouldInherit != null) {
      result
        ..add('shouldInherit')
        ..add(serializers.serialize(object.shouldInherit,
            specifiedType: const FullType(bool)));
    }
    if (object.revertMinutes != null) {
      result
        ..add('revertMinutes')
        ..add(serializers.serialize(object.revertMinutes,
            specifiedType: const FullType(int)));
    }
    if (object.revertMode != null) {
      result
        ..add('revertMode')
        ..add(serializers.serialize(object.revertMode,
            specifiedType: const FullType(String)));
    }
    if (object.revertScheduledAt != null) {
      result
        ..add('revertScheduledAt')
        ..add(serializers.serialize(object.revertScheduledAt,
            specifiedType: const FullType(String)));
    }
    if (object.isLocked != null) {
      result
        ..add('isLocked')
        ..add(serializers.serialize(object.isLocked,
            specifiedType: const FullType(bool)));
    }
    if (object.lastKnown != null) {
      result
        ..add('lastKnown')
        ..add(serializers.serialize(object.lastKnown,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  PendingSystemMode deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PendingSystemModeBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'shouldInherit':
          result.shouldInherit = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'revertMinutes':
          result.revertMinutes = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'revertMode':
          result.revertMode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'revertScheduledAt':
          result.revertScheduledAt = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isLocked':
          result.isLocked = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'lastKnown':
          result.lastKnown = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$PendingSystemMode extends PendingSystemMode {
  @override
  final String target;
  @override
  final bool shouldInherit;
  @override
  final int revertMinutes;
  @override
  final String revertMode;
  @override
  final String revertScheduledAt;
  @override
  final bool isLocked;
  @override
  final String lastKnown;

  factory _$PendingSystemMode(
          [void Function(PendingSystemModeBuilder) updates]) =>
      (new PendingSystemModeBuilder()..update(updates)).build();

  _$PendingSystemMode._(
      {this.target,
      this.shouldInherit,
      this.revertMinutes,
      this.revertMode,
      this.revertScheduledAt,
      this.isLocked,
      this.lastKnown})
      : super._();

  @override
  PendingSystemMode rebuild(void Function(PendingSystemModeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PendingSystemModeBuilder toBuilder() =>
      new PendingSystemModeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingSystemMode &&
        target == other.target &&
        shouldInherit == other.shouldInherit &&
        revertMinutes == other.revertMinutes &&
        revertMode == other.revertMode &&
        revertScheduledAt == other.revertScheduledAt &&
        isLocked == other.isLocked &&
        lastKnown == other.lastKnown;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, target.hashCode), shouldInherit.hashCode),
                        revertMinutes.hashCode),
                    revertMode.hashCode),
                revertScheduledAt.hashCode),
            isLocked.hashCode),
        lastKnown.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PendingSystemMode')
          ..add('target', target)
          ..add('shouldInherit', shouldInherit)
          ..add('revertMinutes', revertMinutes)
          ..add('revertMode', revertMode)
          ..add('revertScheduledAt', revertScheduledAt)
          ..add('isLocked', isLocked)
          ..add('lastKnown', lastKnown))
        .toString();
  }
}

class PendingSystemModeBuilder
    implements Builder<PendingSystemMode, PendingSystemModeBuilder> {
  _$PendingSystemMode _$v;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  bool _shouldInherit;
  bool get shouldInherit => _$this._shouldInherit;
  set shouldInherit(bool shouldInherit) =>
      _$this._shouldInherit = shouldInherit;

  int _revertMinutes;
  int get revertMinutes => _$this._revertMinutes;
  set revertMinutes(int revertMinutes) => _$this._revertMinutes = revertMinutes;

  String _revertMode;
  String get revertMode => _$this._revertMode;
  set revertMode(String revertMode) => _$this._revertMode = revertMode;

  String _revertScheduledAt;
  String get revertScheduledAt => _$this._revertScheduledAt;
  set revertScheduledAt(String revertScheduledAt) =>
      _$this._revertScheduledAt = revertScheduledAt;

  bool _isLocked;
  bool get isLocked => _$this._isLocked;
  set isLocked(bool isLocked) => _$this._isLocked = isLocked;

  String _lastKnown;
  String get lastKnown => _$this._lastKnown;
  set lastKnown(String lastKnown) => _$this._lastKnown = lastKnown;

  PendingSystemModeBuilder();

  PendingSystemModeBuilder get _$this {
    if (_$v != null) {
      _target = _$v.target;
      _shouldInherit = _$v.shouldInherit;
      _revertMinutes = _$v.revertMinutes;
      _revertMode = _$v.revertMode;
      _revertScheduledAt = _$v.revertScheduledAt;
      _isLocked = _$v.isLocked;
      _lastKnown = _$v.lastKnown;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingSystemMode other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PendingSystemMode;
  }

  @override
  void update(void Function(PendingSystemModeBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PendingSystemMode build() {
    final _$result = _$v ??
        new _$PendingSystemMode._(
            target: target,
            shouldInherit: shouldInherit,
            revertMinutes: revertMinutes,
            revertMode: revertMode,
            revertScheduledAt: revertScheduledAt,
            isLocked: isLocked,
            lastKnown: lastKnown);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
