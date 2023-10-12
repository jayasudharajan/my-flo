package com.flo.notification.sdk.model.activity

import java.time.LocalDateTime
import java.util.UUID

import com.flo.notification.sdk.model.{Alarm, DeliveryEvent, DeliveryEventMedium, Incident, Severity, SystemMode}
import com.flo.notification.sdk.service.{DeliveryMediumStatus, IncidentReason, IncidentStatus}
import com.softwaremill.quicklens._

import scala.annotation.tailrec

case class EntityActivity(date: LocalDateTime,
                          `type`: String,
                          action: String,
                          id: UUID,
                          item: EntityActivityItem)


case class Device(id: UUID, macAddress: String)

case class EntityActivityItem(id: UUID,
                              alarm: SimpleAlarm,
                              device: Device,
                              status: String,
                              reason: Option[String],
                              snoozeTo: Option[LocalDateTime],
                              locationId: UUID,
                              systemMode: String,
                              fwValues: FwValues,
                              resolutionDate: Option[LocalDateTime],
                              updateAt: LocalDateTime,
                              createAt: LocalDateTime,
                              deliveryMedium: Seq[DeliveryDetailsByUser])

object EntityActivityItem {
  def build(incident: Incident, deliveryEvents: Seq[DeliveryEvent], maybeAlarm: Option[Alarm], macAddress: String): EntityActivityItem = {
    EntityActivityItem(
      id = incident.id,
      alarm = SimpleAlarm(
        id = maybeAlarm.map(_.id).getOrElse(incident.alarmId),
        severity = maybeAlarm.map(a => Severity.toString(a.severity)).getOrElse("")
      ),
      device = Device(incident.icdId, macAddress),
      status = IncidentStatus.toString(incident.status),
      reason = incident.reason.map(IncidentReason.toString),
      snoozeTo = incident.snoozeTo,
      locationId = incident.locationId,
      systemMode = SystemMode.toString(incident.systemMode),
      fwValues = FwValues(incident.dataValues, maybeAlarm),
      resolutionDate = if (incident.status == IncidentStatus.Resolved) Some(incident.updateAt) else None,
      updateAt = incident.updateAt,
      createAt = incident.createAt,
      deliveryMedium = deliveryEvents
        .groupBy(_.userId)
        .map { case (userId, events) =>
          DeliveryDetailsByUser.fromEvents(userId.toString, events)
        }
        .toSeq
    )
  }
}

case class SimpleAlarm(id: Int, severity: String)

case class FwValues(gpm: Any,
                    galUsed: Any,
                    psiDelta: Any,
                    leakLossMinGal: Any,
                    leakLossMaxGal: Any,
                    flowEventDuration: Any)

object FwValues {
  def apply(dataValues: Map[String, Any], maybeAlarm: Option[Alarm]): FwValues = {
    val leakLossMinGal = maybeAlarm.flatMap(_.metadata.get("leakLossMinGal")).getOrElse(0.0D)
    val leakLossMaxGal = maybeAlarm.flatMap(_.metadata.get("leakLossMaxGal")).getOrElse(0.0D)

    FwValues(
      gpm = dataValues.getOrElse("fr", None),
      galUsed = dataValues.getOrElse("ft", None),
      psiDelta = None,
      leakLossMinGal,
      leakLossMaxGal,
      flowEventDuration = dataValues.getOrElse("efd", None)
    )
  }
}

case class DeliveryDetailsByUser(userId: String,
                                 sms: Option[DeliveryMediumDetails],
                                 email: Option[DeliveryMediumDetails],
                                 push: Option[DeliveryMediumDetails],
                                 voice: Option[DeliveryMediumDetails])

case class DeliveryMediumDetails(status: String, createdAt: LocalDateTime, updatedAt: LocalDateTime)

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
            .setToIf(event.medium == DeliveryEventMedium.VoiceCall)(Some(details))

          buildDetails(tail, updatedDetails)

        case Nil => deliveryDetailsByUser
      }

    buildDetails(deliveryEvents, DeliveryDetailsByUser(userId, None, None, None, None))
  }
}