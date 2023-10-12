package com.flo.notification.router.core.filter

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm

import scala.concurrent.{ExecutionContext, Future}

final private class AlarmsMuteFilter(retrieveDeliverySettings: DeliverySettingsRetriever)(
    implicit ec: ExecutionContext
) extends AlarmIncidentFilter {

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode).map { settings =>
      settings
        .filter(_.isMuted)
        .fold[FilterResult](AllMediumsAllowed) { _ =>
          NoMediumsAllowed(AlarmsMuted)
        }
    }

}
