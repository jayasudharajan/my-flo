package com.flo.puck.http

import java.time.{LocalDateTime, ZoneOffset}

import com.flo.puck.core.api._
import com.flo.puck.http.device.{ActionRulesResponse, DeviceRequest}
import com.flo.puck.http.gateway.{Away, Close, CurrentTelemetry, DeviceResponse, DeviceShutoffPayload, DeviceTelemetry, HardwareThresholds, Home, Open, Sleep, SystemMode, SystemModeType, ThresholdValues, Unknown, UnknownValveState, Valve, ValveState}
import com.flo.puck.http.nrv2.{AlarmEventResponse, AlarmIncident, ClearAlertsRequest, DeviceInfo, TelemetrySnapshot}
import io.circe._
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import com.flo.puck.core.api.{Away => AwayApi, Home => HomeApi, Sleep => SleepApi, SystemMode => SystemModeApi, Unknown => UnknownApi}

package object circe {

  val customConfig: Configuration = Configuration.default.withDefaults

  implicit val localDateTimeEncoder: Encoder[LocalDateTime] = Encoder.encodeString.contramap[LocalDateTime](_.toInstant(ZoneOffset.UTC).toString)

  implicit val audioSettingsEncoder: Encoder[AudioSettings] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeAlarmIncident: Encoder[AlarmIncident] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeTelemetrySnapshot: Encoder[TelemetrySnapshot] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeDeviceProperties: Encoder[DeviceRequest] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val actionRuleDecoder: Decoder[ActionRule] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val actionRulesResponseDecoder: Decoder[ActionRulesResponse] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val actionDecoder: Decoder[Action] = (c: HCursor) => c.as[String].flatMap {
    case "shutOff"  => Right(ShutOff)
    case _          => Right(DiscardedAction)
  }

  implicit val eventDecoder: Decoder[Event] = (c: HCursor) => c.as[String].flatMap {
    case "waterDetected"  => Right(WaterDetected)
    case _                => Right(DiscardedEvent)
  }

  implicit val deviceResponseDecoder: Decoder[DeviceResponse] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val deviceTelemetryDecoder: Decoder[DeviceTelemetry] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val thresholdValuesDecoder: Decoder[ThresholdValues] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val hardwareThresholdsDecoder: Decoder[HardwareThresholds] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val currentTelemetryDecoder: Decoder[CurrentTelemetry] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val systemModeDecoder: Decoder[SystemMode] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val SystemModeTypeDecoder: Decoder[SystemModeType] = (c: HCursor) => c.as[String].flatMap {
    case "home"   => Right(Home)
    case "away"   => Right(Away)
    case "sleep"  => Right(Sleep)
    case _        => Right(Unknown)
  }

  implicit val valveTypeDecoder: Decoder[ValveState] = (c: HCursor) => c.as[String].flatMap {
    case "open"   => Right(Open)
    case "closed" => Right(Close)
    case _        => Right(UnknownValveState)
  }

  implicit val encodeValveState: Encoder[ValveState] = {
    case Close             => Json.fromString("closed")
    case Open              => Json.fromString("open")
    case UnknownValveState => Json.fromString("unknown")
  }

  implicit val decodeValve: Decoder[Valve] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val encodeValve: Encoder[Valve] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeDeviceRequest: Encoder[DeviceShutoffPayload] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val alertStateDecoder: Decoder[AlertState] = (c: HCursor) => c.as[String].flatMap {
    case "inactive"   => Right(AlertInactive)
    case "triggered"  => Right(AlertTriggered)
    case "resolved"   => Right(AlertResolved)
    case "snoozed"    => Right(AlertSnoozed)
    case _            => Right(AlertUnknown)
  }

  implicit val alarmEventResponseDecoder: Decoder[AlarmEventResponse] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val SystemModeApiTypeDecoder: Decoder[SystemModeApi] = (c: HCursor) => c.as[String].flatMap {
    case "home"   => Right(HomeApi)
    case "away"   => Right(AwayApi)
    case "sleep"  => Right(SleepApi)
    case _        => Right(UnknownApi)
  }

  implicit val alarmDecoder: Decoder[Alarm] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val alarmEventDecoder: Decoder[AlarmEvent] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val encodeDeviceInfo: Encoder[DeviceInfo] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeClearAlertsRequest: Encoder[ClearAlertsRequest] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }
}
