package flo.models.http

import java.time.LocalDateTime
import java.util.UUID

import com.flo.notification.sdk.model._
import com.flo.notification.sdk.service.{DeliveryMediumStatus, IncidentReason, IncidentStatus}
import com.softwaremill.quicklens._

import scala.annotation.tailrec

case class FwValues(
    gpm: Any,
    galUsed: Any,
    psiDelta: Any,
    leakLossMinGal: Any,
    leakLossMaxGal: Any,
    flowEventDuration: Any
)

object FwValues {
  def apply(dataValues: Map[String, Any], alarm: Alarm): FwValues = {
    val leakLossMinGal = alarm.metadata.getOrElse("leakLossMinGal", 0.0D)
    val leakLossMaxGal = alarm.metadata.getOrElse("leakLossMaxGal", 0.0D)

    FwValues(
      gpm = dataValues.getOrElse("fr", None),
      galUsed = dataValues.getOrElse("ef", None),
      psiDelta = None,
      leakLossMinGal,
      leakLossMaxGal,
      flowEventDuration = dataValues.getOrElse("efd", None)
    )
  }
}

case class DeliveryMediumDetails(status: String,
                                 createdAt: LocalDateTime,
                                 updatedAt: LocalDateTime,
                                 data: Option[Map[String, Any]] = None)

case class DeliveryDetailsByUser(userId: String,
                                 sms: Option[DeliveryMediumDetails],
                                 email: Option[DeliveryMediumDetails],
                                 push: Option[DeliveryMediumDetails],
                                 voice: Option[DeliveryMediumDetails])

object DeliveryDetailsByUser {
  def fromEvents(userId: String, deliveryEvents: Seq[DeliveryEvent]): DeliveryDetailsByUser =
    buildDetails(userId, deliveryEvents)

  private def buildDetails(userId: String, deliveryEvents: Seq[DeliveryEvent]): DeliveryDetailsByUser = {

    @tailrec
    def buildDetails(deliveryEvents: Seq[DeliveryEvent],
                     deliveryDetailsByUser: DeliveryDetailsByUser): DeliveryDetailsByUser =
      deliveryEvents match {
        case event :: tail =>
          val details =
            DeliveryMediumDetails(DeliveryMediumStatus.toString(event.status), event.createAt, event.updateAt)

          val updatedDetails = deliveryDetailsByUser
            .modify(_.sms)
            .setToIf(event.medium == DeliveryEventMedium.Sms)(Some(details))
            .modify(_.email)
            .setToIf(event.medium == DeliveryEventMedium.Email)(Some(details))
            .modify(_.push)
            .setToIf(event.medium == DeliveryEventMedium.PushNotification)(Some(details))
            .modify(_.voice)
            .setToIf(event.medium == DeliveryEventMedium.VoiceCall)(
              Some(
                details
                  .modify(_.data)
                  .setTo(event.info.get("digits").map(d => Map("digits" -> d)))
              )
            )

          buildDetails(tail, updatedDetails)

        case Nil => deliveryDetailsByUser
      }

    buildDetails(deliveryEvents, DeliveryDetailsByUser(userId, None, None, None, None))
  }
}

case class UserFeedbackResponse(userId: UUID,
                                options: Seq[FeedbackIdValue],
                                displayTitle: String,
                                displaySummary: String,
                                createdAt: LocalDateTime,
                                updatedAt: LocalDateTime)

case class AlertEventResponse(
    id: UUID,
    alarm: SimpleAlarm,
    deviceId: UUID,
    status: String,
    reason: Option[String],
    snoozeTo: Option[LocalDateTime],
    locationId: UUID,
    systemMode: String,
    displayTitle: String,
    displayMessage: String,
    fwValues: FwValues,
    rawFwPayload: Map[String, Any],
    resolutionDate: Option[LocalDateTime],
    updateAt: LocalDateTime,
    createAt: LocalDateTime,
    deliveryMedium: Seq[DeliveryDetailsByUser],
    healthTest: Option[HealthTestInfo],
    feedback: Option[UserFeedbackResponse]
)

case class HealthTestInfo(roundId: UUID)

case class SimpleAlarm(id: Int, severity: String)

object AlertEventResponse {
  val defaultLocale = "en-us"
  val example = AlertEventResponse(
    UUID.randomUUID(),
    SimpleAlarm(54, "warning"),
    UUID.randomUUID(),
    IncidentStatus.toString(IncidentStatus.Resolved),
    Some(IncidentReason.toString(IncidentReason.Cleared)),
    None,
    UUID.randomUUID(),
    SystemMode.toString(SystemMode.Away),
    "High Water Usage",
    "You have a fast water flow detected alert.",
    FwValues(20.4, 34.5, 34, 53, 34, 30),
    Map(),
    None,
    LocalDateTime.now(),
    LocalDateTime.now(),
    Seq(
      DeliveryDetailsByUser(
        UUID.randomUUID().toString,
        Some(DeliveryMediumDetails("queued", LocalDateTime.now(), LocalDateTime.now())),
        None,
        None,
        None
      )
    ),
    None,
    None
  )

  def apply(incidentWithAlarmInfo: IncidentWithAlarmInfo,
            deliveryEvents: Seq[DeliveryEvent],
            title: String,
            message: String,
            feedback: Option[UserFeedbackResponse]): AlertEventResponse = {

    val incident = incidentWithAlarmInfo.incident
    val alarm    = incidentWithAlarmInfo.alarm

    val resolutionDate = if (incident.status == IncidentStatus.Resolved) Some(incident.updateAt) else None

    AlertEventResponse(
      incident.id,
      SimpleAlarm(alarm.id, Severity.toString(alarm.severity)),
      incident.icdId,
      IncidentStatus.toString(incident.status),
      incident.reason.map(IncidentReason.toString),
      incident.snoozeTo,
      incident.locationId,
      SystemMode.toString(incident.systemMode),
      title,
      message,
      FwValues(incident.dataValues, alarm),
      incident.dataValues,
      resolutionDate,
      incident.updateAt,
      incident.createAt,
      deliveryEvents
        .groupBy(_.userId)
        .map {
          case (userId, events) =>
            DeliveryDetailsByUser.fromEvents(userId.toString, events)
        }
        .toSeq,
      incident.healthTestRoundId.map(HealthTestInfo),
      feedback
    )
  }
}
