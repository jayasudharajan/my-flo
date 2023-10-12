library unit_system;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flotechnologies/generated/i18n.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import '../utils.dart';
import 'serializers.dart';

part 'unit_system.g.dart';

@BuiltValueEnum(wireName: 'unitSystem')
class UnitSystem extends EnumClass {
  
  static Serializer<UnitSystem> get serializer => _$unitSystemSerializer;

  @BuiltValueEnumConst(wireName: 'imperial_us')
  static const UnitSystem imperialUs = _$wireImperialUs;

  @BuiltValueEnumConst(wireName: 'metric_kpa')
  static const UnitSystem metricKpa = _$wireMetricKpa;

  @BuiltValueEnumConst(wireName: 'metric_bar')
  static const UnitSystem metricBar = _$wireMetricBar;

  const UnitSystem._(String name) : super(name);

  static BuiltSet<UnitSystem> get values => _$wireValues;
  static UnitSystem valueOf(String name) => _$wireValueOf(name);
  
  // UnitSystem.imperialUs.volumeText(context, value);
  String volumeText(material.BuildContext context, double value, {
    UnitSystem inUnit = imperialUs,
    UnitSystem outUnit,
    NumberFormat format,
    bool short = true,
  }) {
    outUnit ??= this;
    format ??= NumberFormat('#.#');
    return inUnit == imperialUs ? outUnit == imperialUs ? "${format.format(value)} ${short ? S.of(context).gal_ : S.of(context).gallons}" : "${format.format(toLiters(value))} ${S.of(context).liters}"
                                : outUnit == imperialUs ? "${format.format(toGallons(value))} ${short ? S.of(context).gal_ : S.of(context).gallons}" : "${format.format(value)} ${S.of(context).liters}";
  }

  String volumePmText(material.BuildContext context, double value, {
    UnitSystem inUnit = imperialUs,
    UnitSystem outUnit,
    NumberFormat format,
  }) {
    outUnit ??= this;
    format ??= NumberFormat('#.#');
    return inUnit == imperialUs ? outUnit == imperialUs ? "${format.format(value)} gpm" : "${format.format(toLiters(value))} lpm"
        : outUnit == imperialUs ? "${format.format(toGallons(value))} gpm" : "${format.format(value)} lpm";
  }
}