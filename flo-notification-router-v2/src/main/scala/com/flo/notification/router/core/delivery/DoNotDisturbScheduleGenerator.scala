package com.flo.notification.router.core.delivery

import java.time._

import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.TimeZoneRetriever
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.{ExecutionContext, Future}

final private class DoNotDisturbScheduleGenerator(
    clock: Clock,
    retrieveDoNotDisturbSettings: DoNotDisturbSettingsRetriever,
    defaultDoNotDisturbSettings: DoNotDisturbSettings,
    getTimeZone: TimeZoneRetriever
)(
    implicit ec: ExecutionContext
) {
  import DoNotDisturbScheduleGenerator.allMediums

  case class AllowedMediumsConfig(
      email: Boolean,
      sms: Boolean,
      pushNotification: Boolean,
      voiceCall: Boolean
  )

  def getMediumSchedule(alarm: Alarm,
                        user: User,
                        device: Device,
                        deliveryMedium: DeliveryMedium): Future[Option[OffsetDateTime]] =
    getMediumsSchedule(alarm, user, device).map {
      case Some(schedule) if schedule.mediums.contains(deliveryMedium) => Some(schedule.time)
      case _                                                           => None
    }

  private def getMediumsSchedule(alarm: Alarm, user: User, device: Device): Future[Option[DoNotDisturbSchedule]] =
    retrieveDoNotDisturbSettings(user.id).map { maybeDndSettings =>
      val dndSettings = maybeDndSettings.getOrElse(defaultDoNotDisturbSettings)
      val zoneId      = getTimeZone(device, user)

      if (!isUserInDoNotDisturbTimeRange(zoneId, dndSettings)) {
        None
      } else {
        if (dndSettings.allowedSeverities.contains(alarm.severity)) {
          None
        } else {
          Some(
            buildResult(
              AllowedMediumsConfig(
                dndSettings.allowEmail,
                dndSettings.allowSms,
                dndSettings.allowPushNotification,
                dndSettings.allowVoiceCall
              ),
              createScheduleTime(dndSettings.endsAt, zoneId)
            )
          )
        }
      }
    }

  private def createScheduleTime(endsAt: LocalTime, zoneId: ZoneId): OffsetDateTime = {
    val zoneOffset = zoneId.getRules
      .getOffset(Instant.now())
    val today = LocalDate.now(zoneId)
    val tentativeDateTime = endsAt
      .atOffset(zoneOffset)
      .atDate(today)

    tentativeDateTime
  }

  private def isUserInDoNotDisturbTimeRange(zoneId: ZoneId, dndSettings: DoNotDisturbSettings): Boolean = {
    val now = LocalTime.now(clock.withZone(zoneId))

    if (dndSettings.startsAt.isAfter(dndSettings.endsAt)) {
      now.isAfter(dndSettings.startsAt) || now.isBefore(dndSettings.endsAt)
    } else now.isAfter(dndSettings.startsAt) && now.isBefore(dndSettings.endsAt)
  }

  private def buildResult(mediumsConfig: AllowedMediumsConfig, scheduleTime: OffsetDateTime): DoNotDisturbSchedule = {
    val sms: List[DeliveryMedium]       = if (mediumsConfig.sms) List(SmsMedium) else List()
    val email: List[DeliveryMedium]     = if (mediumsConfig.email) List(EmailMedium) else List()
    val voiceCall: List[DeliveryMedium] = if (mediumsConfig.voiceCall) List(VoiceCallMedium) else List()
    val push: List[DeliveryMedium]      = if (mediumsConfig.pushNotification) List(PushNotificationMedium) else List()

    val mediumsToDeliverNow             = sms ++ email ++ voiceCall ++ push
    val mediumsToDeliveryOnScheduleTime = allMediums.diff(mediumsToDeliverNow)

    DoNotDisturbSchedule(mediumsToDeliveryOnScheduleTime, scheduleTime)
  }
}

object DoNotDisturbScheduleGenerator {
  private val allMediums = List(EmailMedium, PushNotificationMedium, SmsMedium, VoiceCallMedium)
}
