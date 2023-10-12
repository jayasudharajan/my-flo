// GENERATED CODE - DO NOT MODIFY BY HAND

part of connectivity;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Connectivity> _$connectivitySerializer =
    new _$ConnectivitySerializer();

class _$ConnectivitySerializer implements StructuredSerializer<Connectivity> {
  @override
  final Iterable<Type> types = const [Connectivity, _$Connectivity];
  @override
  final String wireName = 'Connectivity';

  @override
  Iterable<Object> serialize(Serializers serializers, Connectivity object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.rssi != null) {
      result
        ..add('rssi')
        ..add(serializers.serialize(object.rssi,
            specifiedType: const FullType(double)));
    }
    if (object.ssid != null) {
      result
        ..add('ssid')
        ..add(serializers.serialize(object.ssid,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Connectivity deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ConnectivityBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'rssi':
          result.rssi = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ssid':
          result.ssid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Connectivity extends Connectivity {
  @override
  final double rssi;
  @override
  final String ssid;

  factory _$Connectivity([void Function(ConnectivityBuilder) updates]) =>
      (new ConnectivityBuilder()..update(updates)).build();

  _$Connectivity._({this.rssi, this.ssid}) : super._();

  @override
  Connectivity rebuild(void Function(ConnectivityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConnectivityBuilder toBuilder() => new ConnectivityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Connectivity && rssi == other.rssi && ssid == other.ssid;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, rssi.hashCode), ssid.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Connectivity')
          ..add('rssi', rssi)
          ..add('ssid', ssid))
        .toString();
  }
}

class ConnectivityBuilder
    implements Builder<Connectivity, ConnectivityBuilder> {
  _$Connectivity _$v;

  double _rssi;
  double get rssi => _$this._rssi;
  set rssi(double rssi) => _$this._rssi = rssi;

  String _ssid;
  String get ssid => _$this._ssid;
  set ssid(String ssid) => _$this._ssid = ssid;

  ConnectivityBuilder();

  ConnectivityBuilder get _$this {
    if (_$v != null) {
      _rssi = _$v.rssi;
      _ssid = _$v.ssid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Connectivity other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Connectivity;
  }

  @override
  void update(void Function(ConnectivityBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Connectivity build() {
    final _$result = _$v ?? new _$Connectivity._(rssi: rssi, ssid: ssid);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
