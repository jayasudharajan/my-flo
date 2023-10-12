// GENERATED CODE - DO NOT MODIFY BY HAND

part of timezone;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<TimeZone> _$timeZoneSerializer = new _$TimeZoneSerializer();

class _$TimeZoneSerializer implements StructuredSerializer<TimeZone> {
  @override
  final Iterable<Type> types = const [TimeZone, _$TimeZone];
  @override
  final String wireName = 'TimeZone';

  @override
  Iterable<Object> serialize(Serializers serializers, TimeZone object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'tz',
      serializers.serialize(object.tz, specifiedType: const FullType(String)),
    ];
    if (object.display != null) {
      result
        ..add('display')
        ..add(serializers.serialize(object.display,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  TimeZone deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TimeZoneBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'tz':
          result.tz = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'display':
          result.display = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$TimeZone extends TimeZone {
  @override
  final String tz;
  @override
  final String display;

  factory _$TimeZone([void Function(TimeZoneBuilder) updates]) =>
      (new TimeZoneBuilder()..update(updates)).build();

  _$TimeZone._({this.tz, this.display}) : super._() {
    if (tz == null) {
      throw new BuiltValueNullFieldError('TimeZone', 'tz');
    }
  }

  @override
  TimeZone rebuild(void Function(TimeZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TimeZoneBuilder toBuilder() => new TimeZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TimeZone && tz == other.tz && display == other.display;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, tz.hashCode), display.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TimeZone')
          ..add('tz', tz)
          ..add('display', display))
        .toString();
  }
}

class TimeZoneBuilder implements Builder<TimeZone, TimeZoneBuilder> {
  _$TimeZone _$v;

  String _tz;
  String get tz => _$this._tz;
  set tz(String tz) => _$this._tz = tz;

  String _display;
  String get display => _$this._display;
  set display(String display) => _$this._display = display;

  TimeZoneBuilder();

  TimeZoneBuilder get _$this {
    if (_$v != null) {
      _tz = _$v.tz;
      _display = _$v.display;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TimeZone other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TimeZone;
  }

  @override
  void update(void Function(TimeZoneBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TimeZone build() {
    final _$result = _$v ?? new _$TimeZone._(tz: tz, display: display);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
