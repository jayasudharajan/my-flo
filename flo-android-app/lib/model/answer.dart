library answer;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'answer.g.dart';

@BuiltValueEnum(wireName: 'answer')
class Answer extends EnumClass {
  
  static Serializer<Answer> get serializer => _$answerSerializer;

  @BuiltValueEnumConst(wireName: 'yes')
  static const Answer yes = _$wireYes;

  @BuiltValueEnumConst(wireName: 'no')
  static const Answer no = _$wireNo;

  @BuiltValueEnumConst(wireName: 'unsure')
  static const Answer unsure = _$wireUnsure;

  const Answer._(String name) : super(name);

  static BuiltSet<Answer> get values => _$wireValues;
  static Answer valueOf(String name) => _$wireValueOf(name);
  static const String UNSURE = "unsure";
}