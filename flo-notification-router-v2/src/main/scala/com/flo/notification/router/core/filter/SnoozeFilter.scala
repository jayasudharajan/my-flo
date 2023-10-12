package com.flo.notification.router.core.filter
import java.time.{Clock, LocalDateTime}

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private class SnoozeFilter(clock: Clock, retrieveSnoozeTime: SnoozeTimeRetriever)(
    implicit ec: ExecutionContext
) extends AlarmIncidentFilter {

  import SnoozeFilter.log

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    retrieveSnoozeTime(alarm.id, device.id, device.location.id, user.id).map { maybeSnoozeTime =>
      log.debug(
        p"Retrieved Snooze Time for Alarm ${alarm.id}, Device ${device.id} and Location ${device.location.id} => $maybeSnoozeTime"
      )

      maybeSnoozeTime
        .filter(snoozeTime => LocalDateTime.now(clock).isBefore(snoozeTime))
        .fold[FilterResult](AllMediumsAllowed) { _ =>
          NoMediumsAllowed(Snoozed)
        }
    }
}

object SnoozeFilter {
  private val log = logbookFor(getClass)
}
