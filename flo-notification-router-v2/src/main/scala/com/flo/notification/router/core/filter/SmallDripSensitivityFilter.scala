package com.flo.notification.router.core.filter

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.{ExecutionContext, Future}

final private class SmallDripSensitivityFilter(retrieveUserAlarmSettings: UserAlarmSettingsRetriever)(
    implicit ec: ExecutionContext
) extends AlarmIncidentFilter {

  private val alarmsBySensitivity = Map(
    1 -> Set(28),
    2 -> Set(28, 29),
    3 -> Set(28, 29, 30),
    4 -> Set(28, 29, 30, 31)
  )

  private val smallDripAlarms = Set(28, 29, 30, 31)

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    if (!isSmallDripAlarm(alarm)) Future.successful(AllMediumsAllowed)
    else {
      retrieveUserAlarmSettings(user.id, device.id).map { settings =>
        val sensitivity   = settings.flatMap(_.smallDripSensitivity).getOrElse(1)
        val allowedAlarms = alarmsBySensitivity.getOrElse(sensitivity, Set())

        if (allowedAlarms.contains(alarmIncident.alarmId)) AllMediumsAllowed
        else NoMediumsAllowed(SmallDripSensitivity)
      }
    }

  private def isSmallDripAlarm(alarm: Alarm) = smallDripAlarms.contains(alarm.id)
}
