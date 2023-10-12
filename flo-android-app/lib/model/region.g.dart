// GENERATED CODE - DO NOT MODIFY BY HAND

part of region;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Region> _$regionSerializer = new _$RegionSerializer();

class _$RegionSerializer implements StructuredSerializer<Region> {
  @override
  final Iterable<Type> types = const [Region, _$Region];
  @override
  final String wireName = 'Region';

  @override
  Iterable<Object> serialize(Serializers serializers, Region object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'abbrev',
      serializers.serialize(object.abbrev,
          specifiedType: const FullType(String)),
      'timezones',
      serializers.serialize(object.timezones,
          specifiedType:
              const FullType(BuiltList, const [const FullType(TimeZone)])),
    ];

    return result;
  }

  @override
  Region deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RegionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'abbrev':
          result.abbrev = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'timezones':
          result.timezones.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(TimeZone)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Region extends Region {
  @override
  final String name;
  @override
  final String abbrev;
  @override
  final BuiltList<TimeZone> timezones;

  factory _$Region([void Function(RegionBuilder) updates]) =>
      (new RegionBuilder()..update(updates)).build();

  _$Region._({this.name, this.abbrev, this.timezones}) : super._() {
    if (name == null) {
      throw new BuiltValueNullFieldError('Region', 'name');
    }
    if (abbrev == null) {
      throw new BuiltValueNullFieldError('Region', 'abbrev');
    }
    if (timezones == null) {
      throw new BuiltValueNullFieldError('Region', 'timezones');
    }
  }

  @override
  Region rebuild(void Function(RegionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegionBuilder toBuilder() => new RegionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Region &&
        name == other.name &&
        abbrev == other.abbrev &&
        timezones == other.timezones;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, name.hashCode), abbrev.hashCode), timezones.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Region')
          ..add('name', name)
          ..add('abbrev', abbrev)
          ..add('timezones', timezones))
        .toString();
  }
}

class RegionBuilder implements Builder<Region, RegionBuilder> {
  _$Region _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _abbrev;
  String get abbrev => _$this._abbrev;
  set abbrev(String abbrev) => _$this._abbrev = abbrev;

  ListBuilder<TimeZone> _timezones;
  ListBuilder<TimeZone> get timezones =>
      _$this._timezones ??= new ListBuilder<TimeZone>();
  set timezones(ListBuilder<TimeZone> timezones) =>
      _$this._timezones = timezones;

  RegionBuilder();

  RegionBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _abbrev = _$v.abbrev;
      _timezones = _$v.timezones?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Region other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Region;
  }

  @override
  void update(void Function(RegionBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Region build() {
    _$Region _$result;
    try {
      _$result = _$v ??
          new _$Region._(
              name: name, abbrev: abbrev, timezones: timezones.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'timezones';
        timezones.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Region', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
