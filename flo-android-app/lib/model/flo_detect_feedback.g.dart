// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_detect_feedback;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FloDetectFeedback> _$floDetectFeedbackSerializer =
    new _$FloDetectFeedbackSerializer();

class _$FloDetectFeedbackSerializer
    implements StructuredSerializer<FloDetectFeedback> {
  @override
  final Iterable<Type> types = const [FloDetectFeedback, _$FloDetectFeedback];
  @override
  final String wireName = 'FloDetectFeedback';

  @override
  Iterable<Object> serialize(Serializers serializers, FloDetectFeedback object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.cases != null) {
      result
        ..add('case')
        ..add(serializers.serialize(object.cases,
            specifiedType: const FullType(int)));
    }
    if (object.correctFixture != null) {
      result
        ..add('correctFixture')
        ..add(serializers.serialize(object.correctFixture,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  FloDetectFeedback deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FloDetectFeedbackBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'case':
          result.cases = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'correctFixture':
          result.correctFixture = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$FloDetectFeedback extends FloDetectFeedback {
  @override
  final int cases;
  @override
  final String correctFixture;

  factory _$FloDetectFeedback(
          [void Function(FloDetectFeedbackBuilder) updates]) =>
      (new FloDetectFeedbackBuilder()..update(updates)).build();

  _$FloDetectFeedback._({this.cases, this.correctFixture}) : super._();

  @override
  FloDetectFeedback rebuild(void Function(FloDetectFeedbackBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FloDetectFeedbackBuilder toBuilder() =>
      new FloDetectFeedbackBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FloDetectFeedback &&
        cases == other.cases &&
        correctFixture == other.correctFixture;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, cases.hashCode), correctFixture.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FloDetectFeedback')
          ..add('cases', cases)
          ..add('correctFixture', correctFixture))
        .toString();
  }
}

class FloDetectFeedbackBuilder
    implements Builder<FloDetectFeedback, FloDetectFeedbackBuilder> {
  _$FloDetectFeedback _$v;

  int _cases;
  int get cases => _$this._cases;
  set cases(int cases) => _$this._cases = cases;

  String _correctFixture;
  String get correctFixture => _$this._correctFixture;
  set correctFixture(String correctFixture) =>
      _$this._correctFixture = correctFixture;

  FloDetectFeedbackBuilder();

  FloDetectFeedbackBuilder get _$this {
    if (_$v != null) {
      _cases = _$v.cases;
      _correctFixture = _$v.correctFixture;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FloDetectFeedback other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FloDetectFeedback;
  }

  @override
  void update(void Function(FloDetectFeedbackBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FloDetectFeedback build() {
    final _$result = _$v ??
        new _$FloDetectFeedback._(cases: cases, correctFixture: correctFixture);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
