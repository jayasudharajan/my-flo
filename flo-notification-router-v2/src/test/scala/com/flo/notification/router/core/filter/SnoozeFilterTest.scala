package com.flo.notification.router.core.filter

import java.time.{Clock, Instant, LocalDateTime, ZoneId}

import com.flo.AsyncTest
import com.flo.notification.router.core.api._
import org.mockito.Mockito.when

import scala.concurrent.Future

class SnoozeFilterTest extends AsyncTest {
  private val clock            = Clock.fixed(Instant.ofEpochMilli(0), ZoneId.of("UTC"))
  private val clockAfterSnooze = Clock.fixed(Instant.ofEpochMilli(1564437228142L), ZoneId.of("UTC"))
  private val alarmIncident    = randomAlarmIncident
  private val snoozeTime       = LocalDateTime.of(2019, 1, 1, 0, 0)

  "Snooze Filter" - {

    "should allow all mediums when there is no latest snoozed alarm event" in {
      val retrieveSnoozeTime = mock[SnoozeTimeRetriever]
      val alarm              = randomAlarm
      val device             = randomDevice
      val user               = randomUser
      val snoozeFilter       = new SnoozeFilter(clock, retrieveSnoozeTime)

      when(retrieveSnoozeTime(alarm.id, device.id, device.location.id, user.id)).thenReturn(Future.successful(None))

      snoozeFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }

    "should return a failed future when retrieving latest snoozed alarm event fails" in {
      val retrieveSnoozeTime = mock[SnoozeTimeRetriever]
      val alarm              = randomAlarm
      val device             = randomDevice
      val user               = randomUser
      val snoozeFilter       = new SnoozeFilter(clock, retrieveSnoozeTime)

      when(retrieveSnoozeTime(alarm.id, device.id, device.location.id, user.id))
        .thenReturn(Future.failed(new RuntimeException))

      snoozeFilter.apply(alarmIncident, alarm, user, device).failed.map { e =>
        e shouldBe an[RuntimeException]
      }
    }

    "should deny all mediums when snooze time is after current time" in {
      val retrieveSnoozeTime = mock[SnoozeTimeRetriever]
      val alarm              = randomAlarm
      val device             = randomDevice
      val user               = randomUser
      val snoozeFilter       = new SnoozeFilter(clock, retrieveSnoozeTime)

      when(retrieveSnoozeTime(alarm.id, device.id, device.location.id, user.id))
        .thenReturn(Future.successful(Some(snoozeTime)))

      snoozeFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual NoMediumsAllowed(Snoozed)
      }
    }

    "should allow all mediums when snooze time is before current time" in {
      val retrieveSnoozeTime = mock[SnoozeTimeRetriever]
      val alarm              = randomAlarm
      val device             = randomDevice
      val user               = randomUser
      val snoozeFilter       = new SnoozeFilter(clockAfterSnooze, retrieveSnoozeTime)

      when(retrieveSnoozeTime(alarm.id, device.id, device.location.id, user.id))
        .thenReturn(Future.successful(Some(snoozeTime)))

      snoozeFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }

  }
}
