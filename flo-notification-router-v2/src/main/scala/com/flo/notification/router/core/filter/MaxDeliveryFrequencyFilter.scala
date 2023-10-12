package com.flo.notification.router.core.filter

import java.time.{Clock, Instant, LocalDateTime}

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private class MaxDeliveryFrequencyFilter(clock: Clock,
                                               retrieveFrequencyCapExpiration: FrequencyCapExpirationRetriever)(
    implicit ec: ExecutionContext
) extends AlarmIncidentFilter {

  import MaxDeliveryFrequencyFilter.log

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    retrieveFrequencyCapExpiration(alarm.id, device.id, user.id).map { maybeFrequencyCapExpiration =>
      log.debug(
        p"Retrieved Frequency Cap Expiration for Alarm ${alarm.id}, Device ${device.id} and Location ${device.location.id} => $maybeFrequencyCapExpiration"
      )

      val alarmIncidentTimestamp =
        LocalDateTime.ofInstant(Instant.ofEpochMilli(alarmIncident.timestamp), clock.getZone.normalized())

      maybeFrequencyCapExpiration
        .filter(_.isAfter(alarmIncidentTimestamp))
        .fold[FilterResult](AllMediumsAllowed) { _ =>
          NoMediumsAllowed(MaxDeliveryFrequencyCap)
        }
    }
}

private object MaxDeliveryFrequencyFilter {
  private val log = logbookFor(getClass)
}
