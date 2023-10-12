library flo;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';

import 'package:chopper/chopper.dart';
import 'package:faker/faker.dart';
import 'package:fimber/fimber.dart';
import 'package:flotechnologies/model/connectivity.dart';
import 'package:flotechnologies/model/device_alerts_settings.dart';
import 'package:flotechnologies/model/magic_link_payload.dart';
import 'package:flotechnologies/model/notifications.dart';
import 'package:flotechnologies/model/pending_system_mode.dart';
import 'package:flotechnologies/model/registration_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embrace/flutter_embrace.dart';
import 'package:instabug_flutter/NetworkLogger.dart';
import 'package:instabug_flutter/models/network_data.dart';
import 'package:instabug_flutter/utils/http_client_logger.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:rxdart/rxdart.dart';
import 'package:superpower/superpower.dart';
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../utils.dart';
import 'account_role.dart';
import 'alarm.dart';
import 'alert.dart';
import 'alert_action.dart';
import 'alert_feedback.dart';
import 'alert_feedback_option.dart';
import 'alert_feedbacks.dart';
import 'alert_statistics.dart';
import 'alerts.dart';
import 'alarms.dart';
import 'alerts_settings.dart';
import 'amenity.dart';
import 'app_info.dart';
import 'certificate.dart';
import 'certificate2.dart';
import 'change_password.dart';
import 'device.dart';
import 'device_item.dart';
import 'duration_value.dart';
import 'email_payload.dart';
import 'email_status.dart';
import 'email_status2.dart';
import 'firmware_properties.dart';
import 'fixture.dart';
import 'flo_detect.dart';
import 'flo_detect_event.dart';
import 'flo_detect_events.dart';
import 'flo_detect_feedback.dart';
import 'flo_detect_feedback_payload.dart';
import 'health_test.dart';
import 'health_tests.dart';
import 'install_status.dart';
import 'irrigation_schedule.dart';
import 'item.dart';
import 'item_list.dart';
import 'items.dart';
import 'link_device_payload.dart';
import 'locale.dart';
import 'locales.dart';
import 'location_size.dart';
import 'login_state.dart';
import 'logout_payload.dart';
import 'name.dart';
import 'oauth_token.dart';
import 'oauth_payload.dart';
import 'magic_link_payload.dart';
import 'onboarding.dart';
import 'plumbing_type.dart';
import 'preference_category.dart';
import 'push_notification_token.dart';
import 'registration_payload2.dart';
import 'response_error.dart';
import 'serializers.dart';
import 'subscription.dart';
import 'system_mode.dart';
import 'target.dart';
import 'ticket.dart';
import 'ticket2.dart';
import 'timezone.dart';
import 'token.dart';
import 'unit_system.dart';
import 'user.dart';
import 'id.dart';
import 'location.dart';
import 'schedule.dart';
import 'package:http/http.dart' as http;

import 'valve.dart';
import 'verify_payload.dart';
import 'package:device_info/device_info.dart';

import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

import 'water_source.dart';
import 'water_usage.dart';
//import 'package:ssl_pinning_plugin/ssl_pinning_plugin.dart';

import 'water_usage_aggregations.dart';
import 'water_usage_averages.dart';
import 'water_usage_averages_aggregations.dart';
import 'water_usage_item.dart';
import 'water_usage_params.dart';
import 'weekday_averages.dart';

part 'flo.chopper.dart';

final jsonSerializers = serializers;

class Headers {
  static const String AUTHORIZATION = 'Authorization';
}

class BuiltValueConverter extends JsonConverter {
  T _deserialize<T>(dynamic value) => jsonSerializers.deserializeWith<T>(
        jsonSerializers.serializerForType(T),
        value,
      );

  BuiltList<T> _deserializeListOf<T>(Iterable value) => BuiltList<T>(
        value.map((value) => _deserialize<T>(value)).toList(growable: false),
      );

  dynamic _decode<T>(entity) {
    /// handle case when we want to access to Map<String, dynamic> directly
    /// getResource or getMapResource
    /// Avoid dynamic or unconverted value, this could lead to several issues
    if (entity is T) return entity;

    try {
      if (entity is List) return _deserializeListOf<T>(entity);
      return _deserialize<T>(entity);
    } catch (e) {
      Fimber.e("", ex: e);
      return null;
    }
  }

  @override
  Response<ResultType> convertResponse<ResultType, Item>(Response response) {
    // use [JsonConverter] to decode json
    final jsonRes = super.convertResponse(response);
    final body = _decode<Item>(jsonRes.body);
    try {
      return jsonRes.replace<ResultType>(body: body);
    } catch (e) {
      Fimber.e("", ex: e);
      return Response<ResultType>(jsonRes.base, body);
    }
  }

  @override
  Request convertRequest(Request request) => super.convertRequest(
        request.replace(
          body: serializers.serialize(request.body),
        ),
      );
}

@ChopperApi()
abstract class Flo extends ChopperService {
  static Flo create(ChopperClient client, {String clientId, String clientSecret}) {
    final flo = _$Flo(client);
    flo.clientId = clientId;
    flo.clientSecret = clientSecret;
    return flo;
  }
  
  OauthToken oauth;
  bool refreshed = false;

  /*
  @Get(path: "v1/{id}/"
  Future<Response> getOauthToken(@Path() String id);

  @Get(path: "v1/list")
  Future<Response<BuiltList<OauthToken>>> getBuiltListOauthTokens();

  @Get(path: "")
  Future<Response<OauthToken>> getTypedOauthToken();

  @Post()
  Future<Response<OauthToken>> newOauthToken(
      @Body() OauthToken resource,
      {@Header() String name});
  */

  @deprecated
  @Post(path: "v1/oauth2/token")
  Future<Response<OauthToken>> login(@Body() OauthPayload payload);

  @Post(path: "v2/session/firestore")
  Future<Response<Token>> getFirestoreToken({@required @Header(Headers.AUTHORIZATION) String authorization,
  });

  @Post(path: "v2/devices/{id}/healthTest/run")
  Future<Response<HealthTest>> runHealthTest(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/devices/{id}/healthTest/latest")
  Future<Response<HealthTest>> getHealthTest(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/devices/{id}/healthTest")
  Future<Response<HealthTests>> getHealthTests(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/devices/{id}/healthTest/{roundId}")
  Future<Response<HealthTest>> getHealthTestByRoundId(@Path("id") String id, @Path("roundId") String roundId, {@required @Header(Headers.AUTHORIZATION) String authorization});

  Future<HealthTest> getHealthTestOrRun(@Path("id") String deviceId, HealthTest healthTest, {@required String authorization}) async {
    if (healthTest.isRunning && healthTest.isValid) {
      return healthTest;
    }

    if (healthTest.isRunning && !healthTest.isValid && (healthTest.roundId != null) ?? false) {
      try {
        final runningHealthTest = (await getHealthTestByRoundId(deviceId, healthTest.roundId, authorization: authorization)).body;
        return runningHealthTest;
      } catch (err) {
        Fimber.e("", ex: err);
      }
    }

    try {
      final runningHealthTest = (await runHealthTest(deviceId, authorization: authorization)).body;
      return runningHealthTest;
    } catch (err) {
      Fimber.e("", ex: err);
      final runningHealthTest = (await getHealthTest(deviceId, authorization: authorization)).body;
      return runningHealthTest;
    }

    return null;
  }

  @Get(path: "v2/alarms/{id}")
  Future<Response<Alarm>> getAlarm(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/alarms")
  Future<Response<Alarms>> getAlarms({@required @Header(Headers.AUTHORIZATION) String authorization,
    @Query('isInternal')
    bool isInternal,
    /// TODO: maybe not supported
    @deprecated
    @Query('isShutoff')
    bool isShutoff,
    /// TODO: maybe not supported
    @deprecated
    @Query('active')
    bool active,
    /// Indicates if alarms are enabled in the whole system or not
    @Query('enabled')
    bool enabled,
  });

  @Post(path: "v2/users/{id}/alarmSettings")
  Future<Response<dynamic>> putAlertsSettings(@Path("id") String id, @Body() AlertsSettings alertsSettings,
      {@required @Header(Headers.AUTHORIZATION) String authorization, });

  Future<Response<dynamic>> putSmallDripSensitivity(int sensitivity, {
        @required
        String authorization,
        @required
        String userId,
        @required
        String deviceId,
      }) async {
        return await putAlertsSettings(userId,
        AlertsSettings((b) => b
        ..items = ListBuilder([
          DeviceAlertsSettings((b) => b
          ..deviceId = deviceId
          ..smallDripSensitivity = sensitivity
          )
        ])
        ),
          authorization: authorization);
      }

      /*
  /// TODO: implement
  @deprecated
  @Put(path: "v2/alarms/{id}/clear")
  Future<Response<dynamic>> clearAlarm(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization,
  });

  /// TODO: implement
  @deprecated
  @Put(path: "v2/alarms/clear")
  Future<Response<dynamic>> clearAlarms(@Body() String id, {@required @Header(Headers.AUTHORIZATION) String authorization,
  });
      */

  ///Mute 'Small Drip' alert for device XYZ for 2 hours.
  ///POST /api/v2/alerts/action BODY: { "deviceId" : "XYZ", "alarmIds" : [28,29,30,31], "snoozeSeconds" : 7200 }
  ///Clear 'Fast Water Flow' alert for device XYZ. Do not snooze, the next time it occurs it will again generate alert.
  ///POST /api/v2/alerts/action BODY: { "deviceId" : "XYZ", "alarmIds" : [10], "snoozeSeconds" : 0 }
  @Post(path: "v2/alerts/action")
  Future<Response<dynamic>> putAlertAction(@Body() AlertAction action, {
    @required @Header(Headers.AUTHORIZATION) String authorization,
  });

  Future<Response<dynamic>> snooze({
    @required
    String deviceId,
    @required
    Duration duration,
    @required
    Set<int> alarmIds,
    @required @Header(Headers.AUTHORIZATION) String authorization,
  }) async {
    return await putAlertAction(AlertAction((b) => b
      ..deviceId = deviceId
      ..snoozeSeconds = duration.inSeconds
      ..alarmIds = ListBuilder(alarmIds)
    ), authorization: authorization);
  }

  /*
  @Post(path: "v2/alerts/{id}/userFeedback")
  Future<Response<dynamic>> putAlertFeedback(
      /// Alert ID
      @Path("id") String id, @Body() AlertFeedback feedback, {
        @required @Header(Headers.AUTHORIZATION) String authorization,
      });
  */
  @Post(path: "v2/alerts/{id}/userFeedback")
  Future<Response<dynamic>> putAlertFeedback(
      /// Alert ID
      @Path("id") String id, @Body() AlertFeedbacks feedbacks, {
        @required @Header(Headers.AUTHORIZATION) String authorization,
      });

  @Post(path: "v2/alerts/{id}/userFeedback")
  Future<Response<dynamic>> putAlertFeedbacks(
      String id, Iterable<AlertFeedbackOption> options, {
        @required String authorization,
      }) async {
    return await putAlertFeedback(id,
        AlertFeedbacks((b) => b
          ..feedbacks = ListBuilder(options.map((it) => it.toFeedback()))
        ),
        authorization: authorization);
  }


  @Get(path: "v2/alerts/statistics")
  Future<Response<AlertStatistics>> getAlertStatistics({
    /// Multiple locationId query params are allowed
    @Query('locationId')
    String locationId,
    /// Multiple deviceId query params are allowed
    @Query('deviceId')
    String deviceId,
    @required @Header(Headers.AUTHORIZATION) String authorization,
  });


  @Get(path: "v2/alerts")
  Future<Response<Alerts>> getAlerts({
    @required @Header(Headers.AUTHORIZATION) String authorization,
    @Query('locationId')
    String locationId,
    @Query('deviceId')
    Set<String> deviceIds,
    @deprecated
    @Query('macAddress')
    String macAddress,
    /// Date on which events were created. Multiple filters are allowed. The date should be in UTC. Allowed operators: eq, lt, let, gt, get.
    @Query('createdAt')
    String createdAt,
    /// Alarm event status. Multiple filters are allowed. Allowed operators: eq, lt, let, gt, get.
    /// "status": "resolved|triggered"
    /// triggered - Alerts pending user feedback
    /// resolved - Resolved, reason will contain detail why
    /// Available values : triggered, resolved
    @Query('status')
    String status,
    /// info - Informational message. e.g. Health Test Completed
    /// warning - Should look into. e.g. High Water Temperature
    /// critical - Water shutoff events. e.g. Fast Water Flow
    /// Available values : info, critical, warning
    @Query('severity')
    String severity,
    /// Multiple filters are allowed.
    /// cleared - Cleared by user
    /// snoozed - User muted alert for some time
    /// cancelled - System clered the alert before user
    /// Available values : cleared, snoozed, cancelled
    @Query('reason')
    String reason,
    /// Language
    @Query('lang')
    String language,
    /// Page number
    @Query('page')
    int page = 1,
    /// Page size
    @Query('size')
    int size = 100,
  });

  Future<Response<Alerts>> getAlertsByLocation(
      String locationId, {
        @required String authorization,
        DateTime createdAt,
        //String createdAtOperator ,
        String status,
        String severity,
        String language,
        int page,
        int size = 100,
      }) async {
    // "eq, lt, let, gt, get"
    return getAlerts(authorization: authorization,
        //createdAt: createdAt ?? "gt:${DateTime.now().toIso8601String()}",
        //createdAt: createdAt ?? "gt:${DateTime.now().subtract(Duration(days: 30)).toIso8601String()}",
        status: status,
        severity: severity,
        language: language,
        page: page,
        size: size,
        locationId: locationId);
  }

  Future<Response<Alerts>> getAlertsByDeviceId(
      String deviceId, {
        @required String authorization,
        String createdAt,
        String status,
        String severity,
        String language,
        int page,
        int size = 100,
      }) async {
    return getAlerts(authorization: authorization,
      // createdAt: createdAt ?? DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      //createdAt: createdAt ?? "gt:${DateTime.now().subtract(Duration(days: 30)).toIso8601String()}",
      status: status,
      severity: severity,
      language: language,
      page: page,
      size: size,
      deviceIds: {deviceId},
    );
  }

  Future<Response<Alerts>> getAlertsByDevice(
      String macAddress, {
        @required String authorization,
        String createdAt,
        String status,
        String severity,
        String language,
        int page,
        int size = 100,
      }) async {
  return getAlerts(authorization: authorization,
      // createdAt: createdAt ?? DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      //createdAt: createdAt ?? "gt:${DateTime.now().subtract(Duration(days: 30)).toIso8601String()}",
      status: status,
      severity: severity,
      language: language,
      page: page,
      size: size,
      macAddress: macAddress,
  );
  }

  @Get(path: "v2/alerts/{id}")
  Future<Response<Alert>> getAlert(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Post(path: "v2/presence/me")
  Future<Response<dynamic>> presence(@Body() AppInfo appInfo, {@required @Header(Headers.AUTHORIZATION) String authorization});

  Future<BuiltList<Item>> prvItems({String authorization}) async {
    //final List<Widget> items = (or(() => snapshot?.data?.items?.first['prv'].toList()) ?? <Item>[])
    final res = await list(Location.PRV, authorization: authorization);
    return res.body.items ?? BuiltList<Item>();
  }

  @deprecated
  @Post(path: "v1/userregistration")
  Future<Response> registration(@Body() RegistrationPayload payload); // TODO: return typed

  @Post(path: "v2/users/register")
  Future<Response> registration2(@Body() RegistrationPayload2 payload); // TODO: return typed

  @deprecated
  @Post(path: "v1/userregistration/email")
  Future<Response<EmailStatus>> emailStatus(@Body() EmailPayload payload);

  @Get(path: "v2/users/register")
  Future<Response<EmailStatus2>> emailStatus2(@Query('email') String email);

  @deprecated
  @Post(path: "v1/users/requestreset/user")
  Future<Response> resetPassword(@Body() EmailPayload payload); // TODO: return typed

  @Post(path: "v2/users/password/request-reset")
  Future<Response> resetPassword2(@Body() EmailPayload payload); // TODO: return typed

  // NOTICE: There is no v2 yet
  @deprecated
  @Post(path: "v1/passwordless/start")
  Future<Response> magicLink(@Body() MagicLinkPayload payload); // TODO: return typed

  // ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration#In-AppUserRegistration-POST/api/v1/userregistration/resend
  @deprecated
  @Post(path: "v1/userregistration/resend")
  Future<Response> resendEmail(@Body() EmailPayload payload); // TODO: return typed

  // ref. https://api-gw-dev.flocloud.co/docs/#/User%20Registration/post_api_v2_users_register_resend
  @Post(path: "v2/users/register/resend")
  Future<Response> resendEmail2(@Body() EmailPayload payload); // TODO: return typed

  @Get(path: "v2/users/{id}")
  Future<Response<User>> getUser(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization,
    /// Comma-separated names of the attributes to be expanded
    @Query('expand')
    String expand = "alarmSettings",
  });

  @Post(path: "v2/users/{id}/enabledFeatures")
  Future<Response<dynamic>> enabledFeatures(@Path("id") String id, @Body() Items items, {
    @required @Header(Headers.AUTHORIZATION) String authorization,
  });

  Future<Response<dynamic>> enableFeatures(@Path("id") String id, Set<String> features,
      {
        String authorization,
      }) async {
    return await enabledFeatures(id,
        Items((b) => b
          ..items = ListBuilder(features)),
        authorization: authorization);
  }

  @Delete(path: "v2/users/{id}/enabledFeatures")
  Future<Response<dynamic>> deleteFeatures(@Path("id") String id, @Body() Items items, {
    @required @Header(Headers.AUTHORIZATION) String authorization,
  });

  Future<Response<dynamic>> disableFeatures(@Path("id") String id, Set<String> features,
      {
        String authorization,
      }) async {
    return await deleteFeatures(id,
        Items((b) => b
          ..items = ListBuilder(features)),
        authorization: authorization);
  }

  @Get(path: "v2/locations/{id}")
  Future<Response<Location>> getLocation(@Path("id") String id,
      {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Post(path: "v2/locations")
  Future<Response<Location>> addLocation(@Body() Location location, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Delete(path: "v2/locations/{id}")
  Future<Response<dynamic>> removeLocation(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Post(path: "v2/devices/{id}/fwproperties")
  Future<Response<dynamic>> putFirmwareProperties(@Path("id") String id, @Body() FirmwareProperties props, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/flodetect/computations")
  Future<Response<FloDetect>> getFloDetectByDevice0(
      /// MAC address of device to retrieve fixture detection computations for.
      @Query("macAddress")
      String macAddress,
      {
        /// Duration of the date range the computation covers
        /// Available values : 24h, 7d FloDetect.DURATION_24H, FloDetect.DURATION_7D
        @Query("duration")
        String duration = FloDetect.DURATION_24H,
        @required
        @Header(Headers.AUTHORIZATION)
        String authorization,
      });

  Future<Response<FloDetect>> getFloDetectByDevice(
      /// MAC address of device to retrieve fixture detection computations for.
      @Query("macAddress")
      String macAddress,
      {
        /// Duration of the date range the computation covers
        /// Available values : 24h, 7d FloDetect.DURATION_24H, FloDetect.DURATION_7D
        @Query("duration")
        String duration = FloDetect.DURATION_24H,
        @required
        @Header(Headers.AUTHORIZATION)
        String authorization,
      }) async {
    final res = await getFloDetectByDevice0(macAddress, duration: duration, authorization: authorization);
    if (res.body.isStale ?? false) {
      return Response(res.base, res.body.rebuild((b) => b
        ..fixtures = ListBuilder()
      ));
    } else {
      return res;
    }
  }

  @Get(path: "v2/flodetect/computations/{id}/events")
  Future<Response<FloDetectEvents>> getFloDetectEvents(
      /// Computation ID
      @Path("id") String id,
      {
        /// URI encoded date that represents the offset for pagination. This should be the start property of the last event in the previous page.
        @Query("start")
        String start,
        /// Page size, default 50
        @Query("size")
        int size,
        /// Ascending or descending sort order of events based on start date. Ascending by default.
        /// Available values : asc, desc FloDetectEvent.ASC, FloDetectEvent.DESC
        @Query("order")
        String order,
        @required
        @Header(Headers.AUTHORIZATION)
        String authorization,
      });

  @Post(path: "v2/flodetect/computations/{id}/events/{start}")
  Future<Response<dynamic>> putFloDetectFeedback(
      @Path("id") String id,
      @Path("start") String start,
      @Body() FloDetectFeedbackPayload floDetectFeedback,
      {@required @Header(Headers.AUTHORIZATION) String authorization});

  Future<Response<dynamic>> putFloDetectFeedback2(
      String id,
      String start,
      FloDetectFeedback floDetectFeedback,
      {@required String authorization}) async {
    return await putFloDetectFeedback(id, start, FloDetectFeedbackPayload((b) => b..feedback = floDetectFeedback.toBuilder()), authorization: authorization);
  }


  /// req: {"id":"0efb5f70-b427-11e9-b32e-41c3e15cbdc9","device_id":"a810872bd801","event":{"name":"installed"}}
  /// res: [{"created_at":"2019-08-01T06:39:06.097Z","icd_id":"5d89ede1-1244-47b9-baa7-44ffb52d2825","event":2},null,[null,null]]
  /// ref. admin site
  @deprecated
  @Post(path: "v1/onboarding/event/device")
  Future<Response<dynamic>> onboarding(@Body() Onboarding props, {@required @Header(Headers.AUTHORIZATION) String authorization});

  Future<Response<dynamic>> installDeviceEvent(String id, String deviceId, {@required String authorization}) async {
    return await onboarding(Onboarding((b) => b
    ..id = id
    ..deviceId = deviceId
    ..event = Name((b) => b..name = "installed").toBuilder()
    ), authorization: authorization);
  }

  /// curl -X POST \
  ///             -H "Content-Type:application/json" \
  ///             -H "Authorization:$(_get_token)" \
  ///             -d'{ "device_id": "'$mac'" }' https://$(_get_url)/api/v1/onboarding/event/device/installed 2>/dev/null
  /// Doesn't work
  @deprecated
  @Post(path: "v1/onboarding/event/device/installed")
  Future<Response<dynamic>> installedDevice(@Body() Onboarding props, {@required @Header(Headers.AUTHORIZATION) String authorization});

  Future<Response<dynamic>> installDevice(String deviceId, {@required @Header(Headers.AUTHORIZATION) String authorization}) async {
    return await installedDevice(Onboarding((b) => b
      ..deviceId = deviceId
    ), authorization: authorization);
  }

  @deprecated
  @Post(path: "v1/devicesystemmode/icd/{id}/forcedsleep/enable")
  Future<Response<dynamic>> forceSleep(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @deprecated
  @Post(path: "v1/devicesystemmode/icd/{id}/forcedsleep/disable")
  Future<Response<dynamic>> unforceSleep(@Path("id") String id, {@required @Header(Headers.AUTHORIZATION) String authorization});

  @Post(path: "v2/users/register/verify")
  Future<Response<OauthToken>> verify(@Body() VerifyPayload payload);

  @deprecated
  @Post(path: "v1/logout/")
  Future<Response> logout(@Body() LogoutPayload payload, {@required @Header(Headers.AUTHORIZATION) String authorization});

  // NOTICE: There is no v2 yet
  @deprecated
  @Get(path: "v1/locales")
  Future<Response<Locales>> locales({@Header(Headers.AUTHORIZATION) String authorization});

  /// country: all countries supported
  /// region_us: US states
  /// region_ca: CA states
  /// timezone_us: timezones in the US
  /// timezone_ca: timezones in CA
  /// {
  ///   "items": [
  ///     {
  ///       "key": "string",
  ///       "shortDisplay": "string",
  ///       "longDisplay": "string"
  ///     }
  ///   ]
  /// }
  @Get(path: "v2/lists")
  Future<Response<Items>> countryItems({@Header(Headers.AUTHORIZATION) String authorization,
    @Query('id')
    String id = "country",
  });

  Future<Iterable<Locale>> countries({String authorization}) async {
    final res = await countryItems(authorization: authorization);
    return or(() => res.body.items.first["country"])?.map((it) => Locale((b) => b
        ..locale = it.key
        ..name = it.longDisplay ?? it.shortDisplay
        )) ?? [];
  }

  @Get(path: "v2/lists")
  Future<Response<Items>> lists(@Query("id") Set<String> ids, {@Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/lists")
  Future<Response<Items>> listsById(@Query("id") String ids, {@Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/lists/{id}")
  Future<Response<ItemList>> list(@Path("id") String id, {@Header(Headers.AUTHORIZATION) String authorization});

  /*
  Future<Response<Items>> locationProfiles({String authorization}) async => await lists2(Location.PROFILES.join(","), authorization: authorization);

  Future<Response<Items>> allLocationProfiles({String authorization}) async => await lists2(Location.ALL_PROFILES.join(","), authorization: authorization);

  Future<BuiltList<Item>> locationTypes({String authorization}) async {
    return null;
  }
  */

  Future<PreferenceCategory> preferenceCategory({String authorization}) async {
    final res = await futureOr<Response<Items>>(() => listsById({
      Location.PRV,
      Location.PIPE_TYPE,
      ...Location.FIXTURES,
      Location.IRRIGATION_TYPE,
      Location.LOCATION_SIZE,
      Location.LOCATION_SIZE,
      Location.RESIDENCE_TYPE,
    }.join(","), authorization: authorization));

    final items = res?.body?.items;

    return PreferenceCategory((b) => b
      ..prv = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.PRV)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..pipeType = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.PIPE_TYPE)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..fixtureIndoor = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.FIXTURE_INDOOR)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..fixtureOutdoor = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.FIXTURE_OUTDOOR)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..homeAppliance = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.HOME_APPLIANCE)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..irrigationType = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.IRRIGATION_TYPE)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..locationSize = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.LOCATION_SIZE)?.values?.first?.where((it) => it.key != null)) ?? const [])
      ..residenceType = ListBuilder(or(() => items.firstWhere((it) => it?.entries?.first?.key == Location.RESIDENCE_TYPE)?.values?.first?.where((it) => it.key != null)) ?? const [])
    );
  }

  @Get(path: "v2/lists?id=timezone_{country}")
  Future<Response<Items>> timezoneItems(@Path("country") String country, {@Header(Headers.AUTHORIZATION) String authorization});

  Future<Iterable<TimeZone>> timezones(String country, {String authorization}) async {
    final Response<Items> res = await timezoneItems(country, authorization: authorization);
    return or(() =>  res.body.items.first["timezone_${country}"])?.map((it) => TimeZone((b) => b
      ..tz = it.key
      ..display = it.longDisplay ?? it.shortDisplay
    )) ?? [];
  }

  @Get(path: "v2/lists?id=region_{country}")
  Future<Response<Items>> regionItems(@Path("country") String country, {@Header(Headers.AUTHORIZATION) String authorization});

  Future<Iterable<Item>> regions(String country, {String authorization}) async {
    final res = await regionItems(country, authorization: authorization);
    return or(() => res.body.items.first["region_${country}"]) ?? [];
  }

  @Get(path: "v2/lists/device_make")
  Future<Response<ItemList>> deviceMakeItemList({@Header(Headers.AUTHORIZATION) String authorization});

  @Get(path: "v2/lists?id=device_model_{deviceMake}")
  Future<Response<Items>> deviceModelItems(@Path("deviceMake") String deviceMake, {String authorization});

  Future<List<Item>> deviceModels({String authorization}) async {
    final List<String> deviceMakes = await Observable.fromFuture(deviceMakeItemList(authorization: authorization))
        .map((it) => it.body.items)
        .expand((it) => it)
        .map((it) => it.key)
        .toList();
    final models = await lists(deviceMakes.map((it) => "device_model_${it}").toSet(), authorization: authorization).then((it) => it.body);
    return models.items
        .expand((it) => it.values)
        .expand((it) => it)
        .toList();
  }

  Future<List<DeviceItem>> deviceModelsWithType({String authorization}) async {
    final Map<String, Item> deviceMakes = Maps.fromIterable2((await deviceMakeItemList(authorization: authorization)).body.items, key: (it) => "device_model_${it.key}");
    final models = await lists(deviceMakes.keys.toSet(), authorization: authorization).then((it) => it.body);
    return models.items
        .expand((map) => map.entries)
        .expand((it) => it.value.map((model) => DeviceItem((b) => b
      ..type = deviceMakes[it.key]?.toBuilder()
      ..key = model.key
      ..shortDisplay = model.shortDisplay
      ..longDisplay = model.longDisplay
      ..language = model.language
    ))).toList();
  }

  Future<Iterable<Item>> deviceModelsByMake(String deviceMake, {String authorization}) async {
    final res = await deviceModelItems(deviceMake, authorization: authorization);
    return or(() => res.body.items.first["device_model_${deviceMake}"]) ?? [];
  }

  Future<Iterable<Item>> floDeviceV2Models({String authorization}) {
    return deviceModelsByMake(Device.FLO_DEVICE_V2, authorization: authorization);
  }

  // NOTICE: There is no v2 yet
  @deprecated
  @Get(path: "v1/locales/{locale}")
  Future<Response<Locale>> locale(@Path("locale") String country, {@Header(Headers.AUTHORIZATION) String authorization});

  // NOTICE: There is no v2 yet
  @deprecated
  @Get(path: "v1/countrystateprovinces/{country}")
  Future<Response<BuiltList<String>>> getStateProvinces(@Path("country") String country, {@Header(Headers.AUTHORIZATION) String authorization});

  /// getCertificate2(Ticket((b) => b..data = qrdata), authorization: authorization);
  @Post(path: "v2/devices/pair/init")
  Future<Response<Certificate2>> getCertificate(@Body() Ticket payload, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  /// getCertificate2(Ticket2((b) => b..data = qrdata), authorization: authorization);
  @Post(path: "v2/devices/pair/init")
  Future<Response<Certificate2>> getCertificate2(@Body() Ticket2 payload, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  @Post(path: "v2/devices/pair/init")
  Future<Response<Certificate2>> getCertificateByDeviceModel(@Body() Device device, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization,
  });

  @Post(path: "v2/devices/pair/complete")
  Future<Response<Device>> linkDevice(@Body() LinkDevicePayload payload, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });


  //@Get(path: "v2/devices/{id}")
  @Get(path: "v2/devices/{id}")
  Future<Response<Device>> getDevice(@Path("id") String id, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
      @Query('expand')
      String expand = "irrigationSchedule",
    });

  @Get(path: "v2/devices/{id}")
  Future<Response<Device>> getDeviceWithCertificate(@Path("id") String id, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization,
    @Query('expand')
    String expand = "pairingData",
  });

  Future<Certificate2> getCertificateByDevice(String id, {
    @required
    String authorization,
  }) async {
    final res = await getDeviceWithCertificate(id, authorization: authorization);
    return res.body.certificate;
  }

  @Post(path: "v2/users/{id}/password")
  Future<Response<ChangePassword>> changePasswords(@Path("id") String id,
      @Body() ChangePassword payload,
      {
        @required
        @Header(Headers.AUTHORIZATION) String authorization,
      });

  Future<Response<ChangePassword>> changePassword(@Path("id") String id,
      String password,
      String newPassword,
      {
        @required
        @Header(Headers.AUTHORIZATION) String authorization,
      }) async {
    return await changePasswords(id, ChangePassword((b) => b
      ..oldPassword = password
      ..newPassword = newPassword
    ), authorization: authorization);
  }


  @Get(path: "v2/water/averages")
  Future<Response<WaterUsageAverages>> waterUsageAveragesDevice({
    @required
    @Header(Headers.AUTHORIZATION)
    String authorization,
    /// MAC address of device to retrieve water consumption for. The param macAddress is exclusive with locationId, only one can be specified
    @required
    @Query('macAddress')
    String macAddress,
    /// If timezone is not specified as part of the date range, then this timezone will be applied to the date. Defaults to the location or device's local timezone.
    @Query('tz')
    String tz,
  });
  @Get(path: "v2/water/averages")
  Future<Response<WaterUsageAverages>> waterUsageAveragesLocation({
    @required
    @Header(Headers.AUTHORIZATION)
    String authorization,
    /// ID of location to retrieve water consumption for. The param locationId is exclusive with macAddress, only one can be specified
    @required
    @Query('locationId')
    String locationId,
    /// If timezone is not specified as part of the date range, then this timezone will be applied to the date. Defaults to the location or device's local timezone.
    @Query('tz')
    String tz,
  });

  @Get(path: "v2/water/consumption")
  Future<Response<WaterUsage>> waterUsageLocation({
    @required
    @Header(Headers.AUTHORIZATION)
    String authorization,
    /// Inclusive start of date range of data. Recommend to round to the closest hour and not specify timezone.
    @required
    @Query('startDate')
    String startDate,
    /// Exclusive end of date range of data. Recommend to round to the closest hour and not specify timezone.
    @Query('endDate')
    String endDate,
    /// ID of location to retrieve water consumption for. The param locationId is exclusive with macAddress, only one can be specified
    @required
    @Query('locationId')
    String locationId,
    /// Time interval to aggregate consumption. Default is 1h.
    /// Available values : 1h, 1d
    @Query('interval')
    String interval,
    /// If timezone is not specified as part of the date range, then this timezone will be applied to the date. Defaults to the location or device's local timezone.
    @Query('tz')
    String tz,
  });

  @Get(path: "v2/water/consumption")
  Future<Response<WaterUsage>> waterUsageDevice({
    @required
    @Header(Headers.AUTHORIZATION)
    String authorization,
    /// Inclusive start of date range of data. Recommend to round to the closest hour and not specify timezone.
    @required
    @Query('startDate')
    String startDate,
    /// Exclusive end of date range of data. Recommend to round to the closest hour and not specify timezone.
    @Query('endDate')
    String endDate,
    /// MAC address of device to retrieve water consumption for. The param macAddress is exclusive with locationId, only one can be specified
    @required
    @Query('macAddress')
    String macAddress,
    /// Time interval to aggregate consumption. Default is 1h.
    /// Available values : 1h, 1d
    @Query('interval')
    String interval,
    /// If timezone is not specified as part of the date range, then this timezone will be applied to the date. Defaults to the location or device's local timezone.
    //@Query('tz')
    //String tz,
  });

  Future<Response<WaterUsage>> waterUsageTodayLocation({
    @required
    String locationId,
    String interval = INTERVAL_1H,
    //String tz = TimeZone.UTC,
    String authorization,
  }) async {
    /// We don't use DateTime.add(Duration) for the endDate
    /// Because we shouldn't expect the date different is the same 86,400 seconds of duration for a day
    final today = DateTimes.today();
    final startDate = today.toIso8601String();
    //final endDate = tomorrow.toIso8601String();
    final endDate = null;
    return await waterUsageLocation(
      authorization: authorization,
      startDate: startDate,
      endDate: endDate,
      interval: interval,
      locationId: locationId,
      //tz: tz,
    );
  }
  Future<Response<WaterUsage>> waterUsageTodayDevice({
    @required
    String macAddress,
    String interval = INTERVAL_1H,
    //String tz = TimeZone.UTC,
    String authorization,
  }) async {
    /// We don't use DateTime.add(Duration) for the endDate
    /// Because we shouldn't expect the date different is the same 86,400 seconds of duration for a day
    final today = DateTimes.today();
    final startDate = today.toIso8601String();
    //final endDate = tomorrow.toIso8601String();
    final endDate = null;
    return await waterUsageDevice(
      authorization: authorization,
      startDate: startDate,
      endDate: endDate,
      interval: interval,
      macAddress: macAddress,
      //tz: tz,
    );
  }

  Future<Response<WaterUsage>> waterUsageWeekLocation({
    @required
    String locationId,
    String interval = INTERVAL_1D,
    //String tz,
    String authorization,
  }) async {
    final now = DateTime.now();
    final startDate = DateTimes.lastWeekday(6, from: now);
    final endDate = DateTimes.today(from: startDate, offsetDays: 7);
    return await waterUsageLocation(
      authorization: authorization,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      interval: interval,
      //tz: tz,
      locationId: locationId,
    );
  }

  Future<Response<WaterUsage>> waterUsageWeekDevice({
    @required
    String macAddress,
    String interval = INTERVAL_1D,
    //String tz = TimeZone.UTC,
    String authorization,
  }) async {
    final now = DateTime.now();
    final startDate = DateTimes.lastWeekday(6, from: now);
    final endDate = DateTimes.today(from: startDate, offsetDays: 7);
    return await waterUsageDevice(
      authorization: authorization,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      interval: interval,
      //tz: tz,
      macAddress: macAddress,
    );
  }

  @deprecated
  @Post(path: "v1/pairing/unpair/{icd_id}")
  Future<Response<Device>> unlinkDevice(@Path("icd_id") String icdId, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  @Post(path: "v2/devices/{id}")
  Future<Response<Device>> putDeviceById(@Path("id") String id, @Body() Device device, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  Future<Response<Device>> putDevice(Device device, {
      @required
      String authorization,
    }) async {
      return await putDeviceById(device.id, device.rebuild((b) => b
      ..id = null
      ..macAddress = null
      ..deviceType = null
      ..connectivity = null
      ..deviceModel = null
      ..isConnected = null
      ..lastHeardFromTime = null
      ..firmwareVersion = null
      ..firmwareProperties = null
      ..notifications = null
      ..telemetries = null
      ..valveState = null
      ..isPaired = null
      ..location = null
      ..installStatus = null
      ..healthTest = null
      ..fsTimestamp = null
      ..deviceId = null
      ..irrigationSchedule = null
      ..certificate = null
      ..learning = null
      ..serialNumber = null
      ..estimateWaterUsage = null
      ), authorization: authorization);
    }

  Future<Response<Device>> setValveOpenById(final String id, {
      @required
      final bool open,
      @required
      String authorization,
    }) async {
      return await putDeviceById(id,
      Device((b) => b..valve = Valve((b) => b..target = open ? Valve.OPEN : Valve.CLOSED).toBuilder()),
       authorization: authorization);
    }


  Future<Response<Device>> openValveById(final String id, {
      @required
      String authorization,
    }) async {
      return await setValveOpenById(id, open: true, authorization: authorization);
    }

  Future<Response<Device>> closeValveById(String id, {
      @required
      String authorization,
    }) async {
      return await setValveOpenById(id, open: false, authorization: authorization);
    }

  @Post(path: "v2/locations/{id}")
  Future<Response<Location>> putLocationById(@Path("id") String id, @Body() Location location, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  Future<Response<Location>> putLocation(Location location, {
      @required
      String authorization,
    }) async {
      /// NOTICE:
      /// The backend doesn't accept the "" empty string and not support clear any of fields for now
      /// we have to remove the prop if the prop is empty string before sending
      /// Expect it could be removed one day, that’s error-prone tho.
      /// because we have to put this kinda of to any of API call,
      /// and we don’t think we can remember to add this kinda guard conditions when we add other props every time.
      return await putLocationById(location.id, location.rebuild((b) => b
      ..id = null
      ..devices = null
      ..userRoles = null
      ..systemModes = null
      ..account = null
      ..users = null
      ..notifications = null
      ..dirty = null
      ..nickname = (b?.nickname?.isNotEmpty ?? false) ? b.nickname : null
      ..address = (b?.address?.isNotEmpty ?? false) ? b.address : null
      ..address2 = (b?.address2?.isNotEmpty ?? false) ? b.address2 : null
      ..city = (b?.city?.isNotEmpty ?? false) ? b.city : null
      ..state = (b?.state?.isNotEmpty ?? false) ? b.state : null
      ..country = (b?.country?.isNotEmpty ?? false) ? b.country : null
      ..postalCode = (b?.postalCode?.isNotEmpty ?? false) ? b.postalCode : null
      ..timezone = (b?.timezone?.isNotEmpty ?? false) ? b.timezone : null
      ..homeownersInsurance = (b?.homeownersInsurance?.isNotEmpty ?? false) ? b.homeownersInsurance : null
      ..waterUtility = (b?.waterUtility?.isNotEmpty ?? false) ? b.waterUtility : null
      ), authorization: authorization);
    }

  @Post(path: "v2/users/{id}")
  Future<Response<User>> putUserById(@Path("id") String id, @Body() User user, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  /*
  Future<Response<User>> enanbleFeatures(@Path("id") String id, Set<String> features, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization,
  }) async {
  return await putUserById(id, User((b) => b..enabledFeatures = ListBuilder(features)), authorization: authorization);
  }
  */


  Future<Response<User>> putUser(User user, {
      @required
      String authorization,
    }) async {
      /// NOTICE:
      /// The backend doesn't accept the "" empty string and not support clear any of fields for now
      /// we have to remove the prop if the prop is empty string before sending
      /// Expect it could be removed one day, that’s error-prone tho.
      /// because we have to put this kinda of to any of API call,
      /// and we don’t think we can remember to add this kinda guard conditions when we add other props every time.
      return await putUserById(user.id, user.rebuild((b) => b
      ..id = null
      ..email = null // Backend doesn't support yet
      ..isActive = null
      ..locations = null
      ..locationRoles = null
      ..accountRole = null
      ..account = null
      ..locationRoles = null
      ..locations = null
      ..alertsSettings = null
      ..firstName = (b?.firstName?.isNotEmpty ?? false) ? b.firstName : null
      ..lastName = (b?.lastName?.isNotEmpty ?? false) ? b.lastName : null
      ..phoneMobile = (b?.phoneMobile?.isNotEmpty ?? false) ? b.phoneMobile : null
      ..middleName = (b?.middleName?.isNotEmpty ?? false) ? b.middleName : null
      ..prefixName = (b?.prefixName?.isNotEmpty ?? false) ? b.prefixName : null
      ..suffixName = (b?.suffixName?.isNotEmpty ?? false) ? b.suffixName : null
      ..locale = (b?.locale?.isNotEmpty ?? false) ? b.locale : null
      ..enabledFeatures = null
      ), authorization: authorization);
    }

  @Post(path: "v2/locations/{id}/systemMode")
  Future<Response<dynamic>> putSystemMode(@Path("id") String id, @Body() PendingSystemMode systemMode, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  @Post(path: "v2/devices/{id}/systemMode")
  Future<Response<dynamic>> putDeviceSystemMode(@Path("id") String id, @Body() PendingSystemMode systemMode, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization,
  });

  Future<Response<dynamic>> forceSleep2(String id, {
    @required
    String authorization,
  }) async {
    return await putDeviceSystemMode(id,
        PendingSystemMode((b) => b
          ..target = SystemMode.SLEEP
          ..isLocked = true
        ),
        authorization: authorization);
  }

  Future<Response<dynamic>> unforceSleep2(String id, {
    String target = SystemMode.SLEEP,
    @required
    String authorization,
  }) async {
    return await putDeviceSystemMode(id,
        PendingSystemMode((b) => b
          ..target = target
          ..isLocked = false
        ),
        authorization: authorization);
  }

  Future<Response<dynamic>> sleep(String id, {
      @required
      Duration duration,
      @required
      String revertMode,
      @required
      String authorization,
    }) async {
      return await putSystemMode(id,
       PendingSystemMode((b) => b
       ..target = SystemMode.SLEEP
       ..revertMinutes = duration.inMinutes
       ..revertMode = revertMode
       ),
       authorization: authorization);
    }

  Future<Response<dynamic>> away(String id, {
      @required
      String authorization,
    }) async {
      return await putSystemMode(id,
       PendingSystemMode((b) => b
       ..target = SystemMode.AWAY
       ),
       authorization: authorization);
    }

  Future<Response<dynamic>> home(String id, {
      @required
      String authorization,
    }) async {
      return await putSystemMode(id,
       PendingSystemMode((b) => b
       ..target = SystemMode.HOME
       ),
       authorization: authorization);
    }

  /*
    POST /api/v2/locations/<id>
    "irrigationSchedule": {
      "isEnabled": true
    }
  */
  Future<Response<Location>> setIrrigationEnabled(String id, bool enabled, {
      @required
      String authorization,
    }) async {
    return await putLocationById(id, Location((b) => b
        ..irrigationSchedule = IrrigationSchedule((b2) => b2..enabled = enabled).toBuilder()
        ), authorization: authorization);
  }

  Future<Response<Location>> enableIrrigation(String id, {
      @required
      String authorization,
    }) async {
    return await setIrrigationEnabled(id, true, authorization: authorization);
  }

  Future<Response<Location>> disableIrrigation(String id, {
      @required
      String authorization,
    }) async {
    return await setIrrigationEnabled(id, false, authorization: authorization);
  }

  @Post(path: "v2/devices/{id}/reset")
  Future<Response<dynamic>> resetDevice(@Path("id") String id, @Body() Target target, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  Future<Response<dynamic>> restartDevice(String id, {
    @required
    String authorization,
  }) async {
    return await resetDevice(id, Target.power, authorization: authorization);
  }

  @Delete(path: "v2/devices/{id}")
  Future<Response<Device>> unlinkDevice2(@Path("id") String id, {
      @required
      @Header(Headers.AUTHORIZATION) String authorization,
    });

  Future<Response> logoutByContext(context, {@required String authorization}) async {
    final deviceId = await Devices.id(context);
    return logout(LogoutPayload((b) => b..deviceId = deviceId), authorization: authorization);
  }

  Future<Response> magicLinkByEmail(String email) {
    return magicLink(MagicLinkPayload((b) => b
      ..email = email
      ..clientId = clientId
      ..clientSecret = clientSecret));
  }

  String clientId = "ffffffff-3730-4b07-bcd1-ffffffffffff";
  String clientSecret = "ffffffff-3730-4b07-bcd1-ffffffffffff";

  Future<OauthToken> loginByUsername(String username, String password) async {
    final res = await login(OauthPayload((b) => b
    ..clientId = clientId
    ..clientSecret = clientSecret
    ..grantType = PASSWORD
    ..username = username
    ..password = password
    ));
    oauth = res.body;
    print("$oauth");
    return oauth;
  }

  Future<OauthToken> get refreshToken async {
    if (oauth?.isExpired ?? false) {
      return await refreshTokenBy(oauth);
    }

    throw new Exception("no refresh token");
  }

  static const String PASSWORD = "password";
  static const String REFRESH_TOKEN = "refresh_token";

  Future<OauthToken> refreshTokenBy(OauthToken oauth) async {
    final res = await login(OauthPayload((b) => b
                ..clientId = clientId
                ..clientSecret = clientSecret
                ..refreshToken = oauth.refreshToken
                ..grantType = REFRESH_TOKEN
    ));
    refreshed = true;
    this.oauth = res.body;
    return this.oauth;
  }

  Future<Response> registrationWithState2(LoginState loginState) async {
    return registration2(RegistrationPayload2((b) => b
    ..email = loginState.email
    ..password = loginState.password
    ..firstName = loginState.firstName
    ..lastName = loginState.lastName
    ..country = loginState.country
    ..phone = loginState.phoneNumber
    ));
  }

  Future<Response> registrationWithState(LoginState loginState) async {
    return registration(RegistrationPayload((b) => b
    ..email = loginState.email
    ..password = loginState.password
    ..confirmPassword = loginState.confirmPassword
    ..firstName = loginState.firstName
    ..lastName = loginState.lastName
    ..country = loginState.country
    ..phoneNumber = loginState.phoneNumber
    ));
  }

  Future<bool> isEmailUsed(String email) async {
    final res = await emailStatus2(email);

    if (!res.isSuccessful) {
      throw Exception("!isSuccessful"); // TODO: throw an exception with the response
    }

    Fimber.d("res: ${res.body}");
    Fimber.d("pending: ${res.body.isPending}");
    Fimber.d("isRegistered: ${res.body.isRegistered}");
    return res.body.isPending || res.body.isRegistered;
  }

  Future<bool> isEmailAvailable(String email) async {
    final used = await isEmailUsed(email);
    Fimber.d("used: $used");
    return !(used);
  }

  @Post(path: "v1/pushnotificationtokens/android")
  //Future<Response<PushNotificationToken>> putPushNotificationToken(
  Future<Response<PushNotificationToken>> putPushNotificationToken(
  @Body() PushNotificationToken token, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization
  });


  /// @return {
  ///   mobile_device_id: String,
  ///   client_id: UUID,
  ///   user_id: UUID,
  ///   token: String,
  ///   client_type: Integer,
  ///   created_at: Date,
  ///   updated_at: Date,
  ///   is_disabled: Optional<Integer>
  /// }
  ///
  /// ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/67862547/Notification+Tokens+v2
  @Post(path: "v1/pushnotificationtokens/user/{id}")
  Future<Response<List<PushNotificationToken>>> getPushNotificationToken(
      @Path("id") String id, {
    @required
    @Header(Headers.AUTHORIZATION) String authorization
  });

  @Post(path: "v1/userregistration/verify/oauth2")
  Future<Response<OauthToken>> verifyOauth(@Body() OauthPayload oauth);

  Future<OauthToken> loginByToken(String token) async {
    final res = await verifyOauth(OauthPayload((b) => b
      ..token = token
      ..clientId = clientId
      ..clientSecret = clientSecret
    ));
    return res.body;
  }

  Future<OauthToken> loginByToken2(String token) async {
    final res = await verify(VerifyPayload((b) => b
      ..token = token
      ..clientId = clientId
      ..clientSecret = clientSecret
    ));
    return res.body;
  }

  /// @param id The device UUID
  /// ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/825622698/Keep+Water+Running
  Future<dynamic> keepWaterRunning(String id, {@required String authorization}) async {
    return (await putFirmwareProperties(id, FirmwareProperties((b) => b
        ..alarmSuppressUntilEventEnd = true
    ), authorization: authorization)).body;
  }

  static Flo of(BuildContext context,
  {bool authenticated = true}) {
    if (false) { // FIXME
      return FloMocked();
    }

    //final baseUrl = "https://api-dev.flocloud.co/api",
    //final baseUrl = "https://api.meetflo.com/api",
    final baseUrl = "https://api-gw-dev.flocloud.co/api"; // dev
    //final baseUrl = "https://api-gw.meetflo.com/api";
    //final host = Uri.parse(baseUrl).host;
    //final instabugLogger = HttpClientLogger();
    final client = ChopperClient(
        baseUrl: baseUrl, // prod
        converter: BuiltValueConverter(),
        //errorConverter: ErrorConverters.of(),
        errorConverter: SimpleErrorConverter(),
        interceptors: [
          /*
          (Request req) async {
              final _req = await req.toBaseRequest();
              instabugLogger.onRequest(SimpleHttpClientRequest(_req));
              return req;
          },
          (Response res) {
            final _res = res.base;
            instabugLogger.onResponse(SimpleHttpClientResponse(_res), SimpleHttpClientRequest(_res.request), responseBody: res.body);
            return res;
          },
          */
          (Request req) async {
             Fimber.d("req.baseUrl: ${req.baseUrl}");
             Fimber.d("req.url: ${req.method} ${req.url}");
             Fimber.d("req.parameters: ${req.parameters}");
             Fimber.d("req.headers: ${req.headers}");
             Fimber.d("req.body: ${req.body}");
              /*
              try {
                final sslPinned = (await SslPinningPlugin.check(serverURL: baseUrl, headerHttp: Map(),
                      sha: SHA.SHA256,
                      allowedSHAFingerprints: <String>[
                        // *.flocloud.co
                        //"12 15 06 C6 A3 89 08 11 4B BD 9B 3D 0D 3D E6 F9 4C A0 7E 37 E8 AB A9 35 F6 21 2B 89 85 92 B8 DF", // dev SHA256
                        // *.meetflo.com
                        "7B 68 F3 DB A5 4D AD 9D 02 04 4A DD DD 5F 08 03 68 74 15 61 8B 42 B8 B2 87 58 66 34 6D F6 BC 0E", // prod SHA256
                        //"B8 42 E9 90 72 09 93 C9 D7 10 2D 75 CD 0E 87 3C 9B 15 4E EF", // prod SHA1
                      ], timeout : 50)) == CONNECTION_SECURE;
                  if (sslPinned) {
                  } else {
                    Fimber.d("!SslPinned");
                    navigator.of().pushNamedAndRemoveUntil('/splash', ModalRoute.withName('/'));
                  }
                  Fimber.d("req.baseUrl: ${req.baseUrl}");
                  Fimber.d("req.url: ${req.method} ${req.url}");
                  Fimber.d("req.headers: ${req.headers}");
                  Fimber.d("req.body: ${req.body}");
              } catch (e) {
                Fimber.e("", ex: e);
              }
              */
              return req;
           },
           (Response res) async {
            //try {
            //  await Embrace.logNetworkResponse(res.base);
            //} catch (err) {
            //  Fimber.e("", ex: err);
            //}
             if (res == null) return res;
             final flo = Provider.of<FloNotifier>(navigator.of().context, listen: false).value;
             if (res.isSuccessful) {
               flo.refreshed = false;
             } else if (res.statusCode == HttpStatus.unauthorized) { // !isSuccessful
               if (flo.refreshed) {
                 navigator.of().pushNamedAndRemoveUntil('/login', ModalRoute.withName('/'));
               } else if (authenticated) {
                 /// token expired
                 /// invalid token
                 Fimber.d("res: ${res?.statusCode}");
                 Fimber.d("res.isSuccessful: ${res.isSuccessful}");
                 try {
                   final unauthFlo = createProd();
                   final oauthProvider = Provider.of<OauthTokenNotifier>(
                       context, listen: false);
                   final oauth = await unauthFlo.refreshTokenBy(oauthProvider.value);
                   oauthProvider.value = oauth;
                   oauthProvider.invalidate();
                   flo.oauth = oauth;
                   flo.refreshed = true;

                   navigator.of().pushNamedAndRemoveUntil('/splash', ModalRoute.withName('/'));
                 } catch (err) {
                   Fimber.e("", ex: err);
                   navigator.of().pushNamedAndRemoveUntil('/login', ModalRoute.withName('/'));
                 }
               }
             }
             return res;
           },
        ],
    );
    client.onError.listen((res) {
      Fimber.e("onError ${res.body}");
      Fimber.e("onError ResponseError ${res.body is ResponseError}");
    });
    return Flo.create(client,
     // prod
     //clientId: "86d05ffc-3730-4b07-bcd1-95315800262f",
     //clientSecret: "86d05ffc-3730-4b07-bcd1-95315800262f");
     // dev
     clientId: "199eba7e-a1cc-4b18-9821-301acc0503c9",
     clientSecret: "199eba7e-a1cc-4b18-9821-301acc0503c9");
     // other
     //clientId: "3baec26f-0e8b-4e1d-84b0-e178f05ea0a5",
     //clientSecret: "3baec26f-0e8b-4e1d-84b0-e178f05ea0a5");
  }

  static Flo createProd() {
    final client = ChopperClient(
      //baseUrl: "https://api.meetflo.com/api",
      baseUrl: "https://api-gw.meetflo.com/api",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter(),
      interceptors: [
            (Request req) async {
          print("req.baseUrl: ${req.baseUrl}");
          print("req.url: ${req.method} ${req.url}");
          print("req.parameters: ${req.parameters}");
          print("req.headers: ${req.headers}");
          print("req.body: ${req.body}");
          return req;
        },
        (Response res) {
          print("res.body: ${res.body}");
          return res;
        },
      ],
    );
    client.onError.listen((res) {
      print("onError: req.url: ${res.base.request.method} ${res.base.request.url}");
      print("onError: req.headers: ${res.base.request.headers}");
      print("onError: req.statusCode: ${res.statusCode}");
      print("onError: res.body: ${res.body}");
      print("onError: res.body is ResponseError: ${res.body is ResponseError}");
    });
    return Flo.create(client,
        clientId: "86d05ffc-3730-4b07-bcd1-95315800262f",
        clientSecret: "86d05ffc-3730-4b07-bcd1-95315800262f");
  }

  /*
  static Flo createDefault() {
    return createDev();
    //return createMocked();
  }

  static Flo createDev() {
    final client = ChopperClient(
        //baseUrl: "https://api-dev.flocloud.co/api",
        baseUrl: "https://api-gw-dev.flocloud.co/api",
        converter: BuiltValueConverter(),
        errorConverter: BuiltValueConverter()
    );
    client.onError.listen(print);
    return Flo.create(client,
     clientId: "199eba7e-a1cc-4b18-9821-301acc0503c9",
     clientSecret: "199eba7e-a1cc-4b18-9821-301acc0503c9");
     //clientId: "3baec26f-0e8b-4e1d-84b0-e178f05ea0a5",
     //clientSecret: "3baec26f-0e8b-4e1d-84b0-e178f05ea0a5");
  }
  */

  static const String INTERVAL_1D = "1d";
  static const String INTERVAL_1W = "1w";
  static const String INTERVAL_1H = "1h";
}

class FloMocked extends Flo {
  @override
  Type get definitionType => Flo;

  final defaultResponse = http.Response("{}", 200);

  @override
  Future<Response<EmailStatus>> emailStatus(EmailPayload payload) async {
    return Response<EmailStatus>(defaultResponse, EmailStatus((b) => b
    ..isPending = false
    ..isRegistered = true));
  }

  User _user = User((b) => b
            ..id = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            ..email = "demo@flotechnologies.com"
            ..isActive = true
            ..firstName = "Demo"
            ..lastName = "Demo"
            ..phoneMobile = "+1 310-000-0000"
            ..locations = ListBuilder()
            ..locationRoles = ListBuilder()
            ..accountRole = AccountRole((b) => b..accountId = "ffffffff-ffff-4fff-8fff-ffffffffffff").toBuilder()
            ..account = Id((b) => b..id = "ffffffff-ffff-4fff-8fff-ffffffffffff").toBuilder()
            ..unitSystem = UnitSystem.imperialUs
          );

  @override
  Future<Response<User>> getUser(String userId, {String expand = "alarmSettings", String authorization}) async {
    _user = _user.rebuild((b) => b
      ..locations = ListBuilder(locations.keys.map((it) => Id((b) => b..id = it)))
    );
    await Future.delayed(Duration(milliseconds: 300));
    return Response<User>(defaultResponse, _user);
  }

  @override
  Future<Response<Locales>> locales({String authorization}) async {
    return Response<Locales>(defaultResponse, Locales((b) => b
      ..locales = ListBuilder([
        Locale((b) => b
        ..locale = "US"
        ..name = "United States"),
        Locale((b) => b
        ..locale = "TW"
        ..name = "Taiwan"),
      ])
    ));
  }
  @override
  Future<Response<Locale>> locale(String country, {String authorization}) async {
    if (country == "us") {
      return Response<Locale>(defaultResponse,
        Locale.fromJson('{"timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"},{"tz":"US/Aleutian","display":"UTC-09:00 HDT (Aleutian)"},{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"},{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"},{"tz":"US/Alaska","display":"UTC-08:00 AKDT (Alaska)"},{"tz":"US/Arizona","display":"UTC-07:00 MST (Arizona)"},{"tz":"US/Hawaii","display":"UTC-10:00 HST (Hawaii)"},{"tz":"US/Samoa","display":"UTC-11:00 SST (Samoa)"},{"tz":"America/Puerto_Rico","display":"UTC-04:00 AST (Puerto Rico)"},{"tz":"Pacific/Guam","display":"UTC+10:00 ChST (Guam)"}],"regions":[{"name":"Alaska","timezones":[{"tz":"US/Aleutian","display":"UTC-09:00 HDT (Aleutian)"},{"tz":"US/Alaska","display":"UTC-08:00 AKDT (Alaska)"}],"abbrev":"AK"},{"name":"Alabama","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"AL"},{"name":"Arkansas","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"AR"},{"name":"Arizona","timezones":[{"tz":"US/Arizona","display":"UTC-07:00 MST (Arizona)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"AZ"},{"name":"California","timezones":[{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"}],"abbrev":"CA"},{"name":"Colorado","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"CO"},{"name":"Connecticut","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"CT"},{"name":"Washington DC","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"DC"},{"name":"Delaware","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"DE"},{"name":"Florida","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"FL"},{"name":"Georgia","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"GA"},{"name":"Hawaii","timezones":[{"tz":"US/Hawaii","display":"UTC-10:00 HST (Hawaii)"}],"abbrev":"HI"},{"name":"Iowa","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"IA"},{"name":"Idaho","timezones":[{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"ID"},{"name":"Illinois","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"IL"},{"name":"Indiana","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"IN"},{"name":"Kansas","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"},{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"KS"},{"name":"Kentucky","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"KY"},{"name":"Louisiana","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"LA"},{"name":"Massachusetts","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"MA"},{"name":"Maryland","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"MD"},{"name":"Maine","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"ME"},{"name":"Michigan","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"MI"},{"name":"Minnesota","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"MN"},{"name":"Missouri","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"MO"},{"name":"Mississippi","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"MS"},{"name":"Montana","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"MT"},{"name":"North Carolina","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"NC"},{"name":"North Dakota","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"ND"},{"name":"Nebraska","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"},{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"NE"},{"name":"New Hampshire","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"NH"},{"name":"New Jersey","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"NJ"},{"name":"New Mexico","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"NM"},{"name":"Nevada","timezones":[{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"NV"},{"name":"New York","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"NY"},{"name":"Ohio","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"OH"},{"name":"Oklahoma","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"OK"},{"name":"Oregon","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"},{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"}],"abbrev":"OR"},{"name":"Pennsylvania","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"PA"},{"name":"Rhode Island","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"RI"},{"name":"South Carolina","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"SC"},{"name":"South Dakota","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"SD"},{"name":"Tennessee","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"},{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"TN"},{"name":"Texas","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"},{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"TX"},{"name":"Utah","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"UT"},{"name":"Virginia","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"VA"},{"name":"Vermont","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"VT"},{"name":"Washington","timezones":[{"tz":"US/Pacific","display":"UTC-07:00 PDT (Pacific)"}],"abbrev":"WA"},{"name":"Wisconsin","timezones":[{"tz":"US/Central","display":"UTC-05:00 CDT (Central)"}],"abbrev":"WI"},{"name":"West Virginia","timezones":[{"tz":"US/Eastern","display":"UTC-04:00 EDT (Eastern)"}],"abbrev":"WV"},{"name":"Wyoming","timezones":[{"tz":"US/Mountain","display":"UTC-06:00 MDT (Mountain)"}],"abbrev":"WY"}],"name":"United States","locale":"us"}'));
    }
    return Response<Locale>(defaultResponse,
      Locale.fromJson('{"timezones":[{"tz":"Europe/London","display":"UTC+01:00 BST (London)"},{"tz":"America/Cayman","display":"UTC-05:00 EST (Cayman)"}],"regions":[{"name":"Cayman Islands","timezones":[{"tz":"America/Cayman","display":"UTC-05:00 EST (Cayman)"}],"abbrev":"KY"}],"name":"United Kingdom","locale":"uk"}'));
  }

  OauthToken _oauthToken = OauthToken.empty;

  @override
  Future<Response<OauthToken>> login(OauthPayload payload) async {
    _oauthToken = _oauthToken.rebuild((b) => b
      ..accessToken = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..refreshToken = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresIn = 86400000
      ..expiresAt = "2048-12-31T59:59:59.999Z"
      ..issuedAt = "1980-01-01T00:00:00.000Z"
      ..tokenType = "Bearer"
    );

    return Response<OauthToken>(defaultResponse, _oauthToken);
  }

  @override
  Future<Response> magicLink(MagicLinkPayload payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> registration(RegistrationPayload payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> resendEmail(EmailPayload payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> resendEmail2(EmailPayload payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> resetPassword(EmailPayload payload) async {
    return Response(defaultResponse, null);
  }

  static Location get _location => Location.empty.rebuild((b) => b
        ..id = "ffffffff-ffff-4fff-8fff-ffffffffffff"
        ..nickname = "Main Home"
        ..address = "963 Lovelace Road, Tampa Bay"
        ..systemModes = PendingSystemMode((b) => b
          ..isLocked = false
          ..lastKnown = SystemMode.HOME
        ).toBuilder()
        ..city = "Culver City"
        ..state = "CA"
        ..country = "us"
        ..postalCode = "90232"
        ..timezone = "US/Pacific"
        ..gallonsPerDayGoal = 160
        ..occupants = 1
        ..stories = 2
        ..isProfileComplete = false
        ..account = Id((b) => b..id = "").toBuilder()
        ..locationSize = LocationSize.GT_700_FT_LTE_1000_FT
        ..plumbingType = PlumbingType.COPPER
        ..waterSource = WaterSource.UTILITY
        ..indoorAmenities = ListBuilder<String>([Amenities.bathtub])
        ..outdoorAmenities = ListBuilder<String>([Amenities.hottub])
        ..plumbingAppliances = ListBuilder<String>([Amenities.tanklessWaterHeater])
  );

  Map<String, Location> locations = {
    "ffffffff-ffff-4fff-0000-fffffffffff0": _location.rebuild((b) => b
        ..id="ffffffff-ffff-4fff-0000-fffffffffff0"
        ..nickname = "Main Home"
        ..address = "1225 Harvey Street, Seattle, WA 144"
        ..systemModes = PendingSystemMode((b) => b
          ..isLocked = false
          ..lastKnown = SystemMode.HOME
        ).toBuilder()
          ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
          //..criticalCount = 0
          //..warningCount = 4
          //..infoCount = 3
          ).toBuilder()).toBuilder()
          ..irrigationSchedule = IrrigationSchedule((b2) => b2
            ..enabled = true
            ..computed = Schedule((b3) => b3
              ..status = Schedule.NOT_FOUND
              ..times = ListBuilder<BuiltList<String>>([
                BuiltList<String>([ "0:48:19", "1:49:20" ]),
                BuiltList<String>([ "11:08:09", "11:35:12" ]),
                BuiltList<String>([ "18:08:09", "23:35:12" ]),
              ])
            ).toBuilder()
          ).toBuilder()
        ..devices = ListBuilder([
          Device.empty.rebuild((it) => it
          ..id = "ffffffff-ffff-4fff-0000-fffffffffff0"
          ..macAddress = "fffffffffff0"
          ..nickname = "Main Device"
          ..installationPoint = "Home"
          ..installStatus = InstallStatus((b) => b
            ..isInstalled = false
          ).toBuilder()
          ..healthTest = HealthTest((b) => b
            ..status = HealthTest.CANCELLED
            ..leakType = -1
          ).toBuilder()
          ..isConnected = true
          ..connectivity = Connectivity((b) => b..rssi = -20).toBuilder()
          ..systemMode = PendingSystemMode((b) => b
            ..lastKnown = SystemMode.HOME
            ..isLocked = false
          ).toBuilder()
          ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
          //..criticalCount = 0
          //..warningCount = 4
          //..infoCount = 3
          ).toBuilder()).toBuilder()
            ..firmwareProperties = FirmwareProperties((b) => b
              ..serialNumber = "301234556789"
            ).toBuilder()
            ..serialNumber = "301234556789"
            ..firmwareVersion = "3.5.0"
          ),
          Device.empty.rebuild((it) => it
          ..id = "ffffffff-ffff-4fff-0000-fffffffffff1"
          ..macAddress = "fffffffffff1"
          ..nickname = "Irrigation Device"
          ..installationPoint = "Irrigation"
          ..isConnected = false
          ..connectivity = Connectivity((b) => b..rssi = -40).toBuilder()
          ..systemMode = PendingSystemMode((b) => b
            ..isLocked = true
            ..lastKnown = SystemMode.SLEEP
            ).toBuilder()
          ..installStatus = InstallStatus((b) => b
            ..isInstalled = true
          ).toBuilder()
            ..firmwareProperties = FirmwareProperties((b) => b
              ..serialNumber = "301234556789"
            ).toBuilder()
            ..serialNumber = "301234556789"
            ..firmwareVersion = "3.5.0"
          ),
        ])
        ),
      "ffffffff-ffff-4fff-1111-fffffffffff1": _location.rebuild((b) => b
        ..id="ffffffff-ffff-4fff-1111-fffffffffff1"
        ..nickname = "AirBnB"
        ..address = "1225 Harvey Street, Seattle, WA 145"
        ..systemModes = PendingSystemMode((b) => b
          ..isLocked = false
          ..lastKnown = SystemMode.HOME
        ).toBuilder()
          ..irrigationSchedule = IrrigationSchedule((b2) => b2
            ..enabled = false
            /*
            {
              "device_id": "ffffffffffff",
              "times": [
                [ "0:48:19", "1:49:20" ],
                [ "11:08:09", "11:35:12" ]
              ],
              "status": "schedule_found"
            }
            */
            ..computed = Schedule((b3) => b3
              ..status = Schedule.FOUND
              ..times = ListBuilder<BuiltList<String>>([
                BuiltList<String>([ "0:48:19", "1:49:20" ]),
                BuiltList<String>([ "11:08:09", "11:35:12" ]),
              ])
            ).toBuilder()
          ).toBuilder()
        ),
      "ffffffff-ffff-4fff-2222-fffffffffff2": _location.rebuild((b) => b
        ..id="ffffffff-ffff-4fff-2222-fffffffffff2"
        ..nickname = "Weekend house"
        ..address = "1225 Harvey Street, Seattle, WA 146"
        ..systemModes = PendingSystemMode((b) => b
          ..isLocked = false
          ..lastKnown = SystemMode.HOME
        ).toBuilder()
        ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
          //..criticalCount = 0
          //..warningCount = 0
          //..infoCount = 0
          ).toBuilder()).toBuilder()
        ..irrigationSchedule = IrrigationSchedule((b2) => b2
            ..enabled = true
            ..computed = Schedule((b3) => b3
              ..status = Schedule.FOUND
              ..times = ListBuilder<BuiltList<String>>([
                BuiltList<String>([ "0:48:19", "1:49:20" ]),
                BuiltList<String>([ "11:08:09", "11:35:12" ]),
              ])
            ).toBuilder()
          ).toBuilder()
        ..subscription = Subscription((b) => b
            ..isActive = true
        ).toBuilder()
        ..devices = ListBuilder([
          Device.empty.rebuild((it) => it
          ..id = "ffffffff-ffff-4fff-2222-fffffffffff0"
          ..macAddress = "fffffffffff0"
          ..nickname = "Main Device"
          ..installationPoint = "Living room"
          ..isConnected = true
          ..connectivity = Connectivity((b) => b..rssi = -20).toBuilder()
          ..systemMode = PendingSystemMode((b) => b
            ..lastKnown = SystemMode.SLEEP
            ..isLocked = true
          ).toBuilder()
          ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
          //..criticalCount = 0
          //..warningCount = 0
          //..infoCount = 0
          ).toBuilder()).toBuilder()
          ..installStatus = InstallStatus((b) => b
            ..isInstalled = true
          ).toBuilder()
            ..firmwareProperties = FirmwareProperties((b) => b
              ..serialNumber = "301234556789"
            ).toBuilder()
          ..serialNumber = "301234556789"
          ..firmwareVersion = "3.5.0"
          ..healthTest = HealthTest((b) => b..status = HealthTest.RUNNING
            ..startDate = DateTime.now().toString()
            ..endDate = DateTime.now().add(Duration(minutes: 3)).toString()
          ).toBuilder()
          ),
          Device.empty.rebuild((it) => it
          ..id = "ffffffff-ffff-4fff-2222-fffffffffff1"
          ..macAddress = "fffffffffff1"
          ..nickname = "Roof Device"
          ..installationPoint = "Roof"
          ..valve = Valve((b) => b..lastKnown = Valve.CLOSED).toBuilder()
          ..isConnected = true
          ..connectivity = Connectivity((b) => b..rssi = -40).toBuilder()
          ..systemMode = PendingSystemMode((b) => b
            ..lastKnown = SystemMode.AWAY
            ..isLocked = false
          ).toBuilder()
          ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
          ///..criticalCount = 0
          ///..warningCount = 0
          ///..infoCount = 0
          ).toBuilder()).toBuilder()
          ..installStatus = InstallStatus((b) => b
            ..isInstalled = true
          ).toBuilder()
          ..firmwareProperties = FirmwareProperties((b) => b
            ..serialNumber = "301234556789"
          ).toBuilder()
          ..serialNumber = "301234556789"
          ..firmwareVersion = "3.5.0"
          ..healthTest = HealthTest((b) => b
            ..status = HealthTest.COMPLETED
            ..leakType = HealthTest.LEAK_SUCCESSFUL
            ..leakLossMinGal = faker.randomGenerator.decimal(scale: 100.0)
            ..leakLossMaxGal = faker.randomGenerator.decimal(scale: 100.0)
            ..startPressure = faker.randomGenerator.decimal(scale: 100.0)
            ..endPressure = faker.randomGenerator.decimal(scale: 100.0)
            ..startDate = DateTime.now().toString()
            ..endDate = DateTime.now().add(Duration(minutes: 3)).toString()
          ).toBuilder()
          ),
          Device.empty.rebuild((it) => it
            ..id = "ffffffff-ffff-4fff-2222-fffffffffff2"
            ..macAddress = "fffffffffff0"
            ..nickname = "Not Installed Device"
            ..installationPoint = "Living room"
            ..isConnected = true
            ..connectivity = Connectivity((b) => b..rssi = -20).toBuilder()
            ..systemMode = PendingSystemMode((b) => b
              ..lastKnown = SystemMode.SLEEP
              ..isLocked = true
            ).toBuilder()
            ..notifications = AlertStatistics((b) => b..pending = Notifications((b) => b
              ///..criticalCount = 0
              ///..warningCount = 0
              ///..infoCount = 0
            ).toBuilder()).toBuilder()
            ..installStatus = InstallStatus((b) => b
              ..isInstalled = false
            ).toBuilder()
            ..firmwareProperties = FirmwareProperties((b) => b
              ..serialNumber = "301234556789"
            ).toBuilder()
            ..serialNumber = "301234556789"
            ..firmwareVersion = "3.5.0"
            ..healthTest = HealthTest((b) => b..status = HealthTest.RUNNING
              ..startDate = DateTime.now().toString()
              ..endDate = DateTime.now().add(Duration(minutes: 3)).toString()
            ).toBuilder()
          ),
        ])
        ),
  };

  @override
  Future<Response<Location>> getLocation(String id, {String authorization}) async {
    final location = or(() => locations[id]) ?? _location;
    return Response<Location>(defaultResponse, location);
  }

  @override
  Future<Response<Location>> addLocation(Location location, {@required String authorization}) async {
    location.rebuild((b) => b..id = b.id ?? Uuid().v4());
    locations[location.id] = location;
    return Response<Location>(defaultResponse, location);
  }

/*
  Future<Response<Location>> putLocation(String id, {String authorization}) async {
    return Response<Location>(defaultResponse, _location);
  }
*/

  @override
  Future<Response> registration2(RegistrationPayload2 payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> resetPassword2(EmailPayload payload) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<OauthToken>> verify(VerifyPayload payload) async {
    return Response<OauthToken>(defaultResponse, _oauthToken);
  }

  @override
  Future<Response> logout(LogoutPayload payload, {String authorization}) async {
    _oauthToken = OauthToken.empty;
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<EmailStatus2>> emailStatus2(String email) async {
    return Response<EmailStatus2>(defaultResponse, EmailStatus2((b) => b
    ..isPending = false
    ..isRegistered = true));
  }

  @override
  Future<Response<BuiltList<String>>> getStateProvinces(String country, {String authorization}) async {
    Fimber.d("${country}");
    print("${country}");
    if (country == "us") {
      return Response<BuiltList<String>>(defaultResponse,
        BuiltList<String>([
          "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
        ])
      );
    }
    else if (country == "uk") {
      return Response<BuiltList<String>>(defaultResponse,
        BuiltList<String>([
          "UK",
        ])
      );
    }
    else if (country == "au") {
      return Response<BuiltList<String>>(defaultResponse,
        BuiltList<String>([
          "NSW","QLD","SA","TAS","VIC","WA","ACT","JBT","NT"
        ])
      );
    }
    else if (country == "de") {
      return Response<BuiltList<String>>(defaultResponse,
        BuiltList<String>([
          "BW","BY","BE","BB","HB","HH","HE","NI","MV","NW","RP","SL","SN","ST","SH","TH"
        ])
      );
    }
    return Response(defaultResponse, BuiltList<String>([]));
  }

  @override
  Future<Response<Certificate2>> getCertificate(Ticket payload, {String authorization}) async {
    return Response(defaultResponse, Certificate2());
  }

  @override
  Future<Response<Certificate2>> getCertificate2(Ticket2 payload, {String authorization}) async {
    return Response(defaultResponse, Certificate2((b) => b
      ..apName = "Tenda_0E71A0"
      ..apPassword = "tripalink"
    ));
  }

  @override
  Future<Response<Device>> linkDevice(@Body() LinkDevicePayload payload, {String authorization}) async {
    final device = Device.empty.rebuild((b) => b
    ..id = "fffffff1-ffff-ffff-ffff-ffffffffffff"
    ..macAddress = payload.macAddress
    ..nickname = payload.nickname
    ..deviceModel = payload.deviceModel
    ..deviceType = payload.deviceType
    ..isConnected = true
    );
    Fimber.d("${payload}");
    final location = locations[payload.location.id] ?? _location;
    Fimber.d("${location}");
    final devices = location.devices?.toBuilder() ?? ListBuilder();
    Fimber.d("${location.devices}");
    devices.add(device);
    Fimber.d("${devices}");
    locations[payload.location.id] = location.rebuild((b) => b
    ..devices = devices);
    //location.rebuild((b) => b
    //..devices = devices.add
    //);
    return Response(defaultResponse, device);
  }

  @override
  Future<Response<Device>> unlinkDevice(String icdId, {String authorization}) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Device>> unlinkDevice2(String id, {String authorization}) async {
    locations = locations.map((key, location) {
      final list = location.devices?.toList() ?? [];
      list.removeWhere((device) => device.id == id);
      return MapEntry(key, location.rebuild((b) => b..devices = ListBuilder(list)));
    });
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Items>> countryItems({String authorization,
    String id = "country",
  }) async {
    final json = await rootBundle.loadString('assets/country.json');

    return Response<Items>(defaultResponse, Items.fromJson(json));
  }

  @override
  Future<Response<Items>> regionItems(String country, {String authorization}) async {
    final json = country.toLowerCase() == "us" ? await rootBundle.loadString('assets/region_us.json')
                                               : await rootBundle.loadString('assets/region_ca.json');

    return Response<Items>(defaultResponse, Items.fromJson(json));
  }

  @override
  Future<Response<Items>> timezoneItems(String country, {String authorization}) async {
    final json = country.toLowerCase() == "us" ? await rootBundle.loadString('assets/timezone_us.json')
                                               : await rootBundle.loadString('assets/timezone_ca.json');

    return Response<Items>(defaultResponse, Items.fromJson(json));
  }

  @override
  Future<Response<ItemList>> deviceMakeItemList({String authorization}) async {
    return Response<ItemList>(defaultResponse, ItemList((b) => b
      ..items = ListBuilder<Item>([
        Item((b) => b
        ..key = "flo_device_v2"
        ..shortDisplay = "Flo Device"
        ..longDisplay = "Flo Device"
        ),
        Item((b) => b
        ..key = "puck_oem"
        ..shortDisplay = "Puck"
        ..longDisplay = "Puck"
        ).toBuilder()])
    ));
  }

  @override
  Future<Response<Items>> deviceModelItems(String deviceMake, {String authorization}) async  {
    return Response<Items>(defaultResponse, Items((b) => b
      ..items = ListBuilder<BuiltMap<String, BuiltList<Item>>>([BuiltMap<String, BuiltList<Item>>({ "device_model_flo_device_v2" : BuiltList<Item>([
        Item((b) => b
        ..key = "flo_device_075_v2"
        ..shortDisplay = "Flo Device"
        ..longDisplay = "3/4\" Flo Device"
        ),
        Item((b) => b
        ..key = "flo_device_125_v2"
        ..shortDisplay = "Flo Device"
        ..longDisplay = "1 1/4\" Flo Device"
        ),
     ])
      }).toBuilder()])
    ));
  }

  @override
  Future<Response<Device>> putDeviceById(String id, Device device, {String authorization}) async {
    var newDevice = device;
    locations = locations.map((key, location) {
      final list = location.devices?.toList() ?? [];
      return MapEntry(key, location.rebuild((b) => b..devices = ListBuilder(list.map((it) {
        if (it.id == id) {
          newDevice = it.rebuild((b) => b
          ..nickname = device.nickname ?? b.nickname
          ..irrigationType = device.irrigationType ?? b.irrigationType
          ..installationPoint = device.installationPoint ?? b.installationPoint
          ..valve = device.valve.toBuilder() ?? b.valve
          );
          return newDevice;
        } else {
          return it;
        }
      }))));
    });
    return Response(defaultResponse, newDevice);
  }

  @override
  Future<Response<Device>> getDevice(String id, {String authorization,
    String expand = "irrigationSchedule"}) async {
    final device = or(() => $(locations.values ?? [])
      .flatMap((location) => location.devices ?? [])
      .firstWhere((device) => device.id == id));
    return Response(defaultResponse, device);
  }

  @override
  Future<Response<Location>> putLocationById(String id, Location location, {String authorization}) async {
    var newLocation = location;
    locations = locations.map((key, it) {
      return MapEntry(key, it.id == id ? location.rebuild((b) =>
          b..devices = it?.devices?.toBuilder() ?? ListBuilder()
        ) : it);
    });
    return Response(defaultResponse, newLocation);
  }

  @override
  Future<Response<User>> putUserById(String id, User user, {String authorization}) async {
    _user = user.rebuild((b) => b..id = id);
    return Response(defaultResponse, user);
  }

  @override
  Future<Response<dynamic>> putSystemMode(String id, PendingSystemMode systemMode, {String authorization}) async {
    locations = locations.map((key, it) {
      return MapEntry(key, it.id == id ? it.rebuild((b) =>
          b..systemModes = systemMode.toBuilder()
        ) : it);
    });
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Token>> getFirestoreToken({String authorization}) async {
    return Response(defaultResponse, Token((b) => b..token = ""));
  }

  @override
  Future<Response<ChangePassword>> changePasswords(String id, ChangePassword payload, {String authorization}) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<dynamic>> presence(AppInfo appInfo, {String authorization}) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<HealthTest>> getHealthTest(String id, {String authorization}) async {
    final res = await getDevice(id);
    return Response(defaultResponse, res.body.healthTest.rebuild((b) => b
      ..leakType = $(HealthTest.LEAK_TYPES).shuffled().first
      ..startDate = DateTime.now().subtract(Duration(minutes: 3)).toString()
      ..endDate = DateTime.now().toString()
    ));
  }

  @override
  Future<Response<HealthTest>> runHealthTest(String id, {String authorization}) async {
    final res = await getDevice(id);
    return Response(defaultResponse, HealthTest((b) => b
      ..status = HealthTest.RUNNING
      ..startDate = DateTime.now().toString()
      ..endDate = DateTime.now().add(Duration(minutes: 3)).toString()
    ));
  }

  @override
  Future<BuiltList<Item>> prvItems({String authorization, String id = "prv"}) async {
    return ItemList.fromJson('{ "items": [ { "key": "before", "shortDisplay": "Before Flo", "longDisplay": "PRV is before my Flo" }, { "key": "after", "shortDisplay": "After Flo", "longDisplay": "PRV is after my Flo" }, { "key": "none", "shortDisplay": "None", "longDisplay": "I don\'t have a PRV" }, { "key": "unknown", "shortDisplay": "Not Sure", "longDisplay": "Not Sure" } ]}').items;
  }

  @override
  Future<Response<Device>> getDeviceWithCertificate(String id, {String authorization,
    String expand = "pairingData",
  }) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> resetDevice(String id, Target target, {String authorization}) async {
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Alarm>> getAlarm(String id, {String authorization}) async {
    // TODO: implement getAlarm
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Alert>> getAlert(String id, {String authorization}) async {
    // TODO: implement getAlert
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Alerts>> getAlerts({String authorization,
    String locationId,
    Set<String> deviceIds,
    String macAddress,
    String createdAt,
    String status,
    String reason,
    String severity,
    String language,
    int page = 1,
    int size = 100,
  }) async {
    if (page == 1) {
      final alarms = Alarms.fromJson(await rootBundle.loadString('assets/alarms.json'));
      return Response(defaultResponse, Alerts((b) => b
        ..items = ListBuilder(alarms.displays.map((it) => Alert((b) => b
          ..alarm = it.toBuilder()
          ..createAt = DateTime.now().toIso8601String()
          ..status = status
        )))
        ..page = page
        ..total = alarms.items?.length ?? 0
      ));
    }
    return Response(defaultResponse, Alerts((b) => b
      ..items = ListBuilder()
      ..page = page
      ..total = 0
    ));
  }

  @override
  Future<Response<Alarms>> getAlarms({String authorization,
    bool isInternal,
    bool isShutoff,
    bool active,
    bool enabled}) async {
    return Response<Alarms>(defaultResponse, Alarms.fromJson(await rootBundle.loadString('assets/alarms.json')));
  }

  @override
  Future<Response> removeLocation(String id, {String authorization}) async {
    // TODO: implement removeLocation
    return Response(defaultResponse, null);
  }

  /*
  @override
  Future<Response> installDevices(Onboarding props, {String authorization}) async {
    // TODO: implement installDevices
    return Response(defaultResponse, null);
  }
  */

  @override
  Future<Response> putFirmwareProperties(String id, FirmwareProperties props, {String authorization}) async {
    // TODO: implement putFirmwareProperties
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> forceSleep(String id, {String authorization}) async {
    // TODO: implement forceSleep
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> installedDevice(Onboarding props, {String authorization}) async {
    // TODO: implement installedDevice
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> onboarding(Onboarding props, {String authorization}) async {
    // TODO: implement onboarding
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> unforceSleep(String id, {String authorization}) async {
    // TODO: implement unforceSleep
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> putDeviceSystemMode(String id, PendingSystemMode systemMode, {String authorization}) async {
    // TODO: implement putDeviceSystemMode
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<WaterUsage>> waterUsageDevice({String authorization, String startDate, String endDate, String macAddress, String interval, String tz}) async {
    final now = DateTime.now();
    return Response(defaultResponse, WaterUsage((b) => b
      ..aggregations = WaterUsageAggregations((b) => b
        ..sumTotalGallonsConsumed = faker.randomGenerator.decimal(scale: interval == Flo.INTERVAL_1H ? 60 : 400)
      ).toBuilder()
      ..items = ListBuilder(
          Iterable<int>.generate(interval == Flo.INTERVAL_1H ? 24 : 7).map((it) =>
              WaterUsageItem((b) => b
                ..time = now.add(interval == Flo.INTERVAL_1H ? Duration(hours: it) : Duration(days: it) ).toIso8601String()
                ..gallonsConsumed = faker.randomGenerator.decimal(scale: 5)
              )
          ))
    ));
  }

  @override
  Future<Response<WaterUsage>> waterUsageLocation({String authorization, String startDate, String endDate, String locationId, String interval, String tz}) async {
    final now = DateTime.now();
    return Response(defaultResponse, WaterUsage((b) => b
        ..aggregations = WaterUsageAggregations((b) => b
            ..sumTotalGallonsConsumed = faker.randomGenerator.decimal(scale: interval == Flo.INTERVAL_1H ? 200 : 900)
        ).toBuilder()
      ..items = ListBuilder(
        Iterable<int>.generate(interval == Flo.INTERVAL_1H ? 24 : 7).map((it) =>
          WaterUsageItem((b) => b
            ..time = now.add(interval == Flo.INTERVAL_1H ? Duration(hours: it) : Duration(days: it) ).toIso8601String()
            ..gallonsConsumed = faker.randomGenerator.decimal(scale: 5)
          )
        ))
    ));
  }

  @override
  Future<Response<WaterUsageAverages>> waterUsageAveragesDevice({String authorization, String macAddress, String tz}) async {
    return Response(defaultResponse, WaterUsageAverages((b) => b
        ..aggregations = WaterUsageAveragesAggregations((b) => b
          ..weekdayAverages = WeekdayAverages((b) => b
            ..value = 10
          ).toBuilder()
          ..weekdailyAverages = DurationValue((b) => b
            ..value = 15
          ).toBuilder()
          ..monthlyAverages = DurationValue((b) => b
            ..value = 35
          ).toBuilder()
        ).toBuilder()
    ));
  }

  @override
  Future<Response<WaterUsageAverages>> waterUsageAveragesLocation({String authorization, String locationId, String tz}) async {
    return Response(defaultResponse, WaterUsageAverages((b) => b
      ..aggregations = WaterUsageAveragesAggregations((b) => b
        ..weekdayAverages = WeekdayAverages((b) => b
          ..value = 20
        ).toBuilder()
        ..weekdailyAverages = DurationValue((b) => b
          ..value = 30
        ).toBuilder()
        ..monthlyAverages = DurationValue((b) => b
          ..value = 70
        ).toBuilder()
      ).toBuilder()
    ));
  }

  @override
  Future<Response> putAlertsSettings(String id, AlertsSettings alertsSettings, {String authorization}) async {
    // TODO: implement putAlertsSettings
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<HealthTest>> getHealthTestByRoundId(String id, String roundId, {String authorization}) async {
    // TODO: implement getHealthTestByRoundId
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<HealthTests>> getHealthTests(String id, {String authorization}) async {
    // TODO: implement getHealthTests
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<AlertStatistics>> getAlertStatistics({String locationId, String deviceId, String authorization}) async {
    // TODO: implement getAlertStatistics
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> putAlertAction(AlertAction action, {String authorization}) async {
    // TODO: implement putAlertAction
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> putAlertFeedback(String id, AlertFeedbacks feedbacks, {String authorization}) async {
    // TODO: implement putAlertFeedback
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<FloDetect>> getFloDetectByDevice0(String macAddress, {String duration = FloDetect.DURATION_24H, String authorization}) async {
    await Future.delayed(Duration(seconds: 1));
    return Response(defaultResponse,
        FloDetect((b) => b
          ..status = FloDetect.LEARNING
          ..fixtures = ListBuilder(
              Fixture.FIXTURES.map((it) => Fixture((b) => b
                ..name = it
                ..gallons = faker.randomGenerator.decimal(scale: 100.0)
                ..ratio = faker.randomGenerator.decimal(scale: 1.0)
                //..index = faker.randomGenerator.decimal(scale: 5.0).toInt() // TODO
              ))
          )));
  }

  @override
  Future<Response<FloDetectEvents>> getFloDetectEvents(String id, {String start, int size, String order, String authorization}) async {
    await Future.delayed(Duration(seconds: 1));
    return Response(defaultResponse,
        FloDetectEvents((b) => b
          ..items = ListBuilder(
          Iterable<int>.generate(24).map((it) {
            final fixture = $(Fixture.FIXTURES).shuffled().first;
            final correctFixture = $(Fixture.FIXTURES).shuffled().first;
            return FloDetectEvent((b) => b
              ..computationId = id
              ..flow = faker.randomGenerator.decimal(scale: 100.0)
              ..gpm = faker.randomGenerator.decimal(scale: 100.0)
              ..fixture = fixture
              ..duration = Duration(minutes: faker.randomGenerator.decimal(scale: 100.0).toInt()).inSeconds
              ..feedback = FloDetectFeedback((b) => b
                ..cases = correctFixture == fixture ? $([FloDetectFeedback.CONFIRM, FloDetectFeedback.INFORM]).shuffled().first : FloDetectFeedback.WRONG
                ..correctFixture = correctFixture
              ).toBuilder()
            );
          })
          )));
  }

  @override
  Future<Response> putFloDetectFeedback(String id, String start, FloDetectFeedbackPayload floDetectFeedback, {String authorization}) async {
    // TODO: implement putFloDetectFeedback
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Items>> lists(Set<String> ids, {String authorization}) async {
    // TODO: implement lists
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Items>> listsById(String ids, {String authorization}) async {
    // TODO: implement lists2
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> deleteFeatures(String id, Items items, {String authorization}) async {
    // TODO: implement deleteFeatures
    return Response(defaultResponse, null);
  }

  @override
  Future<Response> enabledFeatures(String id, Items items, {String authorization}) async {
    // TODO: implement enabledFeatures
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<ItemList>> list(String id, {String authorization}) async {
    // TODO: implement lists3
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<List<PushNotificationToken>>> getPushNotificationToken(String id, {String authorization}) async {
    // TODO: implement getPushNotificationToken
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<PushNotificationToken>> putPushNotificationToken(PushNotificationToken token, {String authorization}) async {
    // TODO: implement putPushNotificationToken
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<OauthToken>> verifyOauth(OauthPayload oauth) async {
    // TODO: implement verifyOauth
    return Response(defaultResponse, null);
  }

  @override
  Future<Response<Certificate2>> getCertificateByDeviceModel(Device device, {String authorization}) async {
    // TODO: implement getCertificateByDeviceModel
    return Response(defaultResponse, null);
  }
}

const String CONNECTION_SECURE = "CONNECTION_SECURE";
const String CONNECTION_INSECURE = "CONNECTION_INSECURE";

typedef ResponseConverter = FutureOr<Response> Function(Response response);
class SimpleErrorConverter implements ErrorConverter {
  SimpleErrorConverter({ResponseConverter onConvertError}) : this.onConvertError = onConvertError ?? ((res) async => throw res) ;
  final ResponseConverter onConvertError;

  @override
  FutureOr<Response> convertError<BodyType, InnerType>(Response response) async {
    return await onConvertError(response);
  }
}

/*
typedef ResponseConverter<BodyType, InnerType> = FutureOr<Response> Function<BodyType, InnerType>(Response response);
class SimpleErrorConverter<BodyType, InnerType> implements ErrorConverter {
  SimpleErrorConverter({ResponseConverter<BodyType, InnerType> onConvertError}) : this.onConvertError = onConvertError ?? ((res) async => throw res) ;
  final ResponseConverter<BodyType, InnerType> onConvertError;

  @override
  FutureOr<Response> convertError<BodyType, InnerType>(Response response) async {
    return await onConvertError(response);
  }
}
*/
/*
typedef ResponseConverter<BodyType, InnerType> = FutureOr<Response> Function<BodyType, InnerType>(Response response);
class SimpleErrorConverter<BodyType, InnerType> implements ErrorConverter {
  SimpleErrorConverter(this.onConvertError);
  final ResponseConverter<BodyType, InnerType> onConvertError;

  @override
  FutureOr<Response> convertError<BodyType, InnerType>(Response response) async {
    return await onConvertError(response);
  }
}

class ErrorConverters {
  static SimpleErrorConverter<BodyType, InnerType> of<BodyType, InnerType>({ResponseConverter<BodyType, InnerType> onConvertError}) {
    return SimpleErrorConverter<BodyType, InnerType>(onConvertError);
  }
}
*/
