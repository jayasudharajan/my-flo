
library alert;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:intl/intl.dart';
import '../utils.dart';
import 'alert_feedback_flow.dart';
import 'alert_feedbacks.dart';
import 'alert_firmware_value.dart';
import 'device.dart';
import 'health_test.dart';
import 'location.dart';
import 'serializers.dart';

import 'alarm.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'alert_feedback.dart';

part 'alert.g.dart';

abstract class Alert implements Built<Alert, AlertBuilder> {
  Alert._();

  factory Alert([updates(AlertBuilder b)]) = _$Alert;

  @nullable
  @BuiltValueField(wireName: 'id')
  String get id;
  @nullable
  @BuiltValueField(wireName: 'alarm')
  Alarm get alarm;

  @nullable
  @BuiltValueField(wireName: 'displayTitle')
  String get displayTitle;
  @nullable
  @BuiltValueField(wireName: 'displayMessage')
  String get displayMessage;
  @nullable
  @BuiltValueField(wireName: 'icdId')
  String get icdId;
  @nullable
  @BuiltValueField(wireName: 'macAddress')
  String get macAddress;
  @nullable
  @BuiltValueField(wireName: 'deviceId')
  String get deviceId;
  /// Alarm event status. Multiple filters are allowed. Allowed operators: eq, lt, let, gt, get.
  /// "status": "resolved|triggered"
  /// triggered - Alerts pending user feedback
  /// resolved - Resolved, reason will contain detail why
  @nullable
  @BuiltValueField(wireName: 'status')
  String get status;
  @nullable
  @BuiltValueField(wireName: 'reason')
  String get reason;
  /// "snoozeTo": "2019-08-23T18:09:05.242Z",
  @nullable
  @BuiltValueField(wireName: 'snoozeTo')
  String get snoozeTo;
  @nullable
  @BuiltValueField(wireName: 'fwValues')
  AlertFirmwareValue get firmwareValue;
  @nullable
  @BuiltValueField(wireName: 'userFeedback')
  BuiltList<AlertFeedbacks> get userFeedbacks;

  @nullable
  @BuiltValueField(wireName: 'locationId')
  String get locationId;
  @nullable
  @BuiltValueField(wireName: 'systemMode')
  String get systemMode;
  @nullable
  @BuiltValueField(wireName: 'updateAt')
  String get updateAt;
  @nullable
  @BuiltValueField(wireName: 'createAt')
  String get createAt;
  ///  it’s not visible until you call the alerts/action API
  ///   - the duration can be calculated after that.
  @nullable
  @BuiltValueField(wireName: 'resolvedAt')
  String get resolvedAt;
  @nullable
  @BuiltValueField(wireName: 'resolutionDate')
  String get resolutionDate;

  @nullable
  @BuiltValueField(wireName: 'healthTest')
  HealthTest get healthTest;

  /// Multiple filters are allowed.
  /// cleared - Cleared by user
  /// snoozed - User muted alert for some time
  /// cancelled - System clered the alert before user
  /// Available values : cleared, snoozed, cancelled
  @nullable
  @BuiltValueField(serialize: false)
  Location get location;

  @nullable
  @BuiltValueField(serialize: false)
  Device get device;

  static String dayInterceptorAgo(Duration duration, {DateTime since, bool fromNow: false}) {
    if (duration.inMinutes < 1) {
      final seconds = duration.inSeconds.remainder(60).round();
      if (seconds == 0) {
        return null;
      } else {
        return "${duration.inSeconds.remainder(60).round()}s ago";
      }
    } else if (duration.inHours < 1) {
      final seconds = duration.inSeconds.remainder(60).round();
      if (seconds == 0) {
        return "${duration.inMinutes.remainder(60).round()} mins ago";
      } else {
        return "${duration.inMinutes.remainder(60).round()} mins ${seconds} s ago";
      }
    } else if (duration.inHours < 3) { // >= 1hours
      final minutes = duration.inMinutes.remainder(60).round();
      if (minutes == 0) {
        return "${duration.inHours.remainder(24).round()} hrs ago";
      } else {
        return "${duration.inHours.remainder(24).round()} hrs ${minutes} mins ago";
      }
    } else if (duration.inDays <= 1 && since != null) {
      if (since.isAfter(DateTimes.today())) {
        return "Today, at ${DateFormat.jm().format(since).toLowerCase()}";
      } else {
        return "Yesterday, at ${DateFormat.jm().format(since).toLowerCase()}";
      }
    } else {
      if (since != null) {
        return "${DateFormat.MMMMd().format(since)} at ${DateFormat.jm().format(since).toLowerCase()}";
      } else {
        return null;
      }
    }
    return null;
  }

  static String dayInterceptor(Duration duration, {DateTime since}) {
    if (duration.inMinutes < 1) {
      final seconds = duration.inSeconds.remainder(60).round();
      if (seconds == 0) {
        return null;
      } else {
        return "${duration.inSeconds.remainder(60).round()}s";
      }
    } else if (duration.inHours < 1) {
      final seconds = duration.inSeconds.remainder(60).round();
      if (seconds == 0) {
        return "${duration.inMinutes.remainder(60).round()} mins";
      } else {
        return "${duration.inMinutes.remainder(60).round()} mins ${seconds} s";
      }
    } else if (duration.inHours < 3) { // >= 1hours
      final minutes = duration.inMinutes.remainder(60).round();
      if (minutes == 0) {
        return "${duration.inHours.remainder(24).round()} hrs";
      } else {
        return "${duration.inHours.remainder(24).round()} hrs ${minutes} mins";
      }
    } else if (duration.inDays <= 1 && since != null) {
      if (since.isAfter(DateTimes.today())) {
        return "Today, at ${DateFormat.jm().format(since).toLowerCase()}";
      } else {
        return "Yesterday, at ${DateFormat.jm().format(since).toLowerCase()}";
      }
    } else {
      if (since != null) {
        return "${DateFormat.MMMMd().format(since)} at ${DateFormat.jm().format(since).toLowerCase()}";
      } else {
        return null;
      }
    }
    return null;
  }

  DateTime get createAtDateTime => DateTimes.of(createAt, isUtc: true);
  DateTime get resolvedAtDateTime => DateTimes.of(resolvedAt, isUtc: true);
  DateTime get resolutionDateTime => DateTimes.of(resolutionDate, isUtc: true);
  Duration get duration => createAtDateTime.difference(resolvedAtDateTime);

  String get createAgo => timeago.format(createAtDateTime, until: resolvedAtDateTime, allowFromNow: true, intercept: dayInterceptorAgo);
  String get createAgoShort => timeago.format(createAtDateTime, until: resolvedAtDateTime, allowFromNow: true, locale: 'en_short', intercept: dayInterceptor);
  String get resolutionAgo => resolutionDate != null ? timeago.format(createAtDateTime, until: resolutionDateTime, allowFromNow: true, locale: 'en_duration') : null;
  /// Test: String get createAgo => timeago.format(DateTime.now().subtract(Duration(hours: 5)));
  //AlertFeedbackFlow get userFeedbackFlow => systemMode != null ? alarm.userFeedbackFlow(systemMode) : null;
  AlertFeedbackFlow get userFeedbackFlow => systemMode != null ? alarm.userFeedbackFlow(systemMode) : alarm.userFeedbackFlow(systemMode); // FIXME

  String toJson() {
    return json.encode(serializers.serializeWith(Alert.serializer, this));
  }

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Alert.serializer, this);
  }

  @nullable
  static Alert fromJson(String jsonString) {
    return or(() => serializers.deserializeWith(Alert.serializer, json.decode(jsonString)));
  }

  @nullable
  static Alert fromMap2(Map<String, dynamic> map) {
    return or(() => serializers.deserializeWith(Alert.serializer, map));
  }

  @nullable
  static Alert fromJsonObject(JsonObject jsonObject) {
    return or(() => serializers.deserializeWith(Alert.serializer, jsonObject.asMap));
  }

  @nullable
  static Alert from(dynamic value) {
    return as<Alert>(value) ??
        let(as<Map<String, dynamic>>(value), (it) => Alert.fromMap2(it)) ??
        let(as<JsonObject>(value), (it) => Alert.fromJsonObject(it)) ??
        let(as<String>(value), (it) => Alert.fromJson(it));
  }

  static Serializer<Alert> get serializer => _$alertSerializer;

  static const String CLEARED = "cleared";
  @deprecated
  static const String IGNORED = "ignored";
  static const String SNOOZED = "snoozed";
  static const String CANCELLED = "cancelled";
  //static const Set<String> REASONS = const {SNOOZED, CLEARED, IGNORED, CANCELLED};
  static const Set<String> REASONS = const {CLEARED, SNOOZED, CANCELLED};

  bool get isResolved => status != null ? status == RESOLVED : false;
  //bool get isPending => status != null ? status == TRIGGERED : false;
  bool get isPending => !isResolved;
  bool get isSmallDrip => alarm?.isSmallDrip ?? false;

  static const String RESOLVED = "resolved";
  static const String TRIGGERED = "triggered";
  static const String FILTERED = "filtered";

  static Alert empty = Alert();
  bool get isEmpty => this == empty;
}
