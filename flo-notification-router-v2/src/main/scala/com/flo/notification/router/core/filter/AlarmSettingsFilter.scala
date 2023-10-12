package com.flo.notification.router.core.filter

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.Future

final private class AlarmSettingsFilter extends AlarmIncidentFilter {

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    Future.successful {
      alarm match {
        case _ if alarm.isInternal                                   => NoMediumsAllowed(AlarmIsInternal)
        case _ if !alarm.enabled                                     => NoMediumsAllowed(AlarmIsDisabled)
        case _ if doNotNotifyWhenValveIsClosed(alarmIncident, alarm) => NoMediumsAllowed(ValveClosed)
        case _                                                       => AllMediumsAllowed
      }
    }

  private def doNotNotifyWhenValveIsClosed(alarmIncident: AlarmIncident, alarm: Alarm): Boolean = {
    val isValveClosed = alarmIncident.snapshot.sw1.contains(0) && alarmIncident.snapshot.sw2.contains(1)

    isValveClosed && !alarm.sendWhenValveIsClosed
  }
}
