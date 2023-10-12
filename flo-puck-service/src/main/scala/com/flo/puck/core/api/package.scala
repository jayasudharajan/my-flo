package com.flo.puck.core

import java.time.{LocalDateTime, ZoneId}

import com.flo.puck.core.api.activity.EntityActivity

import scala.concurrent.Future

package object api {
  type Json       = io.circe.Json
  type DeviceId   = String
  type MacAddress = String
  type StartDate  = LocalDateTime
  type EndDate    = LocalDateTime
  type TimeZone   = ZoneId
  type AlarmId    = Int
  type EventId    = String
  type AlarmIds   = List[Int]

  type PuckTelemetryProcessor          = PuckTelemetry => Future[Unit]
  type EntityActivityProcessor         = EntityActivity => Future[Unit]
  type ResumeOnExceptions              = Set[Class[_ <: Throwable]]
  type PuckIncidentSender              = (PuckTelemetryProperties, Device) => Future[Unit]
  type DeviceIncidentSender            = Device => Future[Unit]
  type HistoricalPuckTelemetryAppender = PuckTelemetry => Future[Unit]
  type CurrentPuckTelemetrySaver       = (MacAddress, PuckTelemetry) => Future[Unit]
  type AudioSettingsSaver              = (MacAddress, AudioSettings) => Future[Unit]
  type GetActionRules                  = DeviceId => Future[List[ActionRule]]
  type GetDeviceByMacAddress           = MacAddress => Future[Device]
  type GetDeviceById                   = DeviceId => Future[Device]
  type ShutoffDevice                   = DeviceId => Future[Unit]
  type ShutoffExecutor                 = List[ActionRule] => Future[Unit]
  type GetEventsByDeviceId             = DeviceId => Future[List[AlarmEvent]]
  type AlarmAutoResolveProcessor       = (Device, PuckTelemetryProperties) => Future[Unit]
  type AlarmStateSender                = (MacAddress, AlarmEvent) => Future[Unit]

  type PuckTelemetryReportBuilder   = (MacAddress, Option[Interval], Option[TimeZone], Option[StartDate], Option[EndDate]) => Future[PuckTelemetryReport]
  type PuckTelemetryReportRetriever = (MacAddress, Interval, TimeZone, Option[StartDate], Option[EndDate]) => Future[PuckTelemetryReport]

  private[core] type ActionTrigger    = (PuckTelemetryProperties, Device) => Future[Unit]
  private[core] type ActionResolver   = (PuckTelemetryProperties, Device) => Future[Unit]
}
