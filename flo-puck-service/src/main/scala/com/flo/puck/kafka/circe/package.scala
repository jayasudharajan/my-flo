package com.flo.puck.kafka

import java.time.{LocalDateTime, ZoneOffset}

import com.flo.puck.core.api._
import com.flo.puck.core.api.activity._
import com.flo.puck.kafka.nrv2.{AlarmNotificationStatus, AlarmNotificationStatusData, DataAlarm}
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe._

package object circe {

  val customConfig: Configuration = Configuration.default.withDefaults

  implicit val puckTelemetryPropertiesDecoder: Decoder[PuckTelemetryProperties] = {
    implicit val _ = customConfig.copy(
      transformMemberNames = {
        case "macAddress" => "device_id"
        case "deviceId"   => "device_uuid"
        case other => Configuration.snakeCaseTransformation(other)
      }
    )
    deriveConfiguredDecoder
  }

  implicit val puckTelemetryDecoder: Decoder[PuckTelemetry] = {
    implicit val _ = customConfig
    Decoder.instance { c =>
      for {
        props <- c.as[PuckTelemetryProperties]
      } yield {
        PuckTelemetry(props, c.focus.get)
      }
    }
  }

  implicit val puckTelemetryAlertStateDecoder: Decoder[AlertState] = (c: HCursor) => c.as[String].flatMap {
    case "inactive" => Right(AlertInactive)
    case "triggered" => Right(AlertTriggered)
    case "resolved" => Right(AlertResolved)
    case "snoozed" => Right(AlertSnoozed)
    case _ => Right(AlertUnknown)
  }

  implicit val entityActivityDecoder: Decoder[EntityActivity] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val entityActivityStatusDecoder: Decoder[ActivityStatus] = (c: HCursor) => c.as[String].flatMap {
    case "received" => Right(Received)
    case "filtered" => Right(Filtered)
    case "triggered" => Right(Triggered)
    case "resolved" => Right(Resolved)
    case _ => Right(DiscardedStatus)
  }

  implicit val entityActivityReasonDecoder: Decoder[ActivityReason] = (c: HCursor) => c.as[String].flatMap {
    case "snoozed" => Right(Snoozed)
    case _ => Right(DiscardedReason)
  }

  implicit val entityActivityType: Decoder[ActivityType] = (c: HCursor) => c.as[String].flatMap {
    case "alert"    => Right(Alert)
    case _          => Right(DiscardedType)
  }

  implicit val entityActivityAction: Decoder[ActivityAction] = (c: HCursor) => c.as[String].flatMap {
    case "created" => Right(Created)
    case "updated" => Right(Updated)
    case "deleted" => Right(Deleted)
    case _         => Right(DiscardedActivityAction)
  }

  implicit val deviceDecoder: Decoder[EntityActivityDevice] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val entityActivityItemDecoder: Decoder[EntityActivityItem] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val localDateTimeDecoder: Decoder[LocalDateTime] = Decoder.decodeInstant.map(LocalDateTime.ofInstant(_, ZoneOffset.UTC))

  implicit val optEntityActivityItemDecoder: Decoder[Option[EntityActivityItem]] = (c: HCursor) => {
    val maybeEntityActivityItem = entityActivityItemDecoder.apply(c)
    Right(maybeEntityActivityItem.toOption) // We don't want to fail if the item is not the one we are expecting.
  }

  implicit val encodeAlarmNotificationStatus: Encoder[AlarmNotificationStatus] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeAlarmNotificationStatusData: Encoder[AlarmNotificationStatusData] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeDataAlarm: Encoder[DataAlarm] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }
}
