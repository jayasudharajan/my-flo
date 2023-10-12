library serializers;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import '../utils.dart';
import 'alert1.dart';
import 'alert1_notification.dart';
import 'alert_action.dart';
import 'alert_feedbacks.dart';
import 'alert_firmware_value.dart';
import 'alert_settings.dart';
import 'alert_statistics.dart';
import 'api_config.dart';
import 'api_configs.dart';
import 'app_config.dart';
import 'config.dart';
import 'device_alerts_settings.dart';
import 'alerts_settings.dart';
import 'delivery_medium.dart';
import 'delivery_medium_settings.dart';
import 'delivery_mediums.dart';
import 'device_item.dart';
import 'estimate_water_usage.dart';
import 'alert_feedback_step.dart';
import 'alert_feedback_flow_tags.dart';
import 'fixture.dart';
import 'flo_detect.dart';
import 'flo_detect_event.dart';
import 'flo_detect_events.dart';
import 'flo_detect_feedback.dart';
import 'flo_detect_feedback_payload.dart';
import 'health_tests.dart';
import 'icd.dart';
import 'map_result.dart';
import 'firmware_properties_result.dart';
import 'pending_push_notification.dart';
import 'puck_ticket.dart';
import 'push_notification.dart';
import 'push_notification_data.dart';
import 'push_notification_token.dart';
import 'scan_result.dart';
import 'string_items.dart';
import 'subscription_provider.dart';
import 'alert_feedback.dart';
import 'alert_feedback_flow.dart';
import 'alert_feedback_option.dart';
import 'water_usage_aggregations.dart';
import 'alarm.dart';
import 'alarm_action.dart';
import 'alert.dart';
import 'alerts.dart';
import 'alarm_option.dart';
import 'alarms.dart';
import 'app_info.dart';
import 'certificate2.dart';
import 'change_password.dart';
import 'firmware_properties.dart';
import 'health_test.dart';
import 'irrigation_schedule.dart';
import 'learning.dart';
import 'link_device_payload.dart';
import 'magic_link_payload.dart';
import 'name.dart';
import 'onboarding.dart';
import 'pending_system_mode.dart';
import 'registration_payload.dart';
import 'target.dart';
import 'token.dart';
import 'water_usage.dart';
import 'water_usage_averages.dart';
import 'water_usage_averages_aggregations.dart';
import 'water_usage_item.dart';
import 'water_usage_params.dart';
import 'duration_value.dart';
import 'weekday_averages.dart';
import 'wifi_station.dart';
import 'wifi_station_jsonrpc.dart';
import 'account.dart';
import 'account_role.dart';
import 'amenity.dart';
import 'certificate.dart';
import 'connectivity.dart';
import 'device.dart';
import 'email_payload.dart';
import 'email_status.dart';
import 'email_status2.dart';
import 'hardware_thresholds.dart';
import 'install_status.dart';
import 'item_list.dart';
import 'location_role.dart';
import 'location.dart';
import 'location_payload.dart';
import 'location_size.dart';
import 'notifications.dart';
import 'oauth_token.dart';
import 'oauth_payload.dart';
import 'past_water_damage_claim_amount.dart';
import 'plumbing_type.dart';
import 'residence_type.dart';
import 'response_error.dart';
import 'schedule.dart';
import 'subscription.dart';
import 'system_mode.dart';
import 'telemetries.dart';
import 'telemetry2.dart';
import 'threshold.dart';
import 'ticket.dart';
import 'ticket2.dart';
import 'ticket_data.dart';
import 'timezone.dart';
import 'locale.dart';
import 'locales.dart';
import 'region.dart';
import 'magic_link_payload.dart';
import 'user.dart';
import 'registration_payload2.dart';
import 'user_role.dart';
import 'id.dart';
import 'valve.dart';
import 'verify_payload.dart';
import 'logout_payload.dart';
import 'location_type.dart';
import 'answer.dart';

import 'certificates.dart';
import 'certificates_jsonrpc.dart';
import 'jsonrpc_response.dart';
import 'jsonrpc_response_bool.dart';
import 'jsonrpc_wifi_response.dart';
import 'jsonrpc.dart';
import 'token_jsonrpc.dart';
import 'token_params.dart';
import 'wifi.dart';
import 'unit_system.dart';
import 'items.dart';
import 'item.dart';
import 'package:built_value/src/big_int_serializer.dart';
import 'package:built_value/src/date_time_serializer.dart';
import 'package:built_value/src/duration_serializer.dart';
import 'package:built_value/src/int64_serializer.dart';
import 'package:built_value/src/json_object_serializer.dart';
import 'package:built_value/src/num_serializer.dart';
import 'package:built_value/src/uri_serializer.dart';
import 'package:built_value/src/bool_serializer.dart';
import 'package:built_value/src/built_list_multimap_serializer.dart';
import 'package:built_value/src/built_list_serializer.dart';
import 'package:built_value/src/built_map_serializer.dart';
import 'package:built_value/src/built_set_multimap_serializer.dart';
import 'package:built_value/src/built_set_serializer.dart';
import 'package:built_value/src/double_serializer.dart';
import 'package:built_value/src/int_serializer.dart';
import 'package:built_value/src/regexp_serializer.dart';


import 'dart:convert' show json;

import 'water_source.dart';

part 'serializers.g.dart';

final builtSerialiers = (SerializersBuilder()
  ..add(BigIntSerializer())
  ..add(BoolSerializer())
  ..add(BuiltListSerializer())
  ..add(BuiltListMultimapSerializer())
  ..add(BuiltMapSerializer())
  ..add(BuiltSetSerializer())
  ..add(BuiltSetMultimapSerializer())
  ..add(DateTimeSerializer())
  ..add(DoubleSerializer())
  ..add(DurationSerializer())
  ..add(IntSerializer())
  ..add(Int64Serializer())
  ..add(JsonObjectSerializer())
  ..add(NumSerializer())
  ..add(RegExpSerializer())
//..add(StringSerializer())
  ..add(UriSerializer())
  ..addBuilderFactory(const FullType(BuiltList, [FullType.object]),
          () => ListBuilder<Object>())
  ..addBuilderFactory(
      const FullType(
          BuiltListMultimap, [FullType.object, FullType.object]),
          () => ListMultimapBuilder<Object, Object>())
  ..addBuilderFactory(
      const FullType(BuiltMap, [FullType.object, FullType.object]),
          () => MapBuilder<Object, Object>())
  ..addBuilderFactory(const FullType(BuiltSet, [FullType.object]),
          () => SetBuilder<Object>())
  ..addBuilderFactory(
      const FullType(
          BuiltSetMultimap, [FullType.object, FullType.object]),
          () => SetMultimapBuilder<Object, Object>()))
.build();

class SimpleStringSerializer implements PrimitiveSerializer<String> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([String]);
  @override
  final String wireName = 'String';

  @override
  Object serialize(Serializers serializers, String string,
      {FullType specifiedType = FullType.unspecified}) {
    return string;
  }

  @override
  String deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    try {
      return as<String>(serialized) ?? serialized?.toString();
    } catch (err) {
      //Fimber.e("", ex: err);
      print("$err : ${as<Error>(err).stackTrace}");
    }
    return null;
  }
}

@SerializersFor(const [
  OauthToken,
  OauthPayload,
  RegistrationPayload,
  RegistrationPayload2,
  EmailStatus,
  EmailStatus2,
  EmailPayload,
  Locale,
  Locales,
  TimeZone,
  Region,
  MagicLinkPayload,
  User,
  UserRole,
  Location,
  Id,
  LocationRole,
  Account,
  AccountRole,
  VerifyPayload,
  LocationPayload,
  LogoutPayload,
  PlumbingType,
  LocationType,
  LocationSize,
  ResidenceType,
  WaterSource,
  Answer,
  PastWaterDamageClaimAmount,
  SystemMode,
  Amenity,
  Ticket,
  TicketData,
  Ticket2,
  Certificate,
  Valve,
  FirmwareProperties,
  Device,
  PendingSystemMode,
  LinkDevicePayload,
  UnitSystem,
  Items,
  ItemList,
  Item,
  ResponseError,
  JsonRpc,
  JsonRpcResponse,
  JsonRpcWifiResponse,
  JsonRpcResponseBool,
  TokenJsonRpc,
  WifiStation,
  WifiStationJsonRpc,
  CertificatesJsonRpc,
  Threshold,
  HardwareThresholds,
  Connectivity,
  IrrigationSchedule,
  Schedule,
  Notifications,
  Telemetries,
  Telemetry2,
  InstallStatus,
  Token,
  ChangePassword,
  WaterUsage,
  WaterUsageParams,
  WaterUsageItem,
  AppInfo,
  Learning,
  WaterUsageAggregations,
  WaterUsageAveragesAggregations,
  WaterUsageAverages,
  WeekdayAverages,
  DurationValue,
  Target,
  Certificate2,
  Alarm,
  AlarmAction,
  AlarmOption,
  Alert,
  Alarms,
  Alerts,
  Onboarding,
  Name,
  AlertsSettings,
  AlertSettings,
  DeviceAlertsSettings,
  DeliveryMedium,
  DeliveryMediums,
  DeliveryMediumSettings,
  EstimateWaterUsage,
  Subscription,
  SubscriptionProvider,
  HealthTests,
  AlertFirmwareValue,
  AlertFeedback,
  AlertFeedbacks,
  AlertFeedbackFlow,
  AlertFeedbackOption,
  AlertFeedbackStep,
  AlertFeedbackFlowTags,
  AlertAction,
  Fixture,
  FloDetect,
  FloDetectEvent,
  FloDetectEvents,
  FloDetectFeedback,
  FloDetectFeedbackPayload,
  AlertStatistics,
  StringItems,
  PushNotificationToken,
  Config,
  AppConfig,
  ApiConfig,
  ApiConfigs,
  ScanResult,
  MapResult,
  PuckTicket,
  FirmwarePropertiesResult,
  DeviceItem,
  PushNotification,
  PushNotificationData,
  PendingPushNotification,
  Alert1,
  Alert1Notification,
  Icd,
])
//final Serializers serializers = _$serializers;
final Serializers serializers = (_$serializers.toBuilder()
..add(SimpleIntSerializer())
..add(SimpleDoubleSerializer())
..add(SimpleStringSerializer())
..addPlugin(JsonPlugin())
//..add(ListSerializer<AlertFeedback>())
//..add(ListSerializer<AlertFeedbackOption>())
..add(ObjectSerializer())
..addBuilderFactory(
    const FullType(BuiltMap, const [
      const FullType(String),
      const FullType(BuiltList, const [const FullType(Item)])
    ]),
    () => new MapBuilder<String, BuiltList<Item>>())
..addBuilderFactory(const FullType(BuiltList, const [const FullType(Item)]),
    () => new ListBuilder<Item>())
..addBuilderFactory(const FullType(BuiltList, const [
      const FullType(BuiltList, const [const FullType(String)])
    ]),
    () => new ListBuilder<BuiltList<String>>())
).build();

/// Switches to "standard" JSON format.
///
/// The default serialization format is more powerful, with better performance
/// and support for more collection types. But, you may need to interact with
/// other systems that use simple map-based JSON. If so, use
/// [SerializersBuilder.addPlugin] to install this plugin.
///
/// When using this plugin you may wish to also install
/// `Iso8601DateTimeSerializer` which switches serialization of `DateTime`
/// from microseconds since epoch to ISO 8601 format.
class JsonPlugin implements SerializerPlugin {
  static final BuiltSet<Type> _unsupportedTypes =
      BuiltSet<Type>([BuiltListMultimap, BuiltSetMultimap]);

  /// The field used to specify the value type if needed. Defaults to `$`.
  final String discriminator;

  // The key used when there is just a single value, for example if serializing
  // an `int`.
  final String valueKey;

  JsonPlugin({this.discriminator = r'$', this.valueKey = ''});

  @override
  Object beforeSerialize(Object object, FullType specifiedType) {
    if (_unsupportedTypes.contains(specifiedType.root)) {
      throw ArgumentError(
          'Standard JSON cannot serialize type ${specifiedType.root}.');
    }
    return object;
  }

  @override
  Object afterSerialize(Object object, FullType specifiedType) {
    //print(object);
    if (object is List &&
        specifiedType.root != BuiltList &&
        specifiedType.root != BuiltSet &&
        specifiedType.root != JsonObject) {
      if (specifiedType.isUnspecified) {
        //if (!(object is BuiltList) && object.first == "list_t") {
        //  return object.sublist(1);
        //}
        return _toMapWithDiscriminator(object);
      } else {
        return _toMap(object, _needsEncodedKeys(specifiedType));
      }
    } else {
      return object;
    }
  }

  @override
  Object beforeDeserialize(Object object, FullType specifiedType) {
    if (object is Map && specifiedType.root != JsonObject) {
      if (specifiedType.isUnspecified) {
        return _toListUsingDiscriminator(object);
      } else {
        return _toList(object, _needsEncodedKeys(specifiedType));
      }
    } else {
      return object;
    }
  }

  @override
  Object afterDeserialize(Object object, FullType specifiedType) {
    return object;
  }

  /// Returns whether a type has keys that aren't supported by JSON maps; this
  /// only applies to `BuiltMap` with non-String keys.
  bool _needsEncodedKeys(FullType specifiedType) =>
      specifiedType.root == BuiltMap &&
      specifiedType.parameters[0].root != String;

  /// Converts serialization output, a `List`, to a `Map`, when the serialized
  /// type is known statically.
  Map _toMap(List list, bool needsEncodedKeys) {
    print("${list}");
    var result = <String, Object>{};
    for (int i = 0; i != list.length ~/ 2; ++i) {
      final key = list[i * 2];
      final value = list[i * 2 + 1];
      result[needsEncodedKeys ? _encodeKey(key) : key as String] = value;
    }
    return result;
  }

  /// Converts serialization output, a `List`, to a `Map`, when the serialized
  /// type is not known statically. The type will be specified in the
  /// [discriminator] field.
  Map _toMapWithDiscriminator(List list) {
    var type = list[0];

    if (type == 'list') {
      // Embed the list in the map.
      return <String, Object>{discriminator: type, valueKey: list.sublist(1)};
    }

    // Length is at least two because we have one entry for type and one for
    // the value.
    if (list.length == 2) {
      // Just a type and a primitive value. Encode the value in the map.
      return <String, Object>{discriminator: type, valueKey: list[1]};
    }

    // If a map has non-String keys then they need encoding to strings before
    // it can be converted to JSON. Because we don't know the type, we also
    // won't know the type on deserialization, and signal this by changing the
    // type name on the wire to `encoded_map`.
    var needToEncodeKeys = false;
    if (type == 'map') {
      for (int i = 0; i != (list.length - 1) ~/ 2; ++i) {
        if (list[i * 2 + 1] is! String) {
          needToEncodeKeys = true;
          type = 'encoded_map';
          break;
        }
      }
    }

    var result = <String, Object>{};
    for (int i = 0; i != (list.length - 1) ~/ 2; ++i) {
      final key = needToEncodeKeys
          ? _encodeKey(list[i * 2 + 1])
          : list[i * 2 + 1] as String;
      final value = list[i * 2 + 2];
      result[key] = value;
    }
    return result;
  }

  /// JSON-encodes an `Object` key so it can be stored as a `String`. Needed
  /// because JSON maps are only allowed strings as keys.
  String _encodeKey(Object key) {
    return json.encode(key);
  }

  /// Converts [JsonPlugin] serialization output, a `Map`, to a `List`,
  /// when the serialized type is known statically.
  List _toList(Map map, bool hasEncodedKeys) {
    var result = List(map.length * 2);
    var i = 0;
    map.forEach((key, value) {
      // Drop null values, they are represented by missing keys.
      if (value == null) return;

      result[i] = hasEncodedKeys ? _decodeKey(key as String) : key;
      result[i + 1] = value;
      i += 2;
    });
    return result;
  }

  /// Converts [JsonPlugin] serialization output, a `Map`, to a `List`,
  /// when the serialized type is not known statically. The type is retrieved
  /// from the [discriminator] field.
  List _toListUsingDiscriminator(Map map) {
    var type = map[discriminator];

    if (type == null) {
      throw ArgumentError('Unknown type on deserialization. '
          'Need either specifiedType or discriminator field.');
    }

    if (type == 'list') {
      return [type]..addAll(map[valueKey] as Iterable);
    }

    if (map.containsKey(valueKey)) {
      // Just a type and a primitive value. Retrieve the value in the map.
      final result = List(2);
      result[0] = type;
      result[1] = map[valueKey];
      return result;
    }

    // A type name of `encoded_map` indicates that the map has non-String keys
    // that have been serialized and JSON-encoded; decode the keys when
    // converting back to a `List`.
    var needToDecodeKeys = type == 'encoded_map';
    if (needToDecodeKeys) {
      type = 'map';
    }

    var result = List(map.length * 2 - 1);
    result[0] = type;

    var i = 1;
    map.forEach((key, value) {
      if (key == discriminator) return;

      // Drop null values, they are represented by missing keys.
      if (value == null) return;

      result[i] = needToDecodeKeys ? _decodeKey(key as String) : key;
      result[i + 1] = value;
      i += 2;
    });
    return result;
  }

  /// JSON-decodes a `String` encoded using [_encodeKey].
  Object _decodeKey(String key) {
    return json.decode(key);
  }
}

class ListSerializer<T> implements StructuredSerializer<List<T>> {
  final bool structured = true;
  @override
  final Iterable<Type> types =
  BuiltList<Type>([List, List<T>().runtimeType]);
  @override
  final String wireName = 'list_t';

  @override
  Iterable serialize(Serializers serializers, List<T> iterable,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);

    if (specifiedType.parameters.isEmpty) {
      return serializers.serialize(BuiltList<T>(iterable), specifiedType: FullType(BuiltList, [FullType(T)]));
    }

    return iterable
        .map((item) => serializers.serialize(item, specifiedType: specifiedType.parameters[0]));
  }

  @override
  List<T> deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    var elementType = specifiedType.parameters.isEmpty
        ? FullType(T)
        : specifiedType.parameters[0];

    ListBuilder result = isUnderspecified
        ? ListBuilder<T>()
        : serializers.newBuilder(specifiedType) as ListBuilder;

    result.replace(serialized.map(
            (item) => serializers.deserialize(item, specifiedType: elementType)));
    return result.build().map((it) => as<T>(it));
  }
}

class ObjectSerializer implements PrimitiveSerializer<Object> {
  @override
  final Iterable<Type> types =
  BuiltList<Type>([Object, Object().runtimeType]);
  @override
  final String wireName = 'object';

  @override
  Object serialize(Serializers serializers, Object it,
      {FullType specifiedType = FullType.unspecified}) {

    return it;
  }

  @override
  Object deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    var isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;

    return serialized;
  }
}

class SimpleIntSerializer implements PrimitiveSerializer<int> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([int]);
  @override
  final String wireName = 'int';

  @override
  Object serialize(Serializers serializers, int integer,
      {FullType specifiedType = FullType.unspecified}) {
    return integer;
  }

  @override
  int deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    //return as<int>(serialized) ?? int.tryParse(serialized) ?? 0;
    return or(() => Ints.toInt(serialized));
  }
}

class SimpleDoubleSerializer implements PrimitiveSerializer<double> {
  // Constant names match those in [double].
  // ignore_for_file: non_constant_identifier_names
  static final String nan = 'NaN';
  static final String infinity = 'INF';
  static final String negativeInfinity = '-INF';

  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([double]);
  @override
  final String wireName = 'double';

  @override
  Object serialize(Serializers serializers, double aDouble,
      {FullType specifiedType = FullType.unspecified}) {
    if (aDouble.isNaN) {
      return nan;
    } else if (aDouble.isInfinite) {
      return aDouble.isNegative ? negativeInfinity : infinity;
    } else {
      return aDouble;
    }
  }

  @override
  double deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    if (serialized == nan) {
      return double.nan;
    } else if (serialized == negativeInfinity) {
      return double.negativeInfinity;
    } else if (serialized == infinity) {
      return double.infinity;
    } else {
      return as<num>(serialized)?.toDouble();
    }
  }
}
