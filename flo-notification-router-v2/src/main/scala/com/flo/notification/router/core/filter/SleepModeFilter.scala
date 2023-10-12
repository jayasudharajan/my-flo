package com.flo.notification.router.core.filter

import com.flo.Enums.ValveModes
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.Future

final private class SleepModeFilter(exceptions: Set[AlarmId]) extends AlarmIncidentFilter {

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    alarmIncident.systemMode match {
      case ValveModes.SLEEP if exceptions.contains(alarm.id) =>
        Future.successful(AllMediumsAllowed)

      case ValveModes.SLEEP =>
        Future.successful(NoMediumsAllowed(SleepMode))

      case _ =>
        Future.successful(AllMediumsAllowed)
    }
}
