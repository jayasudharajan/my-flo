// GENERATED CODE - DO NOT MODIFY BY HAND

part of pending_push_notification;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PendingPushNotification> _$pendingPushNotificationSerializer =
    new _$PendingPushNotificationSerializer();

class _$PendingPushNotificationSerializer
    implements StructuredSerializer<PendingPushNotification> {
  @override
  final Iterable<Type> types = const [
    PendingPushNotification,
    _$PendingPushNotification
  ];
  @override
  final String wireName = 'PendingPushNotification';

  @override
  Iterable<Object> serialize(
      Serializers serializers, PendingPushNotification object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
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
  PendingPushNotification deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PendingPushNotificationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
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

class _$PendingPushNotification extends PendingPushNotification {
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

  factory _$PendingPushNotification(
          [void Function(PendingPushNotificationBuilder) updates]) =>
      (new PendingPushNotificationBuilder()..update(updates)).build();

  _$PendingPushNotification._(
      {this.title, this.body, this.tag, this.color, this.clickAction})
      : super._();

  @override
  PendingPushNotification rebuild(
          void Function(PendingPushNotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PendingPushNotificationBuilder toBuilder() =>
      new PendingPushNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingPushNotification &&
        title == other.title &&
        body == other.body &&
        tag == other.tag &&
        color == other.color &&
        clickAction == other.clickAction;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc($jc(0, title.hashCode), body.hashCode), tag.hashCode),
            color.hashCode),
        clickAction.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PendingPushNotification')
          ..add('title', title)
          ..add('body', body)
          ..add('tag', tag)
          ..add('color', color)
          ..add('clickAction', clickAction))
        .toString();
  }
}

class PendingPushNotificationBuilder
    implements
        Builder<PendingPushNotification, PendingPushNotificationBuilder> {
  _$PendingPushNotification _$v;

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

  PendingPushNotificationBuilder();

  PendingPushNotificationBuilder get _$this {
    if (_$v != null) {
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
  void replace(PendingPushNotification other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PendingPushNotification;
  }

  @override
  void update(void Function(PendingPushNotificationBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PendingPushNotification build() {
    final _$result = _$v ??
        new _$PendingPushNotification._(
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
