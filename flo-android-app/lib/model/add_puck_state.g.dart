// GENERATED CODE - DO NOT MODIFY BY HAND

part of add_puck_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddPuckState extends AddPuckState {
  @override
  final String model;
  @override
  final String modelDisplay;
  @override
  final String deviceMake;
  @override
  final String nickname;
  @override
  final BuiltList<Wifi> floDeviceWifiList;
  @override
  final Ticket ticket;
  @override
  final Ticket2 ticket2;
  @override
  final Certificate2 certificate;
  @override
  final bool error;
  @override
  final Wifi wifi;
  @override
  final String password;
  @override
  final bool pluggedPowerCord;
  @override
  final bool pluggedOutlet;
  @override
  final bool lightsOn;
  @override
  final String ssid;
  @override
  final int currentPage;
  @override
  final String deviceId;
  @override
  final Id location;

  factory _$AddPuckState([void Function(AddPuckStateBuilder) updates]) =>
      (new AddPuckStateBuilder()..update(updates)).build();

  _$AddPuckState._(
      {this.model,
      this.modelDisplay,
      this.deviceMake,
      this.nickname,
      this.floDeviceWifiList,
      this.ticket,
      this.ticket2,
      this.certificate,
      this.error,
      this.wifi,
      this.password,
      this.pluggedPowerCord,
      this.pluggedOutlet,
      this.lightsOn,
      this.ssid,
      this.currentPage,
      this.deviceId,
      this.location})
      : super._();

  @override
  AddPuckState rebuild(void Function(AddPuckStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddPuckStateBuilder toBuilder() => new AddPuckStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddPuckState &&
        model == other.model &&
        modelDisplay == other.modelDisplay &&
        deviceMake == other.deviceMake &&
        nickname == other.nickname &&
        floDeviceWifiList == other.floDeviceWifiList &&
        ticket == other.ticket &&
        ticket2 == other.ticket2 &&
        certificate == other.certificate &&
        error == other.error &&
        wifi == other.wifi &&
        password == other.password &&
        pluggedPowerCord == other.pluggedPowerCord &&
        pluggedOutlet == other.pluggedOutlet &&
        lightsOn == other.lightsOn &&
        ssid == other.ssid &&
        currentPage == other.currentPage &&
        deviceId == other.deviceId &&
        location == other.location;
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
                                                                            model
                                                                                .hashCode),
                                                                        modelDisplay
                                                                            .hashCode),
                                                                    deviceMake
                                                                        .hashCode),
                                                                nickname
                                                                    .hashCode),
                                                            floDeviceWifiList
                                                                .hashCode),
                                                        ticket.hashCode),
                                                    ticket2.hashCode),
                                                certificate.hashCode),
                                            error.hashCode),
                                        wifi.hashCode),
                                    password.hashCode),
                                pluggedPowerCord.hashCode),
                            pluggedOutlet.hashCode),
                        lightsOn.hashCode),
                    ssid.hashCode),
                currentPage.hashCode),
            deviceId.hashCode),
        location.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AddPuckState')
          ..add('model', model)
          ..add('modelDisplay', modelDisplay)
          ..add('deviceMake', deviceMake)
          ..add('nickname', nickname)
          ..add('floDeviceWifiList', floDeviceWifiList)
          ..add('ticket', ticket)
          ..add('ticket2', ticket2)
          ..add('certificate', certificate)
          ..add('error', error)
          ..add('wifi', wifi)
          ..add('password', password)
          ..add('pluggedPowerCord', pluggedPowerCord)
          ..add('pluggedOutlet', pluggedOutlet)
          ..add('lightsOn', lightsOn)
          ..add('ssid', ssid)
          ..add('currentPage', currentPage)
          ..add('deviceId', deviceId)
          ..add('location', location))
        .toString();
  }
}

class AddPuckStateBuilder
    implements Builder<AddPuckState, AddPuckStateBuilder> {
  _$AddPuckState _$v;

  String _model;
  String get model => _$this._model;
  set model(String model) => _$this._model = model;

  String _modelDisplay;
  String get modelDisplay => _$this._modelDisplay;
  set modelDisplay(String modelDisplay) => _$this._modelDisplay = modelDisplay;

  String _deviceMake;
  String get deviceMake => _$this._deviceMake;
  set deviceMake(String deviceMake) => _$this._deviceMake = deviceMake;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  ListBuilder<Wifi> _floDeviceWifiList;
  ListBuilder<Wifi> get floDeviceWifiList =>
      _$this._floDeviceWifiList ??= new ListBuilder<Wifi>();
  set floDeviceWifiList(ListBuilder<Wifi> floDeviceWifiList) =>
      _$this._floDeviceWifiList = floDeviceWifiList;

  TicketBuilder _ticket;
  TicketBuilder get ticket => _$this._ticket ??= new TicketBuilder();
  set ticket(TicketBuilder ticket) => _$this._ticket = ticket;

  Ticket2Builder _ticket2;
  Ticket2Builder get ticket2 => _$this._ticket2 ??= new Ticket2Builder();
  set ticket2(Ticket2Builder ticket2) => _$this._ticket2 = ticket2;

  Certificate2Builder _certificate;
  Certificate2Builder get certificate =>
      _$this._certificate ??= new Certificate2Builder();
  set certificate(Certificate2Builder certificate) =>
      _$this._certificate = certificate;

  bool _error;
  bool get error => _$this._error;
  set error(bool error) => _$this._error = error;

  WifiBuilder _wifi;
  WifiBuilder get wifi => _$this._wifi ??= new WifiBuilder();
  set wifi(WifiBuilder wifi) => _$this._wifi = wifi;

  String _password;
  String get password => _$this._password;
  set password(String password) => _$this._password = password;

  bool _pluggedPowerCord;
  bool get pluggedPowerCord => _$this._pluggedPowerCord;
  set pluggedPowerCord(bool pluggedPowerCord) =>
      _$this._pluggedPowerCord = pluggedPowerCord;

  bool _pluggedOutlet;
  bool get pluggedOutlet => _$this._pluggedOutlet;
  set pluggedOutlet(bool pluggedOutlet) =>
      _$this._pluggedOutlet = pluggedOutlet;

  bool _lightsOn;
  bool get lightsOn => _$this._lightsOn;
  set lightsOn(bool lightsOn) => _$this._lightsOn = lightsOn;

  String _ssid;
  String get ssid => _$this._ssid;
  set ssid(String ssid) => _$this._ssid = ssid;

  int _currentPage;
  int get currentPage => _$this._currentPage;
  set currentPage(int currentPage) => _$this._currentPage = currentPage;

  String _deviceId;
  String get deviceId => _$this._deviceId;
  set deviceId(String deviceId) => _$this._deviceId = deviceId;

  IdBuilder _location;
  IdBuilder get location => _$this._location ??= new IdBuilder();
  set location(IdBuilder location) => _$this._location = location;

  AddPuckStateBuilder();

  AddPuckStateBuilder get _$this {
    if (_$v != null) {
      _model = _$v.model;
      _modelDisplay = _$v.modelDisplay;
      _deviceMake = _$v.deviceMake;
      _nickname = _$v.nickname;
      _floDeviceWifiList = _$v.floDeviceWifiList?.toBuilder();
      _ticket = _$v.ticket?.toBuilder();
      _ticket2 = _$v.ticket2?.toBuilder();
      _certificate = _$v.certificate?.toBuilder();
      _error = _$v.error;
      _wifi = _$v.wifi?.toBuilder();
      _password = _$v.password;
      _pluggedPowerCord = _$v.pluggedPowerCord;
      _pluggedOutlet = _$v.pluggedOutlet;
      _lightsOn = _$v.lightsOn;
      _ssid = _$v.ssid;
      _currentPage = _$v.currentPage;
      _deviceId = _$v.deviceId;
      _location = _$v.location?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AddPuckState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AddPuckState;
  }

  @override
  void update(void Function(AddPuckStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AddPuckState build() {
    _$AddPuckState _$result;
    try {
      _$result = _$v ??
          new _$AddPuckState._(
              model: model,
              modelDisplay: modelDisplay,
              deviceMake: deviceMake,
              nickname: nickname,
              floDeviceWifiList: _floDeviceWifiList?.build(),
              ticket: _ticket?.build(),
              ticket2: _ticket2?.build(),
              certificate: _certificate?.build(),
              error: error,
              wifi: _wifi?.build(),
              password: password,
              pluggedPowerCord: pluggedPowerCord,
              pluggedOutlet: pluggedOutlet,
              lightsOn: lightsOn,
              ssid: ssid,
              currentPage: currentPage,
              deviceId: deviceId,
              location: _location?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'floDeviceWifiList';
        _floDeviceWifiList?.build();
        _$failedField = 'ticket';
        _ticket?.build();
        _$failedField = 'ticket2';
        _ticket2?.build();
        _$failedField = 'certificate';
        _certificate?.build();

        _$failedField = 'wifi';
        _wifi?.build();

        _$failedField = 'location';
        _location?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AddPuckState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
