// GENERATED CODE - DO NOT MODIFY BY HAND

part of alert_feedback;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AlertFeedback> _$alertFeedbackSerializer =
    new _$AlertFeedbackSerializer();

class _$AlertFeedbackSerializer implements StructuredSerializer<AlertFeedback> {
  @override
  final Iterable<Type> types = const [AlertFeedback, _$AlertFeedback];
  @override
  final String wireName = 'AlertFeedback';

  @override
  Iterable<Object> serialize(Serializers serializers, AlertFeedback object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.cause != null) {
      result
        ..add('cause')
        ..add(serializers.serialize(object.cause,
            specifiedType: const FullType(int)));
    }
    if (object.shouldAcceptAsNormal != null) {
      result
        ..add('shouldAcceptAsNormal')
        ..add(serializers.serialize(object.shouldAcceptAsNormal,
            specifiedType: const FullType(bool)));
    }
    if (object.plumbingFailure != null) {
      result
        ..add('plumbingFailure')
        ..add(serializers.serialize(object.plumbingFailure,
            specifiedType: const FullType(int)));
    }
    if (object.fixture != null) {
      result
        ..add('fixture')
        ..add(serializers.serialize(object.fixture,
            specifiedType: const FullType(String)));
    }
    if (object.causeOther != null) {
      result
        ..add('causeOther')
        ..add(serializers.serialize(object.causeOther,
            specifiedType: const FullType(int)));
    }
    if (object.plumbingFailureOther != null) {
      result
        ..add('plumbingFailureOther')
        ..add(serializers.serialize(object.plumbingFailureOther,
            specifiedType: const FullType(int)));
    }
    if (object.actionTaken != null) {
      result
        ..add('action_taken')
        ..add(serializers.serialize(object.actionTaken,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  AlertFeedback deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AlertFeedbackBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'cause':
          result.cause = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'shouldAcceptAsNormal':
          result.shouldAcceptAsNormal = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'plumbingFailure':
          result.plumbingFailure = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'fixture':
          result.fixture = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'causeOther':
          result.causeOther = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'plumbingFailureOther':
          result.plumbingFailureOther = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'action_taken':
          result.actionTaken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$AlertFeedback extends AlertFeedback {
  @override
  final int cause;
  @override
  final bool shouldAcceptAsNormal;
  @override
  final int plumbingFailure;
  @override
  final String fixture;
  @override
  final int causeOther;
  @override
  final int plumbingFailureOther;
  @override
  final String actionTaken;

  factory _$AlertFeedback([void Function(AlertFeedbackBuilder) updates]) =>
      (new AlertFeedbackBuilder()..update(updates)).build();

  _$AlertFeedback._(
      {this.cause,
      this.shouldAcceptAsNormal,
      this.plumbingFailure,
      this.fixture,
      this.causeOther,
      this.plumbingFailureOther,
      this.actionTaken})
      : super._();

  @override
  AlertFeedback rebuild(void Function(AlertFeedbackBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertFeedbackBuilder toBuilder() => new AlertFeedbackBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertFeedback &&
        cause == other.cause &&
        shouldAcceptAsNormal == other.shouldAcceptAsNormal &&
        plumbingFailure == other.plumbingFailure &&
        fixture == other.fixture &&
        causeOther == other.causeOther &&
        plumbingFailureOther == other.plumbingFailureOther &&
        actionTaken == other.actionTaken;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc(0, cause.hashCode),
                            shouldAcceptAsNormal.hashCode),
                        plumbingFailure.hashCode),
                    fixture.hashCode),
                causeOther.hashCode),
            plumbingFailureOther.hashCode),
        actionTaken.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AlertFeedback')
          ..add('cause', cause)
          ..add('shouldAcceptAsNormal', shouldAcceptAsNormal)
          ..add('plumbingFailure', plumbingFailure)
          ..add('fixture', fixture)
          ..add('causeOther', causeOther)
          ..add('plumbingFailureOther', plumbingFailureOther)
          ..add('actionTaken', actionTaken))
        .toString();
  }
}

class AlertFeedbackBuilder
    implements Builder<AlertFeedback, AlertFeedbackBuilder> {
  _$AlertFeedback _$v;

  int _cause;
  int get cause => _$this._cause;
  set cause(int cause) => _$this._cause = cause;

  bool _shouldAcceptAsNormal;
  bool get shouldAcceptAsNormal => _$this._shouldAcceptAsNormal;
  set shouldAcceptAsNormal(bool shouldAcceptAsNormal) =>
      _$this._shouldAcceptAsNormal = shouldAcceptAsNormal;

  int _plumbingFailure;
  int get plumbingFailure => _$this._plumbingFailure;
  set plumbingFailure(int plumbingFailure) =>
      _$this._plumbingFailure = plumbingFailure;

  String _fixture;
  String get fixture => _$this._fixture;
  set fixture(String fixture) => _$this._fixture = fixture;

  int _causeOther;
  int get causeOther => _$this._causeOther;
  set causeOther(int causeOther) => _$this._causeOther = causeOther;

  int _plumbingFailureOther;
  int get plumbingFailureOther => _$this._plumbingFailureOther;
  set plumbingFailureOther(int plumbingFailureOther) =>
      _$this._plumbingFailureOther = plumbingFailureOther;

  String _actionTaken;
  String get actionTaken => _$this._actionTaken;
  set actionTaken(String actionTaken) => _$this._actionTaken = actionTaken;

  AlertFeedbackBuilder();

  AlertFeedbackBuilder get _$this {
    if (_$v != null) {
      _cause = _$v.cause;
      _shouldAcceptAsNormal = _$v.shouldAcceptAsNormal;
      _plumbingFailure = _$v.plumbingFailure;
      _fixture = _$v.fixture;
      _causeOther = _$v.causeOther;
      _plumbingFailureOther = _$v.plumbingFailureOther;
      _actionTaken = _$v.actionTaken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertFeedback other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AlertFeedback;
  }

  @override
  void update(void Function(AlertFeedbackBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AlertFeedback build() {
    final _$result = _$v ??
        new _$AlertFeedback._(
            cause: cause,
            shouldAcceptAsNormal: shouldAcceptAsNormal,
            plumbingFailure: plumbingFailure,
            fixture: fixture,
            causeOther: causeOther,
            plumbingFailureOther: plumbingFailureOther,
            actionTaken: actionTaken);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
