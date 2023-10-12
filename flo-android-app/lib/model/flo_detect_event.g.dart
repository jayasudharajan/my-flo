// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_detect_event;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FloDetectEvent> _$floDetectEventSerializer =
    new _$FloDetectEventSerializer();

class _$FloDetectEventSerializer
    implements StructuredSerializer<FloDetectEvent> {
  @override
  final Iterable<Type> types = const [FloDetectEvent, _$FloDetectEvent];
  @override
  final String wireName = 'FloDetectEvent';

  @override
  Iterable<Object> serialize(Serializers serializers, FloDetectEvent object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.computationId != null) {
      result
        ..add('computationId')
        ..add(serializers.serialize(object.computationId,
            specifiedType: const FullType(String)));
    }
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.duration != null) {
      result
        ..add('duration')
        ..add(serializers.serialize(object.duration,
            specifiedType: const FullType(int)));
    }
    if (object.fixture != null) {
      result
        ..add('fixture')
        ..add(serializers.serialize(object.fixture,
            specifiedType: const FullType(String)));
    }
    if (object.feedback != null) {
      result
        ..add('feedback')
        ..add(serializers.serialize(object.feedback,
            specifiedType: const FullType(FloDetectFeedback)));
    }
    if (object.type != null) {
      result
        ..add('type')
        ..add(serializers.serialize(object.type,
            specifiedType: const FullType(int)));
    }
    if (object.start != null) {
      result
        ..add('start')
        ..add(serializers.serialize(object.start,
            specifiedType: const FullType(String)));
    }
    if (object.end != null) {
      result
        ..add('end')
        ..add(serializers.serialize(object.end,
            specifiedType: const FullType(String)));
    }
    if (object.flow != null) {
      result
        ..add('flow')
        ..add(serializers.serialize(object.flow,
            specifiedType: const FullType(double)));
    }
    if (object.gpm != null) {
      result
        ..add('gpm')
        ..add(serializers.serialize(object.gpm,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  FloDetectEvent deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FloDetectEventBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'computationId':
          result.computationId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'duration':
          result.duration = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'fixture':
          result.fixture = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'feedback':
          result.feedback.replace(serializers.deserialize(value,
                  specifiedType: const FullType(FloDetectFeedback))
              as FloDetectFeedback);
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'start':
          result.start = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'end':
          result.end = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'flow':
          result.flow = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'gpm':
          result.gpm = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$FloDetectEvent extends FloDetectEvent {
  @override
  final String computationId;
  @override
  final String macAddress;
  @override
  final int duration;
  @override
  final String fixture;
  @override
  final FloDetectFeedback feedback;
  @override
  final int type;
  @override
  final String start;
  @override
  final String end;
  @override
  final double flow;
  @override
  final double gpm;

  factory _$FloDetectEvent([void Function(FloDetectEventBuilder) updates]) =>
      (new FloDetectEventBuilder()..update(updates)).build();

  _$FloDetectEvent._(
      {this.computationId,
      this.macAddress,
      this.duration,
      this.fixture,
      this.feedback,
      this.type,
      this.start,
      this.end,
      this.flow,
      this.gpm})
      : super._();

  @override
  FloDetectEvent rebuild(void Function(FloDetectEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FloDetectEventBuilder toBuilder() =>
      new FloDetectEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FloDetectEvent &&
        computationId == other.computationId &&
        macAddress == other.macAddress &&
        duration == other.duration &&
        fixture == other.fixture &&
        feedback == other.feedback &&
        type == other.type &&
        start == other.start &&
        end == other.end &&
        flow == other.flow &&
        gpm == other.gpm;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc($jc(0, computationId.hashCode),
                                        macAddress.hashCode),
                                    duration.hashCode),
                                fixture.hashCode),
                            feedback.hashCode),
                        type.hashCode),
                    start.hashCode),
                end.hashCode),
            flow.hashCode),
        gpm.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FloDetectEvent')
          ..add('computationId', computationId)
          ..add('macAddress', macAddress)
          ..add('duration', duration)
          ..add('fixture', fixture)
          ..add('feedback', feedback)
          ..add('type', type)
          ..add('start', start)
          ..add('end', end)
          ..add('flow', flow)
          ..add('gpm', gpm))
        .toString();
  }
}

class FloDetectEventBuilder
    implements Builder<FloDetectEvent, FloDetectEventBuilder> {
  _$FloDetectEvent _$v;

  String _computationId;
  String get computationId => _$this._computationId;
  set computationId(String computationId) =>
      _$this._computationId = computationId;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  int _duration;
  int get duration => _$this._duration;
  set duration(int duration) => _$this._duration = duration;

  String _fixture;
  String get fixture => _$this._fixture;
  set fixture(String fixture) => _$this._fixture = fixture;

  FloDetectFeedbackBuilder _feedback;
  FloDetectFeedbackBuilder get feedback =>
      _$this._feedback ??= new FloDetectFeedbackBuilder();
  set feedback(FloDetectFeedbackBuilder feedback) =>
      _$this._feedback = feedback;

  int _type;
  int get type => _$this._type;
  set type(int type) => _$this._type = type;

  String _start;
  String get start => _$this._start;
  set start(String start) => _$this._start = start;

  String _end;
  String get end => _$this._end;
  set end(String end) => _$this._end = end;

  double _flow;
  double get flow => _$this._flow;
  set flow(double flow) => _$this._flow = flow;

  double _gpm;
  double get gpm => _$this._gpm;
  set gpm(double gpm) => _$this._gpm = gpm;

  FloDetectEventBuilder();

  FloDetectEventBuilder get _$this {
    if (_$v != null) {
      _computationId = _$v.computationId;
      _macAddress = _$v.macAddress;
      _duration = _$v.duration;
      _fixture = _$v.fixture;
      _feedback = _$v.feedback?.toBuilder();
      _type = _$v.type;
      _start = _$v.start;
      _end = _$v.end;
      _flow = _$v.flow;
      _gpm = _$v.gpm;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FloDetectEvent other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FloDetectEvent;
  }

  @override
  void update(void Function(FloDetectEventBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FloDetectEvent build() {
    _$FloDetectEvent _$result;
    try {
      _$result = _$v ??
          new _$FloDetectEvent._(
              computationId: computationId,
              macAddress: macAddress,
              duration: duration,
              fixture: fixture,
              feedback: _feedback?.build(),
              type: type,
              start: start,
              end: end,
              flow: flow,
              gpm: gpm);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'feedback';
        _feedback?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FloDetectEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
