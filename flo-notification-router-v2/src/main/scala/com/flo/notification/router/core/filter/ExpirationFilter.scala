package com.flo.notification.router.core.filter

import java.time.{Clock, Duration, Instant, LocalDateTime}

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.Future

final private class ExpirationFilter(clock: Clock, alarmExpiration: Duration) extends AlarmIncidentFilter {
  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    Future.successful {
      if (isAlarmExpired(alarmIncident)) NoMediumsAllowed(Expired)
      else AllMediumsAllowed
    }

  private def isAlarmExpired(alarmIncident: AlarmIncident): Boolean = {
    val alarmIncidentTimestamp =
      LocalDateTime.ofInstant(Instant.ofEpochMilli(alarmIncident.timestamp), clock.getZone.normalized())

    alarmIncidentTimestamp.plus(alarmExpiration).isBefore(LocalDateTime.now(clock))
  }
}
