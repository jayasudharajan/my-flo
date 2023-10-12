// GENERATED CODE - DO NOT MODIFY BY HAND

part of app_info;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AppInfo> _$appInfoSerializer = new _$AppInfoSerializer();

class _$AppInfoSerializer implements StructuredSerializer<AppInfo> {
  @override
  final Iterable<Type> types = const [AppInfo, _$AppInfo];
  @override
  final String wireName = 'AppInfo';

  @override
  Iterable<Object> serialize(Serializers serializers, AppInfo object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'appName',
      serializers.serialize(object.appName,
          specifiedType: const FullType(String)),
      'appVersion',
      serializers.serialize(object.appVersion,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  AppInfo deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new AppInfoBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'appName':
          result.appName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'appVersion':
          result.appVersion = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$AppInfo extends AppInfo {
  @override
  final String appName;
  @override
  final String appVersion;

  factory _$AppInfo([void Function(AppInfoBuilder) updates]) =>
      (new AppInfoBuilder()..update(updates)).build();

  _$AppInfo._({this.appName, this.appVersion}) : super._() {
    if (appName == null) {
      throw new BuiltValueNullFieldError('AppInfo', 'appName');
    }
    if (appVersion == null) {
      throw new BuiltValueNullFieldError('AppInfo', 'appVersion');
    }
  }

  @override
  AppInfo rebuild(void Function(AppInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppInfoBuilder toBuilder() => new AppInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppInfo &&
        appName == other.appName &&
        appVersion == other.appVersion;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, appName.hashCode), appVersion.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AppInfo')
          ..add('appName', appName)
          ..add('appVersion', appVersion))
        .toString();
  }
}

class AppInfoBuilder implements Builder<AppInfo, AppInfoBuilder> {
  _$AppInfo _$v;

  String _appName;
  String get appName => _$this._appName;
  set appName(String appName) => _$this._appName = appName;

  String _appVersion;
  String get appVersion => _$this._appVersion;
  set appVersion(String appVersion) => _$this._appVersion = appVersion;

  AppInfoBuilder();

  AppInfoBuilder get _$this {
    if (_$v != null) {
      _appName = _$v.appName;
      _appVersion = _$v.appVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppInfo other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AppInfo;
  }

  @override
  void update(void Function(AppInfoBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AppInfo build() {
    final _$result =
        _$v ?? new _$AppInfo._(appName: appName, appVersion: appVersion);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
