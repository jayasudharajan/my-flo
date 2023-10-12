// GENERATED CODE - DO NOT MODIFY BY HAND

part of locales;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Locales> _$localesSerializer = new _$LocalesSerializer();

class _$LocalesSerializer implements StructuredSerializer<Locales> {
  @override
  final Iterable<Type> types = const [Locales, _$Locales];
  @override
  final String wireName = 'Locales';

  @override
  Iterable<Object> serialize(Serializers serializers, Locales object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'locales',
      serializers.serialize(object.locales,
          specifiedType:
              const FullType(BuiltList, const [const FullType(Locale)])),
    ];

    return result;
  }

  @override
  Locales deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LocalesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'locales':
          result.locales.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Locale)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$Locales extends Locales {
  @override
  final BuiltList<Locale> locales;

  factory _$Locales([void Function(LocalesBuilder) updates]) =>
      (new LocalesBuilder()..update(updates)).build();

  _$Locales._({this.locales}) : super._() {
    if (locales == null) {
      throw new BuiltValueNullFieldError('Locales', 'locales');
    }
  }

  @override
  Locales rebuild(void Function(LocalesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LocalesBuilder toBuilder() => new LocalesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Locales && locales == other.locales;
  }

  @override
  int get hashCode {
    return $jf($jc(0, locales.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Locales')..add('locales', locales))
        .toString();
  }
}

class LocalesBuilder implements Builder<Locales, LocalesBuilder> {
  _$Locales _$v;

  ListBuilder<Locale> _locales;
  ListBuilder<Locale> get locales =>
      _$this._locales ??= new ListBuilder<Locale>();
  set locales(ListBuilder<Locale> locales) => _$this._locales = locales;

  LocalesBuilder();

  LocalesBuilder get _$this {
    if (_$v != null) {
      _locales = _$v.locales?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Locales other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Locales;
  }

  @override
  void update(void Function(LocalesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Locales build() {
    _$Locales _$result;
    try {
      _$result = _$v ?? new _$Locales._(locales: locales.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'locales';
        locales.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Locales', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
