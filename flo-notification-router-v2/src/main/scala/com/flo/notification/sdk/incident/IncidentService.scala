package com.flo.notification.sdk.incident

import java.time.{Clock, Instant, LocalDateTime}
import java.util.UUID

import com.flo.json4s.SimpleSerialization
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.circe.DeserializeTelemetrySnapshot
import com.flo.notification.sdk.model.{
  Incident,
  IncidentSource,
  IncidentText,
  JsonString,
  LocalizedText,
  UserAlarmSettings
}

import com.flo.notification.sdk.service.{IncidentReason, IncidentStatus, NotificationService}
import com.flo.util.Meter
import com.flo.util.TypeConversions.Uuid._
import com.softwaremill.quicklens._
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class IncidentService(
    clock: Clock,
    notificationService: NotificationService,
    latestHealthTestByDeviceIdRetriever: LatestHealthTestByDeviceIdRetriever,
    generateUuid: => String
)(implicit ec: ExecutionContext) {

  import IncidentService.log

  private val ResolvedAlarmId   = 45
  private val SmallDripAlarmIds = Set(28, 29, 30, 31)

  def retrieveFrequencyCapExpiration(alarmId: AlarmId,
                                     deviceId: DeviceId,
                                     userId: UserId): Future[Option[LocalDateTime]] =
    notificationService.getFrequencyCapExpiration(alarmId, deviceId, userId)

  def retrieveSnoozeTime(alarmId: AlarmId,
                         deviceId: DeviceId,
                         locationId: LocationId,
                         userId: UserId): Future[Option[LocalDateTime]] =
    notificationService.getSnoozeTime(alarmId, deviceId, locationId, userId)

  def registerIncident(incidentInfo: IncidentInfo): Future[Unit] = {

    val (incidentStatus, incidentReason) = incidentInfo.alarmStatus match {
      case Received => (IncidentStatus.Received, None)

      case Filtered(reason) =>
        (IncidentStatus.Filtered, Some(filterReasonToInt(reason)))

      case Triggered => (IncidentStatus.Triggered, None)

      case Resolved(reason) => (IncidentStatus.Resolved, reason.map(x => filterReasonToInt(x)))
    }

    val isSmallDripAlert = SmallDripAlarmIds.contains(incidentInfo.alarmId)
    val maybeRoundId     = incidentInfo.alarmIncident.metadata.roundId
    val isRoundIdEmpty   = maybeRoundId.isEmpty

    val eventualRoundId = if (isRoundIdEmpty && isSmallDripAlert) {
      latestHealthTestByDeviceIdRetriever(incidentInfo.deviceId).map { maybeLastHealthTest =>
        maybeLastHealthTest
          .filter(_.created.isAfter(LocalDateTime.now().minusSeconds(150)))
          .map(_.roundId)
      }
    } else {
      Future.successful(maybeRoundId)
    }

    eventualRoundId.flatMap { roundId =>
      val incident = Incident(
        incidentInfo.alarmIncident.id,
        incidentInfo.alarmId,
        incidentInfo.deviceId,
        incidentStatus,
        incidentReason,
        None,
        incidentInfo.locationId,
        incidentInfo.alarmIncident.systemMode,
        incidentInfo.accountId,
        incidentInfo.groupId.map(UUID.fromString),
        roundId,
        toMap(incidentInfo.alarmIncident.snapshot),
        LocalDateTime.now(clock),
        LocalDateTime.ofInstant(Instant.ofEpochMilli(incidentInfo.alarmIncident.timestamp), clock.getZone.normalized())
      )

      Meter.time("upsertIncident") {
        incidentInfo.alarmIncident.raw.foreach { rawJson =>
          if (incidentInfo.alarmStatus == Received) {
            notificationService
              .createIncidentSource(
                IncidentSource(
                  incidentInfo.alarmIncident.id,
                  incidentInfo.deviceId,
                  JsonString(rawJson.noSpaces),
                  LocalDateTime.now(clock)
                )
              )
              .failed
              .foreach { t =>
                log.warn(p"Failed creating Incident Source with ID ${incidentInfo.alarmIncident.id}", t)
              }
          }
        }

        if (incidentInfo.localizedTexts.nonEmpty) {
          notificationService
            .createIncidentText(
              IncidentText(
                incidentInfo.alarmIncident.id,
                incidentInfo.deviceId,
                incidentInfo.localizedTexts.foldLeft(Map.empty[String, Set[LocalizedText]]) {
                  case (acc, (titleAndMessage, (locales, unitSystems))) =>
                    val unitSystemsStr = unitSystems.map(_.toString.toLowerCase)
                    acc
                      .updated(
                        "title", {
                          val titles             = acc.getOrElse("title", Set.empty[LocalizedText])
                          val maybeLocalizedText = titles.find(_.value == titleAndMessage.title)
                          maybeLocalizedText.fold(titles)(titles - _) + maybeLocalizedText
                            .map { localizedText =>
                              localizedText
                                .modify(_.lang)
                                .setTo(localizedText.lang ++ locales)
                                .modify(_.unitSystems)
                                .setTo(localizedText.unitSystems ++ unitSystemsStr)
                            }
                            .getOrElse(LocalizedText(titleAndMessage.title, locales, unitSystemsStr))
                        }
                      )
                      .updated(
                        "message", {
                          val messages           = acc.getOrElse("message", Set.empty[LocalizedText])
                          val maybeLocalizedText = messages.find(_.value == titleAndMessage.message)
                          maybeLocalizedText.fold(messages)(messages - _) + maybeLocalizedText
                            .map { localizedText =>
                              localizedText
                                .modify(_.lang)
                                .setTo(localizedText.lang ++ locales)
                                .modify(_.unitSystems)
                                .setTo(localizedText.unitSystems ++ unitSystemsStr)
                            }
                            .getOrElse(LocalizedText(titleAndMessage.message, locales, unitSystemsStr))
                        }
                      )
                },
                LocalDateTime.now(clock)
              )
            )
            .failed
            .foreach { t =>
              log.warn(p"Failed creating Incident Text with ID ${incidentInfo.alarmIncident.id}", t)
            }
        }

        notificationService.upsertIncident(incident, incidentInfo.userId.map(UUID.fromString)).map(_ => ())
      }
    }
  }

  def registerDeliveryMediumTriggered(alarmIncidentId: AlarmIncidentId,
                                      deliveryMedium: DeliveryMediumId,
                                      userId: UserId): Future[Unit] =
    notificationService
      .registerDeliveryMediumTriggered(
        alarmIncidentId,
        deliveryMedium,
        userId
      )
      .map(_ => ())

  def resolveHealthTestRelatedAlarms(deviceId: DeviceId): Future[Unit] =
    notificationService
      .resolvePendingIncidents(deviceId, SmallDripAlarmIds, Some(IncidentReason.HealthTestSuccessful))
      .map(_ => ())

  def resolvePendingAlerts(deviceId: DeviceId, reason: FilterReason): Future[Unit] =
    notificationService.resolvePendingIncidents(deviceId, Set(), Some(filterReasonToInt(reason))).map(_ => ())

  def resolvePendingAlerts(deviceId: DeviceId, alarmId: AlarmId, reason: FilterReason): Future[Seq[Incident]] =
    notificationService.resolvePendingIncidents(deviceId, Set(alarmId), Some(filterReasonToInt(reason)))

  def getUserAlarmSettings(userId: UserId, deviceId: DeviceId): Future[Option[UserAlarmSettings]] =
    notificationService
      .getUserAlarmSettings(userId, List(deviceId))
      .map(_.headOption)

  private def filterReasonToInt(incidentReason: FilterReason): Int = incidentReason match {
    case DeliverySettingsNotFound         => IncidentReason.DeliverySettingsNotFound
    case MaxDeliveryFrequencyCap          => IncidentReason.MaxDeliveryFrequencyCap
    case MultipleFilterMerge              => IncidentReason.MultipleFilterMerge
    case DeliverySettingsNoMediumsAllowed => IncidentReason.DeliverySettingsNoMediumAllowed
    case Cleared                          => IncidentReason.Cleared
    case Snoozed                          => IncidentReason.Snoozed
    case AlarmIsInternal                  => IncidentReason.Internal
    case AlarmIsDisabled                  => IncidentReason.Disabled
    case Expired                          => IncidentReason.Expired
    case AlarmNoMediumsAllowed            => IncidentReason.AlarmNoMediumAllowed
    case PointsLimitNotReachedForCategory => IncidentReason.PointsLimitNotReachedForCategory
    case ValveClosed                      => IncidentReason.ValveClosed
    case DeviceUnpaired                   => IncidentReason.DeviceUnpaired
    case SmallDripSensitivity             => IncidentReason.SmallDripSensitivity
    case DeviceAlertStatus                => IncidentReason.DeviceAlertStatus
    case SleepMode                        => IncidentReason.SleepMode
    case FloSenseInSchedule               => IncidentReason.FloSenseInSchedule
    case FloSenseLevelNotReached          => IncidentReason.FloSenseLevelNotReached
    case FloSenseShutoffNotTriggered      => IncidentReason.FloSenseShutoffNotTriggered
    case AlarmsMuted                      => IncidentReason.Muted
  }

  def convertToAlarmIncident(alert: Alert, resolvedIncident: Incident): AlarmIncident = {
    // TODO: Inject this function?
    val telemetrySnapshot =
      new DeserializeTelemetrySnapshot()(SimpleSerialization.serializeWithoutConversions(resolvedIncident.dataValues))
    val resolvedTimestamp = resolvedIncident.createAt.atZone(clock.getZone).toInstant.toEpochMilli

    AlarmIncident(
      id = generateUuid,
      timestamp = alert.timestamp,
      macAddress = alert.macAddress,
      systemMode = alert.systemMode,
      alarmId = ResolvedAlarmId,
      metadata = AlarmIncidentMetadata(alert.metadata.flatMap(_.roundId), None, None, None, None, None, None),
      snapshot = alert.telemetrySnapshot,
      raw = alert.raw,
      applicationType = None,
      Some(
        AlarmIncident(
          id = resolvedIncident.id.toString,
          timestamp = resolvedTimestamp,
          macAddress = alert.macAddress,
          systemMode = resolvedIncident.systemMode,
          alarmId = resolvedIncident.alarmId,
          metadata = AlarmIncidentMetadata(
            roundId = resolvedIncident.healthTestRoundId,
            flosenseStrength = None,
            flosenseShutoffEnabled = None,
            shutoffEpochSec = None,
            inSchedule = None,
            flosenseShutoffLevel = None,
            shutoffTriggered = None
          ),
          snapshot = telemetrySnapshot,
          raw = None,
          applicationType = None
        )
      )
    )
  }

  def cleanUpDeviceData(deviceId: DeviceId): Future[Unit] = {
    val eventualFilterStateDeletion      = notificationService.deleteFilterStateByDeviceId(deviceId)
    val eventualDeliverySettingsDeletion = notificationService.deleteDeliverySettingsByDeviceId(deviceId)
    val eventualAlarmSettingsDeletion    = notificationService.deleteUserAlarmSettingsByDeviceId(deviceId)

    Future
      .sequence(Seq(eventualFilterStateDeletion, eventualDeliverySettingsDeletion, eventualAlarmSettingsDeletion))
      .map(_ => ())
  }

  private def toMap(p: Product): Map[String, Any] = {
    val values = p.productIterator
    p.getClass.getDeclaredFields.map(_.getName -> values.next).toMap
  }
}

object IncidentService {
  private val log = logbookFor(getClass)
}
