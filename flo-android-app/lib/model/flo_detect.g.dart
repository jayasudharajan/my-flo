// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo_detect;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<FloDetect> _$floDetectSerializer = new _$FloDetectSerializer();

class _$FloDetectSerializer implements StructuredSerializer<FloDetect> {
  @override
  final Iterable<Type> types = const [FloDetect, _$FloDetect];
  @override
  final String wireName = 'FloDetect';

  @override
  Iterable<Object> serialize(Serializers serializers, FloDetect object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.device != null) {
      result
        ..add('device')
        ..add(serializers.serialize(object.device,
            specifiedType: const FullType(Device)));
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
    if (object.isStale != null) {
      result
        ..add('isStale')
        ..add(serializers.serialize(object.isStale,
            specifiedType: const FullType(bool)));
    }
    if (object.fixtures != null) {
      result
        ..add('fixtures')
        ..add(serializers.serialize(object.fixtures,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Fixture)])));
    }
    if (object.computeStartDate != null) {
      result
        ..add('computeStartDate')
        ..add(serializers.serialize(object.computeStartDate,
            specifiedType: const FullType(String)));
    }
    if (object.computeEndDate != null) {
      result
        ..add('computeEndDate')
        ..add(serializers.serialize(object.computeEndDate,
            specifiedType: const FullType(String)));
    }
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  FloDetect deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FloDetectBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'device':
          result.device.replace(serializers.deserialize(value,
              specifiedType: const FullType(Device)) as Device);
          break;
        case 'startDate':
          result.startDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'endDate':
          result.endDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isStale':
          result.isStale = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'fixtures':
          result.fixtures.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(Fixture)]))
              as BuiltList<dynamic>);
          break;
        case 'computeStartDate':
          result.computeStartDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'computeEndDate':
          result.computeEndDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$FloDetect extends FloDetect {
  @override
  final String id;
  @override
  final String macAddress;
  @override
  final Device device;
  @override
  final String startDate;
  @override
  final String endDate;
  @override
  final bool isStale;
  @override
  final BuiltList<Fixture> fixtures;
  @override
  final String computeStartDate;
  @override
  final String computeEndDate;
  @override
  final String status;

  factory _$FloDetect([void Function(FloDetectBuilder) updates]) =>
      (new FloDetectBuilder()..update(updates)).build();

  _$FloDetect._(
      {this.id,
      this.macAddress,
      this.device,
      this.startDate,
      this.endDate,
      this.isStale,
      this.fixtures,
      this.computeStartDate,
      this.computeEndDate,
      this.status})
      : super._();

  @override
  FloDetect rebuild(void Function(FloDetectBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FloDetectBuilder toBuilder() => new FloDetectBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FloDetect &&
        id == other.id &&
        macAddress == other.macAddress &&
        device == other.device &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        isStale == other.isStale &&
        fixtures == other.fixtures &&
        computeStartDate == other.computeStartDate &&
        computeEndDate == other.computeEndDate &&
        status == other.status;
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
                                    $jc($jc(0, id.hashCode),
                                        macAddress.hashCode),
                                    device.hashCode),
                                startDate.hashCode),
                            endDate.hashCode),
                        isStale.hashCode),
                    fixtures.hashCode),
                computeStartDate.hashCode),
            computeEndDate.hashCode),
        status.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FloDetect')
          ..add('id', id)
          ..add('macAddress', macAddress)
          ..add('device', device)
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('isStale', isStale)
          ..add('fixtures', fixtures)
          ..add('computeStartDate', computeStartDate)
          ..add('computeEndDate', computeEndDate)
          ..add('status', status))
        .toString();
  }
}

class FloDetectBuilder implements Builder<FloDetect, FloDetectBuilder> {
  _$FloDetect _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  DeviceBuilder _device;
  DeviceBuilder get device => _$this._device ??= new DeviceBuilder();
  set device(DeviceBuilder device) => _$this._device = device;

  String _startDate;
  String get startDate => _$this._startDate;
  set startDate(String startDate) => _$this._startDate = startDate;

  String _endDate;
  String get endDate => _$this._endDate;
  set endDate(String endDate) => _$this._endDate = endDate;

  bool _isStale;
  bool get isStale => _$this._isStale;
  set isStale(bool isStale) => _$this._isStale = isStale;

  ListBuilder<Fixture> _fixtures;
  ListBuilder<Fixture> get fixtures =>
      _$this._fixtures ??= new ListBuilder<Fixture>();
  set fixtures(ListBuilder<Fixture> fixtures) => _$this._fixtures = fixtures;

  String _computeStartDate;
  String get computeStartDate => _$this._computeStartDate;
  set computeStartDate(String computeStartDate) =>
      _$this._computeStartDate = computeStartDate;

  String _computeEndDate;
  String get computeEndDate => _$this._computeEndDate;
  set computeEndDate(String computeEndDate) =>
      _$this._computeEndDate = computeEndDate;

  String _status;
  String get status => _$this._status;
  set status(String status) => _$this._status = status;

  FloDetectBuilder();

  FloDetectBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _macAddress = _$v.macAddress;
      _device = _$v.device?.toBuilder();
      _startDate = _$v.startDate;
      _endDate = _$v.endDate;
      _isStale = _$v.isStale;
      _fixtures = _$v.fixtures?.toBuilder();
      _computeStartDate = _$v.computeStartDate;
      _computeEndDate = _$v.computeEndDate;
      _status = _$v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FloDetect other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$FloDetect;
  }

  @override
  void update(void Function(FloDetectBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FloDetect build() {
    _$FloDetect _$result;
    try {
      _$result = _$v ??
          new _$FloDetect._(
              id: id,
              macAddress: macAddress,
              device: _device?.build(),
              startDate: startDate,
              endDate: endDate,
              isStale: isStale,
              fixtures: _fixtures?.build(),
              computeStartDate: computeStartDate,
              computeEndDate: computeEndDate,
              status: status);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'device';
        _device?.build();

        _$failedField = 'fixtures';
        _fixtures?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'FloDetect', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
