package com.flo.notification.router.core.filter

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private class AlarmIncidentFilters(filters: Seq[AlarmIncidentFilter])(
    implicit ec: ExecutionContext
) {

  import AlarmIncidentFilters.log

  def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] = {

    def applyFilters(filters: Seq[AlarmIncidentFilter], filterResult: FilterResult): Future[FilterResult] =
      filters match {
        case filter :: tail =>
          log.debug(
            p"Applying filter ${filter.getClass.getSimpleName} to AlarmIncident=${alarmIncident.id}, " +
              p"Alarm=${alarm.id}, User=${user.id}, Device=${device.id}"
          )

          filter(alarmIncident, alarm, user, device).flatMap { currentFilterResult =>
            log.debug(
              p"Applied filter ${filter.getClass.getSimpleName} to AlarmIncident=${alarmIncident.id}, " +
                p"Alarm=${alarm.id}, User=${user.id}, Device=${device.id} => $currentFilterResult"
            )

            filterResult.merge(currentFilterResult) match {
              case noMediumsAllowed: NoMediumsAllowed =>
                Future.successful(noMediumsAllowed)
              case allOrSome => applyFilters(tail, allOrSome)
            }
          }

        case Nil => Future.successful(filterResult)
      }

    applyFilters(filters, AllMediumsAllowed)
  }

}

private object AlarmIncidentFilters {
  private val log = logbookFor(getClass)
}
