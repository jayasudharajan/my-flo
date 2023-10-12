// GENERATED CODE - DO NOT MODIFY BY HAND

part of install_status;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<InstallStatus> _$installStatusSerializer =
    new _$InstallStatusSerializer();

class _$InstallStatusSerializer implements StructuredSerializer<InstallStatus> {
  @override
  final Iterable<Type> types = const [InstallStatus, _$InstallStatus];
  @override
  final String wireName = 'InstallStatus';

  @override
  Iterable<Object> serialize(Serializers serializers, InstallStatus object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.isInstalled != null) {
      result
        ..add('isInstalled')
        ..add(serializers.serialize(object.isInstalled,
            specifiedType: const FullType(bool)));
    }
    if (object.installDate != null) {
      result
        ..add('installDate')
        ..add(serializers.serialize(object.installDate,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  InstallStatus deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new InstallStatusBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'isInstalled':
          result.isInstalled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'installDate':
          result.installDate = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$InstallStatus extends InstallStatus {
  @override
  final bool isInstalled;
  @override
  final String installDate;

  factory _$InstallStatus([void Function(InstallStatusBuilder) updates]) =>
      (new InstallStatusBuilder()..update(updates)).build();

  _$InstallStatus._({this.isInstalled, this.installDate}) : super._();

  @override
  InstallStatus rebuild(void Function(InstallStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InstallStatusBuilder toBuilder() => new InstallStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InstallStatus &&
        isInstalled == other.isInstalled &&
        installDate == other.installDate;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, isInstalled.hashCode), installDate.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('InstallStatus')
          ..add('isInstalled', isInstalled)
          ..add('installDate', installDate))
        .toString();
  }
}

class InstallStatusBuilder
    implements Builder<InstallStatus, InstallStatusBuilder> {
  _$InstallStatus _$v;

  bool _isInstalled;
  bool get isInstalled => _$this._isInstalled;
  set isInstalled(bool isInstalled) => _$this._isInstalled = isInstalled;

  String _installDate;
  String get installDate => _$this._installDate;
  set installDate(String installDate) => _$this._installDate = installDate;

  InstallStatusBuilder();

  InstallStatusBuilder get _$this {
    if (_$v != null) {
      _isInstalled = _$v.isInstalled;
      _installDate = _$v.installDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InstallStatus other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$InstallStatus;
  }

  @override
  void update(void Function(InstallStatusBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$InstallStatus build() {
    final _$result = _$v ??
        new _$InstallStatus._(
            isInstalled: isInstalled, installDate: installDate);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
