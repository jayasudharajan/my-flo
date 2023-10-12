package com.flo.notification.router.core.filter

import cats.data.NonEmptySet
import com.flo.AsyncTest
import com.flo.notification.router.core.api.Fixture._
import com.flo.notification.router.core.api._

import scala.concurrent.Future

class AlarmIncidentFiltersTest extends AsyncTest {

  "AlarmIncidentFilter" - {

    "should merge filter results - None" in {
      val f1 = newAlarmIncidentFilter(NoMediumsAllowed(MultipleFilterMerge))
      val f2 = newAlarmIncidentFilter(AllMediumsAllowed)

      new AlarmIncidentFilters(Seq(f1, f2)).apply(randomAlarmIncident, randomAlarm, user, device).map {
        allowedMediums =>
          allowedMediums shouldEqual NoMediumsAllowed(MultipleFilterMerge)
      }
    }

    "should merge filter results - All" in {
      val f1 = newAlarmIncidentFilter(AllMediumsAllowed)
      val f2 = newAlarmIncidentFilter(AllMediumsAllowed)

      new AlarmIncidentFilters(Seq(f1, f2)).apply(randomAlarmIncident, randomAlarm, user, device).map {
        allowedMediums =>
          allowedMediums shouldEqual AllMediumsAllowed
      }
    }

    "should merge filter results - Mixed" in {
      val f1 = newAlarmIncidentFilter(AllMediumsAllowed)
      val f2 = newAlarmIncidentFilter(
        AllowedMediums(NonEmptySet.of(SmsMedium, EmailMedium, PushNotificationMedium, VoiceCallMedium))
      )
      val f3 =
        newAlarmIncidentFilter(AllowedMediums(NonEmptySet.of(EmailMedium, PushNotificationMedium, VoiceCallMedium)))
      val f4 = newAlarmIncidentFilter(AllowedMediums(NonEmptySet.of(PushNotificationMedium, VoiceCallMedium)))

      new AlarmIncidentFilters(Seq(f1, f2, f3, f4)).apply(randomAlarmIncident, randomAlarm, user, device).map {
        allowedMediums =>
          allowedMediums shouldEqual AllowedMediums(NonEmptySet.of(PushNotificationMedium, VoiceCallMedium))
      }
    }

  }

  private def newAlarmIncidentFilter(result: FilterResult): AlarmIncidentFilter =
    (_, _, _, _) => Future.successful(result)

}
