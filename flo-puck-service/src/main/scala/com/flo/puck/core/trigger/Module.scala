package com.flo.puck.core.trigger

import com.flo.puck.core.api._
import com.flo.puck.core.water.{WaterPresenceResolver, WaterShutoffExecutor}

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  implicit def defaultExecutionContext: ExecutionContext
  def highHumidityAlertSender: PuckIncidentSender
  def highTemperatureAlertSender: PuckIncidentSender
  def lowBatteryAlertSender: PuckIncidentSender
  def lowHumidityAlertSender: PuckIncidentSender
  def lowTemperatureAlertSender: PuckIncidentSender
  def sendWaterLeakPuckAlert: PuckIncidentSender
  def sendDeviceShutoffAlert: DeviceIncidentSender
  def getDeviceById: GetDeviceById
  def getActionRules: GetActionRules
  def sendShutoffDeviceAction: ShutoffDevice

  // Private
  private val lowBatteryTrigger       = new LowBatteryIncidentTrigger(lowBatteryAlertSender)
  private val lowHumidityTrigger      = new LowHumidityIncidentTrigger(lowHumidityAlertSender)
  private val highHumidityTrigger     = new HighHumidityIncidentTrigger(highHumidityAlertSender)
  private val lowTemperatureTrigger   = new LowTemperatureIncidentTrigger(lowTemperatureAlertSender)
  private val highTemperatureTrigger  = new HighTemperatureIncidentTrigger(highTemperatureAlertSender)

  private val waterPresenceResolver   = new WaterPresenceResolver(
    getActionRules,
    sendWaterLeakPuckAlert,
    new WaterShutoffExecutor(sendShutoffDeviceAction, getDeviceById, sendDeviceShutoffAlert)
  )

  private val waterLeakTrigger        = new WaterLeakActionTrigger(waterPresenceResolver)

  private val triggers: List[ActionTrigger] = List(
    lowBatteryTrigger,
    lowHumidityTrigger,
    highHumidityTrigger,
    lowTemperatureTrigger,
    highTemperatureTrigger,
    waterLeakTrigger
  )

  // Provides
  val applyActionTrigger: ActionTrigger = new ActionTriggerExecutor(triggers)(defaultExecutionContext)
}
