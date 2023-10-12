import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zendesk/zendesk.dart';
import 'flo_device_service.dart';
import 'flo_stream_service.dart';
import 'model/add_flo_device_state.dart';
import 'model/add_puck_state.dart';
import 'model/alarm.dart';
import 'model/alarms.dart';
import 'model/alert.dart';
import 'model/alert_settings.dart';
import 'model/alerts_settings.dart';
import 'model/alerts_state.dart';
import 'model/app_state.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'model/locales.dart';
import 'model/location.dart';
import 'model/location_payload.dart';
import 'model/login_state.dart';
import 'model/forgot_password_state.dart';
import 'package:rxdart/rxdart.dart';
import 'model/oauth_token.dart';
import 'model/user.dart';
import 'utils.dart';
import 'widgets.dart';

class StateNotifier<T> with ChangeNotifier {
  final BehaviorSubject<T> _subject = BehaviorSubject<T>();
  T _value;

  T get value => _value;
  set value(v) {
    _value = v;
  }

  final ValueChanged<T> onChanged;

  StateNotifier(T initialData, {ValueChanged<T> onChanged}) : onChanged = onChanged ?? ((_) {}) {
    value = initialData;
    _subject.asBroadcastStream()
        .distinct()
        .doOnEach((v) {
          value = v.value;
        })
        .doOnEach((_) => notifyListeners())
        .listen((value) {
          this.onChanged(value);
        });
  }

  void invalidate() {
    _subject.add(value);
  }

  void invalidateWithData(ConsumeFunction<T, T> reducer) {
    value = reducer(value);
    invalidate();
  }

  @override
  void dispose() {
    _subject?.close();
    super.dispose();
  }

  BehaviorSubject<T> get subject => _subject;
}

class OauthTokenNotifier extends StateNotifier<OauthToken> {
  OauthTokenNotifier(OauthToken initialData) : super(initialData);
}

class LoginStateNotifier extends StateNotifier<LoginState> {
  LoginStateNotifier(LoginState initialData) : super(initialData);
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier(ForgotPasswordState initialData) : super(initialData);
}

class LocalesNotifier extends StateNotifier<Locales> {
  LocalesNotifier(Locales initialData) : super(initialData);
}

class UserNotifier extends StateNotifier<User> {
  UserNotifier(User initialData) : super(initialData);
}

class LocationNotifier extends StateNotifier<Location> { // For pending location
  LocationNotifier(Location initialData) : super(initialData);
}

class CurrentLocationNotifier extends StateNotifier<Location> {
  CurrentLocationNotifier(Location initialData) : super(initialData, onChanged: (location) {
    if (location.id?.isNotEmpty ?? false) {
      Future.delayed(Duration.zero, () async {
        final prefs = await SharedPreferences.getInstance();
        final res = await prefs.setString(LAST_LOCATION_ID, location.id);
        Fimber.d("lastLocationId = ${location.id} : $res");
        final lastLocationId = prefs.getString(LAST_LOCATION_ID);
        Fimber.d("lastLocationId: ${lastLocationId}");
      });
    }
  });
}

const LAST_LOCATION_ID = "last_location_id";

class DeviceNotifier extends StateNotifier<Device> {
  DeviceNotifier(Device initialData) : super(initialData);
}

class DevicesNotifier extends StateNotifier<BuiltList<Device>> {
  DevicesNotifier(BuiltList<Device> initialData) : super(initialData);
}

class LocationsNotifier extends StateNotifier<BuiltList<Location>> {
  LocationsNotifier(BuiltList<Location> initialData) : super(initialData);
}

class FloNotifier extends StateNotifier<Flo> {
  FloNotifier(Flo initialData) : super(initialData);
}

class PrefsNotifier extends StateNotifier<SharedPreferences> {
  PrefsNotifier(SharedPreferences initialData) : super(initialData);
}

class AddFloDeviceNotifier extends StateNotifier<AddFloDeviceState> {
  AddFloDeviceNotifier(AddFloDeviceState initialData) : super(initialData);
}

class AddPuckNotifier extends StateNotifier<AddPuckState> {
  AddPuckNotifier(AddPuckState initialData) : super(initialData);
}

class FloStreamServiceNotifier extends StateNotifier<FloStreamService> {
  FloStreamServiceNotifier(FloStreamService initialData) : super(initialData);
}

class AlarmsNotifier extends StateNotifier<BuiltList<Alarm>> {
  AlarmsNotifier(BuiltList<Alarm> initialData) : super(initialData);
}

class AlertsNotifier extends StateNotifier<BuiltList<Alert>> {
  AlertsNotifier(BuiltList<Alert> initialData) : super(initialData);
}

class SelectedDevicesNotifier extends StateNotifier<BuiltList<Device>> {
  SelectedDevicesNotifier(BuiltList<Device> initialData) : super(initialData);
}

class AlertNotifier extends StateNotifier<Alert> {
  AlertNotifier(Alert initialData) : super(initialData);
}

/// Lazy to create a AlertsSettingsState class, let's reuse AlertSettings for that
class AlertsSettingsStateNotifier extends StateNotifier<AlertSettings> {
  AlertsSettingsStateNotifier(AlertSettings initialData) : super(initialData);
}

class FloDeviceServiceNotifier extends StateNotifier<FloDeviceService> {
  FloDeviceServiceNotifier(FloDeviceService initialData) : super(initialData);
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(AppState initialData) : super(initialData);
}

class AlertsStateNotifier extends StateNotifier<AlertsState> {
  AlertsStateNotifier(AlertsState initialData) : super(initialData);
}

class ZendeskNotifier extends StateNotifier<Zendesk> {
  ZendeskNotifier(Zendesk initialData) : super(initialData);
}

class SimpleNavigator {
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  @Nullable
  NavigatorState of() => key.currentState;

  Future<T> pushNamed<T>(String routeName) {
    return of().pushNamed(routeName);
  }

  Future<T> pushNamedAndRemoveUntil<T>(String routeName, RoutePredicate predicate) {
    return of().pushNamedAndRemoveUntil(routeName, predicate);
  }

}

final navigator = SimpleNavigator();

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
