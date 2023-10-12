package com.flo.puck.core

import java.time.Clock

import com.flo.puck.core.api._
import com.flo.puck.core.trigger.ActionTrigger

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def defaultExecutionContext: ExecutionContext
  def puckTelemetryConsumer: Consumer[PuckTelemetryProcessor]
  def entityActivityConsumer: Consumer[EntityActivityProcessor]
  def applyActionTrigger: ActionTrigger
  def appendHistoricalPuckTelemetry: HistoricalPuckTelemetryAppender
  def saveCurrentPuckTelemetry: CurrentPuckTelemetrySaver
  def saveAudioSettings: AudioSettingsSaver
  def getDeviceByMacAddress: GetDeviceByMacAddress
  def defaultClock: Clock
  def retrievePuckTelemetryReport: PuckTelemetryReportRetriever
  def processAlarmAutoResolve: AlarmAutoResolveProcessor

  // Private
  private val processPuckTelemetry = new ProcessPuckTelemetry(
    applyActionTrigger,
    appendHistoricalPuckTelemetry,
    saveCurrentPuckTelemetry,
    getDeviceByMacAddress,
    processAlarmAutoResolve,
  )(defaultExecutionContext)

  private val processEntityActivity = new ProcessEntityActivity(
    defaultClock,
    saveAudioSettings
  )

  puckTelemetryConsumer.start(processPuckTelemetry)
  entityActivityConsumer.start(processEntityActivity)

  sys.addShutdownHook {
    puckTelemetryConsumer.stop()
    entityActivityConsumer.stop()
  }
}
