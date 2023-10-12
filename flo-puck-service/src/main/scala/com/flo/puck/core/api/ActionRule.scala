package com.flo.puck.core.api

sealed trait Action
case object ShutOff         extends Action
case object DiscardedAction extends Action

sealed trait Event
case object WaterDetected  extends Event
case object DiscardedEvent extends Event

case class ActionRule (
  id: String,
  targetDeviceId: String,
  action: Action,
  event: Event,
  order: Int,
  enabled: Boolean
)