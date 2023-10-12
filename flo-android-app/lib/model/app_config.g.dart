// GENERATED CODE - DO NOT MODIFY BY HAND

part of app_config;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AppConfig> _$appConfigSerializer = new _$AppConfigSerializer();

class _$AppConfigSerializer implements StructuredSerializer<AppConfig> {
  @override
  final Iterable<Type> types = const [AppConfig, _$AppConfig];
  @override
  final String wireName = 'AppConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, AppConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.minVersion != null) {
      result
        ..add('minVersion')
        ..add(serializers.serialize(object.minVersion,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  AppConfig deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AppConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'minVersion':
          result.minVersion = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$AppConfig extends AppConfig {
  @override
  final String minVersion;

  factory _$AppConfig([void Function(AppConfigBuilder) updates]) =>
      (new AppConfigBuilder()..update(updates)).build();

  _$AppConfig._({this.minVersion}) : super._();

  @override
  AppConfig rebuild(void Function(AppConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppConfigBuilder toBuilder() => new AppConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppConfig && minVersion == other.minVersion;
  }

  @override
  int get hashCode {
    return $jf($jc(0, minVersion.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AppConfig')
          ..add('minVersion', minVersion))
        .toString();
  }
}

class AppConfigBuilder implements Builder<AppConfig, AppConfigBuilder> {
  _$AppConfig _$v;

  String _minVersion;
  String get minVersion => _$this._minVersion;
  set minVersion(String minVersion) => _$this._minVersion = minVersion;

  AppConfigBuilder();

  AppConfigBuilder get _$this {
    if (_$v != null) {
      _minVersion = _$v.minVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AppConfig;
  }

  @override
  void update(void Function(AppConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AppConfig build() {
    final _$result = _$v ?? new _$AppConfig._(minVersion: minVersion);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
