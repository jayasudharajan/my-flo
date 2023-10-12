package com.flo.notification.router.core.filter

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import scala.concurrent.Future

final private class FloSenseFilter(shutoffExceptions: Set[AlarmId], floSenseAlarms: Set[AlarmId])
    extends AlarmIncidentFilter {

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] = {
    val metadata = alarmIncident.metadata

    Future.successful {
      if (shutoffExceptions.contains(alarm.id) && metadata.shutoffTriggered.contains(false)) {
        NoMediumsAllowed(FloSenseShutoffNotTriggered)
      } else if (floSenseAlarms.contains(alarm.id)) {
        val deviceFloSenseLevel = device.floSenseLevel.getOrElse(0)

        if (metadata.shutoffTriggered.contains(false))
          NoMediumsAllowed(FloSenseShutoffNotTriggered)
        else if (metadata.flosenseShutoffLevel.exists(_ < deviceFloSenseLevel))
          NoMediumsAllowed(FloSenseLevelNotReached)
        else if (metadata.inSchedule.contains(true))
          NoMediumsAllowed(FloSenseInSchedule)
        else AllMediumsAllowed

      } else {
        AllMediumsAllowed
      }
    }
  }
}
