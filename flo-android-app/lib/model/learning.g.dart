// GENERATED CODE - DO NOT MODIFY BY HAND

part of learning;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Learning> _$learningSerializer = new _$LearningSerializer();

class _$LearningSerializer implements StructuredSerializer<Learning> {
  @override
  final Iterable<Type> types = const [Learning, _$Learning];
  @override
  final String wireName = 'Learning';

  @override
  Iterable<Object> serialize(Serializers serializers, Learning object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.outOfLearningDate != null) {
      result
        ..add('outOfLearningDate')
        ..add(serializers.serialize(object.outOfLearningDate,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Learning deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LearningBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'outOfLearningDate':
          result.outOfLearningDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Learning extends Learning {
  @override
  final String outOfLearningDate;

  factory _$Learning([void Function(LearningBuilder) updates]) =>
      (new LearningBuilder()..update(updates)).build();

  _$Learning._({this.outOfLearningDate}) : super._();

  @override
  Learning rebuild(void Function(LearningBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LearningBuilder toBuilder() => new LearningBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Learning && outOfLearningDate == other.outOfLearningDate;
  }

  @override
  int get hashCode {
    return $jf($jc(0, outOfLearningDate.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Learning')
          ..add('outOfLearningDate', outOfLearningDate))
        .toString();
  }
}

class LearningBuilder implements Builder<Learning, LearningBuilder> {
  _$Learning _$v;

  String _outOfLearningDate;
  String get outOfLearningDate => _$this._outOfLearningDate;
  set outOfLearningDate(String outOfLearningDate) =>
      _$this._outOfLearningDate = outOfLearningDate;

  LearningBuilder();

  LearningBuilder get _$this {
    if (_$v != null) {
      _outOfLearningDate = _$v.outOfLearningDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Learning other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Learning;
  }

  @override
  void update(void Function(LearningBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Learning build() {
    final _$result =
        _$v ?? new _$Learning._(outOfLearningDate: outOfLearningDate);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
