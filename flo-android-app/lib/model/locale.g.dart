// GENERATED CODE - DO NOT MODIFY BY HAND

part of locale;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Locale> _$localeSerializer = new _$LocaleSerializer();

class _$LocaleSerializer implements StructuredSerializer<Locale> {
  @override
  final Iterable<Type> types = const [Locale, _$Locale];
  @override
  final String wireName = 'Locale';

  @override
  Iterable<Object> serialize(Serializers serializers, Locale object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'locale',
      serializers.serialize(object.locale,
          specifiedType: const FullType(String)),
    ];
    if (object.regions != null) {
      result
        ..add('regions')
        ..add(serializers.serialize(object.regions,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Region)])));
    }
    if (object.timezones != null) {
      result
        ..add('timezones')
        ..add(serializers.serialize(object.timezones,
            specifiedType:
                const FullType(BuiltList, const [const FullType(TimeZone)])));
    }
    return result;
  }

  @override
  Locale deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LocaleBuilder();

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
        case 'locale':
          result.locale = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'regions':
          result.regions.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Region)]))
              as BuiltList<dynamic>);
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

class _$Locale extends Locale {
  @override
  final String name;
  @override
  final String locale;
  @override
  final BuiltList<Region> regions;
  @override
  final BuiltList<TimeZone> timezones;

  factory _$Locale([void Function(LocaleBuilder) updates]) =>
      (new LocaleBuilder()..update(updates)).build();

  _$Locale._({this.name, this.locale, this.regions, this.timezones})
      : super._() {
    if (name == null) {
      throw new BuiltValueNullFieldError('Locale', 'name');
    }
    if (locale == null) {
      throw new BuiltValueNullFieldError('Locale', 'locale');
    }
  }

  @override
  Locale rebuild(void Function(LocaleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LocaleBuilder toBuilder() => new LocaleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Locale &&
        name == other.name &&
        locale == other.locale &&
        regions == other.regions &&
        timezones == other.timezones;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, name.hashCode), locale.hashCode), regions.hashCode),
        timezones.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Locale')
          ..add('name', name)
          ..add('locale', locale)
          ..add('regions', regions)
          ..add('timezones', timezones))
        .toString();
  }
}

class LocaleBuilder implements Builder<Locale, LocaleBuilder> {
  _$Locale _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _locale;
  String get locale => _$this._locale;
  set locale(String locale) => _$this._locale = locale;

  ListBuilder<Region> _regions;
  ListBuilder<Region> get regions =>
      _$this._regions ??= new ListBuilder<Region>();
  set regions(ListBuilder<Region> regions) => _$this._regions = regions;

  ListBuilder<TimeZone> _timezones;
  ListBuilder<TimeZone> get timezones =>
      _$this._timezones ??= new ListBuilder<TimeZone>();
  set timezones(ListBuilder<TimeZone> timezones) =>
      _$this._timezones = timezones;

  LocaleBuilder();

  LocaleBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _locale = _$v.locale;
      _regions = _$v.regions?.toBuilder();
      _timezones = _$v.timezones?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Locale other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Locale;
  }

  @override
  void update(void Function(LocaleBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Locale build() {
    _$Locale _$result;
    try {
      _$result = _$v ??
          new _$Locale._(
              name: name,
              locale: locale,
              regions: _regions?.build(),
              timezones: _timezones?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'regions';
        _regions?.build();
        _$failedField = 'timezones';
        _timezones?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Locale', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
