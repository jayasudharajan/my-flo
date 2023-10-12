// GENERATED CODE - DO NOT MODIFY BY HAND

part of flo;

// **************************************************************************
// ChopperGenerator
// **************************************************************************

class _$Flo extends Flo {
  _$Flo([ChopperClient client]) {
    if (client == null) return;
    this.client = client;
  }

  final definitionType = Flo;

  Future<Response<OauthToken>> login(OauthPayload payload) {
    final $url = 'v1/oauth2/token';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<OauthToken, OauthToken>($request);
  }

  Future<Response<Token>> getFirestoreToken({String authorization}) {
    final $url = 'v2/session/firestore';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<Token, Token>($request);
  }

  Future<Response<HealthTest>> runHealthTest(String id,
      {String authorization}) {
    final $url = 'v2/devices/${id}/healthTest/run';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<HealthTest, HealthTest>($request);
  }

  Future<Response<HealthTest>> getHealthTest(String id,
      {String authorization}) {
    final $url = 'v2/devices/${id}/healthTest/latest';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<HealthTest, HealthTest>($request);
  }

  Future<Response<HealthTests>> getHealthTests(String id,
      {String authorization}) {
    final $url = 'v2/devices/${id}/healthTest';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<HealthTests, HealthTests>($request);
  }

  Future<Response<HealthTest>> getHealthTestByRoundId(String id, String roundId,
      {String authorization}) {
    final $url = 'v2/devices/${id}/healthTest/${roundId}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<HealthTest, HealthTest>($request);
  }

  Future<Response<Alarm>> getAlarm(String id, {String authorization}) {
    final $url = 'v2/alarms/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Alarm, Alarm>($request);
  }

  Future<Response<Alarms>> getAlarms(
      {String authorization,
      bool isInternal,
      bool isShutoff,
      bool active,
      bool enabled}) {
    final $url = 'v2/alarms';
    final Map<String, dynamic> $params = {
      'isInternal': isInternal,
      'isShutoff': isShutoff,
      'active': active,
      'enabled': enabled
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Alarms, Alarms>($request);
  }

  Future<Response> putAlertsSettings(String id, AlertsSettings alertsSettings,
      {String authorization}) {
    final $url = 'v2/users/${id}/alarmSettings';
    final $headers = {'Authorization': authorization};
    final $body = alertsSettings;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> putAlertAction(AlertAction action, {String authorization}) {
    final $url = 'v2/alerts/action';
    final $headers = {'Authorization': authorization};
    final $body = action;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> putAlertFeedback(String id, AlertFeedbacks feedbacks,
      {String authorization}) {
    final $url = 'v2/alerts/${id}/userFeedback';
    final $headers = {'Authorization': authorization};
    final $body = feedbacks;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<AlertStatistics>> getAlertStatistics(
      {String locationId, String deviceId, String authorization}) {
    final $url = 'v2/alerts/statistics';
    final Map<String, dynamic> $params = {
      'locationId': locationId,
      'deviceId': deviceId
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<AlertStatistics, AlertStatistics>($request);
  }

  Future<Response<Alerts>> getAlerts(
      {String authorization,
      String locationId,
      Set<String> deviceIds,
      String macAddress,
      String createdAt,
      String status,
      String severity,
      String reason,
      String language,
      int page = 1,
      int size = 100}) {
    final $url = 'v2/alerts';
    final Map<String, dynamic> $params = {
      'locationId': locationId,
      'deviceId': deviceIds,
      'macAddress': macAddress,
      'createdAt': createdAt,
      'status': status,
      'severity': severity,
      'reason': reason,
      'lang': language,
      'page': page,
      'size': size
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Alerts, Alerts>($request);
  }

  Future<Response<Alert>> getAlert(String id, {String authorization}) {
    final $url = 'v2/alerts/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Alert, Alert>($request);
  }

  Future<Response> presence(AppInfo appInfo, {String authorization}) {
    final $url = 'v2/presence/me';
    final $headers = {'Authorization': authorization};
    final $body = appInfo;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> registration(RegistrationPayload payload) {
    final $url = 'v1/userregistration';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> registration2(RegistrationPayload2 payload) {
    final $url = 'v2/users/register';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<EmailStatus>> emailStatus(EmailPayload payload) {
    final $url = 'v1/userregistration/email';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<EmailStatus, EmailStatus>($request);
  }

  Future<Response<EmailStatus2>> emailStatus2(String email) {
    final $url = 'v2/users/register';
    final Map<String, dynamic> $params = {'email': email};
    final $request = Request('GET', $url, client.baseUrl, parameters: $params);
    return client.send<EmailStatus2, EmailStatus2>($request);
  }

  Future<Response> resetPassword(EmailPayload payload) {
    final $url = 'v1/users/requestreset/user';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> resetPassword2(EmailPayload payload) {
    final $url = 'v2/users/password/request-reset';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> magicLink(MagicLinkPayload payload) {
    final $url = 'v1/passwordless/start';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> resendEmail(EmailPayload payload) {
    final $url = 'v1/userregistration/resend';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> resendEmail2(EmailPayload payload) {
    final $url = 'v2/users/register/resend';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<User>> getUser(String id,
      {String authorization, String expand = "alarmSettings"}) {
    final $url = 'v2/users/${id}';
    final Map<String, dynamic> $params = {'expand': expand};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<User, User>($request);
  }

  Future<Response> enabledFeatures(String id, Items items,
      {String authorization}) {
    final $url = 'v2/users/${id}/enabledFeatures';
    final $headers = {'Authorization': authorization};
    final $body = items;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> deleteFeatures(String id, Items items,
      {String authorization}) {
    final $url = 'v2/users/${id}/enabledFeatures';
    final $headers = {'Authorization': authorization};
    final $body = items;
    final $request =
        Request('DELETE', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<Location>> getLocation(String id, {String authorization}) {
    final $url = 'v2/locations/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Location, Location>($request);
  }

  Future<Response<Location>> addLocation(Location location,
      {String authorization}) {
    final $url = 'v2/locations';
    final $headers = {'Authorization': authorization};
    final $body = location;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Location, Location>($request);
  }

  Future<Response> removeLocation(String id, {String authorization}) {
    final $url = 'v2/locations/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('DELETE', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> putFirmwareProperties(String id, FirmwareProperties props,
      {String authorization}) {
    final $url = 'v2/devices/${id}/fwproperties';
    final $headers = {'Authorization': authorization};
    final $body = props;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<FloDetect>> getFloDetectByDevice0(String macAddress,
      {String duration = FloDetect.DURATION_24H, String authorization}) {
    final $url = 'v2/flodetect/computations';
    final Map<String, dynamic> $params = {
      'macAddress': macAddress,
      'duration': duration
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<FloDetect, FloDetect>($request);
  }

  Future<Response<FloDetectEvents>> getFloDetectEvents(String id,
      {String start, int size, String order, String authorization}) {
    final $url = 'v2/flodetect/computations/${id}/events';
    final Map<String, dynamic> $params = {
      'start': start,
      'size': size,
      'order': order
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<FloDetectEvents, FloDetectEvents>($request);
  }

  Future<Response> putFloDetectFeedback(
      String id, String start, FloDetectFeedbackPayload floDetectFeedback,
      {String authorization}) {
    final $url = 'v2/flodetect/computations/${id}/events/${start}';
    final $headers = {'Authorization': authorization};
    final $body = floDetectFeedback;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> onboarding(Onboarding props, {String authorization}) {
    final $url = 'v1/onboarding/event/device';
    final $headers = {'Authorization': authorization};
    final $body = props;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> installedDevice(Onboarding props, {String authorization}) {
    final $url = 'v1/onboarding/event/device/installed';
    final $headers = {'Authorization': authorization};
    final $body = props;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> forceSleep(String id, {String authorization}) {
    final $url = 'v1/devicesystemmode/icd/${id}/forcedsleep/enable';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> unforceSleep(String id, {String authorization}) {
    final $url = 'v1/devicesystemmode/icd/${id}/forcedsleep/disable';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<OauthToken>> verify(VerifyPayload payload) {
    final $url = 'v2/users/register/verify';
    final $body = payload;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<OauthToken, OauthToken>($request);
  }

  Future<Response> logout(LogoutPayload payload, {String authorization}) {
    final $url = 'v1/logout/';
    final $headers = {'Authorization': authorization};
    final $body = payload;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<Locales>> locales({String authorization}) {
    final $url = 'v1/locales';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Locales, Locales>($request);
  }

  Future<Response<Items>> countryItems(
      {String authorization, String id = "country"}) {
    final $url = 'v2/lists';
    final Map<String, dynamic> $params = {'id': id};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Items, Items>($request);
  }

  Future<Response<Items>> lists(Set<String> ids, {String authorization}) {
    final $url = 'v2/lists';
    final Map<String, dynamic> $params = {'id': ids};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Items, Items>($request);
  }

  Future<Response<Items>> listsById(String ids, {String authorization}) {
    final $url = 'v2/lists';
    final Map<String, dynamic> $params = {'id': ids};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Items, Items>($request);
  }

  Future<Response<ItemList>> list(String id, {String authorization}) {
    final $url = 'v2/lists/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<ItemList, ItemList>($request);
  }

  Future<Response<Items>> timezoneItems(String country,
      {String authorization}) {
    final $url = 'v2/lists?id=timezone_${country}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Items, Items>($request);
  }

  Future<Response<Items>> regionItems(String country, {String authorization}) {
    final $url = 'v2/lists?id=region_${country}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Items, Items>($request);
  }

  Future<Response<ItemList>> deviceMakeItemList({String authorization}) {
    final $url = 'v2/lists/device_make';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<ItemList, ItemList>($request);
  }

  Future<Response<Items>> deviceModelItems(String deviceMake,
      {String authorization}) {
    final $url = 'v2/lists?id=device_model_${deviceMake}';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<Items, Items>($request);
  }

  Future<Response<Locale>> locale(String country, {String authorization}) {
    final $url = 'v1/locales/${country}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<Locale, Locale>($request);
  }

  Future<Response<BuiltList<String>>> getStateProvinces(String country,
      {String authorization}) {
    final $url = 'v1/countrystateprovinces/${country}';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<BuiltList<String>, String>($request);
  }

  Future<Response<Certificate2>> getCertificate(Ticket payload,
      {String authorization}) {
    final $url = 'v2/devices/pair/init';
    final $headers = {'Authorization': authorization};
    final $body = payload;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Certificate2, Certificate2>($request);
  }

  Future<Response<Certificate2>> getCertificate2(Ticket2 payload,
      {String authorization}) {
    final $url = 'v2/devices/pair/init';
    final $headers = {'Authorization': authorization};
    final $body = payload;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Certificate2, Certificate2>($request);
  }

  Future<Response<Certificate2>> getCertificateByDeviceModel(Device device,
      {String authorization}) {
    final $url = 'v2/devices/pair/init';
    final $headers = {'Authorization': authorization};
    final $body = device;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Certificate2, Certificate2>($request);
  }

  Future<Response<Device>> linkDevice(LinkDevicePayload payload,
      {String authorization}) {
    final $url = 'v2/devices/pair/complete';
    final $headers = {'Authorization': authorization};
    final $body = payload;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<Device>> getDevice(String id,
      {String authorization, String expand = "irrigationSchedule"}) {
    final $url = 'v2/devices/${id}';
    final Map<String, dynamic> $params = {'expand': expand};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<Device>> getDeviceWithCertificate(String id,
      {String authorization, String expand = "pairingData"}) {
    final $url = 'v2/devices/${id}';
    final Map<String, dynamic> $params = {'expand': expand};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<ChangePassword>> changePasswords(
      String id, ChangePassword payload,
      {String authorization}) {
    final $url = 'v2/users/${id}/password';
    final $headers = {'Authorization': authorization};
    final $body = payload;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<ChangePassword, ChangePassword>($request);
  }

  Future<Response<WaterUsageAverages>> waterUsageAveragesDevice(
      {String authorization, String macAddress, String tz}) {
    final $url = 'v2/water/averages';
    final Map<String, dynamic> $params = {'macAddress': macAddress, 'tz': tz};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<WaterUsageAverages, WaterUsageAverages>($request);
  }

  Future<Response<WaterUsageAverages>> waterUsageAveragesLocation(
      {String authorization, String locationId, String tz}) {
    final $url = 'v2/water/averages';
    final Map<String, dynamic> $params = {'locationId': locationId, 'tz': tz};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<WaterUsageAverages, WaterUsageAverages>($request);
  }

  Future<Response<WaterUsage>> waterUsageLocation(
      {String authorization,
      String startDate,
      String endDate,
      String locationId,
      String interval,
      String tz}) {
    final $url = 'v2/water/consumption';
    final Map<String, dynamic> $params = {
      'startDate': startDate,
      'endDate': endDate,
      'locationId': locationId,
      'interval': interval,
      'tz': tz
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<WaterUsage, WaterUsage>($request);
  }

  Future<Response<WaterUsage>> waterUsageDevice(
      {String authorization,
      String startDate,
      String endDate,
      String macAddress,
      String interval}) {
    final $url = 'v2/water/consumption';
    final Map<String, dynamic> $params = {
      'startDate': startDate,
      'endDate': endDate,
      'macAddress': macAddress,
      'interval': interval
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<WaterUsage, WaterUsage>($request);
  }

  Future<Response<Device>> unlinkDevice(String icdId, {String authorization}) {
    final $url = 'v1/pairing/unpair/${icdId}';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<Device>> putDeviceById(String id, Device device,
      {String authorization}) {
    final $url = 'v2/devices/${id}';
    final $headers = {'Authorization': authorization};
    final $body = device;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<Location>> putLocationById(String id, Location location,
      {String authorization}) {
    final $url = 'v2/locations/${id}';
    final $headers = {'Authorization': authorization};
    final $body = location;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<Location, Location>($request);
  }

  Future<Response<User>> putUserById(String id, User user,
      {String authorization}) {
    final $url = 'v2/users/${id}';
    final $headers = {'Authorization': authorization};
    final $body = user;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<User, User>($request);
  }

  Future<Response> putSystemMode(String id, PendingSystemMode systemMode,
      {String authorization}) {
    final $url = 'v2/locations/${id}/systemMode';
    final $headers = {'Authorization': authorization};
    final $body = systemMode;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> putDeviceSystemMode(String id, PendingSystemMode systemMode,
      {String authorization}) {
    final $url = 'v2/devices/${id}/systemMode';
    final $headers = {'Authorization': authorization};
    final $body = systemMode;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response> resetDevice(String id, Target target,
      {String authorization}) {
    final $url = 'v2/devices/${id}/reset';
    final $headers = {'Authorization': authorization};
    final $body = target;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  Future<Response<Device>> unlinkDevice2(String id, {String authorization}) {
    final $url = 'v2/devices/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('DELETE', $url, client.baseUrl, headers: $headers);
    return client.send<Device, Device>($request);
  }

  Future<Response<PushNotificationToken>> putPushNotificationToken(
      PushNotificationToken token,
      {String authorization}) {
    final $url = 'v1/pushnotificationtokens/android';
    final $headers = {'Authorization': authorization};
    final $body = token;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<PushNotificationToken, PushNotificationToken>($request);
  }

  Future<Response<List<PushNotificationToken>>> getPushNotificationToken(
      String id,
      {String authorization}) {
    final $url = 'v1/pushnotificationtokens/user/${id}';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client
        .send<List<PushNotificationToken>, PushNotificationToken>($request);
  }

  Future<Response<OauthToken>> verifyOauth(OauthPayload oauth) {
    final $url = 'v1/userregistration/verify/oauth2';
    final $body = oauth;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<OauthToken, OauthToken>($request);
  }
}
