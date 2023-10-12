package com.flo.notification.router.core

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.alert.{Ignored, Resolved}
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.SystemMode
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class ProcessAlertStatus(retrieveUsersByMacAddress: UsersByMacAddressRetriever,
                         resolvePendingAlertsForAlarm: PendingAlertsForAlarmResolver,
                         convertToAlarmIncident: AlarmIncidentConverter,
                         processAlarmIncident: AlarmIncidentProcessor,
                         cancelDelivery: DeliveryCancel)(implicit ec: ExecutionContext)
    extends AlertStatusProcessor {

  import ProcessAlertStatus.log

  // TODO: Make these configurable.
  private val AlarmIdsResolutionNotification = Set(10, 11, 26)

  override def apply(alert: Alert): Future[Unit] =
    alert.status match {
      case Resolved => onIgnoredOrResolvedStatus(alert)
      case Ignored  => onIgnoredOrResolvedStatus(alert)
      case _ =>
        log.info(
          p"Ignoring Alert Status for alarmId=${alert.alarmId}, macAddress=${alert.macAddress}, status=${alert.status}."
        )
        Future.unit
    }

  private def onIgnoredOrResolvedStatus(alert: Alert): Future[Unit] = {
    log.info(p"Processing Alert Status: $alert")

    retrieveUsersByMacAddress(alert.macAddress).flatMap {
      case None =>
        log.warn(p"No device found with MAC address ${alert.macAddress}.")
        Future.unit

      case Some(deviceUsers) =>
        doProcess(alert, deviceUsers.users, deviceUsers.device)
    }
  }

  private def doProcess(alert: Alert, users: Seq[User], device: Device): Future[Unit] = {
    log.info(p"Resolving pending alerts for Device=${device.id}, Alarm=${alert.alarmId}")

    resolvePendingAlertsForAlarm(device.id, alert.alarmId, DeviceAlertStatus).flatMap { resolvedIncidents =>
      log.info(
        p"Pending alerts for Device=${device.id}, Alarm=${alert.alarmId} were resolved: ${resolvedIncidents.map(_.id).mkString("[", ",", "]")}"
      )

      resolvedIncidents.foreach { incident =>
        users.foreach { user =>
          // TODO: Optimize this to cancel only deliveries that were scheduled.
          doCancelDelivery(VoiceCallMedium, alert.alarmId, user.id, device.id, incident.id.toString)
          doCancelDelivery(PushNotificationMedium, alert.alarmId, user.id, device.id, incident.id.toString)
          doCancelDelivery(SmsMedium, alert.alarmId, user.id, device.id, incident.id.toString)
          doCancelDelivery(EmailMedium, alert.alarmId, user.id, device.id, incident.id.toString)
        }
      }

      if (isAlertResolvedNotificationEnabled(alert)) {
        Future
          .traverse(resolvedIncidents) { incident =>
            val alertResolvedIncident = convertToAlarmIncident(alert, incident)
            log.info(p"Processing Alert Resolved incident: $alertResolvedIncident")
            processAlarmIncident(alertResolvedIncident)
          }
          .map(_ => ())
      } else Future.unit
    }
  }

  private def doCancelDelivery(deliveryMedium: DeliveryMedium,
                               alarmId: AlarmId,
                               userId: UserId,
                               deviceId: DeviceId,
                               incidentId: AlarmIncidentId): Future[Unit] = {
    log.debug(
      p"Canceling ${deliveryMedium.toString} call delivery for Alarm=$alarmId, User=$userId, Device=$deviceId}, Incident=$incidentId"
    )
    val eventualCancellation = cancelDelivery(deliveryMedium, alarmId, userId, deviceId, incidentId)
    eventualCancellation.failed.foreach { t =>
      log.warn(
        p"Error canceling ${deliveryMedium.toString} for Alarm=$alarmId, User=$userId, Device=$deviceId, Incident=$incidentId",
        t
      )
    }
    eventualCancellation
  }

  private def isAlertResolvedNotificationEnabled(alert: Alert): Boolean =
    AlarmIdsResolutionNotification.contains(alert.alarmId) && alert.systemMode == SystemMode.Home
}

private object ProcessAlertStatus {
  private val log = logbookFor(getClass)
}
