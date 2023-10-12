library water_usage;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:superpower/superpower.dart';
import '../utils.dart';
import 'water_usage_aggregations.dart';
import 'serializers.dart';
import 'water_usage_item.dart';
import 'water_usage_params.dart';

part 'water_usage.g.dart';

abstract class WaterUsage implements Built<WaterUsage, WaterUsageBuilder> {
  WaterUsage._();

  factory WaterUsage([updates(WaterUsageBuilder b)]) = _$WaterUsage;

  @nullable
  @BuiltValueField(wireName: 'params')
  WaterUsageParams get params;
  @nullable
  @BuiltValueField(wireName: 'items')
  BuiltList<WaterUsageItem> get items;
  @nullable
  @BuiltValueField(wireName: 'aggregations')
  WaterUsageAggregations get aggregations;

  bool get isNotEmpty => ($(items ?? <WaterUsageItem>[]).where((it) => it.time != null).distinctBy((it) => it.time).where((it) => it.datetime != null).isNotEmpty ?? false) && (itemsSorted?.any((it) => it.gallonsConsumed != 0) ?? false);
  bool get isEmpty => !isNotEmpty;

  BuiltList<WaterUsageItem> get itemsSorted => BuiltList<WaterUsageItem>( // TODO: optimize
      $(items ?? <WaterUsageItem>[])
      .where((it) => it.time != null)
      .map((it) => it.rebuild((b) => b..time = it.datetime?.toIso8601String()))
      .where((it) => it.time != null)
      .distinctBy((it) => it.time)
      .sortedBy((it) => it.datetime)
  );

  BuiltList<WaterUsageItem> get hours {
    final itemsMap = Maps.fromIterable2<DateTime, WaterUsageItem>(itemsSorted.where((it) => it.time != null), key: (it) => DateTimes.hour(it.datetime));
    final item = or(() => itemsMap.values.first) ?? WaterUsageItem((b) => b
      ..time = DateTimes.today().toIso8601String()
      ..gallonsConsumed = 0
    );

    DateTimes.hours(item.datetime).forEach((it) =>
        itemsMap.putIfAbsent(it, () => WaterUsageItem((b) => b
          ..time = it.toIso8601String()
          ..gallonsConsumed = 0
        ))
    );
    final hrs = BuiltList<WaterUsageItem>($(itemsMap.values ?? <WaterUsageItem>[])
        .where((it) => it.datetime != null)
        .sortedBy((it) => it.datetime));

    //Fimber.d("hrs: $hrs");
    return hrs;
  }

  BuiltList<WaterUsageItem> weekdays(int weekday) {
    final itemsMap = Maps.fromIterable2<DateTime, WaterUsageItem>(itemsSorted.where((it) => it.time != null), key: (it) => DateTimes.today(from: it.datetime));
    final item = or(() => itemsMap.values.first) ?? WaterUsageItem((b) => b
      ..time = DateTimes.lastWeekday(weekday).toIso8601String()
      ..gallonsConsumed = 0
    );
    DateTimes.weekdays(DateTimes.today(from: item.datetime)).forEach((it) =>
      itemsMap.putIfAbsent(it, () => WaterUsageItem((b) => b
      ..time = it.toIso8601String()
      ..gallonsConsumed = 0
      ))
    );
    return BuiltList<WaterUsageItem>($(itemsMap.values ?? <WaterUsageItem>[])
        .where((it) => it.datetime != null)
        .sortedBy((it) => it.datetime));
  }


  // TODO: optimize
  double get total => aggregations?.sumTotalGallonsConsumed ?? $(items ?? const <WaterUsageItem>[]).sumBy((it) => it.gallonsConsumed ?? 0.0) ?? 0.0;

  WaterUsage merge(WaterUsage it) =>
    it != null ? rebuild((b) => b
      ..items = ListBuilder(
          Maps.reduce<String, WaterUsageItem>(
              Maps.fromIterable2(items, key: (item) => item.time),
              Maps.fromIterable2(it.items, key: (item) => item.time),
              reduce: (that, it) => that + it
          ).values
      )
      ..aggregations = aggregations != null ? (aggregations + it.aggregations).toBuilder() : it.aggregations
    ) : this;

  WaterUsage operator +(WaterUsage it) => merge(it);

  WaterUsage operator *(int value) => List.generate(value, (it) => this).reduce((that, it) => that + it);

  String toJson() {
    return json.encode(serializers.serializeWith(WaterUsage.serializer, this));
  }

  static WaterUsage fromJson(String jsonString) {
    return serializers.deserializeWith(
        WaterUsage.serializer, json.decode(jsonString));
  }

  static Serializer<WaterUsage> get serializer => _$waterUsageSerializer;

  static WaterUsage empty = WaterUsage();
}
