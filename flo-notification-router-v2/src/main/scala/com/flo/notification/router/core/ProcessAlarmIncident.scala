package com.flo.notification.router.core

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.{AutoResolutionFilterReason, DeliveryFilterReason, _}
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.sdk.model.{Alarm, Severity, SystemMode}
import com.flo.util.Meter
import perfolation._
import com.softwaremill.quicklens._

import scala.concurrent.{ExecutionContext, Future}

final private class ProcessAlarmIncident(
    retrieveUsersByMacAddress: UsersByMacAddressRetriever,
    retrieveAlarm: AlarmRetriever,
    deliverAlarmIncident: AlarmIncidentDelivery,
    applyAlarmIncidentFilters: AlarmIncidentFilter,
    registerIncident: RegisterIncident,
    localizationService: LocalizationService,
    resolveHealthTestRelatedAlarms: HealthTestRelatedAlarmsResolver
)(implicit ec: ExecutionContext)
    extends AlarmIncidentProcessor {

  import ProcessAlarmIncident.log

  override def apply(alarmIncident: AlarmIncident): Future[Unit] = {
    log.info(p"Processing Alarm Incident: $alarmIncident")

    Meter
      .time("retrieveUsersByMacAddress") {
        retrieveUsersByMacAddress(alarmIncident.macAddress)
      }
      .flatMap {
        case None =>
          log.warn(p"No device found with MAC address ${alarmIncident.macAddress}.")
          Future.unit

        case Some(deviceUsers) =>
          // Warning. Any exception here will be swallowed. We don't need to bubble them up for now.
          // TODO: Check if this is what we actually want. Add retry strategy here?

          Meter.time("processAlarmForDevice") {
            processAlarmForDevice(alarmIncident, deviceUsers.device)
          }

          Future
            .traverse(deviceUsers.users) { user =>
              processAlarmForUser(alarmIncident, user, deviceUsers.device)
            }
            .map(_ => ())
      }
  }

  // TODO: Refactor this to have two different pipelines for processing alarms? (i.e. two different consumers)
  private val AutoHealthTestSuccessful   = 5
  private val ManualHealthTestSuccessful = 34
  private val HealthTestSuccessfulAlarms = Set(AutoHealthTestSuccessful, ManualHealthTestSuccessful)

  private def processAlarmForDevice(alarmIncident: AlarmIncident, device: Device): Future[Unit] =
    if (HealthTestSuccessfulAlarms.contains(alarmIncident.alarmId)) {
      resolveHealthTestRelatedAlarms(device.id)
    } else Future.unit

  private def processAlarmForUser(alarmIncident: AlarmIncident, user: User, device: Device): Future[Unit] =
    Meter.time("processAlarmForUser") {
      val alarmId = alarmIncident.alarmId

      log.debug(p"Retrieving Alarm with ID $alarmId")

      Meter
        .time("retrieveAlarm") {
          retrieveAlarm(alarmId)
        }
        .flatMap {
          case None =>
            log.error(p"No Alarm found for AlarmId=$alarmId")
            Future.unit

          case Some(alarm) =>
            log.debug(p"Alarm found with ID $alarmId => $alarm")

            val eventualReceivedIncident = Meter.time("registerIncident") {
              registerIncident(
                IncidentInfo(
                  alarmIncident,
                  alarmId,
                  device.id,
                  device.location.id,
                  user.account.id,
                  user.groupId,
                  Received
                )
              )
            }

            eventualReceivedIncident.flatMap { _ =>
              log.debug(
                p"Applying filters to AlarmIncident=${alarmIncident.id}, " +
                  p"Alarm=${alarm.id}, User=${user.id}, Device=${device.id}"
              )

              Meter
                .time("applyAlarmIncidentFilters") {
                  applyAlarmIncidentFilters(alarmIncident, alarm, user, device)
                }
                .flatMap {

                  case noMediumsAllowed @ NoMediumsAllowed(reason) =>
                    log.info(
                      p"Incident id ${alarmIncident.id} from device ${device.id} about alarm $alarmId was filtered for User ${user.id}. No messages will be delivered. Filter Result = $noMediumsAllowed"
                    )
                    setIncidentStatus(
                      alarmIncident,
                      alarm,
                      user,
                      device,
                      Some(reason)
                    )

                  case filterResult =>
                    log.debug(
                      p"Applied filters to AlarmIncident=${alarmIncident.id}, " +
                        p"Alarm=${alarm.id}, User=${user.id}, Device=${device.id}. Filter Result = $filterResult"
                    )

                    val deliverySettings = DeliverySettings(
                      sms = filterResult.allows(SmsMedium),
                      email = filterResult.allows(EmailMedium),
                      pushNotification = filterResult.allows(PushNotificationMedium),
                      voiceCall = filterResult.allows(VoiceCallMedium)
                    )

                    deliverAlarmIncident(alarmIncident, alarm, user, device, deliverySettings).flatMap { _ =>
                      setIncidentStatus(alarmIncident, alarm, user, device)
                    }
                }
            }
        }
    }

  private def setIncidentStatus(alarmIncident: AlarmIncident,
                                alarm: Alarm,
                                user: User,
                                device: Device,
                                reason: Option[FilterReason] = None): Future[Unit] = {

    val status = {
      if (isInfoSeverity(alarm)) Resolved(reason)
      else {
        reason
          .map {
            case r if r.isInstanceOf[DeliveryFilterReason]       => Triggered
            case r if r.isInstanceOf[AutoResolutionFilterReason] => Resolved(reason)
            case r                                               => Filtered(r)
          }
          .getOrElse(Triggered)
      }
    }

    val incidentInfo = IncidentInfo(
      alarmIncident,
      alarm.id,
      device.id,
      device.location.id,
      user.account.id,
      user.groupId,
      status
    )

    status match {
      case Filtered(_) => registerIncident(incidentInfo)

      case _ =>
        val systemMode            = SystemMode.toString(alarmIncident.systemMode)
        val eventualLocalizedArgs = localizationService.buildDefaultFullyLocalizedArgs(alarmIncident, user, device)

        for {
          localizedArgs <- eventualLocalizedArgs
          localizedTitleAndMessages <- localizationService.retrieveLocalizedAlarmTitleAndMessage(
                                        alarm.id,
                                        systemMode,
                                        localizedArgs
                                      )
        } yield {
          registerIncident(
            incidentInfo
              .modify(_.localizedTexts)
              .setTo(localizedTitleAndMessages)
              .modify(_.userId)
              .setTo(Some(user.id))
          )
        }
    }
  }

  private def isInfoSeverity(alarm: Alarm): Boolean = alarm.severity == Severity.Info
}

private object ProcessAlarmIncident {
  private val log = logbookFor(getClass)
}
