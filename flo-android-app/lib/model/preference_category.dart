library preference_category;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'item.dart';

part 'preference_category.g.dart';

abstract class PreferenceCategory
    implements Built<PreferenceCategory, PreferenceCategoryBuilder> {
  PreferenceCategory._();

  factory PreferenceCategory(
      [updates(PreferenceCategoryBuilder b)]) = _$PreferenceCategory;

  @nullable
  BuiltList<Item> get prv;
  @nullable
  BuiltList<Item> get pipeType;

  /// Fixtures
  @nullable
  BuiltList<Item> get fixtureIndoor;
  /// Fixtures
  @nullable
  BuiltList<Item> get fixtureOutdoor;
  /// Fixtures
  @nullable
  BuiltList<Item> get homeAppliance;

  @nullable
  BuiltList<Item> get irrigationType;
  @nullable
  BuiltList<Item> get locationSize;

  @nullable
  BuiltList<Item> get residenceType;
}