package com.flo.puck.http

import akka.actor.ActorSystem
import com.flo.puck.conf._
import com.flo.puck.core.api._
import com.flo.puck.http.circe.{DeserializeActionRules, DeserializeAlarmEvent, DeserializeDeviceResponse, SerializeAlarmIncident, SerializeDeviceProperties, SerializeDeviceShutoffPayload}
import com.flo.puck.http.conf.HttpConfig
import com.flo.puck.http.device.{PostDeviceProperties, PuckData, GetActionRules => GetActionRulesHttp}
import com.flo.puck.http.gateway.{DeviceShutoffAction, GetDeviceById => GetDeviceByIdDefault, GetDeviceByMacAddress => GetDeviceByMacAddressDefault}
import com.flo.puck.http.notification.{GetEvent, PostEvent}
import com.flo.puck.http.nrv2.{AlarmId, DeviceIncidentAdapter, TelemetryIncidentAdapter}
import com.flo.puck.http.util.VersionAdapter
import com.typesafe.config.Config

import scala.concurrent.ExecutionContext

trait Module {

  // Requires
  def appConfig: Config
  def defaultExecutionContext: ExecutionContext
  def actorSystem: ActorSystem
  def generateUuid: String

  // Privates
  private val httpConfig = appConfig.as[HttpConfig]("http")
  // Device api
  private val fwPropertiesUri = httpConfig.deviceApi.baseUri + httpConfig.deviceApi.endpoints.fwProperties
  private val actionRulesUri = httpConfig.deviceApi.baseUri + httpConfig.deviceApi.endpoints.actionRules
  // Notification api
  private val alertsUri = httpConfig.notificationApi.baseUri + httpConfig.notificationApi.endpoints.events
  // Public Gateway
  private val devicesByMacAddressUri = httpConfig.publicGateway.baseUri + httpConfig.publicGateway.endpoints.devices
  private val accessTokenGw = httpConfig.publicGateway.accessToken
  private val devicesByIdUri = httpConfig.publicGateway.baseUri + httpConfig.publicGateway.endpoints.devicesById

  // critical alarms
  private val waterLeakAlarmId = 100
  private val deviceShutoffAlarmId = 101
  // warning alarms
  private val highHumidityAlarmId = 102
  private val lowHumidityAlarmId = 103
  private val highTemperatureAlarmId = 104
  private val lowTemperatureAlarmId = 105
  private val lowBatteryAlarmId = 106

  private val incidentAdapterFactory: AlarmId => TelemetryIncidentAdapter = alarmId =>
    new TelemetryIncidentAdapter(alarmId, generateUuid)

  private val deviceIncidentAdapterFactory: AlarmId => DeviceIncidentAdapter = alarmId =>
    new DeviceIncidentAdapter(alarmId, generateUuid)

  private val postEvent = new PostEvent(
    new SerializeAlarmIncident,
    alertsUri
  )(defaultExecutionContext, actorSystem)

  private val postDeviceProperties = new PostDeviceProperties(
    new SerializeDeviceProperties,
    fwPropertiesUri,
    new VersionAdapter
  )(defaultExecutionContext, actorSystem)

  // Provides
  val saveCurrentPuckTelemetry: CurrentPuckTelemetrySaver = (macAddress: MacAddress, puckTelemetry: PuckTelemetry) =>
    postDeviceProperties.apply((macAddress, PuckData(Some(puckTelemetry), None)))

  val saveAudioSettings: AudioSettingsSaver = (macAddress: MacAddress, audioSettings: AudioSettings) =>
    postDeviceProperties.apply((macAddress, PuckData(None, Some(audioSettings))))

  val getActionRules: GetActionRules = new GetActionRulesHttp(
    actionRulesUri,
    new DeserializeActionRules
  )(defaultExecutionContext, actorSystem)

  val getDeviceByMacAddress: GetDeviceByMacAddress = new GetDeviceByMacAddressDefault(
    devicesByMacAddressUri,
    accessTokenGw,
    new DeserializeDeviceResponse
  )(defaultExecutionContext, actorSystem)

  val getDeviceById: GetDeviceById = new GetDeviceByIdDefault(
    devicesByIdUri,
    accessTokenGw,
    new DeserializeDeviceResponse
  )(defaultExecutionContext, actorSystem)

  val getEventsByDevice = new GetEvent(
    alertsUri,
    new DeserializeAlarmEvent,
  )(defaultExecutionContext, actorSystem)

  val sendShutoffDeviceAction: ShutoffDevice = new DeviceShutoffAction(
    devicesByIdUri,
    accessTokenGw,
    new SerializeDeviceShutoffPayload
  )(defaultExecutionContext, actorSystem)

  val highHumidityAlertSender: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(highHumidityAlarmId)(puckTelemetryProperties, device))

  val highTemperatureAlertSender: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(highTemperatureAlarmId)(puckTelemetryProperties, device))

  val lowBatteryAlertSender: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(lowBatteryAlarmId)(puckTelemetryProperties, device))

  val lowHumidityAlertSender: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(lowHumidityAlarmId)(puckTelemetryProperties, device))

  val lowTemperatureAlertSender: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(lowTemperatureAlarmId)(puckTelemetryProperties, device))

  val sendWaterLeakPuckAlert: PuckIncidentSender = (puckTelemetryProperties: PuckTelemetryProperties, device: Device) =>
    postEvent(incidentAdapterFactory(waterLeakAlarmId)(puckTelemetryProperties, device))

  val sendDeviceShutoffAlert: DeviceIncidentSender = (device: Device) =>
    postEvent(deviceIncidentAdapterFactory(deviceShutoffAlarmId)(device))

}
