// GENERATED CODE - DO NOT MODIFY BY HAND

part of wifi;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Wifi> _$wifiSerializer = new _$WifiSerializer();

class _$WifiSerializer implements StructuredSerializer<Wifi> {
  @override
  final Iterable<Type> types = const [Wifi, _$Wifi];
  @override
  final String wireName = 'Wifi';

  @override
  Iterable<Object> serialize(Serializers serializers, Wifi object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'ssid',
      serializers.serialize(object.ssid, specifiedType: const FullType(String)),
    ];
    if (object.encryption != null) {
      result
        ..add('encryption')
        ..add(serializers.serialize(object.encryption,
            specifiedType: const FullType(String)));
    }
    if (object.signal != null) {
      result
        ..add('signal')
        ..add(serializers.serialize(object.signal,
            specifiedType: const FullType(double)));
    }
    return result;
  }

  @override
  Wifi deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WifiBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'ssid':
          result.ssid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'encryption':
          result.encryption = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'signal':
          result.signal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$Wifi extends Wifi {
  @override
  final String ssid;
  @override
  final String encryption;
  @override
  final double signal;

  factory _$Wifi([void Function(WifiBuilder) updates]) =>
      (new WifiBuilder()..update(updates)).build();

  _$Wifi._({this.ssid, this.encryption, this.signal}) : super._() {
    if (ssid == null) {
      throw new BuiltValueNullFieldError('Wifi', 'ssid');
    }
  }

  @override
  Wifi rebuild(void Function(WifiBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WifiBuilder toBuilder() => new WifiBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Wifi &&
        ssid == other.ssid &&
        encryption == other.encryption &&
        signal == other.signal;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, ssid.hashCode), encryption.hashCode), signal.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Wifi')
          ..add('ssid', ssid)
          ..add('encryption', encryption)
          ..add('signal', signal))
        .toString();
  }
}

class WifiBuilder implements Builder<Wifi, WifiBuilder> {
  _$Wifi _$v;

  String _ssid;
  String get ssid => _$this._ssid;
  set ssid(String ssid) => _$this._ssid = ssid;

  String _encryption;
  String get encryption => _$this._encryption;
  set encryption(String encryption) => _$this._encryption = encryption;

  double _signal;
  double get signal => _$this._signal;
  set signal(double signal) => _$this._signal = signal;

  WifiBuilder();

  WifiBuilder get _$this {
    if (_$v != null) {
      _ssid = _$v.ssid;
      _encryption = _$v.encryption;
      _signal = _$v.signal;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Wifi other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Wifi;
  }

  @override
  void update(void Function(WifiBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Wifi build() {
    final _$result =
        _$v ?? new _$Wifi._(ssid: ssid, encryption: encryption, signal: signal);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
