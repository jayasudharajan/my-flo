import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef Callable<T> = void Function(T value);
class Activity {
  factory Activity() => _instance;

  @visibleForTesting
  Activity.private(MethodChannel channel, eventChannel) : _channel = channel, _eventChannel = eventChannel {
    _channel.setMethodCallHandler((call) async {
      return null;
    });
  }

  static final Activity _instance = Activity.private(const MethodChannel('activity'), const EventChannel('activity/event'));
  final MethodChannel _channel;
  final EventChannel _eventChannel;
  Stream<dynamic> _stream;
  Callable<Map<String, dynamic>> _onNewIntent = (_) {};

  Stream<dynamic> get stream {
    if (_stream == null) {
      _stream = _eventChannel.receiveBroadcastStream();
    }
    return _stream;
  }
}
