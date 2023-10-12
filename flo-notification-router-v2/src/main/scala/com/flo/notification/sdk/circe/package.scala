package com.flo.notification.sdk

import com.flo.Models.KafkaMessages.SmsMessage
import com.flo.notification.router.core.api.alert._
import com.flo.notification.router.core.api.{
  AlarmData,
  AlarmIncident,
  AlarmIncidentMetadata,
  Alert,
  CallMessage,
  MetaData,
  TelemetrySnapshot,
  VoiceCall,
  VoiceCallData
}
import com.flo.notification.sdk.model.SystemMode
import io.circe._
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.syntax._

package object circe {

  val customConfig: Configuration = Configuration.default.withDefaults

  implicit val decodeTelemetrySnapshot: Decoder[TelemetrySnapshot] = {
    implicit val _ = customConfig
    deriveConfiguredDecoder
  }

  implicit val decodeAlarmIncidentMetadata: Decoder[AlarmIncidentMetadata] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredDecoder
  }

  implicit val metaData: Encoder[MetaData] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }
  implicit val callMessage: Encoder[CallMessage] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }
  implicit val voiceCallData: Encoder[VoiceCallData] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }
  implicit val encodeVoiceCall: Encoder[VoiceCall] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }
  implicit val encodeSmsMessage: Encoder[SmsMessage] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }
  implicit val encodeAlarmData: Encoder[AlarmData] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  implicit val encodeAlarmIncidentMetadata: Encoder[AlarmIncidentMetadata] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }

  implicit val encodeTelemetrySnapshot: Encoder[TelemetrySnapshot] = {
    implicit val _ = customConfig
    deriveConfiguredEncoder
  }

  private case class UserActivityEvent(appType: Option[Int])
  implicit private val decodeUserActivityEvent: Decoder[UserActivityEvent] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredDecoder
  }

  implicit val decodeAlarmIncident: Decoder[AlarmIncident] = (c: HCursor) =>
    for {
      id         <- c.downField("id").as[String]
      timestamp  <- c.downField("ts").as[Long]
      macAddress <- c.downField("did").as[String]
      systemMode <- c.downField("data")
                     .downField("snapshot")
                     .downField("sm")
                     .as[Int]
      alarmId <- c.downField("data")
                  .downField("alarm")
                  .downField("reason")
                  .as[Int]
      snapshot <- c.downField("data")
                   .downField("snapshot")
                   .as[TelemetrySnapshot]
      maybeMetadata <- c.downField("data")
                        .downField("alarm")
                        .downField("info")
                        .as[Option[AlarmIncidentMetadata]]
      userActivityEvent <- c.downField("user_activity_event").as[Option[UserActivityEvent]]
    } yield {
      val metadata       = maybeMetadata.getOrElse(AlarmIncidentMetadata(None, None, None, None, None, None, None))
      val safeSystemMode = if (systemMode <= 0) SystemMode.Home else systemMode

      AlarmIncident(
        id,
        timestamp,
        macAddress,
        safeSystemMode,
        alarmId,
        metadata,
        snapshot,
        c.focus,
        userActivityEvent.flatMap(_.appType)
      )
  }

  implicit val encodeAlarmIncident: Encoder[AlarmIncident] = (incident: AlarmIncident) =>
    Json.obj(
      ("id", Json.fromString(incident.id)),
      ("ts", Json.fromLong(incident.timestamp)),
      ("did", Json.fromString(incident.macAddress)),
      (
        "data",
        Json.obj(
          ("snapshot", incident.snapshot.asJson),
          (
            "alarm",
            Json.obj(
              ("reason", Json.fromInt(incident.alarmId)),
              ("info", incident.metadata.asJson)
            )
          )
        )
      ),
      (
        "user_activity_event",
        Json.obj(
          ("app_type", incident.applicationType.asJson)
        )
      )
  )

  implicit val decodeAlert: Decoder[Alert] = (c: HCursor) =>
    for {
      timestamp  <- c.downField("ts").as[Long]
      macAddress <- c.downField("did").as[String]
      systemMode <- c.downField("data")
                     .downField("snapshot")
                     .downField("sm")
                     .as[Int]
      status <- c.downField("status").as[Int]
      alarmId <- c.downField("data")
                  .downField("alarm")
                  .downField("reason")
                  .as[Int]
      snapshot <- c.downField("data")
                   .downField("snapshot")
                   .as[TelemetrySnapshot]
      metadata <- c.downField("data")
                   .downField("alarm")
                   .downField("info")
                   .as[Option[AlarmIncidentMetadata]]
    } yield {
      val alertStatus: AlertStatus = status match {
        case 1 => Resolved
        case 2 => Ignored
        case 3 => Unresolved
        case 4 => Muted
      }

      Alert(timestamp, macAddress, systemMode, alarmId, alertStatus, metadata, snapshot, c.focus)
  }
}
