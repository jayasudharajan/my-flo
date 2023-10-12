import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:flotechnologies/add_location_screen.dart';
import 'package:flotechnologies/main.dart';
import 'package:flotechnologies/model/alarm.dart';
import 'package:flotechnologies/model/alarms.dart';
import 'package:flotechnologies/model/alert.dart';
import 'package:flotechnologies/model/alert1.dart';
import 'package:flotechnologies/model/alert_feedback.dart';
import 'package:flotechnologies/model/alert_feedback_flow.dart';
import 'package:flotechnologies/model/alert_feedback_option.dart';
import 'package:flotechnologies/model/amenity.dart';
import 'package:flotechnologies/model/device.dart';
import 'package:flotechnologies/model/duration_value.dart';
import 'package:flotechnologies/model/fixture.dart';
import 'package:flotechnologies/model/flo_detect.dart';
import 'package:flotechnologies/model/health_test.dart';
import 'package:flotechnologies/model/item.dart';
import 'package:flotechnologies/model/items.dart';
import 'package:flotechnologies/model/location.dart';
import 'package:flotechnologies/model/notifications.dart';
import 'package:flotechnologies/model/pending_push_notification.dart';
import 'package:flotechnologies/model/push_notification.dart';
import 'package:flotechnologies/model/push_notification_data.dart';
import 'package:flotechnologies/model/serializers.dart';
import 'package:flotechnologies/model/water_usage.dart';
import 'package:flotechnologies/model/water_usage_averages.dart';
import 'package:flotechnologies/model/water_usage_averages_aggregations.dart';
import 'package:flotechnologies/model/weekday_averages.dart';
import 'package:flotechnologies/model/wifi.dart';
import 'package:flotechnologies/utils.dart';
import 'package:flotechnologies/validations.dart';
import 'package:flotechnologies/widgets.dart';
import 'package:flotechnologies/model/water_usage_aggregations.dart';
import 'package:flotechnologies/model/water_usage_item.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:test/test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:chopper/chopper.dart';

import 'package:flotechnologies/model/flo.dart';
import 'package:flotechnologies/model/oauth_token.dart';
import 'package:flotechnologies/model/oauth_payload.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:superpower/superpower.dart';
import 'package:timezone/timezone.dart' as timezone;

void main() {
  test('should DateTimes.hours', () async {
    final lastWeekday = DateTime.tryParse("2019-08-18T00:00:00.000");
    final hours = DateTimes.hours(lastWeekday);
    expect(hours.last.toIso8601String(), "2019-08-18T23:00:00.000");
    expect(hours.length, 24);
  });
  test('should WaterUsage.hours', () async {
    final waterUsage = WaterUsage((b) => b..items = ListBuilder([WaterUsageItem((b) => b..time = "2019-08-18T00:00:00.000")]));
    final actual = waterUsage.hours;
    expect(actual.last.datetime.toIso8601String(), "2019-08-18T23:00:00.000");
    expect(actual.length, 24);
  });
  test('should WaterkUsage.weekdays', () async {
    //final lastWeekday = DateTimes.lastWeekday(7).toIso8601String();
    //print("$lastWeekday");
    final actual = WaterUsage((b) => b..items = ListBuilder([WaterUsageItem((b) => b..time = "2019-08-18T00:00:00.000")])).weekdays(7);
    final expected = BuiltList<WaterUsageItem>([
      WaterUsageItem((b) => b
        ..time = "2019-08-18T00:00:00.000"
      ),
      WaterUsageItem((b) => b
        ..time = "2019-08-19T00:00:00.000"
        ..gallonsConsumed = 0.0,
      ),
      WaterUsageItem((b) => b
        ..time = "2019-08-20T00:00:00.000"
        ..gallonsConsumed = 0.0,
      ),
      WaterUsageItem((b) => b
        ..time = "2019-08-21T00:00:00.000"
        ..gallonsConsumed = 0.0,
      ),
      WaterUsageItem((b) => b
        ..time = "2019-08-22T00:00:00.000"
        ..gallonsConsumed = 0.0,
      ),
      WaterUsageItem((b) => b
        ..time = "2019-08-23T00:00:00.000"
        ..gallonsConsumed = 0.0,
      ),
    WaterUsageItem((b) => b
      ..time = "2019-08-24T00:00:00.000"
      ..gallonsConsumed = 0.0,
    ),
    ]);
    expect(actual, expected);
  });

  test('should merge WaterUsageItem', () async {
    final waterUsageAggregations = WaterUsageItem((b) => b
      ..time = "2019-08-01T11:19:00.000"
      ..gallonsConsumed = 1
    );
    final actual = waterUsageAggregations + waterUsageAggregations;
    final expected = WaterUsageItem((b) => b
      ..time = "2019-08-01T11:19:00.000"
      ..gallonsConsumed = 2
    );
    expect(actual, expected);
  });
  test('should merge WaterUsageAggregations', () async {
    final waterUsageAggregations = WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28
    );
    final actual = waterUsageAggregations + waterUsageAggregations;
    final expected = WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28 * 2.0
    );
    expect(actual, expected);

    /*
    expect(WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28
    ) + null, WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28
    ));
    expect(WaterUsageAggregations() + WaterUsageAggregations(), WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 0
    ));
    expect(WaterUsageAggregations() + WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28
    ), WaterUsageAggregations((b) => b
      ..sumTotalGallonsConsumed = 28
    ));
    */
  });
  test('should WaterUsageAverages + WaterUsageAverages', () async {
    expect(WaterUsageAverages() + WaterUsageAverages(), WaterUsageAverages.empty);
    expect(WaterUsageAverages() + null, WaterUsageAverages.empty);
    expect(WaterUsageAverages() + WaterUsageAverages.empty, WaterUsageAverages.empty);

    expect(WaterUsageAverages.empty + WaterUsageAverages(), WaterUsageAverages.empty);
    expect(WaterUsageAverages.empty + null, WaterUsageAverages.empty);
    expect(WaterUsageAverages.empty + WaterUsageAverages.empty, WaterUsageAverages.empty);

    final waterUsageAverages357 = WaterUsageAverages((b) => b
      ..aggregations = WaterUsageAveragesAggregations((b) => b
        ..weekdailyAverages = DurationValue((b) => b
          ..value = 3
        ).toBuilder()
        ..monthlyAverages = DurationValue((b) => b
          ..value = 5
        ).toBuilder()
        ..weekdayAverages = WeekdayAverages((b) => b
          ..value = 7
        ).toBuilder()
      ).toBuilder()
    );

    expect(
        waterUsageAverages357 + waterUsageAverages357,
        WaterUsageAverages((b) => b
          ..aggregations = WaterUsageAveragesAggregations((b) => b
            ..weekdailyAverages = DurationValue((b) => b
              ..value = 6
            ).toBuilder()
            ..monthlyAverages = DurationValue((b) => b
              ..value = 10
            ).toBuilder()
            ..weekdayAverages = WeekdayAverages((b) => b
              ..value = 14
            ).toBuilder()
          ).toBuilder()
        )
    );
    expect(
        waterUsageAverages357 + WaterUsageAverages(),
        waterUsageAverages357
    );
    expect(
        waterUsageAverages357 + WaterUsageAverages.empty,
        waterUsageAverages357
    );
    expect(
        waterUsageAverages357 + null,
        waterUsageAverages357
    );
    expect(
        WaterUsageAverages() + waterUsageAverages357,
        waterUsageAverages357
    );
    expect(
        WaterUsageAverages.empty + waterUsageAverages357,
        waterUsageAverages357
    );
  });
  test('should * waterUsage', () async {
    final waterUsage = WaterUsage((b) => b
      ..aggregations = WaterUsageAggregations((b) => b
        ..sumTotalGallonsConsumed = 28
      ).toBuilder()
      ..items = ListBuilder([
        WaterUsageItem((b) => b
          ..time = "2019-08-01T11:19:00.000"
          ..gallonsConsumed = 1
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-02T11:19:00.000"
          ..gallonsConsumed = 2
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-03T11:19:00.000"
          ..gallonsConsumed = 3
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-04T11:19:00.000"
          ..gallonsConsumed = 4
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-05T11:19:00.000"
          ..gallonsConsumed = 5
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-06T11:19:00.000"
          ..gallonsConsumed = 6
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-07T11:19:00.000"
          ..gallonsConsumed = 7
        ),
      ])
    );
    final actual = waterUsage * 3;
    final expected = WaterUsage((b) => b
      ..aggregations = WaterUsageAggregations((b) => b
        ..sumTotalGallonsConsumed = 28 * 3.0
      ).toBuilder()
      ..items = ListBuilder([
        WaterUsageItem((b) => b
          ..time = "2019-08-01T11:19:00.000"
          ..gallonsConsumed = 1 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-02T11:19:00.000"
          ..gallonsConsumed = 2 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-03T11:19:00.000"
          ..gallonsConsumed = 3 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-04T11:19:00.000"
          ..gallonsConsumed = 4 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-05T11:19:00.000"
          ..gallonsConsumed = 5 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-06T11:19:00.000"
          ..gallonsConsumed = 6 * 3.0
        ),
        WaterUsageItem((b) => b
          ..time = "2019-08-07T11:19:00.000"
          ..gallonsConsumed = 7 * 3.0
        ),
      ])
    );
    print("$actual");
    expect(actual, expected);
  });
  test('should combine FloDetect', () async {
    final it = FloDetect((b) => b
      ..fixtures = ListBuilder([
        Fixture((b) => b
          ..type = Fixture.TYPE_TOILET
          ..name = Fixture.TOILET
          ..gallons = 10
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_FAUCET
          ..name = Fixture.FAUCET
          ..gallons = 15
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_APPLIANCE
          ..name = Fixture.APPLIANCE
          ..gallons = 25
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_SHOWER
          ..name = Fixture.SHOWER_BATH
          ..gallons = 20
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_POOL
          ..name = Fixture.POOL
          ..gallons = 10
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_IRRIGATION
          ..name = Fixture.IRRIGATION
          ..gallons = 10
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_OTHER
          ..name = Fixture.OTHER
          ..gallons = 10
        ),
      ])
    );
    final actual = it + it; // double it for testing combine operator+()
    final expected = FloDetect((b) => b
      ..fixtures = ListBuilder([
        Fixture((b) => b
          ..type = Fixture.TYPE_TOILET
          ..name = Fixture.TOILET
          ..gallons = 20
          ..ratio = 0.1
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_FAUCET
          ..name = Fixture.FAUCET
          ..gallons = 30
          ..ratio = 0.15
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_APPLIANCE
          ..name = Fixture.APPLIANCE
          ..gallons = 50
          ..ratio = 0.25
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_SHOWER
          ..name = Fixture.SHOWER_BATH
          ..gallons = 40
          ..ratio = 0.2
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_POOL
          ..name = Fixture.POOL
          ..gallons = 20
          ..ratio = 0.1
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_IRRIGATION
          ..name = Fixture.IRRIGATION
          ..gallons = 20
          ..ratio = 0.1
          ..numEvents = 0
        ),
        Fixture((b) => b
          ..type = Fixture.TYPE_OTHER
          ..name = Fixture.OTHER
          ..gallons = 20
          ..ratio = 0.1
          ..numEvents = 0
        ),
      ])
    );
    print("$actual");
    expect(actual, expected);
  });
  test('should merge waterUsage', () async {
    final waterUsage = WaterUsage((b) => b
      ..aggregations = WaterUsageAggregations((b) => b
            ..sumTotalGallonsConsumed = 28
        ).toBuilder()
        ..items = ListBuilder([
          WaterUsageItem((b) => b
            ..time = "2019-08-01T11:19:00.000"
            ..gallonsConsumed = 1
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-02T11:19:00.000"
            ..gallonsConsumed = 2
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-03T11:19:00.000"
            ..gallonsConsumed = 3
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-04T11:19:00.000"
            ..gallonsConsumed = 4
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-05T11:19:00.000"
            ..gallonsConsumed = 5
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-06T11:19:00.000"
            ..gallonsConsumed = 6
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-07T11:19:00.000"
            ..gallonsConsumed = 7
          ),
        ])
    );
    final actual = waterUsage + waterUsage;
    final expected = WaterUsage((b) => b
        ..aggregations = WaterUsageAggregations((b) => b
            ..sumTotalGallonsConsumed = 28 * 2.0
        ).toBuilder()
        ..items = ListBuilder([
          WaterUsageItem((b) => b
            ..time = "2019-08-01T11:19:00.000"
            ..gallonsConsumed = 1 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-02T11:19:00.000"
            ..gallonsConsumed = 2 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-03T11:19:00.000"
            ..gallonsConsumed = 3 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-04T11:19:00.000"
            ..gallonsConsumed = 4 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-05T11:19:00.000"
            ..gallonsConsumed = 5 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-06T11:19:00.000"
            ..gallonsConsumed = 6 * 2.0
          ),
          WaterUsageItem((b) => b
            ..time = "2019-08-07T11:19:00.000"
            ..gallonsConsumed = 7 * 2.0
          ),
        ])
    );
    print("$actual");
    expect(actual, expected);
  });
  test('should sorted', () async {
    //$(devices).whereNotNull().sortedBy((it) => it.nickname ?? "")
    final actual   = BuiltList<String>($(["Zork nickname", "Aork nickname", "Work nickname", "zome nickname", "work nickname", "aome nickname", "0ome nickname", "home nickname"]).sorted().toList());
    final expected = BuiltList<String>(["0ome nickname", "Aork nickname", "Work nickname", "Zork nickname", "aome nickname", "home nickname", "work nickname", "zome nickname"]);
    print("$actual");
    expect(actual, expected);
  });
  test('should parse error', () async {
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        if (req.method == 'POST') {
          //return http.Response('{"type":"Fatal","message":"fatal erorr"}', 500);
          //return http.Response('{"type":"Fatal","message":"fatal erorr"}', 200);
          //return http.Response('{"access_token":"","refresh_token":"","expires_in":86400,"user_id":"ffffffff-ffff-4fff-8fff-ffffffffffff","expires_at":"2019-05-10T09:18:37.000Z","issued_at":"2019-05-09T09:18:37.000Z","token_type":"Bearer"}', 200);
          return http.Response('{"ac":"","refresh_token":"","expires_in":86400,"user_id":"ffffffff-ffff-4fff-8fff-ffffffffffff","expires_at":"2019-05-10T09:18:37.000Z","issued_at":"2019-05-09T09:18:37.000Z","token_type":"Bearer"}', 200);
        }
        return null;
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter()
    ));

    final oauth = await flo.loginByUsername("username", "");
    print('oauth: ${oauth}'); // undecoded String
    expect(oauth, null);
  });

  test('should serialized', () async {
    final oauthToken = OauthToken((b) => b
      ..accessToken = ""
      ..refreshToken = ""
      ..expiresIn = 86400
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresAt = "2019-05-10T09:18:37.000Z"
      ..issuedAt = "2019-05-09T09:18:37.000Z"
      ..tokenType = "Bearer"
    );
    final oauthTokenString = '{"access_token":"","refresh_token":"","expires_in":86400,"user_id":"ffffffff-ffff-4fff-8fff-ffffffffffff","expires_at":"2019-05-10T09:18:37.000Z","issued_at":"2019-05-09T09:18:37.000Z","token_type":"Bearer"}';
    //final jsonSerializers = (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
    //final jsonSerializers = (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
    print(serializers.serialize(oauthToken, specifiedType: FullType(OauthToken)));
  });

  test('should parse ok', () async {
    //[{"property":"should_accept_as_normal","value":false},{"property":"cause","value":1}]
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        print(req.body);
        return http.Response(
            '{"access_token":"","refresh_token":"","expires_in":86400,"user_id":"ffffffff-ffff-4fff-8fff-ffffffffffff","expires_at":"2019-05-10T09:18:37.000Z","issued_at":"2019-05-09T09:18:37.000Z","token_type":"Bearer"}',
            200);
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter(),
    ));

    final oauth = await flo.loginByUsername("username", "");
    expect(oauth, OauthToken((b) => b
      ..accessToken = ""
      ..refreshToken = ""
      ..expiresIn = 86400
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresAt = "2019-05-10T09:18:37.000Z"
      ..issuedAt = "2019-05-09T09:18:37.000Z"
      ..tokenType = "Bearer"
    ));
  });
  test('should hasDigits()', () {
    expect(hasDigits("Abc1234"), true);
    expect(hasDigits(""), false);
    expect(hasDigits("Abc"), false);
  });
  test('should hasUpperCase()', () {
    expect(hasUpperCase("Abc1234"), true);
    expect(hasUpperCase("abc1234"), false);
    expect(hasUpperCase(""), false);
  });
  test('should hasLowerCase()', () {
    expect(hasUpperCase("Abc1234"), true);
    expect(hasUpperCase("abc1234"), false);
    expect(hasUpperCase(""), false);
  });
  test('should isValidEmail()', () {
    expect(isValidEmail(""), false);
    expect(isValidEmail(" "), false);
    expect(isValidEmail("andrew@flotechnologies.com"), true);
    expect(isValidEmail("@flotechnologies.com"), false);
    expect(isValidEmail("andrew@flotechnologies"), false);
  });
  test('should hasWhitespace()', () {
    expect(hasWhitespace("Abcd123"), false);
    expect(hasWhitespace("Abc d123"), true);
    expect(hasWhitespace(" Abcd123"), true);
    expect(hasWhitespace("Abcd123 "), true);
    expect(hasWhitespace(""), false);
    expect(hasWhitespace(" "), true);
  });
  test('should isPostalCode', () {
    expect(isPostalCode("00000", "US"), true);
    expect(isPostalCode("0000", "US"), false);
    expect(isPostalCode("000000", "US"), false);
    expect(isPostalCode("", "US"), false);
    expect(isPostalCode(" ", "US"), false);
  });
  test('should simple bedrooms', () {
    expect(getSimpleBathrooms(2, 3), 2.5);
    expect(getSimpleBathrooms(2, 2), 2);
    expect(getSimpleBathrooms(3, 2), 3);
    expect(getSimpleBathrooms(0, 0), 0);
    expect(getSimpleBathrooms(0, 1), 0.5);
    expect(getSimpleBathrooms(1, 0), 1);
    expect(getSimpleBathrooms(1, 1), 1);
    expect(getSimpleBathrooms(1, 2), 1.5);
  });
  test('should putAlertFeedback()', () async {
    final flo = Flo.create(ChopperClient(
        client: MockClient((req) async {
          print(req.body);
          if (req.method == 'POST') {
            return http.Response('{}',
                200);
          }
          return null;
        }),
        baseUrl: "http://localhost",
        converter: BuiltValueConverter(),
        errorConverter: BuiltValueConverter()
    ));

    final res = await flo.putAlertFeedbacks("", [AlertFeedbackOption((b) => b
      ..property = AlertFeedback.SHOULD_ACCEPT_AS_NORMAL
      ..value = true)], authorization: "");
    print(res);
    //expect(res != null, true);
  });
  test('should serialize List<AlertFeedbackOption>', () async {
    final items = <AlertFeedbackOption>[
      AlertFeedbackOption((b) => b..property = "String"..value = "Foo"),
      AlertFeedbackOption((b) => b..property = "int"..value = 3),
      AlertFeedbackOption((b) => b..property = "int"..value = 0),
      AlertFeedbackOption((b) => b..property = "int"..value = -1),
      AlertFeedbackOption((b) => b..property = "bool"..value = true),
      AlertFeedbackOption((b) => b..property = "bool"..value = false),
    ];
    //final serialized = serializers.serialize(items, specifiedType: const FullType(BuiltList, const [const FullType(AlertFeedbackOption)]));
    final serialized = serializers.serialize(items);
    print(serialized);
    final jsonString = json.encode(serialized);
    print(jsonString);
    expect(jsonString, '{"feedback":[{"property":"should_accept_as_normal","value":true}]}');
  });
  test('should serialize BuiltList<AlertFeedbackOption>', () async {
    final items = <AlertFeedbackOption>[AlertFeedbackOption((b) => b..property = "Foo"..value = "Bar"), AlertFeedbackOption((b) => b..property = "Andrew"..value = "Chen")];
    //final serialized = serializers.serialize(items, specifiedType: const FullType(BuiltList, const [const FullType(AlertFeedbackOption)]));
    final serialized = serializers.serialize(items);
    print(serialized);
    final jsonString = json.encode(serialized);
    print(jsonString);
  });
  test('should serialize BuiltList<String>', () async {
    final items = BuiltList<String>(["Andrew", "Chen"]);
    //final serialized = serializers.serialize(items, specifiedType: const FullType(BuiltList, const [const FullType(String)]));
    final serialized = serializers.serialize(items);
    print(serialized);
    final jsonString = json.encode(serialized);
    print(jsonString);
  });
  test('should serialize Items', () async {
    final jsonString = '{ "items": [ { "country": [ { "key": "us", "shortDisplay": "USA", "longDisplay": "United States of America" }, { "key": "ca", "shortDisplay": "Canada", "longDisplay": "Canada" }, { "key": "au", "shortDisplay": "Australia", "longDisplay": "Australia" }, { "key": "de", "shortDisplay": "Germany", "longDisplay": "Germany" }, { "key": "nz", "shortDisplay": "New Zealand", "longDisplay": "New Zealand" }, { "key": "sg", "shortDisplay": "Singapore", "longDisplay": "Singapore" }, { "key": "ch", "shortDisplay": "Switzerland", "longDisplay": "Switzerland" }, { "key": "th", "shortDisplay": "Thailand", "longDisplay": "Thailand" }, { "key": "uk", "shortDisplay": "United Kingdom", "longDisplay": "United Kingdom" } ] } ] }';
    final items = Items.fromJson(jsonString);
    final serialized = serializers.serialize(items);
    print(serialized);
    final jsonString2 = json.encode(serialized);
    print(jsonString2);
  });
  test('should serialize BuiltList<Item>', () async {
    final items = BuiltList<Item>([Item((b) => b..longDisplay="Andrew"..shortDisplay="Chen")]);
    final serialized = serializers.serialize(items);
    print(serialized);
    final jsonString = json.encode(serialized);
    print(jsonString);
  });

  test('should parse nested map and list items ok', () async {
    final jsonString = '{ "items": [ { "country": [ { "key": "us", "shortDisplay": "USA", "longDisplay": "United States of America" }, { "key": "ca", "shortDisplay": "Canada", "longDisplay": "Canada" }, { "key": "au", "shortDisplay": "Australia", "longDisplay": "Australia" }, { "key": "de", "shortDisplay": "Germany", "longDisplay": "Germany" }, { "key": "nz", "shortDisplay": "New Zealand", "longDisplay": "New Zealand" }, { "key": "sg", "shortDisplay": "Singapore", "longDisplay": "Singapore" }, { "key": "ch", "shortDisplay": "Switzerland", "longDisplay": "Switzerland" }, { "key": "th", "shortDisplay": "Thailand", "longDisplay": "Thailand" }, { "key": "uk", "shortDisplay": "United Kingdom", "longDisplay": "United Kingdom" } ] } ] }';
    final items = Items.fromJson(jsonString);
    //print(items);
    expect(items != null, true);
    print(items.items.first['country']);
  });
  test('should get countries', () async {
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        if (req.method == 'GET') {
          return http.Response('{ "items": [ { "country": [ { "key": "us", "shortDisplay": "USA", "longDisplay": "United States of America" }, { "key": "ca", "shortDisplay": "Canada", "longDisplay": "Canada" }, { "key": "au", "shortDisplay": "Australia", "longDisplay": "Australia" }, { "key": "de", "shortDisplay": "Germany", "longDisplay": "Germany" }, { "key": "nz", "shortDisplay": "New Zealand", "longDisplay": "New Zealand" }, { "key": "sg", "shortDisplay": "Singapore", "longDisplay": "Singapore" }, { "key": "ch", "shortDisplay": "Switzerland", "longDisplay": "Switzerland" }, { "key": "th", "shortDisplay": "Thailand", "longDisplay": "Thailand" }, { "key": "uk", "shortDisplay": "United Kingdom", "longDisplay": "United Kingdom" } ] } ] }',
          200);
        }
        return null;
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter()
    ));

    final res = await flo.countries();
    print(res);
    expect(res != null, true);
  });
  test('should get regions', () async {
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        if (req.method == 'GET') {
          return http.Response(
'{"items":[{"region_us":[{"key":"al","shortDisplay":"AL","longDisplay":"Alabama"},{"key":"ak","shortDisplay":"AK","longDisplay":"Alaska"},{"key":"az","shortDisplay":"AZ","longDisplay":"Arizona"},{"key":"ar","shortDisplay":"AR","longDisplay":"Arkansas"},{"key":"ca","shortDisplay":"CA","longDisplay":"California"},{"key":"co","shortDisplay":"CO","longDisplay":"Colorado"},{"key":"ct","shortDisplay":"CT","longDisplay":"Connecticut"},{"key":"de","shortDisplay":"DE","longDisplay":"Delaware"},{"key":"fl","shortDisplay":"FL","longDisplay":"Florida"},{"key":"ga","shortDisplay":"GA","longDisplay":"Georgia"},{"key":"hi","shortDisplay":"HI","longDisplay":"Hawaii"},{"key":"id","shortDisplay":"ID","longDisplay":"Idaho"},{"key":"il","shortDisplay":"IL","longDisplay":"Illinois"},{"key":"in","shortDisplay":"IN","longDisplay":"Indiana"},{"key":"ia","shortDisplay":"IA","longDisplay":"Iowa"},{"key":"ks","shortDisplay":"KS","longDisplay":"Kansas"},{"key":"ky","shortDisplay":"KY","longDisplay":"Kentucky"},{"key":"la","shortDisplay":"LA","longDisplay":"Louisiana"},{"key":"me","shortDisplay":"ME","longDisplay":"Maine"},{"key":"md","shortDisplay":"MD","longDisplay":"Maryland"},{"key":"ma","shortDisplay":"MA","longDisplay":"Massachusetts"},{"key":"mi","shortDisplay":"MI","longDisplay":"Michigan"},{"key":"mn","shortDisplay":"MN","longDisplay":"Minnesota"},{"key":"ms","shortDisplay":"MS","longDisplay":"Mississippi"},{"key":"mo","shortDisplay":"MO","longDisplay":"Missouri"},{"key":"mt","shortDisplay":"MT","longDisplay":"Montana"},{"key":"ne","shortDisplay":"NE","longDisplay":"Nebraska"},{"key":"nv","shortDisplay":"NV","longDisplay":"Nevada"},{"key":"nh","shortDisplay":"NH","longDisplay":"New Hampshire"},{"key":"nj","shortDisplay":"NJ","longDisplay":"New Jersey"},{"key":"nm","shortDisplay":"NM","longDisplay":"New Mexico"},{"key":"ny","shortDisplay":"NY","longDisplay":"New York"},{"key":"nc","shortDisplay":"NC","longDisplay":"North Carolina"},{"key":"nd","shortDisplay":"ND","longDisplay":"North Dakota"},{"key":"oh","shortDisplay":"OH","longDisplay":"Ohio"},{"key":"ok","shortDisplay":"OK","longDisplay":"Oklahoma"},{"key":"or","shortDisplay":"OR","longDisplay":"Oregon"},{"key":"pa","shortDisplay":"PA","longDisplay":"Pennsylvania"},{"key":"ri","shortDisplay":"RI","longDisplay":"Rhode Island"},{"key":"sc","shortDisplay":"SC","longDisplay":"South Carolina"},{"key":"sd","shortDisplay":"SD","longDisplay":"South Dakota"},{"key":"tn","shortDisplay":"TN","longDisplay":"Tennessee"},{"key":"tx","shortDisplay":"TX","longDisplay":"Texas"},{"key":"ut","shortDisplay":"UT","longDisplay":"Utah"},{"key":"vt","shortDisplay":"VT","longDisplay":"Vermont"},{"key":"va","shortDisplay":"VA","longDisplay":"Virginia"},{"key":"wa","shortDisplay":"WA","longDisplay":"Washington"},{"key":"dc","shortDisplay":"DC","longDisplay":"Washington DC"},{"key":"wv","shortDisplay":"WV","longDisplay":"West Virginia"},{"key":"wi","shortDisplay":"WI","longDisplay":"Wisconsin"},{"key":"wy","shortDisplay":"WY","longDisplay":"Wyoming"}]}]}',
          200);
        }
        return null;
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter()
    ));

    final res = await flo.regions("us");
    print(res);
    expect(res != null, true);
  });
  test('should get timezones', () async {
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        if (req.method == 'GET') {
          return http.Response(
'{"items":[{"timezone_us":[{"key":"US/Aleutian","shortDisplay":"US/Aleutian","longDisplay":"US/Aleutian"},{"key":"US/Alaska","shortDisplay":"US/Alaska","longDisplay":"US/Alaska"},{"key":"US/Central","shortDisplay":"US/Central","longDisplay":"US/Central"},{"key":"US/Mountain","shortDisplay":"US/Mountain","longDisplay":"US/Mountain"},{"key":"US/Pacific","shortDisplay":"US/Pacific","longDisplay":"US/Pacific"},{"key":"US/Eastern","shortDisplay":"US/Eastern","longDisplay":"US/Eastern"},{"key":"US/Arizona","shortDisplay":"US/Arizona","longDisplay":"US/Arizona"},{"key":"US/Hawaii","shortDisplay":"US/Hawaii","longDisplay":"US/Hawaii"},{"key":"US/Samoa","shortDisplay":"US/Samoa","longDisplay":"US/Samoa"},{"key":"America/Puerto_Rico","shortDisplay":"America/Puerto_Rico","longDisplay":"America/Puerto_Rico"},{"key":"Pacific/Guam","shortDisplay":"Pacific/Guam","longDisplay":"Pacific/Guam"}]}]}',
          200);
        }
        return null;
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter()
    ));

    final res = await flo.timezones("us");
    print(res);
    expect(res != null, true);
  });
  test('should sort wifi', () async {
    final result = [
      Wifi((b) => b
      ..ssid = ""
      ..encryption = ""
      ..signal = -40
      ),
      Wifi((b) => b
      ..ssid = ""
      ..encryption = ""
      ..signal = -70
      ),
      Wifi((b) => b
      ..ssid = ""
      ..encryption = ""
      ..signal = -60
      ),
    ];
    print(sort(result, (a, b) => (a.signal - b.signal).toInt()));
  });
  test('should enum name', () async {
    expect(Amenity.bathtub.name, "bathtub");
    print(Amenity.hotTub.name);
    expect(Amenity.hotTub.name, "hot_tub");
  });
  test('should format number', () async {
    expect(NumberFormat("#.#").format(2.0), "2");
    expect(NumberFormat("#.#").format(2.5), "2.5");
    expect(NumberFormat("#.#").format(12.0), "12");
    expect(NumberFormat("#.#").format(12.5), "12.5");
    expect(NumberFormat("#.#").format(12.50), "12.5");
  });

  test('should remove item from list', () async {
    List<String> list = ["1", "2", "3"];
    list.removeWhere((it) => it == "2");
    expect(list.contains("2"), false);
  });

  test('should parse Location', () async {
    //final jsonString = await rootBundle.loadString('assets/location.json');
    final jsonString = '{"id":"1e981775-48ec-41ef-83a2-6e9cd38febc1","users":[{"id":"d28cb52e-6144-4aac-8840-3ad3d21b8f06"}],"devices":[{"id":"08b218c5-6cea-4f1c-8607-30063bc0e254","macAddress":"c8df845a335e"},{"id":"4ed45452-0bb9-4fd4-8f68-ee024da4445e","macAddress":"74e182117725"}],"userRoles":[{"userId":"d28cb52e-6144-4aac-8840-3ad3d21b8f06","roles":["owner"]}],"address":"8855 Washington Blvd ","city":"Culver City ","state":"AB","country":"ca","postalCode":"90232 ","timezone":"Canada/Mountain","gallonsPerDayGoal":50,"occupants":3,"stories":2,"isProfileComplete":true,"hasPastWaterDamage":true,"showerBathCount":2,"toiletCount":3,"nickname":"Second","irrigationSchedule":{"isEnabled":false},"systemMode":{},"locationType":"sfh","residenceType":"primary","waterSource":"utility","locationSize":"gt_700_ft_lte_1000_ft","waterShutoffKnown":"unsure","plumbingType":"unsure","indoorAmenities":[],"outdoorAmenities":["fountain"],"plumbingAppliances":["tankless_water_heater"],"pastWaterDamageClaimAmount":"gt_10k_usd_lte_50k_usd","notifications":{"criticalCount":12,"warningCount":9,"infoCount":3},"account":{"id":"69db4938-956b-44d2-8962-9cae0ff098b7"}}';
    final location = Location.fromJson(jsonString);
    print("${location}");
    expect(location.devices.first.id, "08b218c5-6cea-4f1c-8607-30063bc0e254");
    /*
    expect(response1.body, OauthToken((b) => b
      ..accessToken = ""
      ..refreshToken = ""
      ..expiresIn = 86400
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresAt = "2019-05-10T09:18:37.000Z"
      ..issuedAt = "2019-05-09T09:18:37.000Z"
      ..tokenType = "Bearer"
    ));
    */
  });

  test('should parse Location 2', () async {
    //final jsonString = await rootBundle.loadString('assets/location.json');
    final jsonString = '{"id":"1e981775-48ec-41ef-83a2-6e9cd38febc1","users":[{"id":"d28cb52e-6144-4aac-8840-3ad3d21b8f06"}],"devices":[{"id":"08b218c5-6cea-4f1c-8607-30063bc0e254","macAddress":"c8df845a335e"},{"id":"4ed45452-0bb9-4fd4-8f68-ee024da4445e","macAddress":"74e182117725"}],"userRoles":[{"userId":"d28cb52e-6144-4aac-8840-3ad3d21b8f06","roles":["owner"]}],"address":"8855 Washington Blvd ","city":"Culver City ","state":"AB","country":"ca","postalCode":"90232 ","timezone":"Canada/Mountain","gallonsPerDayGoal":50,"occupants":3,"stories":2,"isProfileComplete":true,"hasPastWaterDamage":true,"showerBathCount":2,"toiletCount":3,"nickname":"Second","irrigationSchedule":{"isEnabled":true},"systemMode":{},"locationType":"sfh","residenceType":"primary","waterSource":"utility","locationSize":"gt_700_ft_lte_1000_ft","waterShutoffKnown":"unsure","plumbingType":"unsure","indoorAmenities":[],"outdoorAmenities":["fountain"],"plumbingAppliances":["tankless_water_heater"],"pastWaterDamageClaimAmount":"gt_10k_usd_lte_50k_usd","notifications":{"criticalCount":12,"warningCount":9,"infoCount":3},"account":{"id":"69db4938-956b-44d2-8962-9cae0ff098b7"}}';
    final location = Location.fromJson(jsonString);
    print("${location}");
    expect(location.devices.first.id, "08b218c5-6cea-4f1c-8607-30063bc0e254");
    /*
    expect(response1.body, OauthToken((b) => b
      ..accessToken = ""
      ..refreshToken = ""
      ..expiresIn = 86400
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresAt = "2019-05-10T09:18:37.000Z"
      ..issuedAt = "2019-05-09T09:18:37.000Z"
      ..tokenType = "Bearer"
    ));
    */
  });

  test('should getLocation', () async {
    //final jsonString = await rootBundle.loadString('assets/location.json');
    final jsonString = '{"id":"1e981775-48ec-41ef-83a2-6e9cd38febc1","users":[{"id":"d28cb52e-6144-4aac-8840-3ad3d21b8f06"}],"devices":[{"id":"08b218c5-6cea-4f1c-8607-30063bc0e254","macAddress":"c8df845a335e"},{"id":"4ed45452-0bb9-4fd4-8f68-ee024da4445e","macAddress":"74e182117725"}],"userRoles":[{"userId":"d28cb52e-6144-4aac-8840-3ad3d21b8f06","roles":["owner"]}],"address":"8855 Washington Blvd ","city":"Culver City ","state":"AB","country":"ca","postalCode":"90232 ","timezone":"Canada/Mountain","gallonsPerDayGoal":50,"occupants":3,"stories":2,"isProfileComplete":true,"hasPastWaterDamage":true,"showerBathCount":2,"toiletCount":3,"nickname":"Second","irrigationSchedule":{"isEnabled":false},"systemMode":{},"locationType":"sfh","residenceType":"primary","waterSource":"utility","locationSize":"gt_700_ft_lte_1000_ft","waterShutoffKnown":"unsure","plumbingType":"unsure","indoorAmenities":[],"outdoorAmenities":["fountain"],"plumbingAppliances":["tankless_water_heater"],"pastWaterDamageClaimAmount":"gt_10k_usd_lte_50k_usd","notifications":{"criticalCount":12,"warningCount":9,"infoCount":3},"account":{"id":"69db4938-956b-44d2-8962-9cae0ff098b7"}}';
    final flo = Flo.create(ChopperClient(
      client: MockClient((req) async {
        return http.Response(jsonString, 200);
      }),
      baseUrl: "http://localhost",
      converter: BuiltValueConverter(),
      errorConverter: BuiltValueConverter(),
    ));

    final response1 = await flo.getLocation("", authorization: "");
    print("${response1.body}");
    /*
    expect(response1.body, OauthToken((b) => b
      ..accessToken = ""
      ..refreshToken = ""
      ..expiresIn = 86400
      ..userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
      ..expiresAt = "2019-05-10T09:18:37.000Z"
      ..issuedAt = "2019-05-09T09:18:37.000Z"
      ..tokenType = "Bearer"
    ));
    */
  });

  test('should filter flatMap', () async {
    final found = or(() => $([[1,2,3],[4,5,6]])
      .flatMap((it) => it)
      .onEach((it) => print("$it"))
      .firstWhere((it) => it == 4));
   
    expect(found, 4);
  });

  test('should not filter flatMap', () async {
    final found = or(() => $([[1,2,3],[4,5,6]])
      .flatMap((it) => it)
      .onEach((it) => print("$it"))
      .firstWhere((it) => it == 7));
   
    expect(found, null);
  });

  test('should filter map flatMap', () async {
    final Map<String, Location> locations = {
      "ffffffff-ffff-4fff-0000-fffffffffff0": Location.empty.rebuild((b) => b
          ..id="ffffffff-ffff-4fff-0000-fffffffffff0"
          ..nickname = "Main Home"
          ..address = "1225 Harvey Street, Seattle, WA 144"
          ..devices = ListBuilder([
            Device.empty.rebuild((it) => it
            ..id = "ffffffff-ffff-4fff-0000-fffffffffff0"
            ..macAddress = "fffffffffff0"
            ..nickname = "Main Device"
            ..installationPoint = "Home"
            ),
            Device.empty.rebuild((it) => it
            ..id = "ffffffff-ffff-4fff-0000-fffffffffff1"
            ..macAddress = "fffffffffff1"
            ..nickname = "Irrigation Device"
            ..installationPoint = "Irrigation"
            ),
          ])
          ),
        "ffffffff-ffff-4fff-1111-fffffffffff1": Location.empty.rebuild((b) => b
          ..id="ffffffff-ffff-4fff-1111-fffffffffff1"
          ..nickname = "AirBnB"
          ..address = "1225 Harvey Street, Seattle, WA 145"
          ),
        "ffffffff-ffff-4fff-2222-fffffffffff2": Location.empty.rebuild((b) => b
          ..id="ffffffff-ffff-4fff-2222-fffffffffff2"
          ..nickname = "Weekend house"
          ..address = "1225 Harvey Street, Seattle, WA 146"
          ..devices = ListBuilder([
            Device.empty.rebuild((it) => it
            ..id = "ffffffff-ffff-4fff-2222-fffffffffff0"
            ..macAddress = "fffffffffff0"
            ..nickname = "Main Device"
            ..installationPoint = "Living room"
            ),
            Device.empty.rebuild((it) => it
            ..id = "ffffffff-ffff-4fff-2222-fffffffffff1"
            ..macAddress = "fffffffffff1"
            ..nickname = "Roof Device"
            ..installationPoint = "Roof"
            ),
          ])
          ),
    };
    final device = or(() => $(locations.values)
      .onEach((location) => print("location.id: ${location.id}"))
      .flatMap((location) => location.devices ?? [])
      .onEach((device) => print("device: ffffffff-ffff-4fff-2222-fffffffffff1 ? ${device.id}"))
      .firstWhere((device) => device.id == "ffffffff-ffff-4fff-2222-fffffffffff1"));
   
    expect(device != null, true);
  });

  test('should parse AlertFeedbackFlow', () async {
    final parsed = AlertFeedbackFlow.fromJson(
        '''{
            "titleText": "In the future, should events like this send alerts?",
            "type": "list",
            "options": [
              {
                "property": "should_accept_as_normal",
                "displayText": "No",
                "sortOrder": 1,
                "value": true,
                "flow": {
                  "titleText": "Please select the option that best describes the source of the issue",
                  "type": "list",
                  "options": [
                    {
                      "property": "cause",
                      "displayText": "Irrigation",
                      "sortOrder": 0,
                      "value": 2,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Pool / Hot Tub",
                      "sortOrder": 1,
                      "value": 3,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Hose Bibb",
                      "sortOrder": 2,
                      "value": 4,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Other",
                      "sortOrder": 3,
                      "value": 1,
                      "flow": {
                        "titleText": "Please explain what caused this alert",
                        "type": "text",
                        "options": [
                          {
                            "property": "cause_other",
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              },
              {
                "property": "should_accept_as_normal",
                "displayText": "Yes",
                "sortOrder": 0,
                "value": false,
                "flow": {
                  "titleText": "Please select the option that best describes the source of the issue",
                  "type": "list",
                  "options": [
                    {
                      "property": "cause",
                      "displayText": "Plumbing Failure",
                      "sortOrder": 0,
                      "value": 5,
                      "flow": {
                        "titleText": "Please describe the plumbing failure",
                        "type": "list",
                        "options": [
                          {
                            "property": "plumbing_failure",
                            "displayText": "Cracked / Burst Pipe",
                            "sortOrder": 0,
                            "value": 2,
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          },
                          {
                            "property": "plumbing_failure",
                            "displayText": "Bad Connector / Supply Line",
                            "sortOrder": 1,
                            "value": 3,
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          },
                          {
                            "property": "plumbing_failure",
                            "displayText": "Sprinkler Head",
                            "sortOrder": 2,
                            "value": 4,
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          },
                          {
                            "property": "plumbing_failure",
                            "displayText": "Not Sure",
                            "sortOrder": 3,
                            "value": 0,
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          },
                          {
                            "property": "plumbing_failure",
                            "displayText": "Other",
                            "sortOrder": 4,
                            "value": 1,
                            "flow": {
                              "titleText": "Please explain what caused this alert",
                              "type": "text",
                              "options": [
                                {
                                  "property": "plumbing_failure_other",
                                  "flow": {
                                    "tag": "sleep_flow"
                                  }
                                }
                              ]
                            }
                          }
                        ]
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Toilet Flapper",
                      "sortOrder": 1,
                      "value": 6,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Pool / Hot Tub",
                      "sortOrder": 2,
                      "value": 3,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Hose Bibb",
                      "sortOrder": 3,
                      "value": 4,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Not Sure",
                      "sortOrder": 4,
                      "value": 0,
                      "flow": {
                        "tag": "sleep_flow"
                      }
                    },
                    {
                      "property": "cause",
                      "displayText": "Other",
                      "sortOrder": 5,
                      "value": 1,
                      "flow": {
                        "titleText": "Please explain what caused this alert",
                        "type": "text",
                        "options": [
                          {
                            "property": "cause_other",
                            "flow": {
                              "tag": "sleep_flow"
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
          ''');

    expect(parsed != null, true);
    print(parsed);
  });

  test('should parse Alarms', () async {
    final alarms = File('assets/alarms.json');
    final alarmsJson = await alarms.readAsString();
    final parsed = Alarms.fromJson(alarmsJson);
    expect(parsed != null, true);
    print(parsed);
  });

  test('should parse AlertFeedbackOption', () async {
    final jsonFile = File('assets/alert_feedback_option.json');
    final jsonString = await jsonFile.readAsString();
    final parsed = AlertFeedbackOption.fromJson(jsonString);
    expect(parsed != null, true);
    print(parsed);
  });

  test('should parse local time', () async {
    final tzf = File('assets/2019a.tzf');
    final timezoneData = await tzf.readAsBytes();
    timezone.initializeDatabase(timezoneData.toList());
    final taipei = timezone.getLocation('Asia/Taipei');

    final utcDate = DateTime.tryParse("2019-07-09T00:48:19Z");
    final taipeiDate = timezone.TZDateTime.from(utcDate, taipei);

    expect(taipeiDate.toString(), "2019-07-09 08:48:19.000+0800");
    
    /*
    final now = DateTime.now();
    final times = BuiltList<BuiltList<String>>([
      BuiltList<String>([ "0:48:19", "1:49:20" ]),
      BuiltList<String>([ "11:08:09", "11:35:12" ]),
      BuiltList<String>([ "18:08:09", "23:35:12" ]),
    ]);

    $(times)
      .flatMap((it) => it)
      //.onEach((it) => print(it))
      .map((it) => it.padLeft(8, '0'))
      .map((time) {
        final date = DateFormat('yyyy-MM-dd').format(now);
        final datetimeUtc = "${date}T${time}Z";
        return DateTime.tryParse(datetimeUtc);
      })
      .whereNotNull()
      //.map((datetime) => datetime.toLocal())
      .map((datetime) => timezone.TZDateTime.from(datetime, taipei))
      .onEach((it) => print("taipei: $it"))
      .toList();
    */
    /*
    final now = DateTime.now();
    print("${now.isUtc}");
    print("${now.toIso8601String()}");
    print("${now}");
    print("${now.toString()}");
    print("${now.timeZoneOffset}");
    print("${now.toUtc()}");
    print("${now.toLocal()}");
    print("${now.timeZoneName}");
    */
    //expect(device != null, true);
  });
  /*
  test('should parse device', () async {
    final deviceMap = {
      "fsTimestamp": {"seconds": 1563391003, "nanoseconds": 712000000},
      "connectivity": {"rssi": -43.0},
      "valveState": {"lastKnown": "opened"},
      "isConnected": true,
      "telemetry":
      {
        "current": {
          "tempF": 93.0,
          "fsTimestamp": {"seconds": 1563302342, "nanoseconds": 876000000},
          "temp": 92.0,
          "gpm": 0.0,
          "psi": 0.5,
          "updated": "2019-07-17T19:20:04Z"
        }
      },
      "systemMode": {
        "lastKnown": "home"
      },
      "deviceId": "74e182117725",
      "updated": "2019-07-17T19:15:01Z"
    };
    final Device device = serializers.deserializeWith<Device>(Device.serializer, deviceMap);
    print("${device}");
    final Device device2 = standardSerializers.deserializeWith<Device>(Device.serializer, deviceMap);
    print("${device2}");
  });
  test('should parse HealthTest', () async {
    final HealthTest healthTest = HealthTest.fromJson('{"roundId":"57df4c63-4460-4eba-831a-ad8aea3eb153","deviceId":"c8df845a335e","created":"2019-07-18T03:09:49Z","updated":"2019-07-18T03:09:53Z","startDate":"2019-07-18T03:09:52Z","endDate":"2019-07-18T03:09:53Z","status":"cancelled","startRawPayload":{"ack_topic":"home/device/c8df845a335e/v1/test-result/mvrzit/ack","data":{"event":"start","round_id":"57df4c63-4460-4eba-831a-ad8aea3eb153","start_pressure":0.6,"started_at":1563419392458},"device_id":"c8df845a335e","id":"82daa682-a909-11e9-98e7-76e27ce31c6f","test":"mvrzit","time":"2019-07-18T03:09:52Z"},"endRawPayload":{"ack_topic":"home/device/c8df845a335e/v1/test-result/mvrzit/ack","data":{"delta_pressure":0,"end_pressure":0.6,"ended_at":1563419393599,"event":"cancel","leak_type":-2,"round_id":"57df4c63-4460-4eba-831a-ad8aea3eb153"},"device_id":"c8df845a335e","id":"836fe01d-a909-11e9-98e7-76e27ce31c6f","test":"mvrzit","time":"2019-07-18T03:09:53Z"},"type":"manual","leakType":-2,"startPressure":0.6,"endPressure":0.6}');
    print("${healthTest}");
  });
  */
  test('should parse Map<String, dyanmic>', () async {
    final badMap = {
      "notification": {
        "title": null, "body": null
      },
      "data": {
        "id": "81d37902-fa58-11e9-b9a2-74e182118ff6", "ts": 1572359365534,
        "icd": {
          "device_id":"74e182118ff6","time_zone":"US\/Pacific","icd_id":"db32ac90-96bd-43d6-b2a0-66e5acf99e5b","system_mode":2
        },
        "version": 1,
        "notification": {
          "severity":2,"name":"low_water_pressure","description":"","alarm_id":15
        }
      }
    };
    final badPush = PushNotification.fromMap2(badMap);
    expect(badPush, PushNotification((b) => b
      ..notification = PendingPushNotification((b) => b).toBuilder()
      ..data = PushNotificationData((b) => b).toBuilder()
    ));


    final okMap = {
      "data": {
        "url": "floapp://alerts",
        "data": {
          "id": "81d37902-fa58-11e9-b9a2-74e182118ff6",
          "macAddress":"74e182118ff6",
          "icdId":"db32ac90-96bd-43d6-b2a0-66e5acf99e5b",
          "alarm": {
            "severity":"info","name":"low_water_pressure","description":"","id":15
          }
        }
      }
    };
    final expectedAlert = Alert((b) => b
      ..id = "81d37902-fa58-11e9-b9a2-74e182118ff6"
      ..macAddress = "74e182118ff6"
      ..icdId = "db32ac90-96bd-43d6-b2a0-66e5acf99e5b"
      ..alarm = Alarm((b) => b
        ..severity = "info"
        ..name = "low_water_pressure"
        ..id = 15
        ..description = ""
      ).toBuilder()
    );
    final push = PushNotification.fromMap2(okMap);
    expect(push, PushNotification((b) => b
      ..data = PushNotificationData((b) => b
        ..url = "floapp://alerts"
        ..data = JsonObject(expectedAlert.toMap())
      ).toBuilder()
    ));

    final alert = Alert.fromJsonObject(push.data.data);
    expect(alert, expectedAlert);
  });

  test('should parse PushNotification', () async {
    final Map<String, dynamic> okMap = {
      "notification": {},
      "data": {
        "collapse_key": "com.flotechnologies.preprod",
        "google.original_priority": "high",
        "google.sent_time": 1572565205196,
        "google.delivered_priority": "high",
        "FloAlarmNotification": {
          "notification": {
            "severity": 1,
            "name": "test Alarm Name",
            "alarm_id": 5
          },
          "id": "f4b49304-007d-4399-98ad-d150a0466d93",
          "icd": {
            "device_id": "h8ygy7ytgy7ygy7-huhghuhghyh-u",
            "time_zone": "Pacific",
            "icd_id": "ICDID bro",
            "system_mode": 2
          },
          "ts": "2017-02-08T05:10:18.866Z"
        },
        "google.ttl": 3,
        "from": 427332962033,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "google.message_id": "0: 1572565205211355 % 86938 db286938db2"
      }
    };
    final push = PushNotification.fromMap2(okMap);
    print(push);
    final data = Maps.get(okMap, 'data');
    print(data);
    final floAlarmNotificaation = Maps.get(data, 'FloAlarmNotification');
    print(floAlarmNotificaation);
    final alert1 = let(floAlarmNotificaation, (it) => Alert1.fromMap2(it));
    print(alert1);
    final alert2 = let(Maps.get<dynamic>(Maps.get<dynamic>(okMap, 'data'), 'FloAlarmNotification'), (it) => Alert1.fromMap2(it));
    print(alert2);
  });

  test('should orEmpty', () async {
    expect(orEmpty<int>(null), 0);
    expect(orEmpty<String>(null), "");
    expect(orEmpty<double>(null), 0.0);
    //expect(orEmpty<List<String>>(null), const <String>[]);
    //expect(orEmpty<Set<String>>(null), const <String>{});
    //expect(orEmpty<Iterable<String>>(null), const <String>[]);
    //expect(orEmpty<Map<int, String>>(null), const <int, String>{});
  });

  test('should map equal', () async {
    final eq = MapEquality();
    expect(eq.equals({"one": "one"}, {"one": "one"}), true);
    expect(eq.equals({"one": "one"}, {"one": "two"}), false);
    expect(eq.equals({"one": "one"}, {"one": 1}), false);
    expect(eq.equals({"one": "1"}, {"one": 1}), false);
  });

  /*
  test('should merge notifications', () async {
    final actual = Notifications((b) => b
        ..
    )
  });
  */
}
