library alerts_state;

import 'package:built_value/built_value.dart';

part 'alerts_state.g.dart';

abstract class AlertsState
    implements Built<AlertsState, AlertsStateBuilder> {
  AlertsState._();

  factory AlertsState([updates(AlertsStateBuilder b)]) = _$AlertsState;

  @nullable
  bool get dirty;
}