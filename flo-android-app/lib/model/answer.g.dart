// GENERATED CODE - DO NOT MODIFY BY HAND

part of answer;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Answer _$wireYes = const Answer._('yes');
const Answer _$wireNo = const Answer._('no');
const Answer _$wireUnsure = const Answer._('unsure');

Answer _$wireValueOf(String name) {
  switch (name) {
    case 'yes':
      return _$wireYes;
    case 'no':
      return _$wireNo;
    case 'unsure':
      return _$wireUnsure;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<Answer> _$wireValues = new BuiltSet<Answer>(const <Answer>[
  _$wireYes,
  _$wireNo,
  _$wireUnsure,
]);

Serializer<Answer> _$answerSerializer = new _$AnswerSerializer();

class _$AnswerSerializer implements PrimitiveSerializer<Answer> {
  static const Map<String, String> _toWire = const <String, String>{
    'yes': 'yes',
    'no': 'no',
    'unsure': 'unsure',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'yes': 'yes',
    'no': 'no',
    'unsure': 'unsure',
  };

  @override
  final Iterable<Type> types = const <Type>[Answer];
  @override
  final String wireName = 'answer';

  @override
  Object serialize(Serializers serializers, Answer object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  Answer deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Answer.valueOf(_fromWire[serialized] ?? serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
