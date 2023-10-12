// GENERATED CODE - DO NOT MODIFY BY HAND

part of preference_category;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PreferenceCategory extends PreferenceCategory {
  @override
  final BuiltList<Item> prv;
  @override
  final BuiltList<Item> pipeType;
  @override
  final BuiltList<Item> fixtureIndoor;
  @override
  final BuiltList<Item> fixtureOutdoor;
  @override
  final BuiltList<Item> homeAppliance;
  @override
  final BuiltList<Item> irrigationType;
  @override
  final BuiltList<Item> locationSize;
  @override
  final BuiltList<Item> residenceType;

  factory _$PreferenceCategory(
          [void Function(PreferenceCategoryBuilder) updates]) =>
      (new PreferenceCategoryBuilder()..update(updates)).build();

  _$PreferenceCategory._(
      {this.prv,
      this.pipeType,
      this.fixtureIndoor,
      this.fixtureOutdoor,
      this.homeAppliance,
      this.irrigationType,
      this.locationSize,
      this.residenceType})
      : super._();

  @override
  PreferenceCategory rebuild(
          void Function(PreferenceCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreferenceCategoryBuilder toBuilder() =>
      new PreferenceCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PreferenceCategory &&
        prv == other.prv &&
        pipeType == other.pipeType &&
        fixtureIndoor == other.fixtureIndoor &&
        fixtureOutdoor == other.fixtureOutdoor &&
        homeAppliance == other.homeAppliance &&
        irrigationType == other.irrigationType &&
        locationSize == other.locationSize &&
        residenceType == other.residenceType;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, prv.hashCode), pipeType.hashCode),
                            fixtureIndoor.hashCode),
                        fixtureOutdoor.hashCode),
                    homeAppliance.hashCode),
                irrigationType.hashCode),
            locationSize.hashCode),
        residenceType.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PreferenceCategory')
          ..add('prv', prv)
          ..add('pipeType', pipeType)
          ..add('fixtureIndoor', fixtureIndoor)
          ..add('fixtureOutdoor', fixtureOutdoor)
          ..add('homeAppliance', homeAppliance)
          ..add('irrigationType', irrigationType)
          ..add('locationSize', locationSize)
          ..add('residenceType', residenceType))
        .toString();
  }
}

class PreferenceCategoryBuilder
    implements Builder<PreferenceCategory, PreferenceCategoryBuilder> {
  _$PreferenceCategory _$v;

  ListBuilder<Item> _prv;
  ListBuilder<Item> get prv => _$this._prv ??= new ListBuilder<Item>();
  set prv(ListBuilder<Item> prv) => _$this._prv = prv;

  ListBuilder<Item> _pipeType;
  ListBuilder<Item> get pipeType =>
      _$this._pipeType ??= new ListBuilder<Item>();
  set pipeType(ListBuilder<Item> pipeType) => _$this._pipeType = pipeType;

  ListBuilder<Item> _fixtureIndoor;
  ListBuilder<Item> get fixtureIndoor =>
      _$this._fixtureIndoor ??= new ListBuilder<Item>();
  set fixtureIndoor(ListBuilder<Item> fixtureIndoor) =>
      _$this._fixtureIndoor = fixtureIndoor;

  ListBuilder<Item> _fixtureOutdoor;
  ListBuilder<Item> get fixtureOutdoor =>
      _$this._fixtureOutdoor ??= new ListBuilder<Item>();
  set fixtureOutdoor(ListBuilder<Item> fixtureOutdoor) =>
      _$this._fixtureOutdoor = fixtureOutdoor;

  ListBuilder<Item> _homeAppliance;
  ListBuilder<Item> get homeAppliance =>
      _$this._homeAppliance ??= new ListBuilder<Item>();
  set homeAppliance(ListBuilder<Item> homeAppliance) =>
      _$this._homeAppliance = homeAppliance;

  ListBuilder<Item> _irrigationType;
  ListBuilder<Item> get irrigationType =>
      _$this._irrigationType ??= new ListBuilder<Item>();
  set irrigationType(ListBuilder<Item> irrigationType) =>
      _$this._irrigationType = irrigationType;

  ListBuilder<Item> _locationSize;
  ListBuilder<Item> get locationSize =>
      _$this._locationSize ??= new ListBuilder<Item>();
  set locationSize(ListBuilder<Item> locationSize) =>
      _$this._locationSize = locationSize;

  ListBuilder<Item> _residenceType;
  ListBuilder<Item> get residenceType =>
      _$this._residenceType ??= new ListBuilder<Item>();
  set residenceType(ListBuilder<Item> residenceType) =>
      _$this._residenceType = residenceType;

  PreferenceCategoryBuilder();

  PreferenceCategoryBuilder get _$this {
    if (_$v != null) {
      _prv = _$v.prv?.toBuilder();
      _pipeType = _$v.pipeType?.toBuilder();
      _fixtureIndoor = _$v.fixtureIndoor?.toBuilder();
      _fixtureOutdoor = _$v.fixtureOutdoor?.toBuilder();
      _homeAppliance = _$v.homeAppliance?.toBuilder();
      _irrigationType = _$v.irrigationType?.toBuilder();
      _locationSize = _$v.locationSize?.toBuilder();
      _residenceType = _$v.residenceType?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PreferenceCategory other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PreferenceCategory;
  }

  @override
  void update(void Function(PreferenceCategoryBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PreferenceCategory build() {
    _$PreferenceCategory _$result;
    try {
      _$result = _$v ??
          new _$PreferenceCategory._(
              prv: _prv?.build(),
              pipeType: _pipeType?.build(),
              fixtureIndoor: _fixtureIndoor?.build(),
              fixtureOutdoor: _fixtureOutdoor?.build(),
              homeAppliance: _homeAppliance?.build(),
              irrigationType: _irrigationType?.build(),
              locationSize: _locationSize?.build(),
              residenceType: _residenceType?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'prv';
        _prv?.build();
        _$failedField = 'pipeType';
        _pipeType?.build();
        _$failedField = 'fixtureIndoor';
        _fixtureIndoor?.build();
        _$failedField = 'fixtureOutdoor';
        _fixtureOutdoor?.build();
        _$failedField = 'homeAppliance';
        _homeAppliance?.build();
        _$failedField = 'irrigationType';
        _irrigationType?.build();
        _$failedField = 'locationSize';
        _locationSize?.build();
        _$failedField = 'residenceType';
        _residenceType?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PreferenceCategory', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
