import 'dart:async';
import 'dart:collection';

import 'package:built_collection/built_collection.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'model/device.dart';
import 'model/oauth_token.dart';
import 'widgets.dart';

T or<T>(T func(), {T orElse()}) {
  try {
    return func();
  } catch (err) {
    //print("$err: ${as<Error>(err)?.stackTrace}");
    return orElse != null ? orElse() : null;
  }
}

Future<T> futureOr<T>(FutureOr<T> Function() future, {T orElse()}) async {
  try {
    return await future();
  } catch (err) {
    //print("$err: ${as<Error>(err)?.stackTrace}");
    return orElse != null ? orElse() : null;
  }
}

Future<T> asyncOr<T>(Future<T> future, {T orElse()}) async {
  try {
    return await future;
  } catch (err) {
    //print("$err: ${as<Error>(err)?.stackTrace}");
    return orElse != null ? orElse() : null;
  }
}

//@deprecated
bool anyOf<T>(T value, Iterable<T> collection) => collection.contains(value);
//bool anyOf<T>(T value, Iterable<T> collection) => collection.any((it) => it == value);

/*
bool allOf<T>(T value, List<T> collection) {
  return collection.contains(value);
}
*/

Future<bool> checkConnectivity() async {
  return anyOf(await (Connectivity().checkConnectivity()), [ConnectivityResult.mobile, ConnectivityResult.wifi]);
  /*
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  }
  if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
  */
}

double toLiters(final double gallons) => gallons * LITER_FACTOR;
double toGallons(final double liters) => liters * 0.264172;

const double LITER_FACTOR = 3.78541178;

double toKpa(final double psi) => psi * 6.894757293168361;
double toCelsius(final double fahrenheit) => (fahrenheit - 32) / 1.8;

class SharedPreferencesUtils {
  static Future<void> putOauth(SharedPreferences prefs, OauthToken oauth) async {
    await prefs.setString('access_token', oauth.accessToken);
    await prefs.setString('refresh_token', oauth.refreshToken);
    await prefs.setInt('expires_in', oauth.expiresIn);
    await prefs.setString('user_id', oauth.userId);
    await prefs.setString('expires_at', oauth.expiresAt);
    await prefs.setString('issued_at', oauth.issuedAt);
    await prefs.setString('token_type', oauth.tokenType);
  }

  static Future<void> clearOauth(SharedPreferences prefs) async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_in');
    await prefs.remove('user_id');
    await prefs.remove('expires_at');
    await prefs.remove('issued_at');
    await prefs.remove('token_type');
  }
}

// See also: https://github.com/dart-lang/sdk/issues/33075
@deprecated
T asOrNull<T>(dynamic it) => as(it);
T as<T>(dynamic it) => it is T ? it : null;

R let<T, R>(dynamic it, R consume(T it)) => it is T ? consume(it) : null;
T orNull<T>(T it, bool predict(T it)) => predict(it) ? it : null;

Iterable<T> notEmptyOrNull<T>(Iterable<T> it) => orNull(it, (that) => that.isNotEmpty);

class Iterables {
  Iterable<T> notEmptyOrNull<T>(Iterable<T> it) => orNull(it, (that) => that.isNotEmpty);
  Iterable<T> orEmpty<T>(Iterable<T> it) => it ?? const [];
}

//Type typeOf<T>() => T;

// Doesn't support subtype?
// Doesn't support Set types
T orEmpty<T>(T it) {
  if (T == double) {
    return it ?? as<T>(0.0) ?? it;
  } else if (T == int) {
    return it ?? as<T>(0) ?? it;
  } else if (T == String) {
    return it ?? as<T>("") ?? it;
  } else if (T == List) {
    return it ?? as<T>(const []) ?? it;
  } else if (T == Set) {
    return it ?? as<T>(const {}) ?? it;
  } else if (T == Iterable) {
    return it ?? as<T>(const []) ?? it;
  } else if (T == Map) {
    return it ?? as<T>(const {}) ?? it;
  } else {
    return it;
  }
}

class Strings {
  static String orNull(String it) => (it?.isNotEmpty ?? false) ? it : null;
}

//class Doubles {
//  static int toInt(Object it) => as<int>(it) ?? as<double>(it)?.toInt() ?? let<String, int>(it, (it2) => int.tryParse(it2));
//}

class Durations {
  //DateFormat.ms().format(DateFormat.ms().parse("00:00").add(Duration(seconds: 60) - Duration(seconds: t.tick))),
  static String ms(Duration duration) {
    final text = "${duration.inMinutes.remainder(60).abs()}:${duration.inSeconds.remainder(60).abs()}";
    return duration.isNegative ? "-${text}" : text;
  }
  static String hms(Duration duration) {
    final text = "${duration.inHours.abs()}:${duration.inMinutes.remainder(60).abs()}:${duration.inSeconds.remainder(60).abs()}";
    return duration.isNegative ? "-${text}" : text;
  }
}

class DateTimes {
  static DateTime hour(DateTime from) {
    return DateTime(from.year, from.month, from.day, from.hour);
  }

  static List<DateTime> hours(DateTime from) {
    return List.generate(24, (i) => DateTime(from.year, from.month, from.day, i));
  }

  static List<DateTime> weekdays(DateTime from) {
    return List.generate(7, (i) => DateTime(from.year, from.month, from.day + i));
  }

  /// original today
  static DateTime today({final DateTime from, int offsetDays = 0}) {
    final _from = from ?? DateTime.now();
    return DateTime(_from.year, _from.month, _from.day + offsetDays);
  }

  ///  5671234567
  ///      ^
  ///   ^      ^
  ///  -3     +5
  /// final lastSat
  /// final nextSat
  static DateTime lastWeekday(weekday, {DateTime from}) {
    from = from ?? DateTime.now();
    //return today(from: from, offsetDays: weekday > from.weekday ? (weekday - from.weekday : weekday - (from.weekday + 7));
    return today(from: from, offsetDays: weekday - (from.weekday + 7));
  }

  ///  5671234567
  ///      ^
  ///   ^      ^
  ///  -3     +5
  /// final lastSat
  /// final nextSat
  static DateTime nextWeekday(weekday, {DateTime from}) {
    from = from ?? DateTime.now();
    return today(from: from, offsetDays: (from.weekday + (7 - weekday)) + 1);
  }

  // TODO
  static DateTime recentWeekday(weekday, {DateTime from}) {
    from = from ?? DateTime.now();
    return today(from: from, offsetDays: weekday < from.weekday ? lastWeekday(weekday) : from.weekday - weekday);
  }

  // TODO
  static DateTime thisWeekday(weekday, {DateTime from, int startDay = 6}) {
    //0123456
    //  ^
    //6012345
    //
    //0 + startDay % 7

    //2 + 6 % 7 = 1
    //weekday + startDay % 7;
    //6 + 6 % 7 = 5
    //if (startDay + 7 < from.weekday + 7)
    return today(from: from, offsetDays: weekday < from.weekday ? lastWeekday(weekday) : from.weekday - weekday);
  }

  static DateTime of(String text, {bool isUtc = false}) => ofNull(text, isUtc: isUtc) ?? DateTime.now();
  //static DateTime ofNull(String text, {bool isUtc = false}) => or(() => DateTime.parse("${text}${isUtc ? "Z" : ""}"));
  static DateTime ofNull(String text, {bool isUtc = false}) {
    return or(() => or(() => isUtc ? DateTime.tryParse("${text}Z") : DateTime.tryParse(text))?.toLocal() ?? DateTime.tryParse(text)?.toLocal());
  }

  static String formatAgo(DateTime since) {
    // TODO
    return null;
  }

  static String formatDuration(Duration duration) {
    // TODO
    return null;
  }
}

/*
class Lists {
  /*
            Maps.reduce<String, WaterUsageItem>(
                Maps.fromIterable2(items, key: (item) => item.time),
                Maps.fromIterable2(it.items, key: (item) => item.time),
                reduce: (that, it) => that + it
            ).values
  */
  Iterable<T> mergeBy<T>(Iterable<T> that, Iterable<T> it, Object key(T element), {T reduce(T that, T it)}) => null;
}
*/


class Maps {
  /*
  factory Map.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) = LinkedHashMap<K, V>.fromIterable;
  */
  //static Map<K, V> fromIterable<T, K, V>(Iterable<T> it, {K key(T element), V value(T element)}) => LinkedHashMap<K, V>.fromIterable(it, key: key, value: value);
  static Map<K, V> fromIterable<T, K, V>(Iterable<T> it, {K key(T element), V value(T element)}) => Map.fromIterable(it, key: key != null ? (k) => key(k) : null, value: value != null ? (v) => value(v) : null);
  static Map<K, T> fromIterable2<K, T>(Iterable<T> it, {K key(T element)}) => Map.fromIterable(it, key: key != null ? (k) => key(k) : null);
  //static Map<K, V> reduce<K, V>(Iterable<MapEntry<K, V>> entries, {V reduce(V that, V it)}) {
  //};
  static Map<K, V> reduce<K, V>(Map<K, V> that, Map<K, V> it, {V reduce(V that, V it)}) {
    it.forEach((k, v) {
      if (that.containsKey(k)) {
        //that.putIfAbsent(k, () => reduce(that[k], v));
        that[k] = reduce(that[k], v);
      } else {
        that.putIfAbsent(k, () => v);
      }
    });
    return that;
  }

  static T get<T>(Map<dynamic, T> that, dynamic key) => (that?.containsKey(key) ?? false) ? as(that[key]) : null;
  static T get2<T, K>(Map<K, T> that, K key) => (that?.containsKey(key) ?? false) ? as(that[key]) : null;
}

/*
class Lists {
  static V sum<T, V>(Iterable<T> iterable, V combine(T that, T it)) => ;
}

class BuiltLists {
  static empty<T extends BuiltList>() => as<BuiltList<T>>(BuiltList<T>());
}
*/

class Bools {
  static bool parse(Object object) {
    if (object is bool) {
      return object;
    }
    if (object is String) {
      return object == "true" || object == "1";
    }
    if (object is int) {
      return object == 1;
    }
    return null;
  }
}

class Ints {
  static int parse(Object object) {
    if (object is int) {
      return object;
    }
    if (object is String) {
      return or(() => int.parse(object));
    }
    return null;
  }
  static int toInt(Object it) => as<int>(it) ?? as<double>(it)?.toInt() ?? let<String, int>(it, (it2) => int.tryParse(it2));
}

const String Nullable = 'nullable';
const String NonNull = 'nonnull';
//const String NotNull = 'notnull';


class Devices {
  static Future<String> id(BuildContext context) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId;
    }
  }

}


class DeviceUtils {

  @Nullable
  static String model(String model, {
    BuildContext context,
  }) => modelOr(model, context: context) ?? Device.FLO_DEVICE_075_V2_DISPLAY; // FIXME

  @Nullable
  static String modelOr(String model, {
    BuildContext context,
  }) {
    switch (model) {
      case Device.FLO_DEVICE_075_V2:
        return Device.FLO_DEVICE_075_V2_DISPLAY;  // FIXME
        break;
      case Device.FLO_DEVICE_125_V2:
        return Device.FLO_DEVICE_125_V2_DISPLAY;  // FIXME
        break;
      case Device.PUCK_V1:
        return Device.PUCK_V1_DISPLAY;  // FIXME
        break;
      default:
        return null;
    }
  }

  @Nullable
  static Widget icon(String model, {bool isConnected: true}) {
    switch (model) {
      case Device.FLO_DEVICE_075_V2:
        return FloDeviceIcon();
        break;
      case Device.FLO_DEVICE_125_V2:
        return FloDeviceQuarterIcon();
        break;
      case Device.PUCK_V1:
        return PuckV1Icon();
        break;
      default:
        return null;
    }
  }

  @Nullable
  static String iconPath(String model, {bool open = true}) {
    switch (model) {
      case Device.FLO_DEVICE_075_V2: {
        if (open) {
          return 'assets/ic_flo_device_on.png';
        } else {
          return 'assets/ic_flo_device_off.png';
        }
      } break;
      case Device.FLO_DEVICE_125_V2: {
        if (open) {
          return 'assets/ic_flo_device_on.png';
        } else {
          return 'assets/ic_flo_device_off.png';
        }
      } break;
      case Device.PUCK_V1:
        return 'assets/ic_puck.png';
      default: {
        if (open) {
          return 'assets/ic_flo_device_on.png';
        } else {
          return 'assets/ic_flo_device_off.png';
        }
      }
    }
  }
}

List<T> moveFirst<T>(List<T> list, T item) {
  if (list.isEmpty) return list;

  final first = or(() => list.first);
  if (first != item) {
    list.remove(item);
    list.first = item;
    list.add(first);
  }
  return list;
}

List<T> moveInFirst<T>(List<T> list, T item, {Object where(T o)}) {
  if (item == null) return list;
  if (list?.isEmpty ?? true) return list;

  where = where ?? (o) => o;

  final first = or(() => list.first);
  Fimber.d("first: $first");
  Fimber.d("selected: $item");
  if (first != item || where(first) != where(item)) {
    list.remove(item);
    list.removeWhere((it) => where(it) == where(item));
    list.insert(0, item);
    return list;
  }
  return list;
}

Future<T> reretry<T>(
    FutureOr<T> Function() fn, {
      Duration delayFactor = const Duration(milliseconds: 200),
      double randomizationFactor = 0.25,
      Duration maxDelay = const Duration(seconds: 30),
      int maxAttempts = 8,
      FutureOr<bool> Function(Exception) retryIf,
      FutureOr<void> Function(Exception) onRetry,
    }) =>
    RetryOptions(
      delayFactor: delayFactor,
      randomizationFactor: randomizationFactor,
      maxDelay: maxDelay,
      maxAttempts: maxAttempts,
    ).retry(() async {
      try {
        return await fn();
      } catch (err) {
        if (!(err is Exception)) {
          throw Exception(err);
        }
        rethrow;
      }
    }, retryIf: retryIf, onRetry: onRetry);

class ModalRoutes {
  static RoutePredicate not(String name) {
    return (Route<dynamic> route) {
      return !route.willHandlePopInternally
          && route is ModalRoute
          && route.settings.name != name;
    };
  }
}
