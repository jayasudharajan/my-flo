// GENERATED CODE - DO NOT MODIFY BY HAND

part of location;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Location> _$locationSerializer = new _$LocationSerializer();

class _$LocationSerializer implements StructuredSerializer<Location> {
  @override
  final Iterable<Type> types = const [Location, _$Location];
  @override
  final String wireName = 'Location';

  @override
  Iterable<Object> serialize(Serializers serializers, Location object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.users != null) {
      result
        ..add('users')
        ..add(serializers.serialize(object.users,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Id)])));
    }
    if (object.devices != null) {
      result
        ..add('devices')
        ..add(serializers.serialize(object.devices,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Device)])));
    }
    if (object.userRoles != null) {
      result
        ..add('userRoles')
        ..add(serializers.serialize(object.userRoles,
            specifiedType:
                const FullType(BuiltList, const [const FullType(UserRole)])));
    }
    if (object.account != null) {
      result
        ..add('account')
        ..add(serializers.serialize(object.account,
            specifiedType: const FullType(Id)));
    }
    if (object.nickname != null) {
      result
        ..add('nickname')
        ..add(serializers.serialize(object.nickname,
            specifiedType: const FullType(String)));
    }
    if (object.address != null) {
      result
        ..add('address')
        ..add(serializers.serialize(object.address,
            specifiedType: const FullType(String)));
    }
    if (object.address2 != null) {
      result
        ..add('address2')
        ..add(serializers.serialize(object.address2,
            specifiedType: const FullType(String)));
    }
    if (object.city != null) {
      result
        ..add('city')
        ..add(serializers.serialize(object.city,
            specifiedType: const FullType(String)));
    }
    if (object.state != null) {
      result
        ..add('state')
        ..add(serializers.serialize(object.state,
            specifiedType: const FullType(String)));
    }
    if (object.country != null) {
      result
        ..add('country')
        ..add(serializers.serialize(object.country,
            specifiedType: const FullType(String)));
    }
    if (object.postalCode != null) {
      result
        ..add('postalCode')
        ..add(serializers.serialize(object.postalCode,
            specifiedType: const FullType(String)));
    }
    if (object.timezone != null) {
      result
        ..add('timezone')
        ..add(serializers.serialize(object.timezone,
            specifiedType: const FullType(String)));
    }
    if (object.gallonsPerDayGoal != null) {
      result
        ..add('gallonsPerDayGoal')
        ..add(serializers.serialize(object.gallonsPerDayGoal,
            specifiedType: const FullType(double)));
    }
    if (object.occupants != null) {
      result
        ..add('occupants')
        ..add(serializers.serialize(object.occupants,
            specifiedType: const FullType(int)));
    }
    if (object.stories != null) {
      result
        ..add('stories')
        ..add(serializers.serialize(object.stories,
            specifiedType: const FullType(int)));
    }
    if (object.isProfileComplete != null) {
      result
        ..add('isProfileComplete')
        ..add(serializers.serialize(object.isProfileComplete,
            specifiedType: const FullType(bool)));
    }
    if (object.waterShutoffKnown != null) {
      result
        ..add('waterShutoffKnown')
        ..add(serializers.serialize(object.waterShutoffKnown,
            specifiedType: const FullType(Answer)));
    }
    if (object.indoorAmenities != null) {
      result
        ..add('indoorAmenities')
        ..add(serializers.serialize(object.indoorAmenities,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    if (object.outdoorAmenities != null) {
      result
        ..add('outdoorAmenities')
        ..add(serializers.serialize(object.outdoorAmenities,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    if (object.plumbingAppliances != null) {
      result
        ..add('plumbingAppliances')
        ..add(serializers.serialize(object.plumbingAppliances,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    if (object.locationType != null) {
      result
        ..add('locationType')
        ..add(serializers.serialize(object.locationType,
            specifiedType: const FullType(LocationType)));
    }
    if (object.residenceType != null) {
      result
        ..add('residenceType')
        ..add(serializers.serialize(object.residenceType,
            specifiedType: const FullType(String)));
    }
    if (object.waterSource != null) {
      result
        ..add('waterSource')
        ..add(serializers.serialize(object.waterSource,
            specifiedType: const FullType(String)));
    }
    if (object.locationSize != null) {
      result
        ..add('locationSize')
        ..add(serializers.serialize(object.locationSize,
            specifiedType: const FullType(String)));
    }
    if (object.showerBathCount != null) {
      result
        ..add('showerBathCount')
        ..add(serializers.serialize(object.showerBathCount,
            specifiedType: const FullType(int)));
    }
    if (object.toiletCount != null) {
      result
        ..add('toiletCount')
        ..add(serializers.serialize(object.toiletCount,
            specifiedType: const FullType(int)));
    }
    if (object.plumbingType != null) {
      result
        ..add('plumbingType')
        ..add(serializers.serialize(object.plumbingType,
            specifiedType: const FullType(String)));
    }
    if (object.homeownersInsurance != null) {
      result
        ..add('homeownersInsurance')
        ..add(serializers.serialize(object.homeownersInsurance,
            specifiedType: const FullType(String)));
    }
    if (object.hasPastWaterDamage != null) {
      result
        ..add('hasPastWaterDamage')
        ..add(serializers.serialize(object.hasPastWaterDamage,
            specifiedType: const FullType(bool)));
    }
    if (object.pastWaterDamageClaimAmount != null) {
      result
        ..add('pastWaterDamageClaimAmount')
        ..add(serializers.serialize(object.pastWaterDamageClaimAmount,
            specifiedType: const FullType(PastWaterDamageClaimAmount)));
    }
    if (object.systemModes != null) {
      result
        ..add('systemMode')
        ..add(serializers.serialize(object.systemModes,
            specifiedType: const FullType(PendingSystemMode)));
    }
    if (object.waterUtility != null) {
      result
        ..add('waterUtility')
        ..add(serializers.serialize(object.waterUtility,
            specifiedType: const FullType(String)));
    }
    if (object.subscription != null) {
      result
        ..add('subscription')
        ..add(serializers.serialize(object.subscription,
            specifiedType: const FullType(Subscription)));
    }
    if (object.irrigationSchedule != null) {
      result
        ..add('irrigationSchedule')
        ..add(serializers.serialize(object.irrigationSchedule,
            specifiedType: const FullType(IrrigationSchedule)));
    }
    if (object.notifications != null) {
      result
        ..add('notifications')
        ..add(serializers.serialize(object.notifications,
            specifiedType: const FullType(AlertStatistics)));
    }
    return result;
  }

  @override
  Location deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LocationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'users':
          result.users.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Id)]))
              as BuiltList<dynamic>);
          break;
        case 'devices':
          result.devices.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Device)]))
              as BuiltList<dynamic>);
          break;
        case 'userRoles':
          result.userRoles.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(UserRole)]))
              as BuiltList<dynamic>);
          break;
        case 'account':
          result.account.replace(serializers.deserialize(value,
              specifiedType: const FullType(Id)) as Id);
          break;
        case 'nickname':
          result.nickname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'address':
          result.address = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'address2':
          result.address2 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'city':
          result.city = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'state':
          result.state = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'country':
          result.country = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'postalCode':
          result.postalCode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'timezone':
          result.timezone = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'gallonsPerDayGoal':
          result.gallonsPerDayGoal = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'occupants':
          result.occupants = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'stories':
          result.stories = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'isProfileComplete':
          result.isProfileComplete = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'waterShutoffKnown':
          result.waterShutoffKnown = serializers.deserialize(value,
              specifiedType: const FullType(Answer)) as Answer;
          break;
        case 'indoorAmenities':
          result.indoorAmenities.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
        case 'outdoorAmenities':
          result.outdoorAmenities.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
        case 'plumbingAppliances':
          result.plumbingAppliances.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<dynamic>);
          break;
        case 'locationType':
          result.locationType = serializers.deserialize(value,
              specifiedType: const FullType(LocationType)) as LocationType;
          break;
        case 'residenceType':
          result.residenceType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'waterSource':
          result.waterSource = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'locationSize':
          result.locationSize = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'showerBathCount':
          result.showerBathCount = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'toiletCount':
          result.toiletCount = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'plumbingType':
          result.plumbingType = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'homeownersInsurance':
          result.homeownersInsurance = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'hasPastWaterDamage':
          result.hasPastWaterDamage = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'pastWaterDamageClaimAmount':
          result.pastWaterDamageClaimAmount = serializers.deserialize(value,
                  specifiedType: const FullType(PastWaterDamageClaimAmount))
              as PastWaterDamageClaimAmount;
          break;
        case 'systemMode':
          result.systemModes.replace(serializers.deserialize(value,
                  specifiedType: const FullType(PendingSystemMode))
              as PendingSystemMode);
          break;
        case 'waterUtility':
          result.waterUtility = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'subscription':
          result.subscription.replace(serializers.deserialize(value,
              specifiedType: const FullType(Subscription)) as Subscription);
          break;
        case 'irrigationSchedule':
          result.irrigationSchedule.replace(serializers.deserialize(value,
                  specifiedType: const FullType(IrrigationSchedule))
              as IrrigationSchedule);
          break;
        case 'notifications':
          result.notifications.replace(serializers.deserialize(value,
                  specifiedType: const FullType(AlertStatistics))
              as AlertStatistics);
          break;
      }
    }

    return result.build();
  }
}

class _$Location extends Location {
  @override
  final String id;
  @override
  final BuiltList<Id> users;
  @override
  final BuiltList<Device> devices;
  @override
  final BuiltList<UserRole> userRoles;
  @override
  final Id account;
  @override
  final String nickname;
  @override
  final String address;
  @override
  final String address2;
  @override
  final String city;
  @override
  final String state;
  @override
  final String country;
  @override
  final String postalCode;
  @override
  final String timezone;
  @override
  final double gallonsPerDayGoal;
  @override
  final int occupants;
  @override
  final int stories;
  @override
  final bool isProfileComplete;
  @override
  final Answer waterShutoffKnown;
  @override
  final BuiltList<String> indoorAmenities;
  @override
  final BuiltList<String> outdoorAmenities;
  @override
  final BuiltList<String> plumbingAppliances;
  @override
  final LocationType locationType;
  @override
  final String residenceType;
  @override
  final String waterSource;
  @override
  final String locationSize;
  @override
  final int showerBathCount;
  @override
  final int toiletCount;
  @override
  final String plumbingType;
  @override
  final String homeownersInsurance;
  @override
  final bool hasPastWaterDamage;
  @override
  final PastWaterDamageClaimAmount pastWaterDamageClaimAmount;
  @override
  final PendingSystemMode systemModes;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final String waterUtility;
  @override
  final Subscription subscription;
  @override
  final IrrigationSchedule irrigationSchedule;
  @override
  final AlertStatistics notifications;
  @override
  final bool dirty;

  factory _$Location([void Function(LocationBuilder) updates]) =>
      (new LocationBuilder()..update(updates)).build();

  _$Location._(
      {this.id,
      this.users,
      this.devices,
      this.userRoles,
      this.account,
      this.nickname,
      this.address,
      this.address2,
      this.city,
      this.state,
      this.country,
      this.postalCode,
      this.timezone,
      this.gallonsPerDayGoal,
      this.occupants,
      this.stories,
      this.isProfileComplete,
      this.waterShutoffKnown,
      this.indoorAmenities,
      this.outdoorAmenities,
      this.plumbingAppliances,
      this.locationType,
      this.residenceType,
      this.waterSource,
      this.locationSize,
      this.showerBathCount,
      this.toiletCount,
      this.plumbingType,
      this.homeownersInsurance,
      this.hasPastWaterDamage,
      this.pastWaterDamageClaimAmount,
      this.systemModes,
      this.createdAt,
      this.updatedAt,
      this.waterUtility,
      this.subscription,
      this.irrigationSchedule,
      this.notifications,
      this.dirty})
      : super._();

  @override
  Location rebuild(void Function(LocationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LocationBuilder toBuilder() => new LocationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Location &&
        id == other.id &&
        users == other.users &&
        devices == other.devices &&
        userRoles == other.userRoles &&
        account == other.account &&
        nickname == other.nickname &&
        address == other.address &&
        address2 == other.address2 &&
        city == other.city &&
        state == other.state &&
        country == other.country &&
        postalCode == other.postalCode &&
        timezone == other.timezone &&
        gallonsPerDayGoal == other.gallonsPerDayGoal &&
        occupants == other.occupants &&
        stories == other.stories &&
        isProfileComplete == other.isProfileComplete &&
        waterShutoffKnown == other.waterShutoffKnown &&
        indoorAmenities == other.indoorAmenities &&
        outdoorAmenities == other.outdoorAmenities &&
        plumbingAppliances == other.plumbingAppliances &&
        locationType == other.locationType &&
        residenceType == other.residenceType &&
        waterSource == other.waterSource &&
        locationSize == other.locationSize &&
        showerBathCount == other.showerBathCount &&
        toiletCount == other.toiletCount &&
        plumbingType == other.plumbingType &&
        homeownersInsurance == other.homeownersInsurance &&
        hasPastWaterDamage == other.hasPastWaterDamage &&
        pastWaterDamageClaimAmount == other.pastWaterDamageClaimAmount &&
        systemModes == other.systemModes &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        waterUtility == other.waterUtility &&
        subscription == other.subscription &&
        irrigationSchedule == other.irrigationSchedule &&
        notifications == other.notifications &&
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
                                                                            $jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc(0, id.hashCode), users.hashCode), devices.hashCode), userRoles.hashCode), account.hashCode), nickname.hashCode), address.hashCode), address2.hashCode), city.hashCode), state.hashCode), country.hashCode), postalCode.hashCode), timezone.hashCode), gallonsPerDayGoal.hashCode), occupants.hashCode), stories.hashCode), isProfileComplete.hashCode), waterShutoffKnown.hashCode), indoorAmenities.hashCode), outdoorAmenities.hashCode),
                                                                                plumbingAppliances.hashCode),
                                                                            locationType.hashCode),
                                                                        residenceType.hashCode),
                                                                    waterSource.hashCode),
                                                                locationSize.hashCode),
                                                            showerBathCount.hashCode),
                                                        toiletCount.hashCode),
                                                    plumbingType.hashCode),
                                                homeownersInsurance.hashCode),
                                            hasPastWaterDamage.hashCode),
                                        pastWaterDamageClaimAmount.hashCode),
                                    systemModes.hashCode),
                                createdAt.hashCode),
                            updatedAt.hashCode),
                        waterUtility.hashCode),
                    subscription.hashCode),
                irrigationSchedule.hashCode),
            notifications.hashCode),
        dirty.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Location')
          ..add('id', id)
          ..add('users', users)
          ..add('devices', devices)
          ..add('userRoles', userRoles)
          ..add('account', account)
          ..add('nickname', nickname)
          ..add('address', address)
          ..add('address2', address2)
          ..add('city', city)
          ..add('state', state)
          ..add('country', country)
          ..add('postalCode', postalCode)
          ..add('timezone', timezone)
          ..add('gallonsPerDayGoal', gallonsPerDayGoal)
          ..add('occupants', occupants)
          ..add('stories', stories)
          ..add('isProfileComplete', isProfileComplete)
          ..add('waterShutoffKnown', waterShutoffKnown)
          ..add('indoorAmenities', indoorAmenities)
          ..add('outdoorAmenities', outdoorAmenities)
          ..add('plumbingAppliances', plumbingAppliances)
          ..add('locationType', locationType)
          ..add('residenceType', residenceType)
          ..add('waterSource', waterSource)
          ..add('locationSize', locationSize)
          ..add('showerBathCount', showerBathCount)
          ..add('toiletCount', toiletCount)
          ..add('plumbingType', plumbingType)
          ..add('homeownersInsurance', homeownersInsurance)
          ..add('hasPastWaterDamage', hasPastWaterDamage)
          ..add('pastWaterDamageClaimAmount', pastWaterDamageClaimAmount)
          ..add('systemModes', systemModes)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('waterUtility', waterUtility)
          ..add('subscription', subscription)
          ..add('irrigationSchedule', irrigationSchedule)
          ..add('notifications', notifications)
          ..add('dirty', dirty))
        .toString();
  }
}

class LocationBuilder implements Builder<Location, LocationBuilder> {
  _$Location _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  ListBuilder<Id> _users;
  ListBuilder<Id> get users => _$this._users ??= new ListBuilder<Id>();
  set users(ListBuilder<Id> users) => _$this._users = users;

  ListBuilder<Device> _devices;
  ListBuilder<Device> get devices =>
      _$this._devices ??= new ListBuilder<Device>();
  set devices(ListBuilder<Device> devices) => _$this._devices = devices;

  ListBuilder<UserRole> _userRoles;
  ListBuilder<UserRole> get userRoles =>
      _$this._userRoles ??= new ListBuilder<UserRole>();
  set userRoles(ListBuilder<UserRole> userRoles) =>
      _$this._userRoles = userRoles;

  IdBuilder _account;
  IdBuilder get account => _$this._account ??= new IdBuilder();
  set account(IdBuilder account) => _$this._account = account;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  String _address;
  String get address => _$this._address;
  set address(String address) => _$this._address = address;

  String _address2;
  String get address2 => _$this._address2;
  set address2(String address2) => _$this._address2 = address2;

  String _city;
  String get city => _$this._city;
  set city(String city) => _$this._city = city;

  String _state;
  String get state => _$this._state;
  set state(String state) => _$this._state = state;

  String _country;
  String get country => _$this._country;
  set country(String country) => _$this._country = country;

  String _postalCode;
  String get postalCode => _$this._postalCode;
  set postalCode(String postalCode) => _$this._postalCode = postalCode;

  String _timezone;
  String get timezone => _$this._timezone;
  set timezone(String timezone) => _$this._timezone = timezone;

  double _gallonsPerDayGoal;
  double get gallonsPerDayGoal => _$this._gallonsPerDayGoal;
  set gallonsPerDayGoal(double gallonsPerDayGoal) =>
      _$this._gallonsPerDayGoal = gallonsPerDayGoal;

  int _occupants;
  int get occupants => _$this._occupants;
  set occupants(int occupants) => _$this._occupants = occupants;

  int _stories;
  int get stories => _$this._stories;
  set stories(int stories) => _$this._stories = stories;

  bool _isProfileComplete;
  bool get isProfileComplete => _$this._isProfileComplete;
  set isProfileComplete(bool isProfileComplete) =>
      _$this._isProfileComplete = isProfileComplete;

  Answer _waterShutoffKnown;
  Answer get waterShutoffKnown => _$this._waterShutoffKnown;
  set waterShutoffKnown(Answer waterShutoffKnown) =>
      _$this._waterShutoffKnown = waterShutoffKnown;

  ListBuilder<String> _indoorAmenities;
  ListBuilder<String> get indoorAmenities =>
      _$this._indoorAmenities ??= new ListBuilder<String>();
  set indoorAmenities(ListBuilder<String> indoorAmenities) =>
      _$this._indoorAmenities = indoorAmenities;

  ListBuilder<String> _outdoorAmenities;
  ListBuilder<String> get outdoorAmenities =>
      _$this._outdoorAmenities ??= new ListBuilder<String>();
  set outdoorAmenities(ListBuilder<String> outdoorAmenities) =>
      _$this._outdoorAmenities = outdoorAmenities;

  ListBuilder<String> _plumbingAppliances;
  ListBuilder<String> get plumbingAppliances =>
      _$this._plumbingAppliances ??= new ListBuilder<String>();
  set plumbingAppliances(ListBuilder<String> plumbingAppliances) =>
      _$this._plumbingAppliances = plumbingAppliances;

  LocationType _locationType;
  LocationType get locationType => _$this._locationType;
  set locationType(LocationType locationType) =>
      _$this._locationType = locationType;

  String _residenceType;
  String get residenceType => _$this._residenceType;
  set residenceType(String residenceType) =>
      _$this._residenceType = residenceType;

  String _waterSource;
  String get waterSource => _$this._waterSource;
  set waterSource(String waterSource) => _$this._waterSource = waterSource;

  String _locationSize;
  String get locationSize => _$this._locationSize;
  set locationSize(String locationSize) => _$this._locationSize = locationSize;

  int _showerBathCount;
  int get showerBathCount => _$this._showerBathCount;
  set showerBathCount(int showerBathCount) =>
      _$this._showerBathCount = showerBathCount;

  int _toiletCount;
  int get toiletCount => _$this._toiletCount;
  set toiletCount(int toiletCount) => _$this._toiletCount = toiletCount;

  String _plumbingType;
  String get plumbingType => _$this._plumbingType;
  set plumbingType(String plumbingType) => _$this._plumbingType = plumbingType;

  String _homeownersInsurance;
  String get homeownersInsurance => _$this._homeownersInsurance;
  set homeownersInsurance(String homeownersInsurance) =>
      _$this._homeownersInsurance = homeownersInsurance;

  bool _hasPastWaterDamage;
  bool get hasPastWaterDamage => _$this._hasPastWaterDamage;
  set hasPastWaterDamage(bool hasPastWaterDamage) =>
      _$this._hasPastWaterDamage = hasPastWaterDamage;

  PastWaterDamageClaimAmount _pastWaterDamageClaimAmount;
  PastWaterDamageClaimAmount get pastWaterDamageClaimAmount =>
      _$this._pastWaterDamageClaimAmount;
  set pastWaterDamageClaimAmount(
          PastWaterDamageClaimAmount pastWaterDamageClaimAmount) =>
      _$this._pastWaterDamageClaimAmount = pastWaterDamageClaimAmount;

  PendingSystemModeBuilder _systemModes;
  PendingSystemModeBuilder get systemModes =>
      _$this._systemModes ??= new PendingSystemModeBuilder();
  set systemModes(PendingSystemModeBuilder systemModes) =>
      _$this._systemModes = systemModes;

  String _createdAt;
  String get createdAt => _$this._createdAt;
  set createdAt(String createdAt) => _$this._createdAt = createdAt;

  String _updatedAt;
  String get updatedAt => _$this._updatedAt;
  set updatedAt(String updatedAt) => _$this._updatedAt = updatedAt;

  String _waterUtility;
  String get waterUtility => _$this._waterUtility;
  set waterUtility(String waterUtility) => _$this._waterUtility = waterUtility;

  SubscriptionBuilder _subscription;
  SubscriptionBuilder get subscription =>
      _$this._subscription ??= new SubscriptionBuilder();
  set subscription(SubscriptionBuilder subscription) =>
      _$this._subscription = subscription;

  IrrigationScheduleBuilder _irrigationSchedule;
  IrrigationScheduleBuilder get irrigationSchedule =>
      _$this._irrigationSchedule ??= new IrrigationScheduleBuilder();
  set irrigationSchedule(IrrigationScheduleBuilder irrigationSchedule) =>
      _$this._irrigationSchedule = irrigationSchedule;

  AlertStatisticsBuilder _notifications;
  AlertStatisticsBuilder get notifications =>
      _$this._notifications ??= new AlertStatisticsBuilder();
  set notifications(AlertStatisticsBuilder notifications) =>
      _$this._notifications = notifications;

  bool _dirty;
  bool get dirty => _$this._dirty;
  set dirty(bool dirty) => _$this._dirty = dirty;

  LocationBuilder();

  LocationBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _users = _$v.users?.toBuilder();
      _devices = _$v.devices?.toBuilder();
      _userRoles = _$v.userRoles?.toBuilder();
      _account = _$v.account?.toBuilder();
      _nickname = _$v.nickname;
      _address = _$v.address;
      _address2 = _$v.address2;
      _city = _$v.city;
      _state = _$v.state;
      _country = _$v.country;
      _postalCode = _$v.postalCode;
      _timezone = _$v.timezone;
      _gallonsPerDayGoal = _$v.gallonsPerDayGoal;
      _occupants = _$v.occupants;
      _stories = _$v.stories;
      _isProfileComplete = _$v.isProfileComplete;
      _waterShutoffKnown = _$v.waterShutoffKnown;
      _indoorAmenities = _$v.indoorAmenities?.toBuilder();
      _outdoorAmenities = _$v.outdoorAmenities?.toBuilder();
      _plumbingAppliances = _$v.plumbingAppliances?.toBuilder();
      _locationType = _$v.locationType;
      _residenceType = _$v.residenceType;
      _waterSource = _$v.waterSource;
      _locationSize = _$v.locationSize;
      _showerBathCount = _$v.showerBathCount;
      _toiletCount = _$v.toiletCount;
      _plumbingType = _$v.plumbingType;
      _homeownersInsurance = _$v.homeownersInsurance;
      _hasPastWaterDamage = _$v.hasPastWaterDamage;
      _pastWaterDamageClaimAmount = _$v.pastWaterDamageClaimAmount;
      _systemModes = _$v.systemModes?.toBuilder();
      _createdAt = _$v.createdAt;
      _updatedAt = _$v.updatedAt;
      _waterUtility = _$v.waterUtility;
      _subscription = _$v.subscription?.toBuilder();
      _irrigationSchedule = _$v.irrigationSchedule?.toBuilder();
      _notifications = _$v.notifications?.toBuilder();
      _dirty = _$v.dirty;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Location other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Location;
  }

  @override
  void update(void Function(LocationBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Location build() {
    _$Location _$result;
    try {
      _$result = _$v ??
          new _$Location._(
              id: id,
              users: _users?.build(),
              devices: _devices?.build(),
              userRoles: _userRoles?.build(),
              account: _account?.build(),
              nickname: nickname,
              address: address,
              address2: address2,
              city: city,
              state: state,
              country: country,
              postalCode: postalCode,
              timezone: timezone,
              gallonsPerDayGoal: gallonsPerDayGoal,
              occupants: occupants,
              stories: stories,
              isProfileComplete: isProfileComplete,
              waterShutoffKnown: waterShutoffKnown,
              indoorAmenities: _indoorAmenities?.build(),
              outdoorAmenities: _outdoorAmenities?.build(),
              plumbingAppliances: _plumbingAppliances?.build(),
              locationType: locationType,
              residenceType: residenceType,
              waterSource: waterSource,
              locationSize: locationSize,
              showerBathCount: showerBathCount,
              toiletCount: toiletCount,
              plumbingType: plumbingType,
              homeownersInsurance: homeownersInsurance,
              hasPastWaterDamage: hasPastWaterDamage,
              pastWaterDamageClaimAmount: pastWaterDamageClaimAmount,
              systemModes: _systemModes?.build(),
              createdAt: createdAt,
              updatedAt: updatedAt,
              waterUtility: waterUtility,
              subscription: _subscription?.build(),
              irrigationSchedule: _irrigationSchedule?.build(),
              notifications: _notifications?.build(),
              dirty: dirty);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'users';
        _users?.build();
        _$failedField = 'devices';
        _devices?.build();
        _$failedField = 'userRoles';
        _userRoles?.build();
        _$failedField = 'account';
        _account?.build();

        _$failedField = 'indoorAmenities';
        _indoorAmenities?.build();
        _$failedField = 'outdoorAmenities';
        _outdoorAmenities?.build();
        _$failedField = 'plumbingAppliances';
        _plumbingAppliances?.build();

        _$failedField = 'systemModes';
        _systemModes?.build();

        _$failedField = 'subscription';
        _subscription?.build();
        _$failedField = 'irrigationSchedule';
        _irrigationSchedule?.build();
        _$failedField = 'notifications';
        _notifications?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Location', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
