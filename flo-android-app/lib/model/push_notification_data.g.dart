// GENERATED CODE - DO NOT MODIFY BY HAND

part of push_notification_data;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PushNotificationData> _$pushNotificationDataSerializer =
    new _$PushNotificationDataSerializer();

class _$PushNotificationDataSerializer
    implements StructuredSerializer<PushNotificationData> {
  @override
  final Iterable<Type> types = const [
    PushNotificationData,
    _$PushNotificationData
  ];
  @override
  final String wireName = 'PushNotificationData';

  @override
  Iterable<Object> serialize(
      Serializers serializers, PushNotificationData object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.url != null) {
      result
        ..add('url')
        ..add(serializers.serialize(object.url,
            specifiedType: const FullType(String)));
    }
    if (object.data != null) {
      result
        ..add('data')
        ..add(serializers.serialize(object.data,
            specifiedType: const FullType(JsonObject)));
    }
    if (object.title != null) {
      result
        ..add('title')
        ..add(serializers.serialize(object.title,
            specifiedType: const FullType(String)));
    }
    if (object.body != null) {
      result
        ..add('body')
        ..add(serializers.serialize(object.body,
            specifiedType: const FullType(String)));
    }
    if (object.tag != null) {
      result
        ..add('tag')
        ..add(serializers.serialize(object.tag,
            specifiedType: const FullType(String)));
    }
    if (object.color != null) {
      result
        ..add('color')
        ..add(serializers.serialize(object.color,
            specifiedType: const FullType(String)));
    }
    if (object.clickAction != null) {
      result
        ..add('click_action')
        ..add(serializers.serialize(object.clickAction,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  PushNotificationData deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PushNotificationDataBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'url':
          result.url = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'data':
          result.data = serializers.deserialize(value,
              specifiedType: const FullType(JsonObject)) as JsonObject;
          break;
        case 'title':
          result.title = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'body':
          result.body = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'tag':
          result.tag = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'color':
          result.color = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'click_action':
          result.clickAction = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$PushNotificationData extends PushNotificationData {
  @override
  final String url;
  @override
  final JsonObject data;
  @override
  final String title;
  @override
  final String body;
  @override
  final String tag;
  @override
  final String color;
  @override
  final String clickAction;

  factory _$PushNotificationData(
          [void Function(PushNotificationDataBuilder) updates]) =>
      (new PushNotificationDataBuilder()..update(updates)).build();

  _$PushNotificationData._(
      {this.url,
      this.data,
      this.title,
      this.body,
      this.tag,
      this.color,
      this.clickAction})
      : super._();

  @override
  PushNotificationData rebuild(
          void Function(PushNotificationDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushNotificationDataBuilder toBuilder() =>
      new PushNotificationDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushNotificationData &&
        url == other.url &&
        data == other.data &&
        title == other.title &&
        body == other.body &&
        tag == other.tag &&
        color == other.color &&
        clickAction == other.clickAction;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, url.hashCode), data.hashCode),
                        title.hashCode),
                    body.hashCode),
                tag.hashCode),
            color.hashCode),
        clickAction.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PushNotificationData')
          ..add('url', url)
          ..add('data', data)
          ..add('title', title)
          ..add('body', body)
          ..add('tag', tag)
          ..add('color', color)
          ..add('clickAction', clickAction))
        .toString();
  }
}

class PushNotificationDataBuilder
    implements Builder<PushNotificationData, PushNotificationDataBuilder> {
  _$PushNotificationData _$v;

  String _url;
  String get url => _$this._url;
  set url(String url) => _$this._url = url;

  JsonObject _data;
  JsonObject get data => _$this._data;
  set data(JsonObject data) => _$this._data = data;

  String _title;
  String get title => _$this._title;
  set title(String title) => _$this._title = title;

  String _body;
  String get body => _$this._body;
  set body(String body) => _$this._body = body;

  String _tag;
  String get tag => _$this._tag;
  set tag(String tag) => _$this._tag = tag;

  String _color;
  String get color => _$this._color;
  set color(String color) => _$this._color = color;

  String _clickAction;
  String get clickAction => _$this._clickAction;
  set clickAction(String clickAction) => _$this._clickAction = clickAction;

  PushNotificationDataBuilder();

  PushNotificationDataBuilder get _$this {
    if (_$v != null) {
      _url = _$v.url;
      _data = _$v.data;
      _title = _$v.title;
      _body = _$v.body;
      _tag = _$v.tag;
      _color = _$v.color;
      _clickAction = _$v.clickAction;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushNotificationData other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PushNotificationData;
  }

  @override
  void update(void Function(PushNotificationDataBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PushNotificationData build() {
    final _$result = _$v ??
        new _$PushNotificationData._(
            url: url,
            data: data,
            title: title,
            body: body,
            tag: tag,
            color: color,
            clickAction: clickAction);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
