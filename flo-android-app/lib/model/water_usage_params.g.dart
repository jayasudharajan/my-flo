// GENERATED CODE - DO NOT MODIFY BY HAND

part of water_usage_params;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WaterUsageParams> _$waterUsageParamsSerializer =
    new _$WaterUsageParamsSerializer();

class _$WaterUsageParamsSerializer
    implements StructuredSerializer<WaterUsageParams> {
  @override
  final Iterable<Type> types = const [WaterUsageParams, _$WaterUsageParams];
  @override
  final String wireName = 'WaterUsageParams';

  @override
  Iterable<Object> serialize(Serializers serializers, WaterUsageParams object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
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
    if (object.interval != null) {
      result
        ..add('interval')
        ..add(serializers.serialize(object.interval,
            specifiedType: const FullType(String)));
    }
    if (object.macAddress != null) {
      result
        ..add('macAddress')
        ..add(serializers.serialize(object.macAddress,
            specifiedType: const FullType(String)));
    }
    if (object.locationId != null) {
      result
        ..add('locationId')
        ..add(serializers.serialize(object.locationId,
            specifiedType: const FullType(String)));
    }
    if (object.tz != null) {
      result
        ..add('tz')
        ..add(serializers.serialize(object.tz,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  WaterUsageParams deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WaterUsageParamsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'startDate':
          result.startDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'endDate':
          result.endDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'interval':
          result.interval = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'macAddress':
          result.macAddress = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'locationId':
          result.locationId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'tz':
          result.tz = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$WaterUsageParams extends WaterUsageParams {
  @override
  final String startDate;
  @override
  final String endDate;
  @override
  final String interval;
  @override
  final String macAddress;
  @override
  final String locationId;
  @override
  final String tz;

  factory _$WaterUsageParams(
          [void Function(WaterUsageParamsBuilder) updates]) =>
      (new WaterUsageParamsBuilder()..update(updates)).build();

  _$WaterUsageParams._(
      {this.startDate,
      this.endDate,
      this.interval,
      this.macAddress,
      this.locationId,
      this.tz})
      : super._();

  @override
  WaterUsageParams rebuild(void Function(WaterUsageParamsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WaterUsageParamsBuilder toBuilder() =>
      new WaterUsageParamsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WaterUsageParams &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        interval == other.interval &&
        macAddress == other.macAddress &&
        locationId == other.locationId &&
        tz == other.tz;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, startDate.hashCode), endDate.hashCode),
                    interval.hashCode),
                macAddress.hashCode),
            locationId.hashCode),
        tz.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('WaterUsageParams')
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('interval', interval)
          ..add('macAddress', macAddress)
          ..add('locationId', locationId)
          ..add('tz', tz))
        .toString();
  }
}

class WaterUsageParamsBuilder
    implements Builder<WaterUsageParams, WaterUsageParamsBuilder> {
  _$WaterUsageParams _$v;

  String _startDate;
  String get startDate => _$this._startDate;
  set startDate(String startDate) => _$this._startDate = startDate;

  String _endDate;
  String get endDate => _$this._endDate;
  set endDate(String endDate) => _$this._endDate = endDate;

  String _interval;
  String get interval => _$this._interval;
  set interval(String interval) => _$this._interval = interval;

  String _macAddress;
  String get macAddress => _$this._macAddress;
  set macAddress(String macAddress) => _$this._macAddress = macAddress;

  String _locationId;
  String get locationId => _$this._locationId;
  set locationId(String locationId) => _$this._locationId = locationId;

  String _tz;
  String get tz => _$this._tz;
  set tz(String tz) => _$this._tz = tz;

  WaterUsageParamsBuilder();

  WaterUsageParamsBuilder get _$this {
    if (_$v != null) {
      _startDate = _$v.startDate;
      _endDate = _$v.endDate;
      _interval = _$v.interval;
      _macAddress = _$v.macAddress;
      _locationId = _$v.locationId;
      _tz = _$v.tz;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WaterUsageParams other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$WaterUsageParams;
  }

  @override
  void update(void Function(WaterUsageParamsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WaterUsageParams build() {
    final _$result = _$v ??
        new _$WaterUsageParams._(
            startDate: startDate,
            endDate: endDate,
            interval: interval,
            macAddress: macAddress,
            locationId: locationId,
            tz: tz);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
