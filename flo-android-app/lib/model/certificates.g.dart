// GENERATED CODE - DO NOT MODIFY BY HAND

part of certificates;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Certificates> _$certificatesSerializer =
    new _$CertificatesSerializer();

class _$CertificatesSerializer implements StructuredSerializer<Certificates> {
  @override
  final Iterable<Type> types = const [Certificates, _$Certificates];
  @override
  final String wireName = 'Certificates';

  @override
  Iterable<Object> serialize(Serializers serializers, Certificates object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'encoded_ca_cert',
      serializers.serialize(object.encodedCaCert,
          specifiedType: const FullType(String)),
      'encoded_client_cert',
      serializers.serialize(object.encodedClientCert,
          specifiedType: const FullType(String)),
      'encoded_client_key',
      serializers.serialize(object.encodedClientKey,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Certificates deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new CertificatesBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'encoded_ca_cert':
          result.encodedCaCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'encoded_client_cert':
          result.encodedClientCert = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'encoded_client_key':
          result.encodedClientKey = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$Certificates extends Certificates {
  @override
  final String encodedCaCert;
  @override
  final String encodedClientCert;
  @override
  final String encodedClientKey;

  factory _$Certificates([void Function(CertificatesBuilder) updates]) =>
      (new CertificatesBuilder()..update(updates)).build();

  _$Certificates._(
      {this.encodedCaCert, this.encodedClientCert, this.encodedClientKey})
      : super._() {
    if (encodedCaCert == null) {
      throw new BuiltValueNullFieldError('Certificates', 'encodedCaCert');
    }
    if (encodedClientCert == null) {
      throw new BuiltValueNullFieldError('Certificates', 'encodedClientCert');
    }
    if (encodedClientKey == null) {
      throw new BuiltValueNullFieldError('Certificates', 'encodedClientKey');
    }
  }

  @override
  Certificates rebuild(void Function(CertificatesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CertificatesBuilder toBuilder() => new CertificatesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Certificates &&
        encodedCaCert == other.encodedCaCert &&
        encodedClientCert == other.encodedClientCert &&
        encodedClientKey == other.encodedClientKey;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, encodedCaCert.hashCode), encodedClientCert.hashCode),
        encodedClientKey.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Certificates')
          ..add('encodedCaCert', encodedCaCert)
          ..add('encodedClientCert', encodedClientCert)
          ..add('encodedClientKey', encodedClientKey))
        .toString();
  }
}

class CertificatesBuilder
    implements Builder<Certificates, CertificatesBuilder> {
  _$Certificates _$v;

  String _encodedCaCert;
  String get encodedCaCert => _$this._encodedCaCert;
  set encodedCaCert(String encodedCaCert) =>
      _$this._encodedCaCert = encodedCaCert;

  String _encodedClientCert;
  String get encodedClientCert => _$this._encodedClientCert;
  set encodedClientCert(String encodedClientCert) =>
      _$this._encodedClientCert = encodedClientCert;

  String _encodedClientKey;
  String get encodedClientKey => _$this._encodedClientKey;
  set encodedClientKey(String encodedClientKey) =>
      _$this._encodedClientKey = encodedClientKey;

  CertificatesBuilder();

  CertificatesBuilder get _$this {
    if (_$v != null) {
      _encodedCaCert = _$v.encodedCaCert;
      _encodedClientCert = _$v.encodedClientCert;
      _encodedClientKey = _$v.encodedClientKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Certificates other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Certificates;
  }

  @override
  void update(void Function(CertificatesBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Certificates build() {
    final _$result = _$v ??
        new _$Certificates._(
            encodedCaCert: encodedCaCert,
            encodedClientCert: encodedClientCert,
            encodedClientKey: encodedClientKey);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
