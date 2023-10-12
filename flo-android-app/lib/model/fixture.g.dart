// GENERATED CODE - DO NOT MODIFY BY HAND

part of fixture;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Fixture> _$fixtureSerializer = new _$FixtureSerializer();

class _$FixtureSerializer implements StructuredSerializer<Fixture> {
  @override
  final Iterable<Type> types = const [Fixture, _$Fixture];
  @override
  final String wireName = 'Fixture';

  @override
  Iterable<Object> serialize(Serializers serializers, Fixture object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.name != null) {
      result
        ..add('name')
        ..add(serializers.serialize(object.name,
            specifiedType: const FullType(String)));
    }
    if (object.index != null) {
      result
        ..add('index')
        ..add(serializers.serialize(object.index,
            specifiedType: const FullType(int)));
    }
    if (object.type != null) {
      result
        ..add('type')
        ..add(serializers.serialize(object.type,
            specifiedType: const FullType(int)));
    }
    if (object.gallons != null) {
      result
        ..add('gallons')
        ..add(serializers.serialize(object.gallons,
            specifiedType: const FullType(double)));
    }
    if (object.ratio != null) {
      result
        ..add('ratio')
        ..add(serializers.serialize(object.ratio,
            specifiedType: const FullType(double)));
    }
    if (object.numEvents != null) {
      result
        ..add('numEvents')
        ..add(serializers.serialize(object.numEvents,
            specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  Fixture deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FixtureBuilder();

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
        case 'index':
          result.index = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'gallons':
          result.gallons = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'ratio':
          result.ratio = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'numEvents':
          result.numEvents = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$Fixture extends Fixture {
  @override
  final String name;
  @override
  final int index;
  @override
  final int type;
  @override
  final double gallons;
  @override
  final double ratio;
  @override
  final int numEvents;

  factory _$Fixture([void Function(FixtureBuilder) updates]) =>
      (new FixtureBuilder()..update(updates)).build();

  _$Fixture._(
      {this.name,
      this.index,
      this.type,
      this.gallons,
      this.ratio,
      this.numEvents})
      : super._();

  @override
  Fixture rebuild(void Function(FixtureBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FixtureBuilder toBuilder() => new FixtureBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Fixture &&
        name == other.name &&
        index == other.index &&
        type == other.type &&
        gallons == other.gallons &&
        ratio == other.ratio &&
        numEvents == other.numEvents;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, name.hashCode), index.hashCode), type.hashCode),
                gallons.hashCode),
            ratio.hashCode),
        numEvents.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Fixture')
          ..add('name', name)
          ..add('index', index)
          ..add('type', type)
          ..add('gallons', gallons)
          ..add('ratio', ratio)
          ..add('numEvents', numEvents))
        .toString();
  }
}

class FixtureBuilder implements Builder<Fixture, FixtureBuilder> {
  _$Fixture _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  int _index;
  int get index => _$this._index;
  set index(int index) => _$this._index = index;

  int _type;
  int get type => _$this._type;
  set type(int type) => _$this._type = type;

  double _gallons;
  double get gallons => _$this._gallons;
  set gallons(double gallons) => _$this._gallons = gallons;

  double _ratio;
  double get ratio => _$this._ratio;
  set ratio(double ratio) => _$this._ratio = ratio;

  int _numEvents;
  int get numEvents => _$this._numEvents;
  set numEvents(int numEvents) => _$this._numEvents = numEvents;

  FixtureBuilder();

  FixtureBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _index = _$v.index;
      _type = _$v.type;
      _gallons = _$v.gallons;
      _ratio = _$v.ratio;
      _numEvents = _$v.numEvents;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Fixture other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Fixture;
  }

  @override
  void update(void Function(FixtureBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Fixture build() {
    final _$result = _$v ??
        new _$Fixture._(
            name: name,
            index: index,
            type: type,
            gallons: gallons,
            ratio: ratio,
            numEvents: numEvents);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
