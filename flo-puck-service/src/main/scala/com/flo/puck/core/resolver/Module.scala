package com.flo.puck.core.resolver

import com.flo.puck.core.api.{AlarmAutoResolveProcessor, AlarmStateSender, GetEventsByDeviceId}

import scala.concurrent.ExecutionContext

trait Module {
  // requires
  implicit def defaultExecutionContext: ExecutionContext
  def getEventsByDevice: GetEventsByDeviceId
  def sendAlarmState: AlarmStateSender

  // provides
  val processAlarmAutoResolve: AlarmAutoResolveProcessor = new AlarmAutoResolver(
    getEventsByDevice,
    sendAlarmState,
  )(defaultExecutionContext)
}
