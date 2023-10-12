// GENERATED CODE - DO NOT MODIFY BY HAND

part of user;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<User> _$userSerializer = new _$UserSerializer();

class _$UserSerializer implements StructuredSerializer<User> {
  @override
  final Iterable<Type> types = const [User, _$User];
  @override
  final String wireName = 'User';

  @override
  Iterable<Object> serialize(Serializers serializers, User object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.id != null) {
      result
        ..add('id')
        ..add(serializers.serialize(object.id,
            specifiedType: const FullType(String)));
    }
    if (object.email != null) {
      result
        ..add('email')
        ..add(serializers.serialize(object.email,
            specifiedType: const FullType(String)));
    }
    if (object.isActive != null) {
      result
        ..add('isActive')
        ..add(serializers.serialize(object.isActive,
            specifiedType: const FullType(bool)));
    }
    if (object.firstName != null) {
      result
        ..add('firstName')
        ..add(serializers.serialize(object.firstName,
            specifiedType: const FullType(String)));
    }
    if (object.lastName != null) {
      result
        ..add('lastName')
        ..add(serializers.serialize(object.lastName,
            specifiedType: const FullType(String)));
    }
    if (object.phoneMobile != null) {
      result
        ..add('phoneMobile')
        ..add(serializers.serialize(object.phoneMobile,
            specifiedType: const FullType(String)));
    }
    if (object.locations != null) {
      result
        ..add('locations')
        ..add(serializers.serialize(object.locations,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Id)])));
    }
    if (object.locationRoles != null) {
      result
        ..add('locationRoles')
        ..add(serializers.serialize(object.locationRoles,
            specifiedType: const FullType(
                BuiltList, const [const FullType(LocationRole)])));
    }
    if (object.accountRole != null) {
      result
        ..add('accountRole')
        ..add(serializers.serialize(object.accountRole,
            specifiedType: const FullType(AccountRole)));
    }
    if (object.account != null) {
      result
        ..add('account')
        ..add(serializers.serialize(object.account,
            specifiedType: const FullType(Id)));
    }
    if (object.middleName != null) {
      result
        ..add('middleName')
        ..add(serializers.serialize(object.middleName,
            specifiedType: const FullType(String)));
    }
    if (object.prefixName != null) {
      result
        ..add('prefixName')
        ..add(serializers.serialize(object.prefixName,
            specifiedType: const FullType(String)));
    }
    if (object.suffixName != null) {
      result
        ..add('suffixName')
        ..add(serializers.serialize(object.suffixName,
            specifiedType: const FullType(String)));
    }
    if (object.unitSystem != null) {
      result
        ..add('unitSystem')
        ..add(serializers.serialize(object.unitSystem,
            specifiedType: const FullType(UnitSystem)));
    }
    if (object.locale != null) {
      result
        ..add('locale')
        ..add(serializers.serialize(object.locale,
            specifiedType: const FullType(String)));
    }
    if (object.alertsSettings != null) {
      result
        ..add('alarmSettings')
        ..add(serializers.serialize(object.alertsSettings,
            specifiedType: const FullType(
                BuiltList, const [const FullType(DeviceAlertsSettings)])));
    }
    if (object.enabledFeatures != null) {
      result
        ..add('enabledFeatures')
        ..add(serializers.serialize(object.enabledFeatures,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    if (object.dirty != null) {
      result
        ..add('dirty')
        ..add(serializers.serialize(object.dirty,
            specifiedType: const FullType(bool)));
    }
    return result;
  }

  @override
  User deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserBuilder();

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
        case 'email':
          result.email = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isActive':
          result.isActive = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'firstName':
          result.firstName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'lastName':
          result.lastName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'phoneMobile':
          result.phoneMobile = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'locations':
          result.locations.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Id)]))
              as BuiltList<dynamic>);
          break;
        case 'locationRoles':
          result.locationRoles.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(LocationRole)]))
              as BuiltList<dynamic>);
          break;
        case 'accountRole':
          result.accountRole.replace(serializers.deserialize(value,
              specifiedType: const FullType(AccountRole)) as AccountRole);
          break;
        case 'account':
          result.account.replace(serializers.deserialize(value,
              specifiedType: const FullType(Id)) as Id);
          break;
        case 'middleName':
          result.middleName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'prefixName':
          result.prefixName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'suffixName':
          result.suffixName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'unitSystem':
          result.unitSystem = serializers.deserialize(value,
              specifiedType: const FullType(UnitSystem)) as UnitSystem;
          break;
        case 'locale':
          result.locale = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'alarmSettings':
          result.alertsSettings.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(DeviceAlertsSettings)]))
              as BuiltList<dynamic>);
          break;
        case 'enabledFeatures':
          result.enabledFeatures.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
        case 'dirty':
          result.dirty = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$User extends User {
  @override
  final String id;
  @override
  final String email;
  @override
  final bool isActive;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String phoneMobile;
  @override
  final BuiltList<Id> locations;
  @override
  final BuiltList<LocationRole> locationRoles;
  @override
  final AccountRole accountRole;
  @override
  final Id account;
  @override
  final String middleName;
  @override
  final String prefixName;
  @override
  final String suffixName;
  @override
  final UnitSystem unitSystem;
  @override
  final String locale;
  @override
  final BuiltList<DeviceAlertsSettings> alertsSettings;
  @override
  final BuiltList<String> enabledFeatures;
  @override
  final bool dirty;

  factory _$User([void Function(UserBuilder) updates]) =>
      (new UserBuilder()..update(updates)).build();

  _$User._(
      {this.id,
      this.email,
      this.isActive,
      this.firstName,
      this.lastName,
      this.phoneMobile,
      this.locations,
      this.locationRoles,
      this.accountRole,
      this.account,
      this.middleName,
      this.prefixName,
      this.suffixName,
      this.unitSystem,
      this.locale,
      this.alertsSettings,
      this.enabledFeatures,
      this.dirty})
      : super._();

  @override
  User rebuild(void Function(UserBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserBuilder toBuilder() => new UserBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
        id == other.id &&
        email == other.email &&
        isActive == other.isActive &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        phoneMobile == other.phoneMobile &&
        locations == other.locations &&
        locationRoles == other.locationRoles &&
        accountRole == other.accountRole &&
        account == other.account &&
        middleName == other.middleName &&
        prefixName == other.prefixName &&
        suffixName == other.suffixName &&
        unitSystem == other.unitSystem &&
        locale == other.locale &&
        alertsSettings == other.alertsSettings &&
        enabledFeatures == other.enabledFeatures &&
        dirty == other.dirty;
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
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(
                                                                        $jc(
                                                                            0,
                                                                            id
                                                                                .hashCode),
                                                                        email
                                                                            .hashCode),
                                                                    isActive
                                                                        .hashCode),
                                                                firstName
                                                                    .hashCode),
                                                            lastName.hashCode),
                                                        phoneMobile.hashCode),
                                                    locations.hashCode),
                                                locationRoles.hashCode),
                                            accountRole.hashCode),
                                        account.hashCode),
                                    middleName.hashCode),
                                prefixName.hashCode),
                            suffixName.hashCode),
                        unitSystem.hashCode),
                    locale.hashCode),
                alertsSettings.hashCode),
            enabledFeatures.hashCode),
        dirty.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('User')
          ..add('id', id)
          ..add('email', email)
          ..add('isActive', isActive)
          ..add('firstName', firstName)
          ..add('lastName', lastName)
          ..add('phoneMobile', phoneMobile)
          ..add('locations', locations)
          ..add('locationRoles', locationRoles)
          ..add('accountRole', accountRole)
          ..add('account', account)
          ..add('middleName', middleName)
          ..add('prefixName', prefixName)
          ..add('suffixName', suffixName)
          ..add('unitSystem', unitSystem)
          ..add('locale', locale)
          ..add('alertsSettings', alertsSettings)
          ..add('enabledFeatures', enabledFeatures)
          ..add('dirty', dirty))
        .toString();
  }
}

class UserBuilder implements Builder<User, UserBuilder> {
  _$User _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _email;
  String get email => _$this._email;
  set email(String email) => _$this._email = email;

  bool _isActive;
  bool get isActive => _$this._isActive;
  set isActive(bool isActive) => _$this._isActive = isActive;

  String _firstName;
  String get firstName => _$this._firstName;
  set firstName(String firstName) => _$this._firstName = firstName;

  String _lastName;
  String get lastName => _$this._lastName;
  set lastName(String lastName) => _$this._lastName = lastName;

  String _phoneMobile;
  String get phoneMobile => _$this._phoneMobile;
  set phoneMobile(String phoneMobile) => _$this._phoneMobile = phoneMobile;

  ListBuilder<Id> _locations;
  ListBuilder<Id> get locations => _$this._locations ??= new ListBuilder<Id>();
  set locations(ListBuilder<Id> locations) => _$this._locations = locations;

  ListBuilder<LocationRole> _locationRoles;
  ListBuilder<LocationRole> get locationRoles =>
      _$this._locationRoles ??= new ListBuilder<LocationRole>();
  set locationRoles(ListBuilder<LocationRole> locationRoles) =>
      _$this._locationRoles = locationRoles;

  AccountRoleBuilder _accountRole;
  AccountRoleBuilder get accountRole =>
      _$this._accountRole ??= new AccountRoleBuilder();
  set accountRole(AccountRoleBuilder accountRole) =>
      _$this._accountRole = accountRole;

  IdBuilder _account;
  IdBuilder get account => _$this._account ??= new IdBuilder();
  set account(IdBuilder account) => _$this._account = account;

  String _middleName;
  String get middleName => _$this._middleName;
  set middleName(String middleName) => _$this._middleName = middleName;

  String _prefixName;
  String get prefixName => _$this._prefixName;
  set prefixName(String prefixName) => _$this._prefixName = prefixName;

  String _suffixName;
  String get suffixName => _$this._suffixName;
  set suffixName(String suffixName) => _$this._suffixName = suffixName;

  UnitSystem _unitSystem;
  UnitSystem get unitSystem => _$this._unitSystem;
  set unitSystem(UnitSystem unitSystem) => _$this._unitSystem = unitSystem;

  String _locale;
  String get locale => _$this._locale;
  set locale(String locale) => _$this._locale = locale;

  ListBuilder<DeviceAlertsSettings> _alertsSettings;
  ListBuilder<DeviceAlertsSettings> get alertsSettings =>
      _$this._alertsSettings ??= new ListBuilder<DeviceAlertsSettings>();
  set alertsSettings(ListBuilder<DeviceAlertsSettings> alertsSettings) =>
      _$this._alertsSettings = alertsSettings;

  ListBuilder<String> _enabledFeatures;
  ListBuilder<String> get enabledFeatures =>
      _$this._enabledFeatures ??= new ListBuilder<String>();
  set enabledFeatures(ListBuilder<String> enabledFeatures) =>
      _$this._enabledFeatures = enabledFeatures;

  bool _dirty;
  bool get dirty => _$this._dirty;
  set dirty(bool dirty) => _$this._dirty = dirty;

  UserBuilder();

  UserBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _email = _$v.email;
      _isActive = _$v.isActive;
      _firstName = _$v.firstName;
      _lastName = _$v.lastName;
      _phoneMobile = _$v.phoneMobile;
      _locations = _$v.locations?.toBuilder();
      _locationRoles = _$v.locationRoles?.toBuilder();
      _accountRole = _$v.accountRole?.toBuilder();
      _account = _$v.account?.toBuilder();
      _middleName = _$v.middleName;
      _prefixName = _$v.prefixName;
      _suffixName = _$v.suffixName;
      _unitSystem = _$v.unitSystem;
      _locale = _$v.locale;
      _alertsSettings = _$v.alertsSettings?.toBuilder();
      _enabledFeatures = _$v.enabledFeatures?.toBuilder();
      _dirty = _$v.dirty;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(User other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$User;
  }

  @override
  void update(void Function(UserBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$User build() {
    _$User _$result;
    try {
      _$result = _$v ??
          new _$User._(
              id: id,
              email: email,
              isActive: isActive,
              firstName: firstName,
              lastName: lastName,
              phoneMobile: phoneMobile,
              locations: _locations?.build(),
              locationRoles: _locationRoles?.build(),
              accountRole: _accountRole?.build(),
              account: _account?.build(),
              middleName: middleName,
              prefixName: prefixName,
              suffixName: suffixName,
              unitSystem: unitSystem,
              locale: locale,
              alertsSettings: _alertsSettings?.build(),
              enabledFeatures: _enabledFeatures?.build(),
              dirty: dirty);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'locations';
        _locations?.build();
        _$failedField = 'locationRoles';
        _locationRoles?.build();
        _$failedField = 'accountRole';
        _accountRole?.build();
        _$failedField = 'account';
        _account?.build();

        _$failedField = 'alertsSettings';
        _alertsSettings?.build();
        _$failedField = 'enabledFeatures';
        _enabledFeatures?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'User', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
