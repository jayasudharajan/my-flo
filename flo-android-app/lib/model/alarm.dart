library alarm;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:superpower/superpower.dart';
import '../utils.dart';
import 'alarm_action.dart';
import 'alarm_option.dart';
import 'alert_action.dart';
import 'alert_feedback_flow.dart';
import 'alert_settings.dart';
import 'delivery_mediums.dart';
import 'serializers.dart';
import 'alert_feedback.dart';

part 'alarm.g.dart';

abstract class Alarm implements Built<Alarm, AlarmBuilder> {
  Alarm._();

  factory Alarm([updates(AlarmBuilder b)]) = _$Alarm;

  @nullable
  @BuiltValueField(wireName: 'id')
  int get id;
  @nullable
  @BuiltValueField(wireName: 'name')
  String get name;
  @nullable
  @BuiltValueField(wireName: 'text')
  String get text;
  @nullable
  @BuiltValueField(wireName: 'displayName')
  String get displayName;
  @nullable
  @BuiltValueField(wireName: 'description')
  String get description;
  @nullable
  @BuiltValueField(wireName: 'severity')
  String get severity;
  @nullable
  @BuiltValueField(wireName: 'isInternal')
  bool get isInternal;
  @nullable
  @BuiltValueField(wireName: 'isShutoff')
  bool get isShutoff;
  @nullable
  @BuiltValueField(wireName: 'triggersAlarm')
  Alarm get triggersAlarm;
  @nullable
  @BuiltValueField(wireName: 'actions')
  BuiltList<AlarmAction> get actions;
  Iterable<AlarmAction> get actionsSorted => $(actions).sortedBy((it) => it.sort ?? 0);
  @nullable
  @BuiltValueField(wireName: 'supportOptions')
  BuiltList<AlarmOption> get supportOptions;
  Iterable<AlarmOption> get supportOptionsSorted => $(supportOptions).sortedBy((it) => it.sort ?? 0);
  @nullable
  @BuiltValueField(wireName: 'active')
  bool get active;
  @nullable
  @BuiltValueField(wireName: 'children')
  BuiltList<Alarm> get children;
  @nullable
  @BuiltValueField(wireName: 'parent')
  Alarm get parent;
  @nullable
  @BuiltValueField(wireName: 'deliveryMedium')
  DeliveryMediums get deliveryMedium;
  @nullable
  @BuiltValueField(wireName: 'userFeedbackFlow')
  BuiltList<AlertFeedbackFlow> get userFeedbackFlows;
  @nullable
  @BuiltValueField(wireName: 'count')
  int get count;

  //AlertFeedbackFlow userFeedbackFlow(String systemMode) => or(() => userFeedbackFlows.firstWhere((it) => it.systemMode == systemMode));
  AlertFeedbackFlow userFeedbackFlow(String systemMode) => or(() => userFeedbackFlows.firstWhere((it) => it.systemMode == systemMode)) ?? or(() => userFeedbackFlows.first); // FIXME

  /// TODO
  /*
  AlertAction toAlertAction() {
    AlertAction()
  }
  */

  String toJson() {
    return json.encode(serializers.serializeWith(Alarm.serializer, this));
  }

  static Alarm fromJson(String jsonString) {
    return serializers.deserializeWith(
        Alarm.serializer, json.decode(jsonString));
  }

  static Serializer<Alarm> get serializer => _$alarmSerializer;
  static const String CRITICAL = "critical";
  static const String WARNING = "warning";
  static const String INFO = "info";
  static const Set<String> SEVERITIES = const {CRITICAL, WARNING, INFO};

  AlertSettings alertSettingsBySystemMode(@NonNull String systemMode) =>
      AlertSettings((b) => b
        ..alarmId = id
        ..smsEnabled = (deliveryMedium?.sms?.supported ?? false) ? (b?.smsEnabled ?? or(() => deliveryMedium?.sms?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode))?.enabled ?? false) : null
        ..emailEnabled = (deliveryMedium?.email?.supported ?? false) ? (b?.emailEnabled ?? or(() => deliveryMedium?.email?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode))?.enabled ?? false) : null
        ..pushEnabled = (deliveryMedium?.push?.supported ?? false) ? (b?.pushEnabled ?? or(() => deliveryMedium?.push?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode))?.enabled ?? false) : null
        ..callEnabled = (deliveryMedium?.call?.supported ?? false) ? (b?.callEnabled ?? or(() => deliveryMedium?.call?.defaultSettings?.firstWhere((it) => it?.systemMode == systemMode))?.enabled ?? false) : null
      );

  AlertSettings get alertSettings => AlertSettings((b) => b
    ..alarmId = id
    ..smsEnabled = (deliveryMedium?.sms?.supported ?? false) ? (b?.smsEnabled ?? false) : null
    ..emailEnabled = (deliveryMedium?.email?.supported ?? false) ? (b?.emailEnabled ?? false) : null
    ..pushEnabled = (deliveryMedium?.push?.supported ?? false) ? (b?.pushEnabled ?? false) : null
    ..callEnabled = (deliveryMedium?.call?.supported ?? false) ? (b?.callEnabled ?? false) : null
  );

  static const int SMALL_DRIP_ID_28 = 28;
  static const int SMALL_DRIP_ID_29 = 29;
  static const int SMALL_DRIP_ID_30 = 30;
  static const int SMALL_DRIP_ID_31 = 31;
  static const Set<int> SMALL_DRIP_IDS = {
    SMALL_DRIP_ID_28,
    SMALL_DRIP_ID_29,
    SMALL_DRIP_ID_30,
    SMALL_DRIP_ID_31,
  };

  bool get isSmallDrip => SMALL_DRIP_IDS.contains(id);

  Alarm operator+(Alarm it) {
    if (id != it.id) return this;
    //if (severity != it.severity) return this;

    return rebuild((b) => b
        ..count = (count ?? 0) + (it.count ?? 0)
    );
  }
}