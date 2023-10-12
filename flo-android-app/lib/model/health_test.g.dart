// GENERATED CODE - DO NOT MODIFY BY HAND

part of health_test;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<HealthTest> _$healthTestSerializer = new _$HealthTestSerializer();

class _$HealthTestSerializer implements StructuredSerializer<HealthTest> {
  @override
  final Iterable<Type> types = const [HealthTest, _$HealthTest];
  @override
  final String wireName = 'HealthTest';

  @override
  Iterable<Object> serialize(Serializers serializers, HealthTest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.roundId != null) {
      result
        ..add('roundId')
        ..add(serializers.serialize(object.roundId,
            specifiedType: const FullType(String)));
    }
    if (object.deviceId != null) {
      result
        ..add('deviceId')
        ..add(serializers.serialize(object.deviceId,
            specifiedType: const FullType(String)));
    }
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    if (object.type != null) {
      result
        ..add('type')
        ..add(serializers.serialize(object.type,
            specifiedType: const FullType(String)));
    }
    if (object.leakType != null) {
      result
        ..add('leakType')
        ..add(serializers.serialize(object.leakType,
            specifiedType: const FullType(int)));
    }
    if (object.leakLossMinGal != null) {
      result
        ..add('leakLossMinGal')
        ..add(serializers.serialize(object.leakLossMinGal,
            specifiedType: const FullType(double)));
    }
    if (object.leakLossMaxGal != null) {
      result
        ..add('leakLossMaxGal')
        ..add(serializers.serialize(object.leakLossMaxGal,
            specifiedType: const FullType(double)));
    }
    if (object.startPressure != null) {
      result
        ..add('startPressure')
        ..add(serializers.serialize(object.startPressure,
            specifiedType: const FullType(double)));
    }
    if (object.endPressure != null) {
      result
        ..add('endPressure')
        ..add(serializers.serialize(object.endPressure,
            specifiedType: const FullType(double)));
    }
    if (object.created != null) {
      result
        ..add('created')
        ..add(serializers.serialize(object.created,
            specifiedType: const FullType(String)));
    }
    if (object.updated != null) {
      result
        ..add('updated')
        ..add(serializers.serialize(object.updated,
            specifiedType: const FullType(String)));
    }
    if (object.startDate != null) {
      result
        ..add('startDate')
        ..add(serializers.serialize(object.startDate,
            specifiedType: const FullType(String)));
    }
    if (object.endDate != null) {
      result
        ..add('endDate')
        ..add(serializers.serialize(object.endDate,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  HealthTest deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new HealthTestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'roundId':
          result.roundId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'deviceId':
          result.deviceId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'leakType':
          result.leakType = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'leakLossMinGal':
          result.leakLossMinGal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'leakLossMaxGal':
          result.leakLossMaxGal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'startPressure':
          result.startPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'endPressure':
          result.endPressure = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'created':
          result.created = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'updated':
          result.updated = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'startDate':
          result.startDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'endDate':
          result.endDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$HealthTest extends HealthTest {
  @override
  final String roundId;
  @override
  final String deviceId;
  @override
  final String status;
  @override
  final String type;
  @override
  final int leakType;
  @override
  final double leakLossMinGal;
  @override
  final double leakLossMaxGal;
  @override
  final double startPressure;
  @override
  final double endPressure;
  @override
  final String created;
  @override
  final String updated;
  @override
  final String startDate;
  @override
  final String endDate;

  factory _$HealthTest([void Function(HealthTestBuilder) updates]) =>
      (new HealthTestBuilder()..update(updates)).build();

  _$HealthTest._(
      {this.roundId,
      this.deviceId,
      this.status,
      this.type,
      this.leakType,
      this.leakLossMinGal,
      this.leakLossMaxGal,
      this.startPressure,
      this.endPressure,
      this.created,
      this.updated,
      this.startDate,
      this.endDate})
      : super._();

  @override
  HealthTest rebuild(void Function(HealthTestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HealthTestBuilder toBuilder() => new HealthTestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HealthTest &&
        roundId == other.roundId &&
        deviceId == other.deviceId &&
        status == other.status &&
        type == other.type &&
        leakType == other.leakType &&
        leakLossMinGal == other.leakLossMinGal &&
        leakLossMaxGal == other.leakLossMaxGal &&
        startPressure == other.startPressure &&
        endPressure == other.endPressure &&
        created == other.created &&
        updated == other.updated &&
        startDate == other.startDate &&
        endDate == other.endDate;
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
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc($jc(0, roundId.hashCode),
                                                    deviceId.hashCode),
                                                status.hashCode),
                                            type.hashCode),
                                        leakType.hashCode),
                                    leakLossMinGal.hashCode),
                                leakLossMaxGal.hashCode),
                            startPressure.hashCode),
                        endPressure.hashCode),
                    created.hashCode),
                updated.hashCode),
            startDate.hashCode),
        endDate.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('HealthTest')
          ..add('roundId', roundId)
          ..add('deviceId', deviceId)
          ..add('status', status)
          ..add('type', type)
          ..add('leakType', leakType)
          ..add('leakLossMinGal', leakLossMinGal)
          ..add('leakLossMaxGal', leakLossMaxGal)
          ..add('startPressure', startPressure)
          ..add('endPressure', endPressure)
          ..add('created', created)
          ..add('updated', updated)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class HealthTestBuilder implements Builder<HealthTest, HealthTestBuilder> {
  _$HealthTest _$v;

  String _roundId;
  String get roundId => _$this._roundId;
  set roundId(String roundId) => _$this._roundId = roundId;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  String _type;
  String get type => _$this._type;
  set type(String type) => _$this._type = type;

  int _leakType;
  int get leakType => _$this._leakType;
  set leakType(int leakType) => _$this._leakType = leakType;

  double _leakLossMinGal;
  double get leakLossMinGal => _$this._leakLossMinGal;
  set leakLossMinGal(double leakLossMinGal) =>
      _$this._leakLossMinGal = leakLossMinGal;

  double _leakLossMaxGal;
  double get leakLossMaxGal => _$this._leakLossMaxGal;
  set leakLossMaxGal(double leakLossMaxGal) =>
      _$this._leakLossMaxGal = leakLossMaxGal;

  double _startPressure;
  double get startPressure => _$this._startPressure;
  set startPressure(double startPressure) =>
      _$this._startPressure = startPressure;

  double _endPressure;
  double get endPressure => _$this._endPressure;
  set endPressure(double endPressure) => _$this._endPressure = endPressure;

  String _created;
  String get created => _$this._created;
  set created(String created) => _$this._created = created;

  String _updated;
  String get updated => _$this._updated;
  set updated(String updated) => _$this._updated = updated;

  String _startDate;
  String get startDate => _$this._startDate;
  set startDate(String startDate) => _$this._startDate = startDate;

  String _endDate;
  String get endDate => _$this._endDate;
  set endDate(String endDate) => _$this._endDate = endDate;

  HealthTestBuilder();

  HealthTestBuilder get _$this {
    if (_$v != null) {
      _roundId = _$v.roundId;
      _deviceId = _$v.deviceId;
      _status = _$v.status;
      _type = _$v.type;
      _leakType = _$v.leakType;
      _leakLossMinGal = _$v.leakLossMinGal;
      _leakLossMaxGal = _$v.leakLossMaxGal;
      _startPressure = _$v.startPressure;
      _endPressure = _$v.endPressure;
      _created = _$v.created;
      _updated = _$v.updated;
      _startDate = _$v.startDate;
      _endDate = _$v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HealthTest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$HealthTest;
  }

  @override
  void update(void Function(HealthTestBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$HealthTest build() {
    final _$result = _$v ??
        new _$HealthTest._(
            roundId: roundId,
            deviceId: deviceId,
            status: status,
            type: type,
            leakType: leakType,
            leakLossMinGal: leakLossMinGal,
            leakLossMaxGal: leakLossMaxGal,
            startPressure: startPressure,
            endPressure: endPressure,
            created: created,
            updated: updated,
            startDate: startDate,
            endDate: endDate);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
