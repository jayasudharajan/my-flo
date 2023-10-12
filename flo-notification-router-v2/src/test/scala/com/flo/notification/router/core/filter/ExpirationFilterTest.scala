package com.flo.notification.router.core.filter

import java.time.{Clock, Duration, Instant, ZoneId}

import com.flo.AsyncTest
import com.flo.notification.router.core.api._

class ExpirationFilterTest extends AsyncTest {
  private val clock  = Clock.fixed(Instant.parse("2019-08-01T10:15:30Z"), ZoneId.of("UTC"))
  private val alarm  = randomAlarm
  private val user   = randomUser
  private val device = randomDevice

  "Expiration Filter" - {
    "should allow all mediums when alarm incident is not expired" in {
      val nonExpiredAlarmIncident = randomAlarmIncident.copy(timestamp = 1564663500000L) // 2019-08-01T09:45:00

      new ExpirationFilter(clock, Duration.ofDays(30)).apply(nonExpiredAlarmIncident, alarm, user, device).map {
        filterResult =>
          filterResult shouldEqual AllMediumsAllowed
      }
    }

    "should deny all mediums when alarm incident is expired" in {
      val nonExpiredAlarmIncident = randomAlarmIncident.copy(timestamp = 1559393100000L) // 2019-06-01T09:45:00

      new ExpirationFilter(clock, Duration.ofDays(30)).apply(nonExpiredAlarmIncident, alarm, user, device).map {
        filterResult =>
          filterResult shouldEqual NoMediumsAllowed(Expired)
      }
    }
  }
}
